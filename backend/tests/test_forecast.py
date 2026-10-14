"""Dự báo cuối tháng (hàm thuần)."""

from __future__ import annotations

from datetime import UTC, date, datetime

from app.engine.evaluator import EvalSettings, GoalIn, TxIn, evaluate
from app.engine.forecast import OutflowIn, forecast

OCT = "2026-10"
TODAY = date(2026, 10, 14)
FOOD, RENT = 1, 2


def goals():
    return [
        GoalIn(id=1, name="Tiền trọ", type="reserve", amount=3_000_000, month=OCT, category_id=RENT),
        GoalIn(id=2, name="Tiền ăn", type="budget", amount=5_000_000, month=OCT, category_id=FOOD,
               category_icon="🍜"),
    ]


def ev_for(balance, food_spent=2_000_000, today=TODAY, settings=None, income_received=0):
    txs = [TxIn(id=999, direction="out", amount=food_spent, bank_time=datetime(2026, 10, 2, 5, tzinfo=UTC),
                category_id=FOOD)] if food_spent else []
    return evaluate(month=OCT, goals=goals(), txs=txs, balance=balance, settings=settings or EvalSettings(),
                    today=today, income_received=income_received)


def daily(amount, days=14, end=TODAY):
    return [OutflowIn(id=i, amount=amount, day=date(2026, 10, end.day - i)) for i in range(days)]


def test_user_scenario_no_floor_hit_at_slow_pace():
    ev = ev_for(10_000_000)  # free 4tr, còn 18 ngày (kể cả hôm nay)
    fc = forecast(ev=ev, outflows=daily(200_000), today=TODAY, data_since=date(2026, 9, 1))
    assert fc.status == "ok" and fc.daily_spend == 200_000
    assert fc.floor_hit_date is None
    assert fc.projected_free_end == 4_000_000 - 200_000 * 17
    assert fc.headline.startswith("Chi như hiện tại, cuối tháng còn khoảng")
    assert fc.safe_daily_spend == 4_000_000 // 18


def test_user_scenario_hits_floor_at_fast_pace():
    ev = ev_for(10_000_000)
    fc = forecast(ev=ev, outflows=daily(300_000), today=TODAY, data_since=date(2026, 9, 1))
    # 4tr / 300k = 13,3 ngày -> ngày thứ 14 sau hôm nay = 28/10
    assert fc.floor_hit_date == date(2026, 10, 28)
    assert fc.days_until_floor_hit == 14
    assert "28/10" in fc.headline
    assert fc.min_projected_free < 0


def test_large_one_off_payment_is_capped():
    out = daily(100_000) + [OutflowIn(id=100, amount=5_000_000, day=date(2026, 10, 10))]
    fc = forecast(ev=ev_for(10_000_000), outflows=out, today=TODAY, data_since=date(2026, 9, 1))
    assert fc.capped_count == 1 and fc.capped_amount == 4_000_000
    assert fc.daily_spend == round((100_000 * 14 + 1_000_000) / 14)
    assert any("khoản chi lớn" in d for d in fc.details)


def test_goal_attributed_outflows_are_ignored():
    out = [OutflowIn(id=i, amount=300_000, day=date(2026, 10, 14 - i), goal_id=2) for i in range(14)]
    fc = forecast(ev=ev_for(10_000_000), outflows=out, today=TODAY, data_since=date(2026, 9, 1))
    assert fc.daily_spend == 0


def test_insufficient_data_early_month_without_baseline():
    ev = ev_for(10_000_000, food_spent=0, today=date(2026, 10, 2))
    fc = forecast(ev=ev, outflows=[], today=date(2026, 10, 2), data_since=date(2026, 9, 1))
    assert fc.status == "insufficient_data" and "3 ngày" in fc.reason


def test_early_month_with_baseline_is_low_confidence():
    ev = ev_for(10_000_000, food_spent=0, today=date(2026, 10, 2))
    fc = forecast(ev=ev, outflows=[], today=date(2026, 10, 2), data_since=date(2026, 9, 1), baseline_rate=150_000)
    assert fc.status == "ok" and fc.confidence == "low" and fc.daily_spend == 150_000
    assert any("Ước tính sơ bộ" in d for d in fc.details)


def test_blend_with_baseline_between_3_and_7_days():
    ev = ev_for(10_000_000, food_spent=0, today=date(2026, 10, 4))
    out = [OutflowIn(id=i, amount=400_000, day=date(2026, 10, 4 - i)) for i in range(4)]
    fc = forecast(ev=ev, outflows=out, today=date(2026, 10, 4), data_since=date(2026, 9, 1), baseline_rate=100_000)
    w = 4 / 7
    assert fc.daily_spend == round(w * 400_000 + (1 - w) * 100_000)
    assert fc.confidence == "low"


def test_app_started_mid_month_uses_observed_days_only():
    out = [OutflowIn(id=i, amount=200_000, day=date(2026, 10, 14 - i)) for i in range(3)]
    fc = forecast(ev=ev_for(10_000_000), outflows=out, today=TODAY, data_since=date(2026, 10, 12))
    assert fc.observed_days == 3 and fc.window_days == 3
    assert fc.daily_spend == 200_000


def test_salary_covers_gap_and_recovers_on():
    s = EvalSettings(expected_income_amount=10_000_000, expected_income_day=20)
    ev = ev_for(8_500_000, food_spent=0, settings=s)  # sàn 8tr, free 500k, lương ngày 20 chưa nhận
    fc = forecast(ev=ev, outflows=daily(200_000), today=TODAY, data_since=date(2026, 9, 1), income_day=20)
    assert fc.floor_hit_date == date(2026, 10, 17)
    assert fc.recovers_on == date(2026, 10, 20)
    assert "đủ lại khi nhận lương" in fc.headline
    assert fc.income_pending == 10_000_000


def test_budget_over_pace_reduces_projection():
    ev = ev_for(10_000_000, food_spent=4_200_000)  # 4,2tr / 14 ngày = 300k/ngày -> dự kiến 9,3tr
    food = [OutflowIn(id=i, amount=300_000, day=date(2026, 10, 14 - i), goal_id=2) for i in range(14)]
    fc = forecast(ev=ev, outflows=food, today=TODAY, data_since=date(2026, 9, 1))
    food = next(b for b in fc.budgets if b.goal_id == 2)
    assert food.status == "over_pace" and food.projected_pct > 150
    assert fc.projected_budget_overrun > 0
    assert fc.projected_free_end < ev.free
    assert any("Tiền ăn: với tốc độ này" in d for d in fc.details)


def test_last_day_of_month():
    ev = ev_for(10_000_000, today=date(2026, 10, 31))
    fc = forecast(ev=ev, outflows=daily(100_000, end=date(2026, 10, 31)), today=date(2026, 10, 31),
                  data_since=date(2026, 9, 1))
    assert fc.projected_free_end == ev.free and fc.floor_hit_date is None


def test_already_below_floor():
    ev = ev_for(5_000_000)  # free -1tr
    fc = forecast(ev=ev, outflows=daily(100_000), today=TODAY, data_since=date(2026, 9, 1))
    assert fc.floor_hit_date == TODAY and fc.days_until_floor_hit == 0
    assert fc.headline.startswith("Số dư đang thấp hơn mức sàn")


def test_unknown_balance_is_unavailable():
    ev = ev_for(None)
    assert forecast(ev=ev, outflows=[], today=TODAY, data_since=date(2026, 9, 1)).status == "unavailable"
