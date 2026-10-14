"""Outbox Telegram (retry) và bot (lệnh, nút bấm) với httpx.MockTransport."""

from __future__ import annotations

import asyncio
import json

import httpx
from sqlmodel import select

from app import clock
from app.config import get_settings
from app.ingest.schema import NormalizedTx
from app.ingest.service import ingest_tx
from app.models import Account, Alert, Goal, Transaction
from app.notify import bot
from app.notify.outbox import drain_once
from app.notify.telegram import TelegramClient
from app.seed import category_by_key
from app.services.balance import recompute_balance

CHAT = 4242


class FakeTelegram:
    def __init__(self, fail_first: int = 0):
        self.calls: list[tuple[str, dict]] = []
        self.fail_first = fail_first
        self.next_id = 100

    def handler(self, request: httpx.Request) -> httpx.Response:
        method = request.url.path.rsplit("/", 1)[-1]
        body = json.loads(request.content or b"{}")
        self.calls.append((method, body))
        if self.fail_first > 0:
            self.fail_first -= 1
            return httpx.Response(502, json={"ok": False, "description": "Bad Gateway"})
        if method == "sendMessage":
            self.next_id += 1
            return httpx.Response(200, json={"ok": True, "result": {"message_id": self.next_id}})
        return httpx.Response(200, json={"ok": True, "result": True})

    def client(self) -> TelegramClient:
        return TelegramClient("123:ABC", client=httpx.AsyncClient(transport=httpx.MockTransport(self.handler)))

    def sent(self, method: str = "sendMessage") -> list[dict]:
        return [b for m, b in self.calls if m == method]


def _setup(session):
    food = category_by_key(session, "food")
    rent = category_by_key(session, "rent")
    acc = Account(bank="VCB", account_number="0123456789", last4="6789", name="VCB",
                  manual_balance=10_000_000, manual_balance_at=clock.start_of_day_utc(clock.today_ict()))
    session.add(acc)
    session.add(Goal(name="Tiền trọ", type="reserve", amount=3_000_000, category_id=rent.id, month="2026-10"))
    session.add(Goal(name="Tiền ăn", type="budget", amount=5_000_000, category_id=food.id, month="2026-10"))
    session.commit()
    recompute_balance(session, acc)
    session.commit()
    return acc, food


def _withdraw(session, ext="1", amount=3_500_000, balance=6_500_000, desc="RUT TIEN ATM"):
    return ingest_tx(session, NormalizedTx(
        source="sepay", external_id=ext, direction="out", amount=amount, bank_time=clock.now(), bank="VCB",
        account_number="0123456789", description=desc, balance_after=balance), event_id=None)


def test_outbox_retries_after_failure_and_sends_once(session, fake_now):
    _setup(session)
    _withdraw(session, balance=4_500_000)  # DANGER
    fake = FakeTelegram(fail_first=1)
    tg = fake.client()

    sent = asyncio.run(drain_once(tg, CHAT))
    assert sent == 0
    a = session.exec(select(Alert).where(Alert.kind == "tx")).one()
    session.refresh(a)
    assert not a.telegram_sent and a.telegram_attempts == 1 and a.telegram_next_attempt_at is not None

    # chưa tới giờ thử lại
    assert asyncio.run(drain_once(tg, CHAT)) == 0
    fake_now.advance(seconds=30)
    assert asyncio.run(drain_once(tg, CHAT)) == 1
    session.refresh(a)
    assert a.telegram_sent and a.telegram_message_id == 101
    assert asyncio.run(drain_once(tg, CHAT)) == 0
    msgs = fake.sent()
    assert len(msgs) == 2  # 1 lần lỗi + 1 lần thành công
    assert msgs[-1]["disable_notification"] is False
    assert "inline_keyboard" in msgs[-1]["reply_markup"]
    assert "<b>" in msgs[-1]["text"]


def test_quiet_tx_is_silent(session, fake_now):
    _setup(session)
    _withdraw(session, amount=50_000, balance=9_950_000, desc="tra sua")
    fake = FakeTelegram()
    asyncio.run(drain_once(fake.client(), CHAT))
    assert fake.sent()[0]["disable_notification"] is True


def test_callback_categorize_edits_message(session, fake_now, monkeypatch):
    acc, food = _setup(session)
    out = _withdraw(session)
    fake = FakeTelegram()
    tg = fake.client()
    asyncio.run(drain_once(tg, CHAT))
    monkeypatch.setenv("TELEGRAM_CHAT_ID", str(CHAT))
    get_settings.cache_clear()
    settings = get_settings()
    update = {"update_id": 1, "callback_query": {
        "id": "cb1", "from": {"id": CHAT}, "data": f"c:{out.transaction_id}:{food.id}",
        "message": {"message_id": 101, "chat": {"id": CHAT}}}}
    asyncio.run(bot.handle_update(tg, settings, update))
    tx = session.get(Transaction, out.transaction_id)
    session.refresh(tx)
    assert tx.category_id == food.id and tx.categorized_by == "user"
    assert fake.sent("answerCallbackQuery")[0]["text"] == "Đã phân loại"
    asyncio.run(drain_once(tg, CHAT))
    edits = fake.sent("editMessageText")
    assert len(edits) == 1 and "Ăn uống" in edits[0]["text"] and edits[0]["message_id"] == 101
    get_settings.cache_clear()


def test_bot_ignores_strangers_and_bootstraps_chat_id(session, fake_now, monkeypatch):
    _setup(session)
    fake = FakeTelegram()
    tg = fake.client()
    monkeypatch.setenv("TELEGRAM_CHAT_ID", "")
    get_settings.cache_clear()
    asyncio.run(bot.handle_update(tg, get_settings(), {"update_id": 1, "message": {
        "text": "/start", "chat": {"id": 777}, "from": {"id": 777}}}))
    assert "777" in fake.sent()[0]["text"]
    monkeypatch.setenv("TELEGRAM_CHAT_ID", str(CHAT))
    get_settings.cache_clear()
    asyncio.run(bot.handle_update(tg, get_settings(), {"update_id": 2, "message": {
        "text": "/status", "chat": {"id": 777}, "from": {"id": 777}}}))
    assert len(fake.sent()) == 1  # người lạ bị bỏ qua
    asyncio.run(bot.handle_update(tg, get_settings(), {"update_id": 3, "message": {
        "text": "/status", "chat": {"id": CHAT}, "from": {"id": CHAT}}}))
    assert "Mức sàn" in fake.sent()[-1]["text"]
    get_settings.cache_clear()


def test_next_month_button(session, fake_now, monkeypatch):
    _setup(session)
    out = _withdraw(session, amount=3_000_000, balance=7_000_000, desc="chuyen tien tro T11")
    fake = FakeTelegram()
    tg = fake.client()
    monkeypatch.setenv("TELEGRAM_CHAT_ID", str(CHAT))
    get_settings.cache_clear()
    update = {"update_id": 1, "callback_query": {
        "id": "cb", "from": {"id": CHAT}, "data": f"n:{out.transaction_id}",
        "message": {"message_id": 5, "chat": {"id": CHAT}}}}
    asyncio.run(bot.handle_update(tg, get_settings(), update))
    tx = session.get(Transaction, out.transaction_id)
    session.refresh(tx)
    goal = session.get(Goal, tx.goal_id)
    assert goal.month == "2026-11" and goal.name == "Tiền trọ"
    assert "tháng 11/2026" in fake.sent("answerCallbackQuery")[0]["text"]
    get_settings.cache_clear()
