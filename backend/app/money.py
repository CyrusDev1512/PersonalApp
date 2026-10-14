"""Tiền VND: số nguyên đồng."""

from __future__ import annotations

import re

_DECIMAL_TAIL = re.compile(r"[.,]\d{2}$")
_ONLY_DIGITS = re.compile(r"\d+")


def parse_vnd(text: str | None) -> int | None:
    """'1.000.000', '1,000,000', '1.000.000,00', '1000000 VND', '-50.000đ' -> giá trị tuyệt đối (int)."""
    if text is None:
        return None
    s = str(text).strip()
    s = re.sub(r"(?i)\s*(vnd|vnđ|đ|d)\s*$", "", s)
    s = s.lstrip("+-").strip().replace(" ", "")
    if not s or not re.fullmatch(r"[\d.,]+", s):
        return None
    groups = re.split(r"[.,]", s)
    # Phần thập phân 2 chữ số ở cuối (vd 1.000.000,00) thì bỏ; "1.000" có 3 chữ số là phân cách nghìn.
    if len(groups) > 1 and len(groups[-1]) == 2 and _DECIMAL_TAIL.search(s):
        s = s[:-3]
    digits = "".join(_ONLY_DIGITS.findall(s))
    if not digits:
        return None
    return int(digits)


def format_vnd(amount: int | None) -> str:
    if amount is None:
        return "?"
    sign = "-" if amount < 0 else ""
    return f"{sign}{abs(int(amount)):,}".replace(",", ".") + "đ"


def signed(direction: str, amount: int) -> int:
    return amount if direction == "in" else -amount
