"""Job nền: tick (khoản chờ ghép cặp / email chờ webhook), đọc email, bản tin sáng, chuyển tháng."""

from __future__ import annotations

import asyncio
import base64
import contextlib
import logging
from collections.abc import Callable
from datetime import timedelta
from typing import Any

from sqlmodel import Session, func, select

from app import clock
from app.config import Settings, get_settings
from app.db import kv_get, kv_set, session_scope, write_lock
from app.engine.messages import compose_digest
from app.ingest.service import mark_event, process_event, store_event, tick
from app.models import Alert, IngestEvent
from app.notify.outbox import wake_outbox
from app.services.goals import ensure_month_goals
from app.services.notify import add_info_alert, reevaluate_and_notify
from app.services.summary import build_evaluation, uncategorized_count

log = logging.getLogger(__name__)

EMAIL_FAILING_ALERT_AFTER = timedelta(minutes=30)
WEBHOOK_SILENCE_WARN = timedelta(hours=48)

_poll_lock = asyncio.Lock()


async def run_tick() -> None:
    async with write_lock:
        with session_scope() as s:
            changed = tick(s)
    if changed:
        wake_outbox()


async def run_rollover() -> None:
    async with write_lock:
        with session_scope() as s:
            created = ensure_month_goals(s, clock.current_month())
            reevaluate_and_notify(s, reason="rollover")
            s.commit()
    log.info("Chuyển tháng: tạo %s mục tiêu", created)
    wake_outbox()


def health_lines(s: Session, cfg: Settings) -> list[str]:
    now = clock.now()
    lines: list[str] = []
    email = kv_get(s, "health:email", {}) or {}
    if cfg.email_enabled and email.get("failing_since"):
        lines.append(f"📭 Đọc email ngân hàng đang lỗi: {email.get('last_error') or '?'}")
    for source, enabled in (("sepay", cfg.sepay_enabled), ("casso", cfg.casso_enabled)):
        if not enabled:
            continue
        last = (kv_get(s, f"health:{source}", {}) or {}).get("last_event_at")
        if last is None or clock.ensure_utc(_parse_iso(last)) < now - WEBHOOK_SILENCE_WARN:
            lines.append(f"🔌 Chưa nhận webhook {source.upper()} trong 48 giờ qua — kiểm tra kết nối.")
    bad = s.exec(
        select(func.count(IngestEvent.id)).where(
            IngestEvent.received_at >= now - timedelta(hours=24), IngestEvent.status.in_(["error", "unparsed"])
        )
    ).one()
    if bad:
        lines.append(f"⚙️ {bad} biến động trong 24 giờ qua không đọc được — xem trong app.")
    return lines


def _parse_iso(value: str):
    from datetime import datetime

    return datetime.fromisoformat(value.replace("Z", "+00:00"))


async def run_digest() -> None:
    cfg = get_settings()
    async with write_lock:
        with session_scope() as s:
            ev = build_evaluation(s)
            title, message = compose_digest(ev, uncategorized_count(s, ev.month), health_lines(s, cfg))
            danger = ev.level in ("WARNING", "DANGER")
            s.add(Alert(kind="digest", level=ev.level, month=ev.month, title=title, message=message, loud=danger,
                        read=not danger))
            s.commit()
    wake_outbox()


# ---- email ------------------------------------------------------------------------------------------------


def _record_email_success(s: Session) -> None:
    h = kv_get(s, "health:email", {}) or {}
    h.update({"last_success_at": clock.now().isoformat(), "last_error": None, "failing_since": None,
              "alerted": False})
    kv_set(s, "health:email", h)


def _record_email_failure(s: Session, error: str) -> None:
    now = clock.now()
    h = kv_get(s, "health:email", {}) or {}
    h["last_error"] = error[:300]
    h["last_error_at"] = now.isoformat()
    h.setdefault("failing_since", None)
    if not h.get("failing_since"):
        h["failing_since"] = now.isoformat()
    failing_since = clock.ensure_utc(_parse_iso(h["failing_since"]))
    if now - failing_since >= EMAIL_FAILING_ALERT_AFTER and not h.get("alerted"):
        add_info_alert(s, "📭 Không đọc được email ngân hàng",
                       f"Đã lỗi hơn 30 phút: {error[:200]}. Kiểm tra IMAP_USER / app password.", kind="health",
                       loud=True)
        h["alerted"] = True
    kv_set(s, "health:email", h)


async def poll_email_once(settings: Settings | None = None, connect: Callable[[Settings], Any] | None = None) -> dict:
    """Đọc email mới qua IMAP rồi ingest. Lần chạy đầu nhập im lặng các email từ đầu tháng."""
    from app.ingest.email_parse import parse_email_message
    from app.ingest.imap_client import ImapState, fetch_new_messages, make_imap_connection

    cfg = settings or get_settings()
    if not cfg.email_enabled:
        return {"status": "disabled"}
    if _poll_lock.locked():
        return {"status": "busy"}
    async with _poll_lock:
        async with write_lock:
            with session_scope() as s:
                stored = kv_get(s, "imap_state", {}) or {}
        state = ImapState(uidvalidity=stored.get("uidvalidity"), last_uid=stored.get("last_uid"))
        first_run = state.last_uid is None
        since = clock.today_ict().replace(day=1) if first_run else None
        domains = sorted({d for ds in cfg.bank_domains.values() for d in ds})

        def _fetch():
            conn = (connect or make_imap_connection)(cfg)
            try:
                return fetch_new_messages(conn, cfg.imap_folder, state, domains, since)
            finally:
                with contextlib.suppress(Exception):
                    conn.logout()

        try:
            messages, new_state = await asyncio.to_thread(_fetch)
        except Exception as exc:  # noqa: BLE001
            log.warning("Đọc email lỗi: %s", type(exc).__name__)
            async with write_lock:
                with session_scope() as s:
                    _record_email_failure(s, f"{type(exc).__name__}: {exc}")
                    s.commit()
            wake_outbox()
            return {"status": "error", "error": type(exc).__name__}

        imported = 0
        for msg in messages:
            async with write_lock:
                with session_scope() as s:
                    res = parse_email_message(msg.raw, cfg.bank_domains, cfg.email_require_dkim, clock.now())
                    payload = "" if res.status == "ignored" else "base64:" + base64.b64encode(msg.raw).decode()
                    event = store_event(s, "email", {"subject": (res.subject or "")[:200]}, payload,
                                        external_id=res.message_id)
                    if res.status == "parsed" and res.txs:
                        txs = res.txs
                        process_event(s, event, lambda txs=txs: txs, notify=not first_run)
                        imported += 1
                    else:
                        mark_event(s, event.id, res.status if res.status != "parsed" else "unparsed", res.reason)

        async with write_lock:
            with session_scope() as s:
                kv_set(s, "imap_state", {"uidvalidity": new_state.uidvalidity, "last_uid": new_state.last_uid})
                _record_email_success(s)
                if first_run and imported:
                    reevaluate_and_notify(s, reason="backfill")
                    add_info_alert(s, "📥 Đã nhập giao dịch từ email",
                                   f"Đã đọc {imported} email biến động số dư từ đầu tháng. "
                                   "Mở app để phân loại các khoản chi.")
                s.commit()
        wake_outbox()
        return {"status": "ok", "fetched": len(messages), "imported": imported, "first_run": first_run}


def decode_email_payload(payload_text: str) -> bytes | None:
    if not payload_text.startswith("base64:"):
        return None
    try:
        return base64.b64decode(payload_text[len("base64:"):])
    except ValueError:
        return None
