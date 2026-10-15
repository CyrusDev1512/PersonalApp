"""Phân loại theo luật từ khoá (không khớp chuỗi con, phân biệt chiều tiền)."""

from __future__ import annotations

import pytest
from sqlmodel import select

from app.engine.categorize import RuleIn, categorize
from app.models import Category, CategoryRule
from app.text import normalize_for_match


@pytest.fixture
def rules(session):
    return [RuleIn(id=r.id, category_id=r.category_id, pattern=r.pattern, direction=r.direction,
                   priority=r.priority, origin=r.origin) for r in session.exec(select(CategoryRule))]


@pytest.fixture
def cats(session):
    return {c.system_key: c.id for c in session.exec(select(Category))}


@pytest.mark.parametrize("text,direction,expected", [
    ("GRABFOOD*Com Tam Sai Gon", "out", "food"),
    ("ShopeeFood don hang 123", "out", "food"),
    ("Thanh toan HIGHLANDS COFFEE", "out", "food"),
    ("Chuyển tiền phòng tháng 11", "out", "rent"),
    ("NGUYEN VAN AN chuyen tien tro T10", "out", "rent"),
    ("Thanh toan tien dien EVN thang 10", "out", "bills"),
    ("SHOPEE thanh toan don hang", "out", "shopping"),
    ("CT TNHH ABC COMPANY tra luong T10", "in", "income"),
    ("Hoan tien don hang Shopee", "in", "refund"),
])
def test_matches(rules, cats, text, direction, expected):
    cat_id, _ = categorize(text, direction, rules, cats["income"])
    assert cat_id == cats[expected]


@pytest.mark.parametrize("text", [
    "APPLE.COM/BILL",
    "CIRCLE K THANH PHO HCM",
    "chuyen tien nhanh 247",
    "Mua iPhone tai Thanh pho Thu Duc",
    "NGUYEN VAN BUN chuyen khoan",
])
def test_no_false_positive_for_outflows(rules, cats, text):
    cat_id, _ = categorize(text, "out", rules, cats["income"])
    assert cat_id is None


def test_incoming_food_keyword_is_not_food(rules, cats):
    # khoản vào có chữ "com tam" vẫn là thu nhập mặc định, không phải hoàn tiền ăn uống
    cat_id, _ = categorize("Ban chuyen tien com tam", "in", rules, cats["income"])
    assert cat_id == cats["income"]


def test_user_rule_wins(session, cats):
    rules = [
        RuleIn(id=1, category_id=cats["shopping"], pattern="shopee", direction="out", priority=70),
        RuleIn(id=2, category_id=cats["food"], pattern="shopee", direction="out", priority=10, origin="user"),
    ]
    assert categorize("SHOPEE 123", "out", rules)[0] == cats["food"]


def test_normalize():
    assert normalize_for_match("APPLE.COM/BILL") == ""
    assert normalize_for_match("Cơm Tấm Đặc Biệt") == "com tam dac biet"
