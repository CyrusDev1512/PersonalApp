"""Cấu hình test: DB SQLite in-memory, giờ cố định, không chạy job nền."""

from __future__ import annotations

import os
from datetime import UTC, datetime

import pytest

TEST_TOKEN = "t" * 40
os.environ.update({
    "APP_TOKEN": TEST_TOKEN,
    "DATABASE_URL": "sqlite://",
    "ENABLE_BACKGROUND": "false",
    "SEPAY_API_KEY": "sepay-test-key-0123456789abcdef",
    "SEPAY_HMAC_SECRET": "",
    "CASSO_SECURE_KEY": "",
    "TELEGRAM_BOT_TOKEN": "",
    "TELEGRAM_CHAT_ID": "",
    "IMAP_USER": "",
    "IMAP_PASSWORD": "",
    "OWNER_NAME": "NGUYEN VAN AN",
    "INTERNAL_TRANSFER_HINTS": "",
})

from app import clock  # noqa: E402
from app.config import get_settings  # noqa: E402

get_settings.cache_clear()

# 14/10/2026 10:00 giờ VN = 03:00 UTC
DEFAULT_NOW = datetime(2026, 10, 14, 3, 0, tzinfo=UTC)


class FakeClock:
    def __init__(self, now: datetime):
        self.value = now

    def __call__(self) -> datetime:
        return self.value

    def advance(self, **kw) -> None:
        from datetime import timedelta

        self.value = self.value + timedelta(**kw)


@pytest.fixture
def fake_now():
    fc = FakeClock(DEFAULT_NOW)
    clock.set_now(fc)
    yield fc
    clock.set_now(None)


@pytest.fixture
def engine(fake_now):
    from app.db import init_engine

    get_settings.cache_clear()
    return init_engine("sqlite://")


@pytest.fixture
def session(engine):
    from sqlmodel import Session

    with Session(engine, expire_on_commit=False) as s:
        yield s


@pytest.fixture
def client(engine):
    """TestClient dùng engine in-memory của test (không chạy lifespan để giữ nguyên DB)."""
    from fastapi.testclient import TestClient

    from app.main import create_app

    app = create_app()
    app.router.lifespan_context = _noop_lifespan
    with TestClient(app) as c:
        c.headers["Authorization"] = f"Bearer {TEST_TOKEN}"
        yield c


from contextlib import asynccontextmanager  # noqa: E402


@asynccontextmanager
async def _noop_lifespan(app):
    yield


VCB_NO = "0123456789"


@pytest.fixture
def setup(session, fake_now):
    """TK VCB (số dư 10tr đầu ngày), mục tiêu tháng 10: trọ 3tr, ăn 5tr, đã chi ăn 2tr."""
    from datetime import timedelta

    from app.models import Account, Goal, Transaction
    from app.seed import category_by_key
    from app.services.balance import recompute_balance

    food = category_by_key(session, "food")
    rent = category_by_key(session, "rent")
    start_of_day = clock.start_of_day_utc(clock.today_ict())
    vcb = Account(bank="VCB", account_number=VCB_NO, last4=VCB_NO[-4:], name="VCB chính",
                  manual_balance=10_000_000, manual_balance_at=start_of_day)
    session.add(vcb)
    session.add(Goal(name="Tiền trọ", type="reserve", amount=3_000_000, category_id=rent.id, month="2026-10"))
    session.add(Goal(name="Tiền ăn", type="budget", amount=5_000_000, category_id=food.id, month="2026-10"))
    session.flush()
    session.add(Transaction(account_id=vcb.id, direction="out", amount=2_000_000, category_id=food.id,
                            categorized_by="user", bank_time=start_of_day - timedelta(days=3), evaluated=True))
    session.commit()
    recompute_balance(session, vcb)
    session.commit()
    return {"vcb": vcb, "food": food, "rent": rent}
