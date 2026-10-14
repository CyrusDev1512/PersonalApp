"""Các thao tác người dùng trên một giao dịch (dùng chung cho API và Telegram bot)."""

from __future__ import annotations

from datetime import datetime

from sqlmodel import Session, select

from app import clock
from app.ingest.pairing import PAIR_WINDOW, mark_pair
from app.models import Account, Category, CategoryRule, Goal, Transaction
from app.services.balance import recompute_balance
from app.services.goals import auto_goal_for, ensure_goal
from app.text import normalize_pattern


class ActionError(ValueError):
    """Thao tác không hợp lệ (trả 400 cho API, câu trả lời ngắn cho bot)."""


def _unpair(session: Session, tx: Transaction) -> None:
    if tx.pair_id is None:
        return
    other = session.get(Transaction, tx.pair_id)
    tx.pair_id = None
    if other is not None and other.pair_id == tx.id:
        other.pair_id = None
        if other.categorized_by == "pair":
            other.category_id, other.categorized_by = None, "none"
        session.add(other)


def set_category(
    session: Session, tx: Transaction, category_id: int | None, *, remember_pattern: str | None = None
) -> None:
    if category_id is None:
        _unpair(session, tx)
        tx.category_id, tx.categorized_by = None, "none"
        session.add(tx)
        return
    cat = session.get(Category, category_id)
    if cat is None:
        raise ActionError("Danh mục không tồn tại")
    if remember_pattern:
        _remember_rule(session, cat, tx.direction, remember_pattern)
    if cat.kind == "transfer":
        mark_internal(session, tx)
        return
    _unpair(session, tx)
    tx.category_id, tx.categorized_by, tx.hold_until = cat.id, "user", None
    if tx.goal_id is not None:
        goal = session.get(Goal, tx.goal_id)
        # Đã gán mục tiêu của danh mục khác (vd. "Tính cho tháng sau" tiền trọ) -> bỏ gán, tính theo danh mục mới
        if goal is None or (goal.category_id is not None and goal.category_id != cat.id):
            tx.goal_id = None
    session.add(tx)


def _remember_rule(session: Session, cat: Category, direction: str, remember_pattern: str) -> None:
    if remember_pattern:
        pattern = normalize_pattern(remember_pattern)
        if len(pattern) < 2:
            raise ActionError("Cụm từ để nhớ luật quá ngắn")
        exists = session.exec(
            select(CategoryRule).where(CategoryRule.pattern == pattern, CategoryRule.direction == direction)
        ).first()
        if exists is None:
            session.add(CategoryRule(category_id=cat.id, pattern=pattern, direction=direction, priority=10,
                                     origin="user"))
        else:
            exists.category_id, exists.origin, exists.priority = cat.id, "user", 10
            session.add(exists)


def mark_internal(session: Session, tx: Transaction) -> Transaction | None:
    """Người dùng đánh dấu là chuyển nội bộ: ghép với nửa còn lại nếu tìm thấy."""
    transfer = session.exec(select(Category).where(Category.system_key == "transfer")).first()
    other_dir = "in" if tx.direction == "out" else "out"
    cands = session.exec(
        select(Transaction).where(
            Transaction.direction == other_dir,
            Transaction.amount == tx.amount,
            Transaction.account_id != tx.account_id,
            Transaction.pair_id == None,  # noqa: E711
            Transaction.status != "excluded",
            Transaction.bank_time >= tx.bank_time - PAIR_WINDOW,
            Transaction.bank_time <= tx.bank_time + PAIR_WINDOW,
        )
    ).all()
    banks = {a.id: a for a in session.exec(select(Account)).all()}
    cands = [c for c in cands if banks.get(c.account_id) and banks[c.account_id].bank != "CASH"]
    _unpair(session, tx)
    if cands:
        best = min(cands, key=lambda c: abs(c.bank_time - tx.bank_time))
        mark_pair(session, tx, best)
        tx.categorized_by = best.categorized_by = "user"
        session.add(best)
        session.add(tx)
        return best
    tx.category_id = transfer.id if transfer else None
    tx.goal_id, tx.categorized_by, tx.hold_until = None, "user", None
    session.add(tx)
    return None


def set_goal(session: Session, tx: Transaction, goal_id: int | None) -> None:
    if goal_id is not None:
        goal = session.get(Goal, goal_id)
        if goal is None or goal.archived:
            raise ActionError("Mục tiêu không tồn tại")
    tx.goal_id = goal_id
    session.add(tx)


def goal_for_tx(session: Session, tx: Transaction) -> Goal | None:
    """Mục tiêu mà giao dịch đang được tính vào."""
    if tx.goal_id is not None:
        return session.get(Goal, tx.goal_id)
    if tx.category_id is None:
        return None
    return auto_goal_for(session, tx.category_id, clock.month_of(tx.bank_time))


def assign_next_month(session: Session, tx: Transaction) -> Goal:
    goal = goal_for_tx(session, tx)
    if goal is None:
        raise ActionError("Giao dịch chưa thuộc mục tiêu nào — hãy chọn danh mục trước")
    if goal.month > clock.month_of(tx.bank_time):
        return goal  # đã tính cho tháng sau rồi: bấm lại không đẩy sang tháng kế tiếp
    target = ensure_goal(session, goal.series_id, clock.next_month(goal.month))
    if target is None:
        raise ActionError("Không tạo được mục tiêu tháng sau")
    tx.goal_id = target.id
    session.add(tx)
    return target


def set_excluded(session: Session, tx: Transaction, excluded: bool, now: datetime | None = None) -> None:
    if excluded:
        _unpair(session, tx)
        tx.status, tx.pending_until, tx.hold_until = "excluded", None, None
    elif tx.status == "excluded":
        tx.status = "active"
    session.add(tx)
    session.flush()
    acc = session.get(Account, tx.account_id)
    if acc is not None:
        recompute_balance(session, acc, now)
