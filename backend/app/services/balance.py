"""Số dư tài khoản tự phục hồi: mốc gần nhất (số dư ngân hàng báo / nhập tay) + các giao dịch sau mốc."""

from __future__ import annotations

from datetime import datetime, timedelta

from sqlmodel import Session, select

from app import clock
from app.models import Account, Transaction, TransactionSource

WEBHOOK_SOURCES = ("sepay", "casso")
WEBHOOK_COVERAGE_WINDOW = timedelta(days=7)
_MANUAL_RANK = 10**12  # mốc nhập tay đứng sau mọi giao dịch có cùng thời điểm
MANUAL_SKEW = timedelta(minutes=30)


def has_webhook_coverage(session: Session, account_id: int, now: datetime | None = None) -> bool:
    """TK có nhận webhook gần đây không (khi đó email chỉ là nguồn phụ)."""
    now = now or clock.now()
    row = session.exec(
        select(TransactionSource.id)
        .join(Transaction, Transaction.id == TransactionSource.transaction_id)
        .where(
            Transaction.account_id == account_id,
            TransactionSource.source.in_(WEBHOOK_SOURCES),
            TransactionSource.received_at >= now - WEBHOOK_COVERAGE_WINDOW,
        )
    ).first()
    return row is not None


def recompute_balance(session: Session, account: Account, now: datetime | None = None) -> None:
    txs = session.exec(
        select(Transaction).where(
            Transaction.account_id == account.id,
            Transaction.status == "active",
            Transaction.affects_balance == True,  # noqa: E712
        )
    ).all()
    covered = has_webhook_coverage(session, account.id, now)

    def key(tx: Transaction) -> tuple[datetime, int]:
        return (tx.bank_time, tx.id or 0)

    anchor_key: tuple[datetime, int] | None = None
    anchor_balance: int | None = None
    anchor_tx: Transaction | None = None
    for tx in txs:
        if tx.balance_after is None:
            continue
        if tx.balance_source == "email" and covered:
            continue  # TK có webhook: số dư từ email không làm mốc
        k = key(tx)
        if anchor_key is None or k > anchor_key:
            anchor_key, anchor_balance, anchor_tx = k, tx.balance_after, tx
    manual_at = account.manual_balance_at
    if account.manual_balance is not None and manual_at is not None:
        k = (manual_at, _MANUAL_RANK)
        # Số dư ngân hàng báo, nhận được SAU lúc nhập tay và giờ ngân hàng chỉ sớm hơn chút ít (lệch đồng hồ,
        # webhook đến trễ) là thông tin mới hơn -> vẫn ưu tiên hơn số nhập tay.
        reported_newer = (
            anchor_tx is not None
            and anchor_tx.created_at >= manual_at
            and anchor_tx.bank_time >= manual_at - MANUAL_SKEW
        )
        if anchor_key is None or (k > anchor_key and not reported_newer):
            anchor_key, anchor_balance = k, account.manual_balance

    account.last_tx_at = max((tx.bank_time for tx in txs), default=account.last_tx_at)
    if anchor_key is None or anchor_balance is None:
        account.balance = None
        account.balance_as_of = None
        account.balance_derived = False
    else:
        later = [tx for tx in txs if key(tx) > anchor_key]
        delta = sum(tx.amount if tx.direction == "in" else -tx.amount for tx in later)
        account.balance = anchor_balance + delta
        account.balance_derived = bool(later)
        account.balance_as_of = max([anchor_key[0], *(tx.bank_time for tx in later)])
    session.add(account)
