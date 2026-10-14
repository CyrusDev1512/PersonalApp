"""Phân loại giao dịch theo luật từ khoá (khớp cụm từ theo token, đã bỏ dấu)."""

from __future__ import annotations

from dataclasses import dataclass

from app.text import contains_phrase, normalize_for_match


@dataclass
class RuleIn:
    id: int
    category_id: int
    pattern: str  # đã chuẩn hoá bằng normalize_pattern
    direction: str = "out"  # out | in | any
    priority: int = 100
    origin: str = "seed"


def match_rule(description: str, direction: str, rules: list[RuleIn]) -> RuleIn | None:
    norm = normalize_for_match(description)
    if not norm:
        return None
    hits = [r for r in rules if r.direction in (direction, "any") and contains_phrase(norm, r.pattern)]
    if not hits:
        return None
    # Ưu tiên: priority nhỏ hơn, luật người dùng tạo, cụm từ dài hơn (cụ thể hơn)
    hits.sort(key=lambda r: (r.priority, r.origin != "user", -len(r.pattern), r.id))
    return hits[0]


def categorize(
    description: str,
    direction: str,
    rules: list[RuleIn],
    default_income_category_id: int | None = None,
) -> tuple[int | None, int | None]:
    """Trả về (category_id, rule_id). Khoản vào không khớp luật nào -> mặc định Thu nhập."""
    rule = match_rule(description, direction, rules)
    if rule is not None:
        return rule.category_id, rule.id
    if direction == "in":
        return default_income_category_id, None
    return None, None


# Từ chung chung trong nội dung chuyển khoản — không dùng làm luật
_GENERIC_TOKENS = {
    "chuyen", "tien", "khoan", "thanh", "toan", "ck", "ct", "tt", "tu", "toi", "den", "nap", "rut", "ibft", "ft",
    "mbvcb", "qr", "gd", "nd", "so", "tk", "tai", "cho", "va", "qua", "napas", "trace", "ref", "vcb", "mb", "mbbank",
    "vietcombank", "ngan", "hang", "ma", "giao", "dich", "noi", "dung",
}


def suggest_rule(description: str | None) -> str | None:
    """Cụm từ gợi ý cho "nhớ luật": lấy từ chính nội dung nên chắc chắn khớp lại giao dịch này."""
    norm = normalize_for_match(description)
    runs: list[list[str]] = []
    cur: list[str] = []
    for tok in norm.split():
        if any(ch.isdigit() for ch in tok) or tok in _GENERIC_TOKENS:
            if cur:
                runs.append(cur)
            cur = []
        else:
            cur.append(tok)
    if cur:
        runs.append(cur)
    runs = [r for r in runs if len(" ".join(r)) >= 3]
    if not runs:
        return None
    best = max(runs, key=len)
    phrase = " ".join(best[:3])
    return phrase if contains_phrase(norm, phrase) else None
