"""Chính sách gửi cảnh báo (chống spam, hysteresis). Hàm thuần — trạng thái truyền vào/ra."""

from __future__ import annotations

from dataclasses import dataclass, field, replace
from datetime import date, datetime, timedelta

from app.engine.evaluator import LEVEL_RANK, Evaluation, GoalView

REPEAT_GAP = timedelta(hours=2)  # vào lại cùng mức trong 2 giờ thì không báo lại
HYSTERESIS_MIN = 200_000
BUDGET_THRESHOLDS = (80, 100)
BUDGET_REARM_GAP = 5.0  # tụt 5 điểm % dưới ngưỡng thì cho báo lại


@dataclass
class FloorState:
    last_level: str | None = None
    last_deficit: int | None = None
    notified: dict[str, datetime] = field(default_factory=dict)


@dataclass
class FloorDecision:
    notify: bool
    kind: str | None  # worse | safe | escalate
    level: str  # mức đã áp hysteresis
    state: FloorState


def hysteresis(buffer: int) -> int:
    return max(round(buffer * 0.1), HYSTERESIS_MIN)


def _effective_level(prev: str, ev: Evaluation) -> str:
    """Mức sau khi áp hysteresis: xấu đi thì nhận ngay, tốt lên phải vượt ngưỡng + h."""
    raw = ev.level
    if LEVEL_RANK[raw] >= LEVEL_RANK[prev]:
        return raw
    assert ev.free is not None
    h = hysteresis(ev.buffer)
    if prev == "DANGER":
        if ev.free >= ev.buffer + h:
            return "OK"
        if ev.free >= h or ev.waiting_income:
            return "WARNING"
        return "DANGER"
    # prev == WARNING
    return "OK" if ev.free >= ev.buffer + h else "WARNING"


def decide_floor(state: FloorState | None, ev: Evaluation, reason: str, now: datetime) -> FloorDecision:
    """reason: 'inflow' (tiền vào), 'tx' (khoản chi mới), 'pair', 'recategorize', 'api', 'job', ..."""
    state = state or FloorState()
    if ev.level == "UNKNOWN":
        return FloorDecision(False, None, "UNKNOWN", state)

    prev = state.last_level if state.last_level in LEVEL_RANK else "OK"
    eff = _effective_level(prev, ev)
    new = replace(state, notified=dict(state.notified))
    notify, kind = False, None

    if LEVEL_RANK[eff] > LEVEL_RANK[prev]:
        last = state.notified.get(eff)
        if last is None or now - last >= REPEAT_GAP:
            notify, kind = True, "worse"
            new.notified[eff] = now
        if eff == "DANGER":
            new.last_deficit = ev.deficit
    elif LEVEL_RANK[eff] < LEVEL_RANK[prev]:
        if eff == "OK" and reason == "inflow":
            last = state.notified.get("SAFE")
            if last is None or now - last >= REPEAT_GAP:
                notify, kind = True, "safe"
                new.notified["SAFE"] = now
        if eff != "DANGER":
            new.last_deficit = None
    elif eff == "DANGER":
        deficit = ev.deficit
        last_deficit = state.last_deficit if state.last_deficit else deficit
        if deficit >= last_deficit + max(ev.buffer, round(last_deficit * 0.25)):
            notify, kind = True, "escalate"
            new.last_deficit = deficit
        elif state.last_deficit is None:
            new.last_deficit = deficit

    new.last_level = eff
    return FloorDecision(notify, kind, eff, new)


def decide_budget(goal: GoalView, armed: dict[int, bool]) -> tuple[int | None, dict[int, bool]]:
    """Trả về (ngưỡng cao nhất vừa vượt, trạng thái armed mới). Chỉ áp cho goal ngân sách."""
    new = {th: armed.get(th, True) for th in BUDGET_THRESHOLDS}
    if goal.type != "budget" or goal.amount <= 0:
        return None, new
    fired: int | None = None
    for th in BUDGET_THRESHOLDS:
        if goal.usage_pct >= th:
            if new[th]:
                new[th] = False
                fired = th
        elif goal.usage_pct < th - BUDGET_REARM_GAP:
            new[th] = True
    return fired, new


# ---- dự báo ----------------------------------------------------------------------------------------------

FORECAST_HORIZON_DAYS = 7  # chỉ báo khi dự kiến chạm mức sàn trong 7 ngày tới
FORECAST_REARM_DAYS = 10  # dự báo xa hơn 10 ngày (hoặc không chạm) thì cho báo lại lần sau
FORECAST_MIN_SHORTFALL = 200_000  # thiếu ít hơn 200k thì không đáng báo
FORECAST_ESCALATE_DAYS = 3
FORECAST_ESCALATE_GAP = timedelta(hours=24)


@dataclass
class ForecastState:
    armed: bool = True
    last_sent_at: datetime | None = None
    last_hit: date | None = None


def decide_forecast(state: ForecastState | None, fc, ev: Evaluation, now: datetime) -> tuple[bool, ForecastState]:
    """Có nên gửi cảnh báo "dự báo chạm mức sàn" không. `fc` là engine.forecast.Forecast (hoặc None)."""
    state = state or ForecastState()
    new = replace(state)
    if fc is None or fc.status != "ok" or ev.level not in ("OK", "WARNING") or not ev.goals:
        return False, new
    days = fc.days_until_floor_hit
    if days == 0 or (ev.free is not None and ev.free < 0):
        return False, new  # đã dưới mức sàn: việc của cảnh báo mức sàn, không báo trùng (giữ nguyên trạng thái)
    if days is None or days >= FORECAST_REARM_DAYS:
        new.armed = True
        return False, new
    material = fc.min_projected_free is not None and fc.min_projected_free <= -FORECAST_MIN_SHORTFALL
    if days > FORECAST_HORIZON_DAYS or not material:
        return False, new
    if state.armed:
        new.armed, new.last_sent_at, new.last_hit = False, now, fc.floor_hit_date
        return True, new
    earlier = (state.last_hit is not None and fc.floor_hit_date is not None
               and (state.last_hit - fc.floor_hit_date).days >= FORECAST_ESCALATE_DAYS)
    if earlier and (state.last_sent_at is None or now - state.last_sent_at >= FORECAST_ESCALATE_GAP):
        new.last_sent_at, new.last_hit = now, fc.floor_hit_date
        return True, new
    return False, new
