"""Chính sách gửi cảnh báo: hysteresis, chống spam, leo thang, ngân sách."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

from app.engine.alerts import FloorState, decide_budget, decide_floor
from app.engine.evaluator import EvalSettings, GoalIn, TxIn, evaluate

T0 = datetime(2026, 10, 14, 3, 0, tzinfo=UTC)
GOALS = [
    GoalIn(id=1, name="Tiền trọ", type="reserve", amount=3_000_000, month="2026-10", category_id=2),
    GoalIn(id=2, name="Tiền ăn", type="budget", amount=5_000_000, month="2026-10", category_id=1),
]


def ev_for(balance, food_spent=2_000_000):
    txs = [TxIn(id=1, direction="out", amount=food_spent, bank_time=T0 - timedelta(days=5), category_id=1)]
    return evaluate(month="2026-10", goals=GOALS, txs=txs if food_spent else [], balance=balance,
                    settings=EvalSettings(), today=date(2026, 10, 14))


def test_worse_notifies_once_then_suppressed_within_gap():
    st = FloorState()
    d = decide_floor(st, ev_for(10_000_000), "tx", T0)
    assert not d.notify and d.level == "OK"
    d = decide_floor(d.state, ev_for(6_500_000), "tx", T0)
    assert d.notify and d.kind == "worse" and d.level == "WARNING"
    # dao động quanh ngưỡng: lên OK (vượt hysteresis) rồi lại WARNING trong 2 giờ -> không báo lại
    d = decide_floor(d.state, ev_for(7_500_000), "inflow", T0 + timedelta(minutes=10))
    assert d.level == "OK"
    d = decide_floor(d.state, ev_for(6_500_000), "tx", T0 + timedelta(minutes=20))
    assert d.level == "WARNING" and not d.notify
    # sau 2 giờ thì báo lại
    d2 = decide_floor(FloorState(last_level="OK", notified=d.state.notified), ev_for(6_500_000), "tx",
                      T0 + timedelta(hours=3))
    assert d2.notify


def test_hysteresis_requires_buffer_plus_h_to_clear_warning():
    st = FloorState(last_level="WARNING")
    # buffer 600k, h = max(60k, 200k) = 200k -> cần free >= 800k để về OK
    d = decide_floor(st, ev_for(6_700_000), "inflow", T0)  # free 700k
    assert d.level == "WARNING" and not d.notify
    d = decide_floor(st, ev_for(6_800_000), "inflow", T0)  # free 800k
    assert d.level == "OK" and d.notify and d.kind == "safe"


def test_safe_message_only_for_inflow():
    st = FloorState(last_level="WARNING")
    d = decide_floor(st, ev_for(9_000_000), "recategorize", T0)
    assert d.level == "OK" and not d.notify


def test_danger_clears_to_warning_only_with_margin():
    st = FloorState(last_level="DANGER", last_deficit=500_000)
    d = decide_floor(st, ev_for(6_100_000), "inflow", T0)  # free 100k < h
    assert d.level == "DANGER"
    d = decide_floor(st, ev_for(6_300_000), "inflow", T0)  # free 300k >= h
    assert d.level == "WARNING" and not d.notify


def test_danger_escalates_when_deficit_grows():
    st = FloorState()
    d = decide_floor(st, ev_for(5_500_000), "tx", T0)  # deficit 500k
    assert d.notify and d.level == "DANGER" and d.state.last_deficit == 500_000
    d = decide_floor(d.state, ev_for(5_300_000), "tx", T0 + timedelta(minutes=5))  # +200k < buffer
    assert not d.notify
    d = decide_floor(d.state, ev_for(4_800_000), "tx", T0 + timedelta(minutes=6))  # deficit 1.2tr (+700k)
    assert d.notify and d.kind == "escalate" and d.state.last_deficit == 1_200_000


def test_unknown_never_notifies():
    d = decide_floor(FloorState(last_level="WARNING"), ev_for(None), "tx", T0)
    assert not d.notify and d.state.last_level == "WARNING"


def _goal(usage):
    ev = ev_for(50_000_000, food_spent=int(5_000_000 * usage / 100))
    return ev.goals[1]


def test_budget_thresholds_fire_once_and_rearm():
    g = _goal(82)
    fired, armed = decide_budget(g, {})
    assert fired == 80 and armed == {80: False, 100: True}
    fired, armed = decide_budget(_goal(90), armed)
    assert fired is None
    # một giao dịch vượt cả 80 và 100 -> chỉ báo 100
    fired, armed2 = decide_budget(_goal(104), {})
    assert fired == 100 and armed2 == {80: False, 100: False}
    # tụt dưới 95% (100 - 5) -> 100 được báo lại; 80 vẫn đã báo
    fired, armed3 = decide_budget(_goal(94), armed2)
    assert fired is None and armed3[100] and not armed3[80]


def test_reserve_goals_have_no_budget_alerts():
    ev = ev_for(50_000_000)
    fired, _ = decide_budget(ev.goals[0], {})
    assert fired is None
