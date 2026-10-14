"""Outbox: gửi các Alert chưa gửi lên Telegram, có retry + backoff. Một task duy nhất chạy trong lifespan."""

from __future__ import annotations

import asyncio
import contextlib
import json
import logging
from dataclasses import dataclass
from datetime import timedelta

from sqlmodel import select

from app import clock
from app.db import session_scope, write_lock
from app.models import Alert
from app.notify.telegram import TelegramClient, TelegramError, render_html

log = logging.getLogger(__name__)

MAX_ATTEMPTS = 8
MAX_AGE = timedelta(hours=24)
IDLE_WAIT_SECONDS = 15.0

_wake = asyncio.Event()


def wake_outbox() -> None:
    _wake.set()


@dataclass
class _Job:
    alert_id: int
    edit: bool
    message_id: int | None
    text: str
    markup: dict | None
    loud: bool
    attempts: int


def _backoff(attempts: int) -> timedelta:
    return timedelta(seconds=min(5 * 2 ** attempts, 600))


def _due_jobs(limit: int = 20) -> list[_Job]:
    now = clock.now()
    with session_scope() as s:
        rows = s.exec(
            select(Alert).where(
                Alert.deliver_telegram == True,  # noqa: E712
                Alert.cancelled == False,  # noqa: E712
                (Alert.telegram_sent == False) | (Alert.needs_edit == True),  # noqa: E712
                Alert.created_at >= now - MAX_AGE,
                Alert.telegram_attempts < MAX_ATTEMPTS,
            ).order_by(Alert.id).limit(limit * 3)
        ).all()
        jobs: list[_Job] = []
        for a in rows:
            if a.send_after is not None and a.send_after > now:
                continue
            if a.telegram_next_attempt_at is not None and a.telegram_next_attempt_at > now:
                continue
            edit = a.telegram_sent and a.needs_edit and a.telegram_message_id is not None
            if a.telegram_sent and not edit:
                continue
            markup = json.loads(a.reply_markup_json) if a.reply_markup_json else None
            jobs.append(_Job(a.id, edit, a.telegram_message_id, render_html(a.title, a.message), markup, a.loud,
                             a.telegram_attempts))
            if len(jobs) >= limit:
                break
        return jobs


async def drain_once(client: TelegramClient, chat_id: int) -> int:
    """Gửi một lượt. Trả về số tin gửi/sửa thành công."""
    async with write_lock:
        jobs = _due_jobs()
    if not jobs:
        return 0
    results: list[tuple[_Job, int | None, TelegramError | None]] = []
    for job in jobs:
        try:
            if job.edit:
                await client.edit_message_text(chat_id, job.message_id, job.text, reply_markup=job.markup)
                results.append((job, job.message_id, None))
            else:
                mid = await client.send_message(chat_id, job.text, reply_markup=job.markup,
                                                disable_notification=not job.loud)
                results.append((job, mid, None))
        except TelegramError as exc:
            if job.edit and exc.not_modified:
                results.append((job, job.message_id, None))
            else:
                results.append((job, None, exc))
                if exc.retry_after:
                    break  # bị giới hạn tốc độ: dừng lượt này
    ok = 0
    async with write_lock:
        now = clock.now()
        with session_scope() as s:
            for job, mid, err in results:
                a = s.get(Alert, job.alert_id)
                if a is None:
                    continue
                if err is None:
                    ok += 1
                    a.telegram_sent = True
                    a.needs_edit = False
                    a.telegram_message_id = mid
                    a.telegram_last_error = None
                    a.telegram_next_attempt_at = None
                else:
                    a.telegram_attempts += 1
                    a.telegram_last_error = err.description[:300]
                    if job.edit and err.permanent:
                        a.needs_edit = False  # tin quá cũ/không sửa được: bỏ qua việc sửa
                    elif err.permanent:
                        a.telegram_attempts = MAX_ATTEMPTS
                    else:
                        wait = timedelta(seconds=err.retry_after) if err.retry_after else _backoff(a.telegram_attempts)
                        a.telegram_next_attempt_at = now + wait
                    log.warning("Gửi Telegram thất bại (alert %s): %s", a.id, err.description)
                s.add(a)
            s.commit()
    return ok


async def run_outbox(client: TelegramClient, chat_id: int, stop: asyncio.Event) -> None:
    while not stop.is_set():
        _wake.clear()  # xoá trước khi drain để không lỡ tín hiệu đến trong lúc gửi
        try:
            sent = await drain_once(client, chat_id)
            if sent:
                continue  # còn việc thì làm tiếp ngay
        except Exception:  # noqa: BLE001
            log.exception("Lỗi outbox Telegram")
        with contextlib.suppress(TimeoutError):
            await asyncio.wait_for(_wake.wait(), timeout=IDLE_WAIT_SECONDS)
