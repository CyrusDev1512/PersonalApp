"""Logic mức sàn / được tiêu (hàm thuần)."""

from __future__ import annotations

from datetime import UTC, date, datetime

from app.engine.evaluator import EvalSettings, GoalIn, TxIn, evaluate

OCT = "2026-10"
TODAY = date(2026, 10, 14)
FOOD, RENT, OTHER = 1, 2, 9


def t(day: int, hour: int = 5) -> datetime:
    return datetime(2026, 10, day, hour, 0, tzinfo=UTC)


def goals_oct() -> list[GoalIn]:
    return [
        GoalIn(id=1, name="Tiền trọ", type="reserve", amount=3_000_000, month=OCT, category_id=RENT),
        GoalIn(id=2, name="Tiền ăn", type="budget", amount=5_000_000, month=OCT, category_id=FOOD),
    ]


def run(goals, txs, balance, **kw):
    return evaluate(month=OCT, goals=goals, txs=txs, balance=balance, settings=kw.pop("settings", EvalSettings()),
                    today=kw.pop("today", TODAY), **kw)


def test_user_scenario_14_10_ok_then_warning():
    food_spent = [TxIn(id=10, direction="out", amount=2_000_000, bank_time=t(5), category_id=FOOD)]
    ev = run(goals_oct(), food_spent, 10_000_000)
    assert ev.floor == 6_000_000
    assert ev.free == 4_000_000
    assert ev.buffer == 600_000
    assert ev.level == "OK"
    rent, food = ev.goals
    assert (rent.remaining, food.spent, food.remaining) == (3_000_000, 2_000_000, 3_000_000)

    # Rút 3,5tr (chưa phân loại) -> số dư 6,5tr
    withdraw = TxIn(id=11, direction="out", amount=3_500_000, bank_time=t(14))
    ev = run(goals_oct(), [*food_spent, withdraw], 6_500_000)
    assert ev.floor == 6_000_000
    assert ev.free == 500_000
    assert ev.level == "WARNING"
    assert "500.000đ" in ev.level_reason


def test_danger_when_balance_below_floor():
    ev = run(goals_oct(), [], 7_000_000)
    assert ev.floor == 8_000_000
    assert ev.free == -1_000_000
    assert ev.level == "DANGER"


def test_rent_paid_early_keeps_free_unchanged():
    before = run(goals_oct(), [], 10_000_000)
    paid = [TxIn(id=1, direction="out", amount=3_000_000, bank_time=t(2), category_id=RENT)]
    after = run(goals_oct(), paid, 7_000_000)
    assert after.floor == before.floor - 3_000_000
    assert after.free == before.free


def test_two_goals_same_category_do_not_double_count():
    goals = [
        GoalIn(id=1, name="Tiền ăn", type="budget", amount=5_000_000, month=OCT, category_id=FOOD),
        GoalIn(id=2, name="Tiệc sinh nhật", type="reserve", amount=1_000_000, month=OCT, category_id=FOOD),
    ]
    txs = [TxIn(id=5, direction="out", amount=1_000_000, bank_time=t(10), category_id=FOOD)]
    ev = run(goals, txs, 9_000_000)
    food, party = sorted(ev.goals, key=lambda g: g.id)
    assert food.spent == 1_000_000 and food.auto_match
    assert party.spent == 0 and not party.auto_match
    assert ev.floor == 4_000_000 + 1_000_000
    # Gán trực tiếp cho mục tiêu tiệc thì mới tính vào tiệc
    txs.append(TxIn(id=6, direction="out", amount=600_000, bank_time=t(12), category_id=FOOD, goal_id=2))
    ev = run(goals, txs, 8_400_000)
    food, party = sorted(ev.goals, key=lambda g: g.id)
    assert food.spent == 1_000_000
    assert party.spent == 600_000


def test_goal_linked_tx_counts_regardless_of_date():
    # Trả trọ tháng 11 vào 30/10, gán thẳng goal tháng 11
    nov = [GoalIn(id=7, name="Tiền trọ", type="reserve", amount=3_000_000, month="2026-11", category_id=RENT)]
    early = [TxIn(id=1, direction="out", amount=3_000_000, bank_time=t(30), category_id=RENT, goal_id=7)]
    ev = evaluate(month="2026-11", goals=nov, txs=early, balance=5_000_000, settings=EvalSettings(),
                  today=date(2026, 11, 2))
    assert ev.goals[0].remaining == 0
    assert ev.floor == 0


def test_refund_reduces_spent_and_never_negative():
    txs = [
        TxIn(id=1, direction="out", amount=1_000_000, bank_time=t(3), category_id=FOOD),
        TxIn(id=2, direction="in", amount=300_000, bank_time=t(4), category_id=FOOD),
        TxIn(id=3, direction="in", amount=5_000_000, bank_time=t(5), category_id=FOOD),
    ]
    ev = run(goals_oct(), txs[:2], 10_000_000)
    assert ev.goals[1].spent == 700_000
    ev = run(goals_oct(), txs, 10_000_000)
    assert ev.goals[1].spent == 0


def test_transactions_of_other_months_do_not_count_by_category():
    txs = [TxIn(id=1, direction="out", amount=1_000_000, bank_time=datetime(2026, 9, 30, 10, tzinfo=UTC),
                category_id=FOOD)]
    ev = run(goals_oct(), txs, 10_000_000)
    assert ev.goals[1].spent == 0


def test_month_boundary_uses_vietnam_time():
    # 31/10 18:00 UTC = 01:00 ngày 1/11 giờ VN -> không thuộc tháng 10
    txs = [TxIn(id=1, direction="out", amount=1_000_000, bank_time=datetime(2026, 10, 31, 18, tzinfo=UTC),
                category_id=FOOD)]
    ev = run(goals_oct(), txs, 10_000_000)
    assert ev.goals[1].spent == 0


def test_uncategorized_spend_only_reduces_free():
    txs = [TxIn(id=1, direction="out", amount=500_000, bank_time=t(10))]
    ev = run(goals_oct(), txs, 9_500_000)
    assert ev.floor == 8_000_000
    assert ev.free == 1_500_000


def test_no_goals_is_ok():
    ev = run([], [], 100_000)
    assert ev.level == "OK"
    assert ev.floor == 0


def test_unknown_balance():
    ev = run(goals_oct(), [], None)
    assert ev.level == "UNKNOWN"
    assert ev.free is None
    assert not ev.balance_known


def test_opening_spent_for_goal_created_mid_month():
    goals = goals_oct()
    goals[1].opening_spent = 2_000_000
    ev = run(goals, [], 10_000_000)
    assert ev.goals[1].spent == 2_000_000
    assert ev.floor == 6_000_000


def test_pure_savings_reserve_without_category_needs_full_amount():
    goals = [GoalIn(id=1, name="Tiết kiệm", type="reserve", amount=2_000_000, month=OCT)]
    txs = [TxIn(id=1, direction="out", amount=500_000, bank_time=t(3), category_id=FOOD)]
    ev = run(goals, txs, 3_000_000)
    assert ev.goals[0].remaining == 2_000_000
    assert ev.goals[0].auto_match


def test_expected_income_turns_danger_into_waiting_warning():
    s = EvalSettings(expected_income_amount=15_000_000, expected_income_day=5)
    ev = evaluate(month=OCT, goals=goals_oct(), txs=[], balance=2_000_000, settings=s, today=date(2026, 10, 2))
    assert ev.free == -6_000_000
    assert ev.level == "WARNING" and ev.waiting_income
    # Đã nhận lương -> không còn "chờ lương"
    ev = evaluate(month=OCT, goals=goals_oct(), txs=[], balance=2_000_000, settings=s, today=date(2026, 10, 2),
                  income_received=15_000_000)
    assert ev.level == "DANGER"
    # Quá ngày lương + 3 ngày mà chưa nhận -> DANGER
    ev = evaluate(month=OCT, goals=goals_oct(), txs=[], balance=2_000_000, settings=s, today=date(2026, 10, 9))
    assert ev.level == "DANGER"


def test_in_transit_is_added_back():
    ev = run(goals_oct(), [], 6_000_000, in_transit=3_000_000)
    assert ev.free == 1_000_000
    assert ev.level == "OK"


def test_buffer_uses_min_amount():
    s = EvalSettings(warning_percent=10, warning_min_amount=500_000)
    goals = [GoalIn(id=1, name="Ăn", type="budget", amount=1_000_000, month=OCT, category_id=FOOD)]
    ev = run(goals, [], 1_400_000, settings=s)
    assert ev.buffer == 500_000
    assert ev.level == "WARNING"


def test_usage_pct():
    txs = [TxIn(id=1, direction="out", amount=4_100_000, bank_time=t(3), category_id=FOOD)]
    ev = run(goals_oct(), txs, 20_000_000)
    assert ev.goals[1].usage_pct == 82.0
    assert ev.days_left == 18
