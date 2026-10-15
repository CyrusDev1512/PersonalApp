"""Pipeline ingest: idempotency, khử trùng lặp nhiều nguồn, số dư, chuyển nội bộ, cảnh báo."""

from __future__ import annotations

from datetime import timedelta

from sqlmodel import select

from app import clock
from app.ingest.schema import NormalizedTx
from app.ingest.service import ingest_tx, tick
from app.models import Account, Alert, Transaction
from app.services.summary import build_evaluation

VCB_NO = "0123456789"
MB_NO = "9876543210"


def ntx(source="sepay", ext="1", direction="out", amount=3_500_000, minutes=0, balance=None, desc="RUT TIEN ATM",
        number=VCB_NO, bank="VCB", precision="second", ref=None, **kw) -> NormalizedTx:
    return NormalizedTx(source=source, external_id=ext, direction=direction, amount=amount,
                        bank_time=clock.now() + timedelta(minutes=minutes), time_precision=precision, bank=bank,
                        account_number=number, description=desc, balance_after=balance, reference_code=ref, **kw)


def tx_alerts(session):
    return session.exec(select(Alert).where(Alert.kind == "tx").order_by(Alert.id)).all()


def test_user_scenario_webhook_triggers_warning(session, setup):
    ev = build_evaluation(session)
    assert (ev.floor, ev.free, ev.level) == (6_000_000, 4_000_000, "OK")

    out = ingest_tx(session, ntx(balance=6_500_000), event_id=None)
    assert out.status == "created"
    ev = build_evaluation(session)
    assert (ev.balance, ev.free, ev.level) == (6_500_000, 500_000, "WARNING")
    alerts = tx_alerts(session)
    assert len(alerts) == 1
    a = alerts[0]
    assert a.loud and a.level == "WARNING" and a.title.startswith("⚠️")
    assert "500.000đ" in a.message and a.reply_markup_json  # có nút phân loại


def test_replay_is_idempotent(session, setup):
    ingest_tx(session, ntx(balance=6_500_000), event_id=None)
    again = ingest_tx(session, ntx(balance=6_500_000), event_id=None)
    assert again.status == "duplicate"
    assert len(session.exec(select(Transaction).where(Transaction.amount == 3_500_000)).all()) == 1
    assert len(tx_alerts(session)) == 1


def test_webhook_then_email_merges(session, setup):
    ingest_tx(session, ntx(balance=6_500_000, ref="FT123"), event_id=None)
    out = ingest_tx(session, ntx(source="email", ext="<m1@vcb>", minutes=1, balance=None, desc="GD -3,500,000",
                                 precision="minute"), event_id=None)
    assert out.status == "merged"
    assert len(session.exec(select(Transaction).where(Transaction.amount == 3_500_000)).all()) == 1
    assert len(tx_alerts(session)) == 1
    assert build_evaluation(session).balance == 6_500_000


def test_email_then_webhook_merges_and_notifies_once(session, setup):
    # TK chưa có webhook -> email được tính ngay
    ingest_tx(session, ntx(source="email", ext="<m1@vcb>", balance=6_500_000, precision="minute"), event_id=None)
    out = ingest_tx(session, ntx(source="sepay", ext="99", minutes=1, balance=6_500_000), event_id=None)
    assert out.status == "merged"
    txs = session.exec(select(Transaction).where(Transaction.amount == 3_500_000)).all()
    assert len(txs) == 1 and txs[0].balance_source == "sepay"
    assert len(tx_alerts(session)) == 1


def test_two_identical_amounts_minutes_apart_are_distinct(session, setup):
    ingest_tx(session, ntx(ext="1", amount=50_000, balance=9_950_000, desc="tra sua"), event_id=None)
    ingest_tx(session, ntx(ext="2", amount=50_000, minutes=3, balance=9_900_000, desc="tra sua"), event_id=None)
    # email cho cả hai, không có số dư -> mỗi email ghép với một giao dịch khác nhau
    ingest_tx(session, ntx(source="email", ext="<a>", amount=50_000, minutes=0, precision="minute"), event_id=None)
    ingest_tx(session, ntx(source="email", ext="<b>", amount=50_000, minutes=3, precision="minute"), event_id=None)
    txs = session.exec(select(Transaction).where(Transaction.amount == 50_000)).all()
    assert len(txs) == 2
    assert build_evaluation(session).balance == 9_900_000


def test_different_reported_balances_never_merge(session, setup):
    ingest_tx(session, ntx(source="sepay", ext="1", amount=100_000, balance=9_900_000), event_id=None)
    ingest_tx(session, ntx(source="casso", ext="c1", amount=100_000, balance=9_800_000, minutes=1), event_id=None)
    assert len(session.exec(select(Transaction).where(Transaction.amount == 100_000)).all()) == 2


def test_out_of_order_balance_uses_latest_bank_time(session, setup, fake_now):
    ingest_tx(session, ntx(ext="2", amount=200_000, minutes=10, balance=9_700_000), event_id=None)
    ingest_tx(session, ntx(ext="1", amount=100_000, minutes=0, balance=9_900_000), event_id=None)
    assert build_evaluation(session).balance == 9_700_000


def test_derived_balance_when_source_has_no_balance(session, setup):
    ingest_tx(session, ntx(source="email", ext="<x>", amount=300_000, precision="minute"), event_id=None)
    acc = session.get(Account, setup["vcb"].id)
    assert acc.balance == 9_700_000 and acc.balance_derived


def test_zero_balance_from_source_is_unknown(session, setup):
    t = ntx(amount=100_000, balance=0)
    assert t.balance_after is None


def test_casso_test_payload_ignored(session, setup):
    out = ingest_tx(session, ntx(source="casso", ext="0", number="88888888", bank="VPB", is_test=True,
                                 balance=25_000_000), event_id=None)
    assert out.status == "ignored"
    assert build_evaluation(session).balance == 10_000_000
    assert session.exec(select(Account).where(Account.account_number == "88888888")).first() is None


def test_unknown_account_not_included_in_total(session, setup):
    out = ingest_tx(session, ntx(number="5555666677", bank="TCB", balance=50_000_000, direction="in",
                                 amount=1_000_000), event_id=None)
    assert out.account_created
    acc = session.exec(select(Account).where(Account.account_number == "5555666677")).one()
    assert not acc.include_in_total and not acc.confirmed
    assert build_evaluation(session).balance == 10_000_000
    assert session.exec(select(Alert).where(Alert.kind == "account")).first() is not None


def test_email_pending_on_webhook_covered_account(session, setup, fake_now):
    ingest_tx(session, ntx(ext="w1", amount=10_000, balance=9_990_000, desc="gui xe"), event_id=None)
    out = ingest_tx(session, ntx(source="email", ext="<late>", amount=777_000, minutes=1, precision="minute"),
                    event_id=None)
    tx = session.get(Transaction, out.transaction_id)
    assert tx.status == "pending"
    assert build_evaluation(session).balance == 9_990_000  # chưa tính
    # webhook tới -> gộp, chuyển active
    ingest_tx(session, ntx(ext="w2", amount=777_000, minutes=2, balance=9_213_000), event_id=None)
    session.refresh(tx)
    assert tx.status == "active"
    assert build_evaluation(session).balance == 9_213_000


def test_email_pending_promoted_after_timeout(session, setup, fake_now):
    ingest_tx(session, ntx(ext="w1", amount=10_000, balance=9_990_000, desc="gui xe"), event_id=None)
    out = ingest_tx(session, ntx(source="email", ext="<late>", amount=777_000, minutes=1, precision="minute"),
                    event_id=None)
    fake_now.advance(hours=7)
    assert tick(session)
    tx = session.get(Transaction, out.transaction_id)
    assert tx.status == "active"
    assert build_evaluation(session).balance == 9_990_000 - 777_000


def test_internal_transfer_pairing_produces_no_floor_alert(session, setup, fake_now):
    mb = Account(bank="MB", account_number=MB_NO, last4=MB_NO[-4:], name="MB", manual_balance=1_000_000,
                 manual_balance_at=clock.start_of_day_utc(clock.today_ict()))
    session.add(mb)
    session.commit()
    from app.services.balance import recompute_balance

    recompute_balance(session, mb)
    session.commit()
    before = build_evaluation(session)
    assert before.level == "OK"
    # VCB -> MB 5tr: nội dung chứa số TK MB -> khoản ra được hoãn chờ ghép
    out = ingest_tx(session, ntx(ext="o1", amount=5_000_000, balance=5_000_000,
                                 desc=f"NGUYEN VAN AN chuyen tien toi {MB_NO}"), event_id=None)
    out_tx = session.get(Transaction, out.transaction_id)
    assert out_tx.hold_until is not None
    mid = build_evaluation(session)
    assert mid.level == "OK" and mid.in_transit == 5_000_000
    assert tx_alerts(session) == []
    fake_now.advance(minutes=2)
    ingest_tx(session, ntx(source="casso", ext="i1", direction="in", amount=5_000_000, number=MB_NO, bank="MB",
                           balance=6_000_000, desc="NGUYEN VAN AN chuyen tien"), event_id=None)
    session.refresh(out_tx)
    assert out_tx.pair_id is not None
    after = build_evaluation(session)
    assert after.balance == before.balance and after.level == "OK"
    loud = [a for a in session.exec(select(Alert)).all() if a.loud and a.kind in ("tx", "floor")]
    assert loud == []


def test_held_outflow_without_pair_notifies_after_timeout(session, setup, fake_now):
    mb = Account(bank="MB", account_number=MB_NO, last4=MB_NO[-4:], name="MB", manual_balance=0,
                 manual_balance_at=clock.start_of_day_utc(clock.today_ict()))
    session.add(mb)
    session.commit()
    from app.services.balance import recompute_balance

    recompute_balance(session, mb)
    session.commit()
    ingest_tx(session, ntx(ext="o1", amount=5_000_000, balance=5_000_000, desc=f"chuyen tien {MB_NO}"),
              event_id=None)
    assert tx_alerts(session) == []
    fake_now.advance(minutes=6)
    assert tick(session)
    alerts = tx_alerts(session)
    assert len(alerts) == 1 and alerts[0].level == "DANGER" and alerts[0].loud


def test_old_backfill_does_not_send_per_tx_messages(session, setup):
    ingest_tx(session, ntx(ext="old", amount=100_000, minutes=-300, balance=None, desc="pho bo"), event_id=None)
    assert tx_alerts(session) == []


def test_auto_categorized_food_counts_against_budget(session, setup):
    ingest_tx(session, ntx(ext="f1", amount=2_500_000, balance=7_500_000, desc="GRABFOOD Com Tam"), event_id=None)
    ev = build_evaluation(session)
    food = next(g for g in ev.goals if g.name == "Tiền ăn")
    assert food.spent == 4_500_000 and food.usage_pct == 90.0
    alert = tx_alerts(session)[-1]
    assert "Tiền ăn đã dùng 90%" in alert.message and alert.loud


def test_salary_brings_safe_message(session, setup):
    ingest_tx(session, ntx(ext="1", amount=4_000_000, balance=6_000_000), event_id=None)  # free 0 -> WARNING
    ingest_tx(session, ntx(ext="2", direction="in", amount=15_000_000, minutes=5, balance=21_000_000,
                           desc="CTY ABC tra luong T10"), event_id=None)
    alerts = tx_alerts(session)
    assert alerts[-1].title.startswith("✅")
    assert build_evaluation(session).level == "OK"
