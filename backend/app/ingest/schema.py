"""Dạng chuẩn hoá chung của một giao dịch, dù đến từ SePay, Casso hay email."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any


@dataclass
class NormalizedTx:
    source: str  # sepay | casso | email | manual
    external_id: str  # id duy nhất trong nguồn (SePay id, Casso id, email Message-ID)
    direction: str  # in | out
    amount: int  # > 0
    bank_time: datetime  # aware UTC
    time_precision: str = "second"  # second | minute | approx | date
    bank: str | None = None  # mã chuẩn: VCB, MB, ...
    account_number: str | None = None  # chỉ chữ số
    account_last4: str | None = None
    description: str = ""
    reference_code: str | None = None
    counter_account: str | None = None
    counter_name: str | None = None
    balance_after: int | None = None  # None nếu nguồn không báo (0 cũng coi là không biết)
    is_test: bool = False
    meta: dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if self.direction not in ("in", "out"):
            raise ValueError(f"direction không hợp lệ: {self.direction}")
        if not isinstance(self.amount, int) or self.amount <= 0:
            raise ValueError(f"amount phải là số nguyên dương: {self.amount!r}")
        if self.bank_time.tzinfo is None:
            raise ValueError("bank_time phải có timezone (UTC)")
        if self.account_number:
            digits = "".join(ch for ch in self.account_number if ch.isdigit())
            self.account_number = digits or None
        if self.account_number and not self.account_last4:
            self.account_last4 = self.account_number[-4:]
        if self.balance_after is not None and self.balance_after <= 0:
            # Ngân hàng/aggregator thường trả 0 khi không có thông tin số dư.
            self.balance_after = None


class ParseError(Exception):
    """Payload hợp lệ về xác thực nhưng không đọc được giao dịch."""


class IgnoredPayload(Exception):
    """Payload hợp lệ nhưng cố ý bỏ qua (vd. webhook test)."""


class AuthError(Exception):
    """Sai/thiếu chữ ký hoặc khoá xác thực webhook."""
