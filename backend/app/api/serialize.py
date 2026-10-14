"""Chuyển model/engine object sang JSON theo docs/api.md."""

from __future__ import annotations

from datetime import datetime

from sqlmodel import Session, select

from app import clock
from app.engine.categorize import suggest_rule
from app.engine.evaluator import Evaluation, GoalView
from app.models import Account, Alert, Category, CategoryRule, Goal, Transaction, TransactionSource


def iso(dt: datetime | None) -> str | None:
    return clock.iso_z(dt)


def account_dict(a: Account) -> dict:
    return {
        "id": a.id, "bank": a.bank, "name": a.name, "account_number": a.account_number, "last4": a.last4,
        "include_in_total": a.include_in_total, "confirmed": a.confirmed, "balance": a.balance,
        "balance_as_of": iso(a.balance_as_of), "balance_derived": a.balance_derived,
        "manual_balance": a.manual_balance, "manual_balance_at": iso(a.manual_balance_at),
    }


def goal_view_dict(g: GoalView) -> dict:
    return {
        "id": g.id, "series_id": g.series_id, "name": g.name, "type": g.type, "amount": g.amount,
        "category_id": g.category_id, "category_name": g.category_name, "category_icon": g.category_icon,
        "month": g.month, "repeat_monthly": g.repeat_monthly, "opening_spent": g.opening_spent, "spent": g.spent,
        "remaining": g.remaining, "usage_pct": g.usage_pct, "auto_match": g.auto_match,
    }


def alert_dict(a: Alert) -> dict:
    return {
        "id": a.id, "created_at": iso(a.created_at), "kind": a.kind, "level": a.level, "title": a.title,
        "message": a.message, "read": a.read, "transaction_id": a.transaction_id, "goal_id": a.goal_id,
    }


def category_dict(c: Category) -> dict:
    return {"id": c.id, "name": c.name, "kind": c.kind, "icon": c.icon, "sort_order": c.sort_order,
            "system_key": c.system_key}


def rule_dict(r: CategoryRule) -> dict:
    return {"id": r.id, "category_id": r.category_id, "pattern": r.pattern, "direction": r.direction,
            "priority": r.priority, "origin": r.origin}


def possible_duplicate_of(session: Session, tx: Transaction) -> int | None:
    if tx.is_manual or tx.pair_id is not None:
        return None
    window = 60 * 60
    others = session.exec(
        select(Transaction).where(
            Transaction.id != tx.id,
            Transaction.account_id == tx.account_id,
            Transaction.amount == tx.amount,
            Transaction.direction == tx.direction,
            Transaction.status != "excluded",
        )
    ).all()
    for o in others:
        if abs((o.bank_time - tx.bank_time).total_seconds()) <= window:
            return o.id
    return None


def tx_dict(session: Session, t: Transaction, *, with_duplicates: bool = True) -> dict:
    acc = session.get(Account, t.account_id)
    cat = session.get(Category, t.category_id) if t.category_id else None
    goal = session.get(Goal, t.goal_id) if t.goal_id else None
    sources = sorted(set(session.exec(
        select(TransactionSource.source).where(TransactionSource.transaction_id == t.id)
    ).all()))
    return {
        "id": t.id, "account_id": t.account_id, "account_name": acc.name if acc else None,
        "bank": acc.bank if acc else None, "direction": t.direction, "amount": t.amount,
        "bank_time": iso(t.bank_time), "time_precision": t.time_precision, "description": t.description,
        "reference_code": t.reference_code, "counter_account": t.counter_account, "counter_name": t.counter_name,
        "balance_after": t.balance_after, "category_id": t.category_id, "category_name": cat.name if cat else None,
        "category_icon": cat.icon if cat else None, "goal_id": t.goal_id,
        "goal_name": f"{goal.name} ({goal.month})" if goal else None, "goal_month": goal.month if goal else None,
        "categorized_by": t.categorized_by, "suggested_rule": suggest_rule(t.description),
        "status": t.status, "is_manual": t.is_manual, "affects_balance": t.affects_balance, "pair_id": t.pair_id,
        "sources": sources,
        "possible_duplicate_of": possible_duplicate_of(session, t) if with_duplicates else None,
    }


def evaluation_dict(ev: Evaluation) -> dict:
    return {
        "month": ev.month, "level": ev.level, "level_reason": ev.level_reason, "balance": ev.balance,
        "balance_known": ev.balance_known, "in_transit": ev.in_transit, "floor": ev.floor, "free": ev.free,
        "buffer": ev.buffer, "waiting_income": ev.waiting_income, "days_left": ev.days_left,
        "goals": [goal_view_dict(g) for g in ev.goals],
    }


def forecast_dict(fc) -> dict | None:
    if fc is None:
        return None
    return {
        "status": fc.status, "confidence": fc.confidence, "reason": fc.reason, "observed_days": fc.observed_days,
        "window_days": fc.window_days, "daily_spend": fc.daily_spend, "capped_amount": fc.capped_amount,
        "capped_count": fc.capped_count, "projected_free_end": fc.projected_free_end,
        "projected_budget_overrun": fc.projected_budget_overrun, "income_pending": fc.income_pending,
        "floor_hit_date": fc.floor_hit_date.isoformat() if fc.floor_hit_date else None,
        "days_until_floor_hit": fc.days_until_floor_hit,
        "recovers_on": fc.recovers_on.isoformat() if fc.recovers_on else None,
        "safe_daily_spend": fc.safe_daily_spend, "headline": fc.headline, "details": list(fc.details),
        "budgets": [
            {"goal_id": b.goal_id, "name": b.name, "category_icon": b.category_icon, "spent": b.spent,
             "amount": b.amount, "daily_rate": b.daily_rate, "projected_spent": b.projected_spent,
             "projected_pct": b.projected_pct, "status": b.status, "suggested_daily": b.suggested_daily}
            for b in fc.budgets
        ],
    }
