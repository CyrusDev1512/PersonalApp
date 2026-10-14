"""Tính mức sàn / được tiêu / mức cảnh báo. Hàm thuần — không đụng DB.

Quy ước "Quỹ giữ + Ngân sách":
- spent(goal) = Σ(chi − hoàn) của giao dịch gán thẳng goal_id (bất kể ngày)
               + giao dịch trong tháng của goal, chưa gán goal_id, cùng danh mục (chỉ goal "tự khớp")
               + opening_spent; tối thiểu 0.
- remaining = max(0, amount − spent); mức sàn = Σ remaining; được tiêu = số dư − mức sàn.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, datetime

from app import clock
from app.money import format_vnd

LEVEL_RANK = {"OK": 0, "WARNING": 1, "DANGER": 2}

INCOME_RECEIVED_RATIO = 0.7  # nhận >= 70% lương dự kiến coi như đã nhận
PAYDAY_GRACE_DAYS = 3


@dataclass
class GoalIn:
    id: int
    name: str
    type: str  # reserve | budget
    amount: int
    month: str
    category_id: int | None = None
    category_name: str | None = None
    category_icon: str | None = None
    series_id: str = ""
    repeat_monthly: bool = True
    opening_spent: int = 0
    rank: int | None = None  # thứ tự ưu tiên tự khớp (id mục tiêu đầu tiên của chuỗi) — ổn định qua các tháng


@dataclass
class TxIn:
    id: int
    direction: str  # in | out
    amount: int
    bank_time: datetime
    category_id: int | None = None
    goal_id: int | None = None


@dataclass
class EvalSettings:
    warning_percent: int = 10
    warning_min_amount: int = 500_000
    expected_income_amount: int = 0
    expected_income_day: int = 0


@dataclass
class GoalView:
    id: int
    name: str
    type: str
    amount: int
    month: str
    category_id: int | None
    category_name: str | None
    category_icon: str | None
    series_id: str
    repeat_monthly: bool
    opening_spent: int
    spent: int
    remaining: int
    usage_pct: float
    auto_match: bool


@dataclass
class Evaluation:
    month: str
    balance: int | None
    balance_known: bool
    in_transit: int
    floor: int
    free: int | None
    buffer: int
    level: str  # OK | WARNING | DANGER | UNKNOWN
    level_reason: str
    waiting_income: bool
    expected_pending: int
    days_left: int
    goals: list[GoalView] = field(default_factory=list)

    @property
    def deficit(self) -> int:
        return -self.free if self.free is not None and self.free < 0 else 0


def _signed_spend(tx: TxIn) -> int:
    return tx.amount if tx.direction == "out" else -tx.amount


def auto_match_ids(goals: list[GoalIn]) -> set[int]:
    """Mỗi (danh mục, tháng) chỉ goal của chuỗi tạo sớm nhất được tự khớp theo danh mục."""
    seen: set[tuple[int, str]] = set()
    out: set[int] = set()
    for g in sorted(goals, key=lambda g: (g.rank if g.rank is not None else g.id, g.id)):
        if g.category_id is None:
            continue
        key = (g.category_id, g.month)
        if key in seen:
            continue
        seen.add(key)
        out.add(g.id)
    return out


def compute_goal_views(goals: list[GoalIn], txs: list[TxIn]) -> list[GoalView]:
    auto = auto_match_ids(goals)
    by_id = {g.id: g for g in goals}
    auto_by_cat_month = {(g.category_id, g.month): g.id for g in goals if g.id in auto}
    totals: dict[int, int] = {g.id: 0 for g in goals}
    for tx in txs:
        if tx.goal_id is not None:
            if tx.goal_id in by_id:
                totals[tx.goal_id] += _signed_spend(tx)
            continue
        if tx.category_id is None:
            continue
        gid = auto_by_cat_month.get((tx.category_id, clock.month_of(tx.bank_time)))
        if gid is not None:
            totals[gid] += _signed_spend(tx)

    views: list[GoalView] = []
    for g in sorted(goals, key=lambda g: (g.type != "reserve", g.id)):
        spent = max(0, g.opening_spent + totals[g.id])
        remaining = max(0, g.amount - spent)
        usage = round(spent * 100.0 / g.amount, 1) if g.amount > 0 else 0.0
        views.append(GoalView(
            id=g.id, name=g.name, type=g.type, amount=g.amount, month=g.month, category_id=g.category_id,
            category_name=g.category_name, category_icon=g.category_icon, series_id=g.series_id,
            repeat_monthly=g.repeat_monthly, opening_spent=g.opening_spent, spent=spent, remaining=remaining,
            usage_pct=usage, auto_match=g.id in auto or g.category_id is None,
        ))
    return views


def expected_income_pending(settings: EvalSettings, today: date, month: str, income_received: int) -> int:
    amount, day = settings.expected_income_amount, settings.expected_income_day
    if amount <= 0 or not 1 <= day <= 31:
        return 0
    if clock.month_of(clock.start_of_day_utc(today)) != month:
        return 0
    if income_received >= amount * INCOME_RECEIVED_RATIO:
        return 0
    payday = min(day, clock.days_in_month(month))
    return amount if today.day <= payday + PAYDAY_GRACE_DAYS else 0


def compute_buffer(floor: int, settings: EvalSettings) -> int:
    return max(round(floor * settings.warning_percent / 100), settings.warning_min_amount)


def days_left_in_month(month: str, today: date) -> int:
    if clock.month_of(clock.start_of_day_utc(today)) != month:
        return 0
    return clock.days_in_month(month) - today.day + 1


def evaluate(
    *,
    month: str,
    goals: list[GoalIn],
    txs: list[TxIn],
    balance: int | None,
    settings: EvalSettings,
    today: date,
    in_transit: int = 0,
    income_received: int = 0,
) -> Evaluation:
    views = compute_goal_views(goals, txs)
    floor = sum(v.remaining for v in views)
    buffer = compute_buffer(floor, settings)
    pending = expected_income_pending(settings, today, month, income_received)
    days_left = days_left_in_month(month, today)

    def result(level: str, reason: str, free: int | None, waiting: bool = False) -> Evaluation:
        return Evaluation(
            month=month, balance=balance, balance_known=balance is not None, in_transit=in_transit, floor=floor,
            free=free, buffer=buffer, level=level, level_reason=reason, waiting_income=waiting,
            expected_pending=pending, days_left=days_left, goals=views,
        )

    if balance is None:
        return result("UNKNOWN", "Chưa biết số dư — hãy nhập số dư hiện tại của tài khoản", None)

    free = balance + in_transit - floor
    if not views:
        return result("OK", "Chưa có mục tiêu nào — bấm \"Thêm mục tiêu\" để bắt đầu", free)
    if free >= buffer:
        return result("OK", f"Còn {format_vnd(free)} có thể tiêu thoải mái", free)
    if free >= 0:
        return result("WARNING", f"Chỉ còn {format_vnd(free)} trên mức sàn {format_vnd(floor)}", free)
    if pending > 0 and free + pending >= 0:
        day = settings.expected_income_day
        return result(
            "WARNING",
            f"Đang thiếu {format_vnd(-free)} so với mức sàn, sẽ đủ khi nhận lương (ngày {day})",
            free,
            waiting=True,
        )
    return result("DANGER", f"Đã lấn {format_vnd(-free)} vào tiền dành cho mục tiêu", free)
