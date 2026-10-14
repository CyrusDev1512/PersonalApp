"""Danh mục và luật phân loại mặc định."""

from __future__ import annotations

from sqlmodel import Session, select

from app.models import Category, CategoryRule
from app.text import normalize_pattern

# (system_key, tên, kind, icon, thứ tự)
CATEGORIES = [
    ("food", "Ăn uống", "expense", "🍜", 10),
    ("rent", "Thuê trọ", "expense", "🏠", 20),
    ("transport", "Đi lại", "expense", "🛵", 30),
    ("shopping", "Mua sắm", "expense", "🛒", 40),
    ("bills", "Hoá đơn", "expense", "🧾", 50),
    ("savings", "Tiết kiệm", "expense", "🐷", 60),
    ("other", "Khác", "expense", "📦", 90),
    ("income", "Thu nhập", "income", "💰", 100),
    ("refund", "Hoàn tiền", "income", "↩️", 110),
    ("transfer", "Chuyển nội bộ", "transfer", "↔️", 120),
]

# Cụm từ (không dấu). Không dùng từ 3 chữ cái trơ trọi như "com", "pho", "bun" vì dễ khớp nhầm.
RULES: dict[str, list[tuple[str, str, int]]] = {
    "food": [
        (p, "out", 50)
        for p in [
            "grabfood", "grab food", "shopeefood", "shopee food", "baemin", "befood", "be food", "gofood",
            "highlands", "highland coffee", "phuc long", "the coffee house", "katinat", "starbucks", "cong caphe",
            "trung nguyen", "kfc", "lotteria", "jollibee", "mcdonald", "pizza hut", "domino", "texas chicken",
            "com tam", "com ga", "com van phong", "com trua", "com chay", "pho bo", "pho ga", "bun bo", "bun cha",
            "bun dau", "bun rieu", "banh mi", "hu tieu", "tra sua", "an trua", "an toi", "an sang", "tien an",
            "an uong", "nha hang", "quan an", "quan lau", "lau nuong", "mixue", "gong cha", "bach hoa xanh", "winmart", "coopmart",
        ]
    ],
    "rent": [
        (p, "out", 40)
        for p in [
            "tien tro", "tien nha", "tien phong", "phong tro", "thue phong", "thue nha", "tien thue nha",
            "tien thue phong", "nha tro",
        ]
    ],
    "transport": [
        (p, "out", 60)
        for p in ["grab bike", "grabbike", "grab car", "grabcar", "xanh sm", "be bike", "gojek", "xang", "petrolimex",
                  "gui xe", "vetc", "epass"]
    ],
    "bills": [
        (p, "out", 60)
        for p in ["tien dien", "tien nuoc", "evn", "internet", "fpt telecom", "viettel", "vnpt", "mobifone",
                  "vinaphone", "nap tien dien thoai", "netflix", "spotify", "youtube premium", "icloud"]
    ],
    "shopping": [
        (p, "out", 70)
        for p in ["shopee", "lazada", "tiki", "tiktok shop", "uniqlo", "dien may xanh", "the gioi di dong", "cellphones"]
    ],
    "income": [(p, "in", 50) for p in ["luong", "tra luong", "tien thuong", "salary", "payroll", "bonus"]],
    "refund": [(p, "in", 40) for p in ["hoan tien", "refund", "hoan tra"]],
}


def seed_defaults(session: Session) -> None:
    existing = {c.system_key: c for c in session.exec(select(Category)).all() if c.system_key}
    for key, name, kind, icon, order in CATEGORIES:
        if key in existing:
            continue
        cat = Category(name=name, kind=kind, icon=icon, sort_order=order, system_key=key)
        session.add(cat)
        session.flush()
        for pattern, direction, priority in RULES.get(key, []):
            session.add(CategoryRule(category_id=cat.id, pattern=normalize_pattern(pattern), direction=direction,
                                     priority=priority, origin="seed"))
    session.commit()


def category_by_key(session: Session, key: str) -> Category | None:
    return session.exec(select(Category).where(Category.system_key == key)).first()
