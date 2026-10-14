"""Dự báo cuối tháng theo tốc độ chi. Hàm thuần — không đụng DB.

"Được tiêu" (= số dư − mức sàn) đã trừ sẵn phần còn cần cho các mục tiêu, nên:
- chi trong ngân sách không làm giảm "được tiêu" (mức sàn giảm theo) — cho tới khi vượt ngân sách;
- chi ngoài mục tiêu làm giảm "được tiêu" 1:1.
=> Dự báo = được tiêu − tốc độ chi ngoài mục tiêu × số ngày còn lại − phần vượt ngân sách dự kiến + lương dự kiến.
"""

from __future__ import annotations

import statistics
from dataclasses import dataclass, field
from datetime import date, timedelta

from app import clock
from app.engine.evaluator import Evaluation, GoalView
from app.money import format_vnd


@dataclass(frozen=True)
class OutflowIn:
    id: int
    amount: int
    day: date  # ngày theo giờ VN
    goal_id: int | None = None  # mục tiêu được tính (None = chi ngoài mục tiêu)


@dataclass(frozen=True)
class ForecastCfg:
    window_days: int = 14  # tốc độ chi lấy theo tối đa 14 ngày gần nhất
    min_days: int = 3  # ít hơn 3 ngày dữ liệu thì chưa dự báo (trừ khi có số liệu tháng trước)
    full_days: int = 7  # từ 3 tới 6 ngày: trộn với tháng trước
    large_min: int = 1_000_000  # khoản lớn bất thường: phần vượt max(1tr, 3 × trung vị) không tính vào tốc độ
    large_median_factor: int = 3
    budget_tol_pct: float = 5.0  # dự kiến vượt ngân sách > 5% mới báo "vượt nhịp"


@dataclass
class BudgetPace:
    goal_id: int
    name: str
    category_icon: str | None
    spent: int
    amount: int
    daily_rate: int
    projected_spent: int
    projected_pct: float
    status: str  # on_track | over_pace | exceeded
    suggested_daily: int


@dataclass
class Forecast:
    status: str  # ok | insufficient_data | unavailable
    headline: str
    confidence: str = "normal"  # normal | low
    reason: str | None = None
    observed_days: int = 0
    window_days: int = 0
    daily_spend: int = 0
    capped_amount: int = 0
    capped_count: int = 0
    projected_free_end: int | None = None
    projected_budget_overrun: int = 0
    income_pending: int = 0
    floor_hit_date: date | None = None
    days_until_floor_hit: int | None = None
    recovers_on: date | None = None
    min_projected_free: int | None = None
    safe_daily_spend: int | None = None
    details: list[str] = field(default_factory=list)
    budgets: list[BudgetPace] = field(default_factory=list)


def _ddmm(d: date) -> str:
    return d.strftime("%d/%m")


def capped_total(amounts: list[int], cfg: ForecastCfg) -> tuple[int, int, int]:
    """(tổng đã giới hạn khoản lớn, phần bị bỏ, số khoản bị giới hạn)."""
    if not amounts:
        return 0, 0, 0
    cap = max(cfg.large_min, cfg.large_median_factor * int(statistics.median(amounts)))
    counted = sum(min(a, cap) for a in amounts)
    excess = sum(a - cap for a in amounts if a > cap)
    return counted, excess, sum(1 for a in amounts if a > cap)


def _budget_paces(goals: list[GoalView], *, month_start: date, today: date, observed: int, data_since: date,
                  days_left: int, dim: int, remaining_days: int, cfg: ForecastCfg) -> list[tuple[BudgetPace, float]]:
    out: list[tuple[BudgetPace, float]] = []
    for g in goals:
        if g.type != "budget" or g.amount <= 0:
            continue
        from_month_start = g.opening_spent > 0 or data_since <= month_start
        b_days = (today - month_start).days + 1 if from_month_start else observed
        plan = g.amount / dim
        show_pace = b_days >= cfg.min_days
        if not show_pace:
            rate = plan
        else:
            observed_rate = g.spent / b_days
            if b_days < cfg.full_days:
                w = b_days / cfg.full_days
                rate = w * observed_rate + (1 - w) * plan
            else:
                rate = observed_rate
        projected = g.spent + rate * remaining_days
        pct = round(projected * 100.0 / g.amount, 1)
        if g.spent > g.amount:
            status = "exceeded"
        elif show_pace and pct > 100 + cfg.budget_tol_pct:
            status = "over_pace"
        else:
            status = "on_track"
        out.append((
            BudgetPace(
                goal_id=g.id, name=g.name, category_icon=g.category_icon, spent=g.spent, amount=g.amount,
                daily_rate=round(rate), projected_spent=round(projected), projected_pct=pct, status=status,
                suggested_daily=max(0, g.amount - g.spent) // max(days_left, 1),
            ),
            rate,
        ))
    return out


def forecast(
    *,
    ev: Evaluation,
    outflows: list[OutflowIn],
    today: date,
    data_since: date,
    income_day: int = 0,
    baseline_rate: int | None = None,
    cfg: ForecastCfg | None = None,
) -> Forecast:
    cfg = cfg or ForecastCfg()
    if not ev.balance_known or ev.free is None or ev.days_left <= 0:
        return Forecast(status="unavailable", headline="Chưa đủ thông tin để dự báo")

    year, mon = clock.parse_month(ev.month)
    month_start = date(year, mon, 1)
    dim = clock.days_in_month(ev.month)
    obs_start = max(month_start, data_since)
    observed = (today - obs_start).days + 1
    win_start = max(obs_start, today - timedelta(days=cfg.window_days - 1))
    window = (today - win_start).days + 1

    amounts = [o.amount for o in outflows if o.goal_id is None and win_start <= o.day <= today]
    counted, excess, n_capped = capped_total(amounts, cfg)
    rate_obs = counted / window if window > 0 else 0.0

    confidence = "normal"
    if observed < cfg.min_days:
        if baseline_rate is None:
            msg = f"Chưa đủ dữ liệu để dự báo (cần ít nhất {cfg.min_days} ngày)"
            return Forecast(status="insufficient_data", headline=msg, reason=msg, observed_days=max(observed, 0),
                            window_days=max(window, 0))
        rate, confidence = float(baseline_rate), "low"
    elif observed < cfg.full_days:
        confidence = "low"
        if baseline_rate is not None:
            w = observed / cfg.full_days
            rate = w * rate_obs + (1 - w) * baseline_rate
        else:
            rate = rate_obs
    else:
        rate = rate_obs

    remaining = ev.days_left - 1  # số ngày sau hôm nay
    paces = _budget_paces(ev.goals, month_start=month_start, today=today, observed=observed, data_since=data_since,
                          days_left=ev.days_left, dim=dim, remaining_days=remaining, cfg=cfg)

    def overrun(d: int) -> float:
        total = 0.0
        for p, r in paces:
            total += max(0.0, p.spent + r * d - p.amount) - max(0, p.spent - p.amount)
        return total

    pending = ev.expected_pending
    salary_day: date | None = None
    if pending > 0 and income_day >= 1:
        salary_day = max(date(year, mon, min(income_day, dim)), today + timedelta(days=1))

    free = ev.free
    hit: date | None = today if free < 0 else None
    recovers: date | None = None
    min_free = free
    value = float(free)
    for d in range(1, remaining + 1):
        day = today + timedelta(days=d)
        value = free - rate * d - overrun(d) + (pending if salary_day and day >= salary_day else 0)
        min_free = min(min_free, int(value))
        if value < 0 and hit is None:
            hit = day
        elif value >= 0 and hit is not None and recovers is None and salary_day and day >= salary_day:
            recovers = day
    projected_end = int(value) if remaining > 0 else free
    total_overrun = int(overrun(remaining))
    safe_daily = max(0, free + pending - total_overrun) // ev.days_left

    fc = Forecast(
        status="ok", headline="", confidence=confidence, observed_days=observed, window_days=window,
        daily_spend=round(rate), capped_amount=excess, capped_count=n_capped, projected_free_end=projected_end,
        projected_budget_overrun=total_overrun, income_pending=pending, floor_hit_date=hit,
        days_until_floor_hit=(hit - today).days if hit else None, recovers_on=recovers, min_projected_free=min_free,
        safe_daily_spend=safe_daily, budgets=[p for p, _ in paces],
    )
    fc.headline = _headline(fc, today)
    fc.details = _details(fc, baseline_used=confidence == "low" and baseline_rate is not None)
    return fc


def _headline(fc: Forecast, today: date) -> str:
    if fc.floor_hit_date is not None:
        if fc.floor_hit_date == today:
            text = "Số dư đang thấp hơn mức sàn"
        else:
            text = f"Chi như hiện tại thì khoảng ngày {_ddmm(fc.floor_hit_date)} sẽ chạm mức sàn"
        if fc.recovers_on is not None:
            text += f" (đủ lại khi nhận lương ngày {_ddmm(fc.recovers_on)})"
        return text
    return f"Chi như hiện tại, cuối tháng còn khoảng {format_vnd(fc.projected_free_end)} được tiêu"


def _details(fc: Forecast, *, baseline_used: bool) -> list[str]:
    source = "ước tính theo tháng trước" if baseline_used else f"{fc.window_days} ngày gần nhất"
    lines = [f"Tốc độ chi ngoài mục tiêu: ~{format_vnd(fc.daily_spend)}/ngày ({source})"]
    if fc.capped_count:
        lines.append(f"Không tính phần vượt của {fc.capped_count} khoản chi lớn ({format_vnd(fc.capped_amount)})")
    if fc.safe_daily_spend is not None:
        lines.append(f"Gợi ý: chi ngoài mục tiêu tối đa ~{format_vnd(fc.safe_daily_spend)}/ngày để giữ trên mức sàn")
    for b in fc.budgets:
        if b.status == "over_pace":
            lines.append(f"{b.category_icon or '📊'} {b.name}: với tốc độ này sẽ dùng {b.projected_pct:.0f}% ngân sách"
                         f" — nên chi tối đa ~{format_vnd(b.suggested_daily)}/ngày")
        elif b.status == "exceeded":
            lines.append(f"{b.category_icon or '📊'} {b.name}: đã vượt ngân sách {format_vnd(b.spent - b.amount)}")
    if fc.confidence == "low":
        lines.append(f"Ước tính sơ bộ: mới có {fc.observed_days} ngày dữ liệu")
    return lines
