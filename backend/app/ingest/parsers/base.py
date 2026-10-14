"""Kiểu dữ liệu chung cho các parser email ngân hàng."""

from __future__ import annotations

from collections.abc import Iterable
from dataclasses import dataclass
from datetime import datetime


@dataclass
class ParsedTx:
    """Một giao dịch đọc được từ nội dung email (chưa chuẩn hoá thành `NormalizedTx`)."""

    direction: str | None  # in | out | None (không xác định được)
    amount: int  # > 0
    balance_after: int | None = None
    account_hint: str | None = None  # chỉ chữ số, hoặc dạng che "123xxx456"
    when: datetime | None = None  # giờ Việt Nam, naive
    when_precision: str | None = None  # second | minute | date | None
    description: str = ""
    reference_code: str | None = None
    counter_account: str | None = None


def normalize_domain(domain: str | None) -> str:
    return (domain or "").strip().strip("<>").lstrip("@").rstrip(".").lower()


def domain_matches(domain: str | None, allowed: Iterable[str]) -> bool:
    """`info.vietcombank.com.vn` khớp `vietcombank.com.vn` (bằng nhau hoặc là domain con)."""
    d = normalize_domain(domain)
    if not d:
        return False
    for item in allowed:
        a = normalize_domain(item)
        if a and (d == a or d.endswith("." + a)):
            return True
    return False


class BankParser:
    """Parser cho email của một ngân hàng. Lớp con đặt `bank`, `default_domains` và cài `parse`."""

    bank: str = ""
    default_domains: tuple[str, ...] = ()

    def __init__(self, domains: Iterable[str] | None = None) -> None:
        source = self.default_domains if domains is None else domains
        self.domains: list[str] = [d for d in (normalize_domain(x) for x in source) if d]

    def matches(self, from_domain: str) -> bool:
        return domain_matches(from_domain, self.domains)

    def parse(self, subject: str, text: str) -> list[ParsedTx]:  # pragma: no cover - lớp con cài
        raise NotImplementedError

    def __repr__(self) -> str:
        return f"{type(self).__name__}(bank={self.bank!r}, domains={self.domains!r})"
