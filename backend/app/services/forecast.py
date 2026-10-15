"""Nạp dữ liệu từ DB cho engine dự báo cuối tháng."""

from __future__ import annotations

from datetime import date, datetime

from sqlmodel import Session, func, select

from app import clock
from app.engine.evaluator import Evaluation, attribute_goals
from app.engine.forecast import Forecast, ForecastCfg, OutflowIn, capped_total, forecast
from app.models import Account, Category, Transaction
from app.services import runtime_settings
from app.services.summary import included_accounts, month_inputs, tx_in


def _counts_as_spending(t: Transaction, included: set[int], transfer_ids: set[int], now: datetime) -> bool:
    return (
        t.direction == "out"
        and t.status == "active"
        and t.account_id in included
        and t.affects_balance
        and t.pair_id is None
        and t.category_id not in transfer_ids
        and (t.hold_until is None or t.hold_until <= now)
        and t.bank_time <= now
    )


def _outflows(session: Session, month: str, included: set[int], now: datetime) -> list[OutflowIn]:
    cats = {c.id: c for c in session.exec(select(Category)).all()}
    transfer_ids = {c.id for c in cats.values() if c.kind == "transfer"}
    goal_ins, txs = month_inputs(session, month, cats)
    attribution = attribute_goals(goal_ins, [tx_in(t) for t in txs])
    start, end = clock.month_bounds_utc(month)
    return [
        OutflowIn(id=t.id, amount=t.amount, day=clock.to_ict(t.bank_time).date(), goal_id=attribution.get(t.id))
        for t in txs
        if start <= t.bank_time < end and _counts_as_spending(t, included, transfer_ids, now)
    ]


def _refunds(session: Session, month: str, included: set[int], now: datetime) -> list[OutflowIn]:
    """Khoản tiền hoàn lại (danh mục Hoàn tiền) — bù vào chi tiêu ngoài mục tiêu khi tính tốc độ chi."""
    refund_ids = {c.id for c in session.exec(select(Category)).all() if c.system_key == "refund"}
    if not refund_ids:
        return []
    start, end = clock.month_bounds_utc(month)
    rows = session.exec(
        select(Transaction).where(
            Transaction.direction == "in", Transaction.status == "active", Transaction.category_id.in_(refund_ids),
            Transaction.account_id.in_(included), Transaction.bank_time >= start, Transaction.bank_time < end,
            Transaction.goal_id == None,  # noqa: E711
        )
    ).all()
    return [OutflowIn(id=t.id, amount=t.amount, day=clock.to_ict(t.bank_time).date()) for t in rows
            if t.affects_balance and t.bank_time <= now]


def _data_since(session: Session, accounts: list[Account], today: date) -> date:
    candidates = [clock.to_ict(a.created_at).date() for a in accounts if a.created_at is not None]
    ids = [a.id for a in accounts]
    if ids:
        first_tx = session.exec(select(func.min(Transaction.bank_time)).where(Transaction.account_id.in_(ids))).one()
        if first_tx is not None:
            candidates.append(clock.to_ict(clock.ensure_utc(first_tx)).date())
    return min(candidates, default=today)


def _baseline_rate(session: Session, month: str, included: set[int], data_since: date, now: datetime,
                   cfg: ForecastCfg) -> int | None:
    """Tốc độ chi ngoài mục tiêu của tháng trước (dùng cho đầu tháng). Cần ít nhất `full_days` ngày dữ liệu."""
    prev = clock.prev_month(month)
    year, mon = clock.parse_month(prev)
    prev_start = date(year, mon, 1)
    prev_end = date(year, mon, clock.days_in_month(prev))
    observed_from = max(prev_start, data_since)
    days = (prev_end - observed_from).days + 1
    if days < cfg.full_days:
        return None
    amounts = [o.amount for o in _outflows(session, prev, included, now) if o.goal_id is None]
    counted, _, _ = capped_total(amounts, cfg)
    return round(counted / days)


def build_forecast(session: Session, ev: Evaluation, now: datetime | None = None) -> Forecast | None:
    now = now or clock.now()
    if ev.month != clock.month_of(now):
        return None
    cfg = ForecastCfg()
    today = clock.to_ict(now).date()
    accounts = included_accounts(session)
    included = {a.id for a in accounts}
    data_since = _data_since(session, accounts, today)
    rs = runtime_settings.load(session)
    return forecast(
        ev=ev, outflows=_outflows(session, ev.month, included, now), today=today, data_since=data_since,
        income_day=rs.expected_income_day,
        baseline_rate=_baseline_rate(session, ev.month, included, data_since, now, cfg),
        refunds=_refunds(session, ev.month, included, now), cfg=cfg,
    )
