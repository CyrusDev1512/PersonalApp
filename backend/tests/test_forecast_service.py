"""Dự báo ở tầng DB: lọc khoản chi, cảnh báo, bản tin, API."""

from __future__ import annotations

import asyncio
from datetime import UTC, date, datetime, timedelta

from sqlmodel import select

from app import clock, jobs
from app.engine.alerts import ForecastState, decide_forecast
from app.engine.evaluator import EvalSettings, GoalIn, evaluate
from app.engine.forecast import Forecast
from app.ingest.accounts import cash_account
from app.ingest.service import ingest_tx
from app.models import Account, Alert, Transaction
from app.seed import category_by_key
from app.services.forecast import _outflows, build_forecast
from app.services.summary import build_evaluation
from tests.test_ingest import MB_NO, ntx


def _past(days: int, hour: int = 5) -> datetime:
    return clock.now().replace(hour=hour) - timedelta(days=days)


def _add_tx(session, acc_id, amount, days_ago, **kw):
    t = Transaction(account_id=acc_id, direction="out", amount=amount, bank_time=_past(days_ago), evaluated=True, **kw)
    session.add(t)
    session.commit()
    return t


def test_only_real_non_goal_spending_counts(session, setup):
    vcb = setup["vcb"]
    mb = Account(bank="MB", account_number=MB_NO, last4=MB_NO[-4:], name="MB")
    session.add(mb)
    session.commit()
    transfer = category_by_key(session, "transfer")
    atm = _add_tx(session, vcb.id, 500_000, 1, description="RUT TIEN ATM")
    _add_tx(session, vcb.id, 700_000, 1, category_id=transfer.id, categorized_by="pair", pair_id=999)
    _add_tx(session, vcb.id, 800_000, 1, status="excluded")
    _add_tx(session, vcb.id, 900_000, 1, status="pending")
    _add_tx(session, vcb.id, 300_000, 0, hold_until=clock.now() + timedelta(minutes=3))
    _add_tx(session, cash_account(session).id, 100_000, 1, is_manual=True, affects_balance=False)
    food = _add_tx(session, vcb.id, 200_000, 1, category_id=setup["food"].id)
    included = {vcb.id, mb.id}
    out = {o.id: o for o in _outflows(session, "2026-10", included, clock.now())}
    assert atm.id in out and out[atm.id].goal_id is None
    assert food.id in out and out[food.id].goal_id is not None  # chi tiền ăn: thuộc mục tiêu, không tính tốc độ
    assert len(out) == 3  # ATM + tiền ăn vừa thêm + tiền ăn 3 ngày trước (fixture); các khoản khác bị loại


def test_fast_spending_triggers_one_forecast_alert(session, setup):
    vcb = setup["vcb"]
    _add_tx(session, vcb.id, 1_000_000, 2, description="mua sam")
    _add_tx(session, vcb.id, 1_000_000, 1, description="mua sam")
    ingest_tx(session, ntx(ext="a", amount=1_000_000, balance=9_000_000, desc="mua sam"), event_id=None)
    ev = build_evaluation(session)
    assert ev.level == "OK"
    fc = build_forecast(session, ev)
    assert fc.status == "ok" and fc.days_until_floor_hit is not None and fc.days_until_floor_hit <= 7
    tx_alert = session.exec(select(Alert).where(Alert.kind == "tx")).all()[-1]
    assert tx_alert.loud and "📉 Dự báo" in tx_alert.message
    # thêm giao dịch nữa: không báo dự báo lần hai
    ingest_tx(session, ntx(ext="b", amount=50_000, minutes=5, balance=8_950_000, desc="tra da"), event_id=None)
    last = session.exec(select(Alert).where(Alert.kind == "tx")).all()[-1]
    assert "📉 Dự báo" not in last.message


def test_digest_includes_forecast_line(session, setup):
    vcb = setup["vcb"]
    for d in range(1, 4):
        _add_tx(session, vcb.id, 100_000, d, description="cafe")
    asyncio.run(jobs.run_digest())
    digest = session.exec(select(Alert).where(Alert.kind == "digest")).one()
    assert "📈 Dự báo" in digest.message


def test_summary_forecast_json(client, fake_now):
    client.post("/api/accounts", json={"bank": "VCB", "account_number": "0123456789", "name": "VCB",
                                       "balance": 10_000_000})
    s = client.get("/api/summary").json()
    assert "forecast" in s and s["forecast"]["status"] in ("ok", "insufficient_data")
    old = client.get("/api/summary", params={"month": "2026-09"}).json()
    assert old["forecast"] is None


def _ev(balance, level_goals=True):
    goals = [GoalIn(id=1, name="Tiền ăn", type="budget", amount=5_000_000, month="2026-10", category_id=1)]
    return evaluate(month="2026-10", goals=goals if level_goals else [], txs=[], balance=balance,
                    settings=EvalSettings(), today=date(2026, 10, 14))


def _fc(days, min_free=-500_000):
    hit = date(2026, 10, 14) + timedelta(days=days) if days is not None else None
    return Forecast(status="ok", headline="x", floor_hit_date=hit, days_until_floor_hit=days,
                    min_projected_free=min_free)


T0 = datetime(2026, 10, 14, 3, tzinfo=UTC)


def test_decide_forecast_fires_once_escalates_and_rearms():
    ev = _ev(10_000_000)
    fire, st = decide_forecast(None, _fc(6), ev, T0)
    assert fire and not st.armed
    fire, st = decide_forecast(st, _fc(5), ev, T0 + timedelta(hours=30))
    assert not fire  # chỉ sớm hơn 1 ngày
    fire, st = decide_forecast(st, _fc(2), ev, T0 + timedelta(hours=1))
    assert not fire  # sớm hơn nhưng chưa đủ 24 giờ
    fire, st = decide_forecast(st, _fc(2), ev, T0 + timedelta(hours=30))
    assert fire  # sớm hơn >= 3 ngày, đã qua 24 giờ
    fire, st = decide_forecast(st, _fc(None), ev, T0 + timedelta(days=2))
    assert not fire and st.armed
    assert decide_forecast(st, _fc(6), ev, T0 + timedelta(days=3))[0]


def test_decide_forecast_ignores_small_or_far_or_danger():
    ev = _ev(10_000_000)
    assert not decide_forecast(None, _fc(6, min_free=-100_000), ev, T0)[0]
    assert not decide_forecast(None, _fc(8), ev, T0)[0]
    assert not decide_forecast(ForecastState(), _fc(3), _ev(1_000_000), T0)[0]  # đã DANGER: cảnh báo sàn lo
    assert not decide_forecast(None, _fc(3), _ev(10_000_000, level_goals=False), T0)[0]
