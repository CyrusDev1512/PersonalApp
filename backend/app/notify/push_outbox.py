"""Kênh thông báo đẩy (FCM): rải cảnh báo quan trọng tới từng thiết bị rồi gửi, có retry + backoff."""

from __future__ import annotations

import asyncio
import contextlib
import logging
from dataclasses import dataclass
from datetime import timedelta

from sqlmodel import Session, func, select

from app import clock
from app.db import kv_get, kv_set, session_scope, write_lock
from app.models import Alert, Device, PushDelivery
from app.notify.fcm import FcmClient, FcmError, build_message
from app.notify.outbox import push_wake

log = logging.getLogger(__name__)

CURSOR_KEY = "push:cursor"
MAX_ATTEMPTS = 8
MAX_AGE = timedelta(hours=24)
IDLE_WAIT_SECONDS = 15.0
TEST_KIND = "push_test"


def _backoff(attempts: int) -> timedelta:
    return timedelta(seconds=min(5 * 2 ** attempts, 600))


def should_push(alert: Alert) -> bool:
    """Chỉ đẩy cảnh báo quan trọng: loại được Telegram gửi có chuông (và thông báo thử)."""
    if alert.cancelled:
        return False
    if alert.kind == TEST_KIND:
        return True
    return alert.loud and alert.deliver_telegram and not alert.read


def fan_out(s: Session) -> int:
    """Tạo PushDelivery cho các alert mới. Lần đầu bật: bắt đầu từ alert mới nhất (không đẩy lịch sử)."""
    now = clock.now()
    cursor = kv_get(s, CURSOR_KEY)
    if cursor is None:
        cursor = s.exec(select(func.max(Alert.id))).one() or 0
        kv_set(s, CURSOR_KEY, cursor)
        return 0
    devices = s.exec(select(Device)).all()
    created = 0
    for alert in s.exec(select(Alert).where(Alert.id > cursor).order_by(Alert.id)).all():
        if alert.send_after is not None and alert.send_after > now:
            break  # còn đang hoãn: xét lại lần sau (không bỏ qua)
        cursor = alert.id
        if alert.created_at < now - MAX_AGE or not should_push(alert):
            continue
        for d in devices:
            s.add(PushDelivery(alert_id=alert.id, device_id=d.id))
            created += 1
    kv_set(s, CURSOR_KEY, cursor)
    return created


@dataclass
class _Job:
    delivery_id: int
    device_id: int
    token: str
    message: dict


def _payload(alert: Alert, token: str) -> dict:
    tag = f"tx-{alert.transaction_id}" if alert.transaction_id else f"alert-{alert.id}"
    data = {"alert_id": alert.id, "kind": alert.kind, "level": alert.level, "transaction_id": alert.transaction_id,
            "goal_id": alert.goal_id, "month": alert.month}
    return build_message(token, title=alert.title, body=alert.message, data=data, tag=tag)


def _due_jobs(s: Session, limit: int = 20) -> list[_Job]:
    now = clock.now()
    rows = s.exec(
        select(PushDelivery).where(PushDelivery.status == "pending").order_by(PushDelivery.id).limit(limit * 3)
    ).all()
    jobs: list[_Job] = []
    for d in rows:
        if d.next_attempt_at is not None and d.next_attempt_at > now:
            continue
        alert = s.get(Alert, d.alert_id)
        device = s.get(Device, d.device_id)
        if alert is None or device is None or not should_push(alert) or alert.created_at < now - MAX_AGE:
            d.status = "dropped"
            s.add(d)
            continue
        jobs.append(_Job(d.id, device.id, device.token, _payload(alert, device.token)))
        if len(jobs) >= limit:
            break
    return jobs


async def drain_push_once(fcm: FcmClient) -> int:
    async with write_lock:
        with session_scope() as s:
            fan_out(s)
            jobs = _due_jobs(s)
            s.commit()
    if not jobs:
        return 0
    results: list[tuple[_Job, FcmError | None]] = []
    dead_devices: set[int] = set()
    for job in jobs:
        if job.device_id in dead_devices:
            results.append((job, FcmError("thiết bị không còn nhận được thông báo", dead_token=True)))
            continue
        try:
            await fcm.send(job.message)
            results.append((job, None))
        except FcmError as exc:
            results.append((job, exc))
            if exc.dead_token:
                dead_devices.add(job.device_id)
            if exc.status == 429:
                break  # bị giới hạn tốc độ: dừng lượt này
    ok = 0
    async with write_lock:
        now = clock.now()
        with session_scope() as s:
            config_error: str | None = None
            any_ok = False
            for job, err in results:
                d = s.get(PushDelivery, job.delivery_id)
                if d is None:
                    continue
                device = s.get(Device, job.device_id)
                if err is None:
                    ok += 1
                    any_ok = True
                    d.status, d.sent_at, d.last_error = "sent", now, None
                    if device is not None and device.last_error:
                        device.last_error = None
                        s.add(device)
                    s.add(d)
                    continue
                d.attempts += 1
                d.last_error = err.message[:300]
                if err.config_error:
                    config_error = err.message
                elif device is not None and not err.dead_token:
                    device.last_error = err.message[:300]
                    s.add(device)
                if err.dead_token:
                    _drop_device(s, job.device_id, err.message)
                    d.status = "dropped"
                elif err.retryable and d.attempts < MAX_ATTEMPTS:
                    wait = timedelta(seconds=err.retry_after) if err.retry_after else _backoff(d.attempts)
                    d.next_attempt_at = now + wait
                else:
                    d.status = "failed"
                log.warning("Gửi push thất bại (delivery %s): %s", d.id, err.message)
                s.add(d)
            # Lỗi cấu hình (khoá, project, API chưa bật) hiện cho người dùng qua GET /api/devices
            if config_error is not None:
                kv_set(s, "health:push", {"error": f"Gửi thông báo đẩy lỗi: {config_error}"[:300],
                                          "at": clock.iso_z(now)})
            elif any_ok and (kv_get(s, "health:push", {}) or {}).get("error"):
                kv_set(s, "health:push", {"error": None, "at": clock.iso_z(now)})
            s.commit()
    return ok


def _drop_device(s: Session, device_id: int, reason: str) -> None:
    device = s.get(Device, device_id)
    if device is not None:
        s.delete(device)
    for other in s.exec(select(PushDelivery).where(PushDelivery.device_id == device_id,
                                                   PushDelivery.status == "pending")).all():
        other.status, other.last_error = "dropped", "thiết bị không còn nhận được thông báo"
        s.add(other)
    log.info("Xoá thiết bị %s: %s", device_id, reason)


async def run_push(fcm: FcmClient, stop: asyncio.Event) -> None:
    while not stop.is_set():
        push_wake.clear()
        try:
            if await drain_push_once(fcm):
                continue
        except Exception:  # noqa: BLE001
            log.exception("Lỗi kênh thông báo đẩy")
        with contextlib.suppress(TimeoutError):
            await asyncio.wait_for(push_wake.wait(), timeout=IDLE_WAIT_SECONDS)
