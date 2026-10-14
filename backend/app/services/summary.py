"""Nạp dữ liệu từ DB rồi gọi engine để đánh giá tháng."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import or_
from sqlmodel import Session, func, select

from app import clock
from app.engine.evaluator import Evaluation, GoalIn, TxIn, evaluate
from app.models import Account, Category, Transaction
from app.services import runtime_settings
from app.services.goals import ensure_month_goals, goals_for_month


def included_accounts(session: Session) -> list[Account]:
    return list(session.exec(
        select(Account).where(Account.include_in_total == True, Account.confirmed == True)  # noqa: E712
        .order_by(Account.id)
    ).all())


def build_evaluation(session: Session, month: str | None = None, now: datetime | None = None) -> Evaluation:
    now = now or clock.now()
    cur = clock.month_of(now)
    month = month or cur
    if month == cur:
        ensure_month_goals(session, month)

    cats = {c.id: c for c in session.exec(select(Category)).all()}
    goals = goals_for_month(session, month)
    goal_ins = [
        GoalIn(
            id=g.id, name=g.name, type=g.type, amount=g.amount, month=g.month, category_id=g.category_id,
            category_name=cats[g.category_id].name if g.category_id in cats else None,
            category_icon=cats[g.category_id].icon if g.category_id in cats else None,
            series_id=g.series_id, repeat_monthly=g.repeat_monthly, opening_spent=g.opening_spent,
        )
        for g in goals
    ]
    start, end = clock.month_bounds_utc(month)
    goal_ids = [g.id for g in goals]
    cond = (Transaction.bank_time >= start) & (Transaction.bank_time < end)
    if goal_ids:
        cond = or_(cond, Transaction.goal_id.in_(goal_ids))
    txs = session.exec(select(Transaction).where(Transaction.status == "active", cond)).all()
    tx_ins = [
        TxIn(id=t.id, direction=t.direction, amount=t.amount, bank_time=t.bank_time, category_id=t.category_id,
             goal_id=t.goal_id)
        for t in txs
    ]

    accounts = included_accounts(session)
    balance: int | None = None
    if accounts and all(a.balance is not None for a in accounts):
        balance = sum(a.balance for a in accounts)  # type: ignore[misc]
    included_ids = {a.id for a in accounts}
    in_transit = sum(
        t.amount for t in txs
        if t.account_id in included_ids and t.direction == "out" and t.pair_id is None
        and t.hold_until is not None and t.hold_until > now
    )
    income_ids = {c.id for c in cats.values() if c.system_key == "income"}
    income_received = sum(
        t.amount for t in txs
        if t.direction == "in" and t.category_id in income_ids and t.account_id in included_ids
        and start <= t.bank_time < end
    )
    rs = runtime_settings.load(session)
    return evaluate(
        month=month, goals=goal_ins, txs=tx_ins, balance=balance, settings=rs.eval_settings(),
        today=clock.to_ict(now).date(), in_transit=in_transit, income_received=income_received,
    )


def uncategorized_count(session: Session, month: str) -> int:
    start, end = clock.month_bounds_utc(month)
    included_ids = [a.id for a in included_accounts(session)]
    if not included_ids:
        return 0
    return session.exec(
        select(func.count(Transaction.id)).where(
            Transaction.status == "active",
            Transaction.direction == "out",
            Transaction.category_id == None,  # noqa: E711
            Transaction.goal_id == None,  # noqa: E711
            Transaction.pair_id == None,  # noqa: E711
            Transaction.account_id.in_(included_ids),
            Transaction.bank_time >= start,
            Transaction.bank_time < end,
        )
    ).one()
