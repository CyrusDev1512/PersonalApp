"""Webhook SePay / Casso, danh sách & xử lý lại ingest event, kích hoạt đọc email."""

from __future__ import annotations

import json
import logging
from collections.abc import Callable

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlmodel import select

from app import clock
from app.api import serialize as ser
from app.api.deps import require_token
from app.config import get_settings
from app.db import kv_get, kv_set, session_scope, write_lock
from app.ingest.schema import AuthError, NormalizedTx, ParseError
from app.ingest.service import mark_event, process_event, store_event
from app.models import IngestEvent
from app.notify.outbox import wake_outbox

log = logging.getLogger(__name__)

webhooks = APIRouter(prefix="/webhooks")
events_router = APIRouter(prefix="/api", dependencies=[Depends(require_token)])


async def _read_body(request: Request) -> bytes:
    limit = get_settings().max_body_bytes
    length = request.headers.get("content-length")
    if length and length.isdigit() and int(length) > limit:
        raise HTTPException(status.HTTP_413_CONTENT_TOO_LARGE, "Payload quá lớn")
    body = await request.body()
    if len(body) > limit:
        raise HTTPException(status.HTTP_413_CONTENT_TOO_LARGE, "Payload quá lớn")
    return body


def _count_rejected(source: str) -> None:
    with session_scope() as s:
        key = f"rejected:{source}"
        data = kv_get(s, key, {}) or {}
        data["count"] = int(data.get("count", 0)) + 1
        data["last_at"] = clock.now().isoformat()
        kv_set(s, key, data)
        s.commit()


def _json(raw: bytes) -> dict | None:
    try:
        data = json.loads(raw)
    except ValueError:
        return None
    return data if isinstance(data, dict) else None


async def _handle(source: str, request: Request, raw: bytes, parse: Callable[[dict], list[NormalizedTx]],
                  external_id: str | None) -> dict:
    payload = _json(raw)
    async with write_lock:
        try:
            with session_scope() as s:
                event = store_event(s, source, dict(request.headers), raw.decode("utf-8", "replace"), external_id)
                kv_set(s, f"health:{source}", {"last_event_at": ser.iso(clock.now())})
                s.commit()
                event_id = event.id
        except Exception:  # noqa: BLE001 - không lưu được raw: trả 500 để bên gửi thử lại
            log.exception("Không lưu được webhook %s", source)
            raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "storage error") from None

        def _parse() -> list[NormalizedTx]:
            if payload is None:
                raise ParseError("body không phải JSON object")
            return parse(payload)

        with session_scope() as s:
            process_event(s, s.get(IngestEvent, event_id), _parse)
    wake_outbox()
    return {"success": True}


@webhooks.post("/sepay")
async def sepay_webhook(request: Request) -> dict:
    from app.ingest.sepay import parse_sepay, verify_sepay

    cfg = get_settings()
    if not cfg.sepay_enabled:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not Found")
    raw = await _read_body(request)
    try:
        verify_sepay(request.headers, raw, cfg, clock.now())
    except AuthError:
        async with write_lock:
            _count_rejected("sepay")
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Unauthorized") from None
    payload = _json(raw) or {}
    ext = str(payload["id"]) if payload.get("id") is not None else None
    return await _handle("sepay", request, raw, lambda p: [parse_sepay(p)], ext)


@webhooks.post("/casso")
async def casso_webhook(request: Request) -> dict:
    from app.ingest.casso import parse_casso, verify_casso

    cfg = get_settings()
    if not cfg.casso_enabled:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not Found")
    raw = await _read_body(request)
    try:
        verify_casso(request.headers, raw, cfg)
    except AuthError:
        async with write_lock:
            _count_rejected("casso")
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Unauthorized") from None
    received = clock.now()
    return await _handle("casso", request, raw, lambda p: parse_casso(p, received), None)


# ---- ingest events ----------------------------------------------------------------------------------------


def _event_dict(e: IngestEvent) -> dict:
    return {"id": e.id, "source": e.source, "external_id": e.external_id, "received_at": ser.iso(e.received_at),
            "status": e.status, "error": (e.error or "")[:500] or None, "transaction_id": e.transaction_id,
            "payload_preview": None if e.source == "email" else e.payload_text[:500]}


@events_router.get("/ingest-events")
def list_events(
    event_status: str | None = Query(default=None, alias="status"),
    limit: int = Query(default=50, ge=1, le=500),
) -> list[dict]:
    with session_scope() as s:
        q = select(IngestEvent)
        if event_status:
            q = q.where(IngestEvent.status == event_status)
        return [_event_dict(e) for e in s.exec(q.order_by(IngestEvent.id.desc()).limit(limit))]


@events_router.post("/ingest-events/{event_id}/reprocess")
async def reprocess_event(event_id: int) -> dict:
    from app.jobs import decode_email_payload

    cfg = get_settings()
    async with write_lock:
        with session_scope() as s:
            event = s.get(IngestEvent, event_id)
            if event is None:
                raise HTTPException(status.HTTP_404_NOT_FOUND, "Không tìm thấy event")
            if event.status not in ("unparsed", "error"):
                raise HTTPException(status.HTTP_400_BAD_REQUEST, "Chỉ xử lý lại event lỗi / không đọc được")
            if event.source == "sepay":
                from app.ingest.sepay import parse_sepay

                payload = _json(event.payload_text.encode())

                def parse() -> list[NormalizedTx]:
                    if payload is None:
                        raise ParseError("body không phải JSON object")
                    return [parse_sepay(payload)]
            elif event.source == "casso":
                from app.ingest.casso import parse_casso

                payload = _json(event.payload_text.encode())
                received = event.received_at

                def parse() -> list[NormalizedTx]:
                    if payload is None:
                        raise ParseError("body không phải JSON object")
                    return parse_casso(payload, received)
            elif event.source == "email":
                from app.ingest.email_parse import parse_email_message

                raw = decode_email_payload(event.payload_text)
                if raw is None:
                    raise HTTPException(status.HTTP_400_BAD_REQUEST, "Không còn nội dung email gốc")
                res = parse_email_message(raw, cfg.bank_domains, cfg.email_require_dkim, event.received_at)
                if res.status != "parsed" or not res.txs:
                    mark_event(s, event.id, res.status if res.status != "parsed" else "unparsed", res.reason)
                    return _event_dict(s.get(IngestEvent, event.id))
                txs = res.txs

                def parse() -> list[NormalizedTx]:
                    return txs
            else:
                raise HTTPException(status.HTTP_400_BAD_REQUEST, "Nguồn không hỗ trợ xử lý lại")
            result = process_event(s, event, parse)
            data = _event_dict(result)
    wake_outbox()
    return data


@events_router.post("/jobs/poll-email")
async def trigger_poll_email() -> dict:
    from app.jobs import poll_email_once

    return await poll_email_once()
