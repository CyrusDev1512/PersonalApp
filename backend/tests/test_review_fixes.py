"""Hồi quy cho các lỗi tìm thấy khi review (mỗi test ứng với một phát hiện đã được xác minh)."""

from __future__ import annotations

import asyncio
import json

import httpx
from sqlmodel import select

from app import clock
from app.ingest.service import ingest_tx, tick
from app.models import Account, Alert, Goal, Transaction
from app.notify.outbox import drain_once
from app.notify.telegram import TelegramClient
from app.seed import category_by_key
from app.services import tx_actions
from app.services.balance import recompute_balance
from app.services.goals import ensure_month_goals
from app.services.notify import reevaluate_and_notify
from app.services.summary import build_evaluation
from tests.test_ingest import MB_NO, VCB_NO, ntx, tx_alerts


def _add_mb(session, balance=0):
    mb = Account(bank="MB", account_number=MB_NO, last4=MB_NO[-4:], name="MB", manual_balance=balance,
                 manual_balance_at=clock.start_of_day_utc(clock.today_ict()))
    session.add(mb)
    session.commit()
    recompute_balance(session, mb)
    session.commit()
    return mb


def _loud(session):
    return [a for a in session.exec(select(Alert).order_by(Alert.id)).all() if a.loud and a.deliver_telegram]


def test_internal_transfer_inflow_first_is_held_and_silent(session, setup, fake_now):
    _add_mb(session)
    ingest_tx(session, ntx(ext="w", amount=3_500_000, balance=6_500_000), event_id=None)  # -> WARNING
    fake_now.advance(hours=3)
    before = len(_loud(session))
    # MB nhận 2tr từ chính mình trước khi webhook VCB tới
    inflow = ingest_tx(session, ntx(source="casso", ext="i1", direction="in", amount=2_000_000, number=MB_NO,
                                    bank="MB", balance=2_000_000, desc="NGUYEN VAN AN chuyen tien"), event_id=None)
    held = session.get(Transaction, inflow.transaction_id)
    assert held.hold_until is not None and held.category_id is None
    assert build_evaluation(session).level == "WARNING"  # tiền vào đang chờ ghép không làm "an toàn" giả
    fake_now.advance(minutes=1)
    ingest_tx(session, ntx(ext="o1", amount=2_000_000, balance=4_500_000, desc="chuyen tien sang MB"),
              event_id=None)
    session.refresh(held)
    assert held.pair_id is not None
    assert len(_loud(session)) == before  # không có tin "an toàn" rồi "cảnh báo" giả


def test_silent_backfill_on_webhook_account_never_spams(session, setup, fake_now):
    ingest_tx(session, ntx(ext="w", amount=10_000, balance=9_990_000, desc="gui xe"), event_id=None)
    n0 = len(tx_alerts(session))
    for i in range(5):
        ingest_tx(session, ntx(source="email", ext=f"<old{i}>", amount=40_000 + i, minutes=-60 * 24 * (i + 1),
                               precision="minute"), event_id=None, notify=False)
    recent = ingest_tx(session, ntx(source="email", ext="<recent>", amount=55_000, minutes=-30,
                                    precision="minute"), event_id=None, notify=False)
    assert session.get(Transaction, recent.transaction_id).status == "pending"
    olds = session.exec(select(Transaction).where(Transaction.amount.between(40_000, 40_004))).all()
    assert {t.status for t in olds} == {"active"}  # quá cũ để chờ webhook
    fake_now.advance(hours=7)
    tick(session)
    assert len(tx_alerts(session)) == n0


def test_rollover_keeps_auto_match_series(session, fake_now):
    food = category_by_key(session, "food")
    main = Goal(series_id="ffff", name="Tiền ăn", type="budget", amount=5_000_000, category_id=food.id,
                month="2026-10")
    extra = Goal(series_id="0000", name="Đi chợ", type="budget", amount=1_000_000, category_id=food.id,
                 month="2026-10")
    session.add(main)
    session.flush()
    session.add(extra)
    session.commit()
    ensure_month_goals(session, "2026-11")
    fake_now.value = fake_now.value.replace(month=11, day=5)
    ev = build_evaluation(session)
    auto = [g.name for g in ev.goals if g.auto_match]
    assert auto == ["Tiền ăn"]


def test_next_month_is_idempotent(session, setup):
    out = ingest_tx(session, ntx(ext="r", amount=3_000_000, balance=7_000_000, desc="tien tro T11"), event_id=None)
    tx = session.get(Transaction, out.transaction_id)
    g1 = tx_actions.assign_next_month(session, tx)
    g2 = tx_actions.assign_next_month(session, tx)
    assert g1.id == g2.id and g1.month == "2026-11"
    assert session.exec(select(Goal).where(Goal.month == "2026-12")).first() is None


def test_exclude_keeps_bank_reported_balance(session, setup):
    out = ingest_tx(session, ntx(ext="x", amount=2_000_000, balance=8_000_000, desc="mua do cong ty"), event_id=None)
    tx = session.get(Transaction, out.transaction_id)
    tx_actions.set_excluded(session, tx, True)
    session.commit()
    assert session.get(Account, setup["vcb"].id).balance == 8_000_000


def test_excluded_transaction_still_dedups_other_sources(session, setup):
    out = ingest_tx(session, ntx(ext="x", amount=150_000, balance=9_850_000, desc="an trua"), event_id=None)
    tx = session.get(Transaction, out.transaction_id)
    tx_actions.set_excluded(session, tx, True)
    session.commit()
    again = ingest_tx(session, ntx(source="email", ext="<x>", amount=150_000, minutes=1, precision="minute"),
                      event_id=None)
    assert again.status == "merged" and again.transaction_id == tx.id
    assert session.get(Transaction, tx.id).status == "excluded"


def test_pending_email_merged_by_webhook_gets_transfer_hold(session, setup, fake_now):
    _add_mb(session)
    ingest_tx(session, ntx(ext="w0", amount=10_000, balance=9_990_000, desc="gui xe"), event_id=None)
    e = ingest_tx(session, ntx(source="email", ext="<t>", amount=4_000_000, precision="minute",
                               desc=f"chuyen tien toi {MB_NO}"), event_id=None)
    assert session.get(Transaction, e.transaction_id).status == "pending"
    n0 = len(_loud(session))
    ingest_tx(session, ntx(ext="w1", amount=4_000_000, minutes=1, balance=5_990_000, desc=f"CK toi {MB_NO}"),
              event_id=None)
    tx = session.get(Transaction, e.transaction_id)
    assert tx.status == "active" and tx.hold_until is not None
    assert len(_loud(session)) == n0


def test_pairing_ignores_pending_email(session, setup, fake_now):
    _add_mb(session)
    ingest_tx(session, ntx(ext="w0", amount=10_000, balance=9_990_000, desc="gui xe"), event_id=None)
    e = ingest_tx(session, ntx(source="email", ext="<t>", amount=2_000_000, precision="minute",
                               desc=f"chuyen tien toi {MB_NO}"), event_id=None)
    ingest_tx(session, ntx(source="casso", ext="i", direction="in", amount=2_000_000, number=MB_NO, bank="MB",
                           balance=2_000_000, minutes=1, desc="NGUYEN VAN AN chuyen tien"), event_id=None)
    assert session.get(Transaction, e.transaction_id).pair_id is None


def test_hold_not_applied_to_silent_or_old_transactions(session, setup):
    _add_mb(session)
    out = ingest_tx(session, ntx(ext="old", amount=3_000_000, minutes=-600, desc=f"tien nha T10 chuyen {MB_NO}"),
                    event_id=None, notify=False)
    tx = session.get(Transaction, out.transaction_id)
    assert tx.hold_until is None
    assert tx.category_id == category_by_key(session, "rent").id


def test_category_change_clears_goal_of_other_category(session, setup):
    out = ingest_tx(session, ntx(ext="r", amount=3_000_000, balance=7_000_000, desc="tien tro T11"), event_id=None)
    tx = session.get(Transaction, out.transaction_id)
    tx_actions.assign_next_month(session, tx)
    tx_actions.set_category(session, tx, setup["food"].id)
    assert tx.goal_id is None


def test_remember_rule_with_transfer_category(session, setup):
    out = ingest_tx(session, ntx(ext="t", amount=100_000, balance=9_900_000, desc="Nap vi MoMo"), event_id=None)
    tx = session.get(Transaction, out.transaction_id)
    transfer = category_by_key(session, "transfer")
    tx_actions.set_category(session, tx, transfer.id, remember_pattern="vi momo")
    from app.models import CategoryRule

    rule = session.exec(select(CategoryRule).where(CategoryRule.pattern == "vi momo")).one()
    assert rule.category_id == transfer.id


def test_recategorize_old_message_still_edits(session, setup, fake_now):
    out = ingest_tx(session, ntx(ext="r", amount=3_000_000, balance=7_000_000, desc="tien tro T10"), event_id=None)
    alert = tx_alerts(session)[-1]
    alert.telegram_sent, alert.telegram_message_id = True, 555
    session.add(alert)
    session.commit()
    fake_now.advance(days=2)
    tx = session.get(Transaction, out.transaction_id)
    tx_actions.set_category(session, tx, setup["food"].id)
    reevaluate_and_notify(session, reason="recategorize", edit_tx=tx)
    session.commit()
    calls = []

    def handler(request: httpx.Request) -> httpx.Response:
        calls.append(request.url.path.rsplit("/", 1)[-1])
        return httpx.Response(200, json={"ok": True, "result": True})

    tg = TelegramClient("1:A", client=httpx.AsyncClient(transport=httpx.MockTransport(handler)))
    asyncio.run(drain_once(tg, 1))
    assert "editMessageText" in calls


def test_outbox_keeps_edit_made_during_send(session, setup, monkeypatch):
    ingest_tx(session, ntx(ext="u", amount=200_000, balance=9_800_000, desc="abc"), event_id=None)
    alert_id = tx_alerts(session)[-1].id

    def handler(request: httpx.Request) -> httpx.Response:
        # mô phỏng người dùng sửa trong lúc tin đang được gửi
        from app.db import session_scope

        with session_scope() as s2:
            a = s2.get(Alert, alert_id)
            a.message += "\nĐã phân loại"
            a.revision += 1
            s2.add(a)
            s2.commit()
        return httpx.Response(200, json={"ok": True, "result": {"message_id": 77}})

    tg = TelegramClient("1:A", client=httpx.AsyncClient(transport=httpx.MockTransport(handler)))
    asyncio.run(drain_once(tg, 1))
    a = session.get(Alert, alert_id)
    session.refresh(a)
    assert a.telegram_sent and a.telegram_message_id == 77 and a.needs_edit


def _cat(client, key):
    return next(c["id"] for c in client.get("/api/categories").json() if c["system_key"] == key)


def test_goal_edit_propagates_to_precreated_next_month(client, session):
    client.post("/api/accounts", json={"bank": "VCB", "account_number": VCB_NO, "name": "VCB", "balance": 10_000_000})
    rent = client.post("/api/goals", json={"name": "Tiền trọ", "type": "reserve", "amount": 3_000_000,
                                           "category_id": _cat(client, "rent")}).json()
    t = client.post("/api/transactions", json={"direction": "out", "amount": 3_000_000, "description": "tro T11",
                                               "category_id": _cat(client, "rent")}).json()
    client.patch(f"/api/transactions/{t['id']}", json={"for_next_month": True})
    client.patch(f"/api/goals/{rent['id']}", json={"amount": 3_500_000})
    nov = client.get("/api/goals", params={"month": "2026-11"}).json()
    assert [g["amount"] for g in nov] == [3_500_000]


def test_future_goal_merges_into_repeating_series(client):
    client.post("/api/goals", json={"name": "Tiền trọ", "type": "reserve", "amount": 3_000_000,
                                    "category_id": _cat(client, "rent")})
    r = client.post("/api/goals", json={"name": "Tiền trọ T11", "type": "reserve", "amount": 3_200_000,
                                        "category_id": _cat(client, "rent"), "month": "2026-11"})
    assert r.status_code == 201
    from app.db import session_scope

    with session_scope() as s:
        ensure_month_goals(s, "2026-11")
    nov = client.get("/api/goals", params={"month": "2026-11"}).json()
    assert [(g["name"], g["amount"]) for g in nov] == [("Tiền trọ T11", 3_200_000)]


def test_include_in_total_confirms_account_and_tx_fields(client, session):
    acc = Account(bank="TCB", account_number="5555666677", last4="6677", name="TCB", include_in_total=False,
                  confirmed=False)
    session.add(acc)
    session.commit()
    r = client.patch(f"/api/accounts/{acc.id}", json={"include_in_total": True, "balance": 1_000_000})
    assert r.json()["confirmed"] is True
    t = client.post("/api/transactions", json={"direction": "out", "amount": 50_000,
                                               "description": "GRABFOOD Com Tam 123"}).json()
    assert t["suggested_rule"] == "grabfood com tam" and t["goal_month"] is None
    s = client.get("/api/summary").json()
    assert isinstance(s["ingest_health"]["warnings"], list)
    assert s["ingest_health"]["stale"] == bool(s["ingest_health"]["warnings"])


def test_uncategorized_filter_matches_count(client, session):
    other = Account(bank="TCB", account_number="5555666677", last4="6677", name="TCB", include_in_total=False,
                    confirmed=False)
    session.add(other)
    session.commit()
    session.add(Transaction(account_id=other.id, direction="out", amount=10_000, bank_time=clock.now(),
                            description="x"))
    session.commit()
    s = client.get("/api/summary").json()
    lst = client.get("/api/transactions", params={"uncategorized": True}).json()
    assert lst["total"] == s["uncategorized_count"] == 0


def test_timestamps_in_health_use_z(client, session, monkeypatch):
    from app import jobs
    from app.db import kv_get

    jobs._record_email_success(session)
    session.commit()
    assert kv_get(session, "health:email")["last_success_at"].endswith("Z")
    assert json.dumps(kv_get(session, "health:email"))
