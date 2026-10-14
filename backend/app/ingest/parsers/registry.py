"""Chọn parser theo mã ngân hàng; không có parser riêng thì dùng parser chung."""

from __future__ import annotations

from collections.abc import Mapping, Sequence

from app.ingest.banks import canonical_bank
from app.ingest.parsers.base import BankParser
from app.ingest.parsers.generic import GenericParser
from app.ingest.parsers.mb import MbParser
from app.ingest.parsers.vcb import VcbParser

GENERIC = GenericParser()
_PARSER_CLASSES: tuple[type[BankParser], ...] = (VcbParser, MbParser)


def build_parsers(bank_domains: Mapping[str, Sequence[str]] | None = None) -> list[BankParser]:
    """Parser riêng cho từng ngân hàng; domain lấy từ cấu hình (`Settings.bank_domains`) nếu có."""
    domains = {canonical_bank(k): list(v) for k, v in (bank_domains or {}).items()}
    return [cls(domains.get(cls.bank)) for cls in _PARSER_CLASSES]


PARSERS: list[BankParser] = build_parsers()


def parser_for(bank: str | None, parsers: Sequence[BankParser] | None = None) -> BankParser:
    code = canonical_bank(bank)
    for parser in PARSERS if parsers is None else parsers:
        if parser.bank == code:
            return parser
    return GENERIC


def parser_for_domain(from_domain: str, parsers: Sequence[BankParser] | None = None) -> BankParser | None:
    for parser in PARSERS if parsers is None else parsers:
        if parser.matches(from_domain):
            return parser
    return None
