"""Sức khoẻ các nguồn dữ liệu (dùng cho bản tin sáng và cảnh báo trong app)."""

from __future__ import annotations

from datetime import datetime, timedelta

from sqlmodel import Session, func, select

from app import clock
from app.config import Settings
from app.db import kv_get
from app.models import IngestEvent

WEBHOOK_SILENCE_WARN = timedelta(hours=48)


def parse_iso(value: str) -> datetime:
    return clock.ensure_utc(datetime.fromisoformat(value.replace("Z", "+00:00")))


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
        if last is None or parse_iso(last) < now - WEBHOOK_SILENCE_WARN:
            lines.append(f"🔌 Chưa nhận webhook {source.upper()} trong 48 giờ qua — kiểm tra kết nối.")
    bad = s.exec(
        select(func.count(IngestEvent.id)).where(
            IngestEvent.received_at >= now - timedelta(hours=24), IngestEvent.status.in_(["error", "unparsed"])
        )
    ).one()
    if bad:
        lines.append(f"⚙️ {bad} biến động trong 24 giờ qua không đọc được — xem trong app.")
    return lines
