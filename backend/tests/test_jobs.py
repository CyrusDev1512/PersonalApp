"""Job nền: đọc email (IMAP giả lập), bản tin sáng, chuyển tháng."""

from __future__ import annotations

import asyncio
from datetime import datetime, timedelta
from email.utils import format_datetime

import pytest
from sqlmodel import select

from app import clock, jobs
from app.config import get_settings
from app.ingest import imap_client
from app.ingest.imap_client import FetchedMessage, ImapState
from app.models import Account, Alert, Goal, IngestEvent, Transaction
from app.seed import category_by_key
from app.services.balance import recompute_balance


def vcb_email(msg_id: str, amount: str, balance: str, when: str, content: str, dkim: bool = True) -> bytes:
    auth = ("dkim=pass header.i=@info.vietcombank.com.vn header.s=s1; dmarc=pass header.from=vietcombank.com.vn"
            if dkim else "dkim=fail header.d=evil.example; dmarc=fail header.from=vietcombank.com.vn")
    sent = datetime.strptime(when, "%d/%m/%Y %H:%M:%S").replace(tzinfo=clock.ICT) + timedelta(seconds=30)
    return f"""From: "Vietcombank" <VCBDigibank@info.vietcombank.com.vn>
To: me@gmail.com
Subject: Thong bao giao dich
Message-ID: <{msg_id}>
Date: {format_datetime(sent)}
Authentication-Results: mx.google.com; {auth}
Content-Type: text/plain; charset=utf-8

Tài khoản: 0123456789
Số tiền: {amount} VND
Số dư: {balance} VND
Thời gian: {when}
Nội dung: {content}
""".encode()


class DummyConn:
    def logout(self):
        return ("BYE", [])


@pytest.fixture
def email_env(monkeypatch, session):
    monkeypatch.setenv("IMAP_USER", "me@gmail.com")
    monkeypatch.setenv("IMAP_PASSWORD", "app-password")
    get_settings.cache_clear()
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
    yield
    get_settings.cache_clear()


def _patch_fetch(monkeypatch, batches):
    calls = []

    def fake_fetch(conn, folder, state, from_domains, first_run_since, max_messages=200):
        calls.append({"state": state, "since": first_run_since, "domains": from_domains})
        msgs = batches.pop(0) if batches else []
        last = max([m.uid for m in msgs], default=state.last_uid or 0)
        return msgs, ImapState(uidvalidity=1, last_uid=last)

    monkeypatch.setattr(imap_client, "fetch_new_messages", fake_fetch)
    return calls


def test_first_run_backfills_silently_then_notifies_new(session, email_env, monkeypatch, fake_now):
    old = [FetchedMessage(uid=i, raw=vcb_email(f"old{i}@vcb", "-50,000", f"{10_000_000 - 50_000 * i:,}",
                                               f"0{i}/10/2026 12:00:00", "tra sua")) for i in range(1, 6)]
    new = [FetchedMessage(uid=10, raw=vcb_email("new@vcb", "-3,500,000", "6,250,000", "14/10/2026 10:00:00",
                                                "RUT TIEN ATM"))]
    calls = _patch_fetch(monkeypatch, [old, new])

    r1 = asyncio.run(jobs.poll_email_once(get_settings(), connect=lambda cfg: DummyConn()))
    assert r1["status"] == "ok" and r1["first_run"] and r1["imported"] == 5
    assert calls[0]["since"] == clock.today_ict().replace(day=1)
    assert "vietcombank.com.vn" in calls[0]["domains"]
    # backfill: không có tin cho từng giao dịch, chỉ 1 tin tổng hợp
    assert session.exec(select(Alert).where(Alert.kind == "tx")).all() == []
    assert len(session.exec(select(Alert).where(Alert.title.contains("Đã nhập"))).all()) == 1

    r2 = asyncio.run(jobs.poll_email_once(get_settings(), connect=lambda cfg: DummyConn()))
    assert r2["imported"] == 1 and not r2["first_run"]
    assert calls[1]["state"].last_uid == 5
    tx_alerts = session.exec(select(Alert).where(Alert.kind == "tx")).all()
    assert len(tx_alerts) == 1 and tx_alerts[0].loud


def test_forged_email_is_ignored(session, email_env, monkeypatch, fake_now):
    forged = [FetchedMessage(uid=1, raw=vcb_email("f@vcb", "+50,000,000", "60,000,000", "14/10/2026 09:00:00",
                                                  "luong", dkim=False))]
    _patch_fetch(monkeypatch, [forged])
    asyncio.run(jobs.poll_email_once(get_settings(), connect=lambda cfg: DummyConn()))
    assert session.exec(select(Transaction).where(Transaction.amount == 50_000_000)).first() is None
    ev = session.exec(select(IngestEvent).where(IngestEvent.source == "email")).one()
    assert ev.status == "ignored" and ev.payload_text == ""


def test_imap_failure_recorded_and_alerted_after_30_minutes(session, email_env, monkeypatch, fake_now):
    def boom(*a, **kw):
        raise OSError("connection refused")

    monkeypatch.setattr(imap_client, "fetch_new_messages", boom)
    r = asyncio.run(jobs.poll_email_once(get_settings(), connect=lambda cfg: DummyConn()))
    assert r["status"] == "error"
    assert session.exec(select(Alert).where(Alert.kind == "health")).first() is None
    fake_now.advance(minutes=31)
    asyncio.run(jobs.poll_email_once(get_settings(), connect=lambda cfg: DummyConn()))
    asyncio.run(jobs.poll_email_once(get_settings(), connect=lambda cfg: DummyConn()))
    assert len(session.exec(select(Alert).where(Alert.kind == "health")).all()) == 1


def test_disabled_without_credentials(session, fake_now):
    get_settings.cache_clear()
    assert asyncio.run(jobs.poll_email_once(get_settings()))["status"] == "disabled"


def test_digest_and_rollover(session, email_env, fake_now):
    asyncio.run(jobs.run_digest())
    digest = session.exec(select(Alert).where(Alert.kind == "digest")).one()
    assert "Mức sàn" in digest.message and "Tiền ăn" in digest.message
    fake_now.value = fake_now.value.replace(month=11, day=1, hour=0)
    asyncio.run(jobs.run_rollover())
    nov = session.exec(select(Goal).where(Goal.month == "2026-11")).all()
    assert {g.name for g in nov} == {"Tiền trọ", "Tiền ăn"}
    asyncio.run(jobs.run_rollover())
    assert len(session.exec(select(Goal).where(Goal.month == "2026-11")).all()) == 2
