"""Chuẩn hoá văn bản tiếng Việt để so khớp từ khoá."""

from __future__ import annotations

import re
import unicodedata

_DOMAIN = re.compile(r"\S+\.(?:com|vn|net|org|io|app)(?:\.vn)?\S*", re.IGNORECASE)
_CITY_TOKENS = re.compile(r"\b(?:thanh pho|tp\.? ?hcm|tp\.? ?ho chi minh|ho chi minh|ha noi|tp\.? ?hn|da nang)\b")
_NON_ALNUM = re.compile(r"[^a-z0-9]+")


def strip_accents(text: str) -> str:
    text = unicodedata.normalize("NFD", text)
    text = "".join(ch for ch in text if unicodedata.category(ch) != "Mn")
    return unicodedata.normalize("NFC", text).replace("đ", "d").replace("Đ", "D")


def normalize_for_match(text: str | None) -> str:
    """Chữ thường, bỏ dấu, bỏ domain và tên thành phố, chỉ còn chữ/số cách nhau bởi 1 khoảng trắng."""
    if not text:
        return ""
    s = strip_accents(unicodedata.normalize("NFC", text)).lower()
    s = _DOMAIN.sub(" ", s)
    s = _NON_ALNUM.sub(" ", s)
    s = _CITY_TOKENS.sub(" ", s)
    return " ".join(s.split())


def normalize_pattern(pattern: str) -> str:
    return " ".join(_NON_ALNUM.sub(" ", strip_accents(pattern).lower()).split())


def contains_phrase(haystack_norm: str, phrase_norm: str) -> bool:
    """Khớp cả cụm từ theo ranh giới token (không khớp chuỗi con)."""
    if not phrase_norm:
        return False
    return f" {phrase_norm} " in f" {haystack_norm} "


def digits_only(text: str | None) -> str:
    return re.sub(r"\D", "", text or "")
