"""Nhận ra chuyển khoản giữa các tài khoản của chính mình (VCB <-> MB) để không tính là chi tiêu."""

from __future__ import annotations

from datetime import datetime, timedelta

from sqlmodel import Session, select

from app.config import get_settings
from app.models import Account, Transaction
from app.seed import category_by_key
from app.text import contains_phrase, digits_only, normalize_for_match, normalize_pattern

PAIR_WINDOW = timedelta(minutes=30)
HOLD_FOR_PAIR = timedelta(minutes=5)


def _own_numbers(accounts: list[Account], exclude_id: int) -> list[str]:
    return [
        a.account_number for a in accounts
        if a.id != exclude_id and a.account_number and len(a.account_number) >= 6
    ]


def _mentions_number(text: str, numbers: list[str]) -> bool:
    if not numbers:
        return False
    tokens = set(normalize_for_match(text).split())
    flat = digits_only(text)
    return any(n in tokens or (len(n) >= 8 and n in flat) for n in numbers)


def _mentions_hint(text: str, hints: list[str]) -> bool:
    norm = normalize_for_match(text)
    return any(contains_phrase(norm, normalize_pattern(h)) for h in hints if normalize_pattern(h))


def looks_internal_out(session: Session, tx: Transaction) -> bool:
    """Khoản ra có dấu hiệu chuyển sang TK khác của mình (để hoãn thông báo chờ ghép cặp)."""
    accounts = list(session.exec(select(Account).where(Account.bank != "CASH")).all())
    numbers = _own_numbers(accounts, tx.account_id)
    if tx.counter_account and digits_only(tx.counter_account) in numbers:
        return True
    return _mentions_number(tx.description, numbers) or _mentions_hint(tx.description, get_settings().hint_list)


def _inflow_mentions_owner(tx: Transaction) -> bool:
    cfg = get_settings()
    hints = list(cfg.hint_list)
    if cfg.owner_name:
        hints.append(cfg.owner_name)
    return _mentions_hint(tx.description, hints) or bool(
        tx.counter_name and cfg.owner_name
        and normalize_pattern(cfg.owner_name) == normalize_pattern(tx.counter_name)
    )


def looks_internal_in(session: Session, tx: Transaction) -> bool:
    """Khoản vào có dấu hiệu đến từ TK khác của mình (tên chủ TK, số TK của mình, gợi ý cấu hình)."""
    accounts = list(session.exec(select(Account).where(Account.bank != "CASH")).all())
    numbers = _own_numbers(accounts, tx.account_id)
    if tx.counter_account and digits_only(tx.counter_account) in numbers:
        return True
    return _inflow_mentions_owner(tx) or _mentions_number(tx.description, numbers)


def try_pair(session: Session, tx: Transaction, now: datetime) -> Transaction | None:
    """Ghép `tx` với nửa còn lại (cùng số tiền, khác TK của mình, chiều ngược lại, trong 30 phút)."""
    if tx.pair_id is not None or tx.status == "excluded" or tx.is_manual:
        return None
    if tx.categorized_by == "user":
        return None
    me = session.get(Account, tx.account_id)
    if me is None or not me.include_in_total or not me.confirmed:
        return None
    other_dir = "in" if tx.direction == "out" else "out"
    accounts = {a.id: a for a in session.exec(select(Account)).all()}
    cands = session.exec(
        select(Transaction).where(
            Transaction.direction == other_dir,
            Transaction.amount == tx.amount,
            Transaction.account_id != tx.account_id,
            Transaction.pair_id == None,  # noqa: E711
            Transaction.status == "active",  # email đang chờ webhook (pending) chưa được tính -> chưa ghép
            Transaction.is_manual == False,  # noqa: E712
            Transaction.bank_time >= tx.bank_time - PAIR_WINDOW,
            Transaction.bank_time <= tx.bank_time + PAIR_WINDOW,
        )
    ).all()
    best: Transaction | None = None
    for c in cands:
        acc = accounts.get(c.account_id)
        if acc is None or acc.bank == "CASH" or not acc.include_in_total or not acc.confirmed:
            continue
        if c.categorized_by == "user":
            continue
        out_tx, in_tx = (tx, c) if tx.direction == "out" else (c, tx)
        evidence = (
            out_tx.hold_until is not None
            or in_tx.hold_until is not None
            or looks_internal_out(session, out_tx)
            or _inflow_mentions_owner(in_tx)
            or _mentions_number(in_tx.description, _own_numbers(list(accounts.values()), in_tx.account_id))
        )
        if not evidence:
            continue
        if best is None or abs(c.bank_time - tx.bank_time) < abs(best.bank_time - tx.bank_time):
            best = c
    if best is None:
        return None
    mark_pair(session, tx, best)
    return best


def mark_pair(session: Session, a: Transaction, b: Transaction) -> None:
    transfer = category_by_key(session, "transfer")
    for t, other in ((a, b), (b, a)):
        t.pair_id = other.id
        t.category_id = transfer.id if transfer else None
        t.goal_id = None
        t.categorized_by = "pair"
        t.hold_until = None
        session.add(t)


def hold_deadline(now: datetime) -> datetime:
    return now + HOLD_FOR_PAIR
