"""Bảng dữ liệu (SQLModel). Tiền là số nguyên VND, thời gian lưu UTC."""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

from sqlalchemy import DateTime, Text, UniqueConstraint
from sqlalchemy.types import TypeDecorator
from sqlmodel import Field, SQLModel

from app import clock


class UTCDateTime(TypeDecorator):
    """Lưu datetime naive UTC trong SQLite, đọc ra luôn là aware UTC."""

    impl = DateTime
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        return clock.ensure_utc(value).replace(tzinfo=None)

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        return value.replace(tzinfo=UTC)


def _now() -> datetime:
    return clock.now()


def _uuid() -> str:
    return uuid.uuid4().hex


# Giá trị hợp lệ cho các cột dạng chuỗi
DIRECTIONS = ("in", "out")
GOAL_TYPES = ("reserve", "budget")
CATEGORY_KINDS = ("expense", "income", "transfer")
TX_STATUSES = ("active", "pending", "excluded")
PRECISIONS = ("second", "minute", "approx", "date")
LEVELS = ("OK", "WARNING", "DANGER", "UNKNOWN")


class Account(SQLModel, table=True):
    __tablename__ = "accounts"

    id: int | None = Field(default=None, primary_key=True)
    bank: str = Field(index=True)  # VCB, MB, ... hoặc OTHER
    account_number: str | None = Field(default=None, index=True)
    last4: str | None = Field(default=None, index=True)
    name: str
    include_in_total: bool = True
    confirmed: bool = True
    manual_balance: int | None = None
    manual_balance_at: datetime | None = Field(default=None, sa_type=UTCDateTime)
    # Kết quả recompute_balance (cache để đọc nhanh)
    balance: int | None = None
    balance_as_of: datetime | None = Field(default=None, sa_type=UTCDateTime)
    balance_derived: bool = False
    last_tx_at: datetime | None = Field(default=None, sa_type=UTCDateTime)
    created_at: datetime = Field(default_factory=_now, sa_type=UTCDateTime)


class Category(SQLModel, table=True):
    __tablename__ = "categories"

    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(unique=True)
    kind: str = "expense"  # expense | income | transfer
    icon: str | None = None
    sort_order: int = 100
    system_key: str | None = Field(default=None, index=True)  # food, rent, income, refund, transfer, other...


class CategoryRule(SQLModel, table=True):
    __tablename__ = "category_rules"

    id: int | None = Field(default=None, primary_key=True)
    category_id: int = Field(foreign_key="categories.id", index=True)
    pattern: str  # cụm từ đã bỏ dấu, chữ thường
    direction: str = "out"  # out | in | any
    priority: int = 100
    origin: str = "seed"  # seed | user


class Goal(SQLModel, table=True):
    __tablename__ = "goals"
    __table_args__ = (UniqueConstraint("series_id", "month", name="uq_goal_series_month"),)

    id: int | None = Field(default=None, primary_key=True)
    series_id: str = Field(default_factory=_uuid, index=True)
    name: str
    type: str = "budget"  # reserve | budget
    amount: int
    category_id: int | None = Field(default=None, foreign_key="categories.id")
    month: str = Field(index=True)  # YYYY-MM (giờ VN)
    repeat_monthly: bool = True
    opening_spent: int = 0
    archived: bool = False
    created_at: datetime = Field(default_factory=_now, sa_type=UTCDateTime)
    updated_at: datetime = Field(default_factory=_now, sa_type=UTCDateTime)


class Transaction(SQLModel, table=True):
    __tablename__ = "transactions"

    id: int | None = Field(default=None, primary_key=True)
    account_id: int = Field(foreign_key="accounts.id", index=True)
    direction: str  # in | out
    amount: int  # > 0
    bank_time: datetime = Field(sa_type=UTCDateTime, index=True)
    time_precision: str = "second"
    description: str = Field(default="", sa_type=Text)
    reference_code: str | None = None
    counter_account: str | None = None
    counter_name: str | None = None
    # Số dư sau giao dịch do ngân hàng báo (không phải số tự suy ra)
    balance_after: int | None = None
    balance_source: str | None = None  # sepay | casso | email
    category_id: int | None = Field(default=None, foreign_key="categories.id", index=True)
    goal_id: int | None = Field(default=None, foreign_key="goals.id", index=True)
    categorized_by: str = "none"  # rule | user | pair | none
    status: str = Field(default="active", index=True)  # active | pending | excluded
    pending_until: datetime | None = Field(default=None, sa_type=UTCDateTime)
    affects_balance: bool = True
    is_manual: bool = False
    pair_id: int | None = None
    # Khoản chi có thể là chuyển nội bộ: hoãn đánh giá/thông báo tới thời điểm này để chờ ghép cặp
    hold_until: datetime | None = Field(default=None, sa_type=UTCDateTime)
    evaluated: bool = False  # đã chạy đánh giá + thông báo cho giao dịch này chưa
    quiet: bool = False  # nhập im lặng (backfill): không bao giờ gửi tin riêng cho giao dịch này
    created_at: datetime = Field(default_factory=_now, sa_type=UTCDateTime)
    updated_at: datetime = Field(default_factory=_now, sa_type=UTCDateTime)


class TransactionSource(SQLModel, table=True):
    __tablename__ = "transaction_sources"
    __table_args__ = (UniqueConstraint("source", "external_id", name="uq_source_external"),)

    id: int | None = Field(default=None, primary_key=True)
    transaction_id: int = Field(foreign_key="transactions.id", index=True)
    source: str  # sepay | casso | email | manual
    external_id: str
    received_at: datetime = Field(default_factory=_now, sa_type=UTCDateTime)
    ingest_event_id: int | None = Field(default=None, foreign_key="ingest_events.id")


class IngestEvent(SQLModel, table=True):
    __tablename__ = "ingest_events"

    id: int | None = Field(default=None, primary_key=True)
    source: str = Field(index=True)
    external_id: str | None = None
    received_at: datetime = Field(default_factory=_now, sa_type=UTCDateTime)
    headers_json: str = Field(default="{}", sa_type=Text)
    payload_text: str = Field(default="", sa_type=Text)
    # received | parsed | duplicate | unparsed | ignored | error
    status: str = Field(default="received", index=True)
    error: str | None = Field(default=None, sa_type=Text)
    transaction_id: int | None = None


class Alert(SQLModel, table=True):
    __tablename__ = "alerts"

    id: int | None = Field(default=None, primary_key=True)
    created_at: datetime = Field(default_factory=_now, sa_type=UTCDateTime, index=True)
    # tx | floor | safe | budget | digest | account | health | info
    kind: str
    level: str | None = None  # OK | WARNING | DANGER | UNKNOWN | INFO
    month: str | None = None
    goal_id: int | None = None
    transaction_id: int | None = Field(default=None, index=True)
    title: str
    message: str = Field(sa_type=Text)
    snapshot_json: str | None = Field(default=None, sa_type=Text)
    read: bool = False
    # Outbox Telegram
    deliver_telegram: bool = True
    loud: bool = True  # False => gửi im lặng (disable_notification)
    reply_markup_json: str | None = Field(default=None, sa_type=Text)
    send_after: datetime | None = Field(default=None, sa_type=UTCDateTime)
    telegram_sent: bool = Field(default=False, index=True)
    telegram_message_id: int | None = None
    telegram_attempts: int = 0
    telegram_next_attempt_at: datetime | None = Field(default=None, sa_type=UTCDateTime)
    telegram_last_error: str | None = None
    needs_edit: bool = Field(default=False, index=True)
    revision: int = 0  # tăng mỗi lần nội dung đổi; outbox dùng để không ghi đè bản sửa mới hơn
    cancelled: bool = False


class AlertState(SQLModel, table=True):
    __tablename__ = "alert_states"

    key: str = Field(primary_key=True)
    last_level: str | None = None
    last_sent_at: datetime | None = Field(default=None, sa_type=UTCDateTime)
    last_deficit: int | None = None
    armed: bool = True
    # JSON: {"WARNING": "<iso>", "DANGER": "<iso>"} — lần cuối đã báo từng mức
    notified_json: str = Field(default="{}", sa_type=Text)


class KV(SQLModel, table=True):
    __tablename__ = "kv"

    key: str = Field(primary_key=True)
    value_json: str = Field(sa_type=Text)
