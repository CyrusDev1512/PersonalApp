"""Telegram bot (long-polling): lệnh /status, /goals, /uncat và nút bấm phân loại giao dịch."""

from __future__ import annotations

import asyncio
import json
import logging

from sqlmodel import Session, select

from app import clock
from app.config import Settings
from app.db import kv_get, kv_set, session_scope, write_lock
from app.engine.messages import compose_digest
from app.models import Account, Alert, Transaction
from app.money import format_vnd
from app.notify.outbox import wake_outbox
from app.notify.telegram import TelegramClient, TelegramError, render_html
from app.services import tx_actions
from app.services.notify import category_buttons, reevaluate_and_notify, tx_info
from app.services.summary import build_evaluation, uncategorized_count

log = logging.getLogger(__name__)

OFFSET_KEY = "telegram_offset"
HELP = (
    "Mình theo dõi biến động số dư và cảnh báo khi số dư xuống gần mức cần giữ cho các mục tiêu.\n"
    "/status — tình hình hiện tại\n/goals — mục tiêu tháng này\n/uncat — giao dịch chưa phân loại\n"
    "Bấm các nút dưới mỗi tin biến động để phân loại khoản chi."
)


def _authorized(settings: Settings, chat_id: int | None, from_id: int | None) -> bool:
    return settings.telegram_chat_id is not None and chat_id == settings.telegram_chat_id \
        and from_id == settings.telegram_chat_id


def status_text(session: Session) -> tuple[str, str]:
    ev = build_evaluation(session)
    _title, body = compose_digest(ev, uncategorized_count(session, ev.month), [])
    return "📊 Tình hình hiện tại", body


def goals_text(session: Session) -> str:
    ev = build_evaluation(session)
    if not ev.goals:
        return "Chưa có mục tiêu nào trong tháng này. Mở app và bấm \"Thêm mục tiêu\"."
    lines = []
    for g in ev.goals:
        kind = "Quỹ giữ" if g.type == "reserve" else "Ngân sách"
        lines.append(f"{g.category_icon or '🎯'} {g.name} ({kind}) — {format_vnd(g.spent)}/{format_vnd(g.amount)}"
                     f" ({g.usage_pct:.0f}%), còn cần giữ {format_vnd(g.remaining)}")
    lines.append(f"Mức sàn: {format_vnd(ev.floor)}")
    return "\n".join(lines)


def uncat_items(session: Session, limit: int = 5) -> list[tuple[str, dict]]:
    ev = build_evaluation(session)
    start, end = clock.month_bounds_utc(ev.month)
    included = [a.id for a in session.exec(select(Account).where(Account.include_in_total == True)).all()]  # noqa: E712
    txs = session.exec(
        select(Transaction).where(
            Transaction.status == "active", Transaction.direction == "out",
            Transaction.category_id == None, Transaction.goal_id == None,  # noqa: E711
            Transaction.pair_id == None, Transaction.account_id.in_(included),  # noqa: E711
            Transaction.bank_time >= start, Transaction.bank_time < end,
        ).order_by(Transaction.bank_time.desc()).limit(limit)
    ).all()
    out = []
    for tx in txs:
        info = tx_info(session, tx)
        when = clock.to_ict(tx.bank_time).strftime("%H:%M %d/%m")
        text = render_html(f"−{format_vnd(tx.amount)} · {info.account_label} · {when}", tx.description or "")
        rows = category_buttons(session, tx.id)
        rows.append([{"text": "↔️ Chuyển nội bộ", "callback_data": f"t:{tx.id}"}])
        out.append((text, {"inline_keyboard": rows}))
    return out


async def handle_message(client: TelegramClient, settings: Settings, msg: dict) -> None:
    chat_id = (msg.get("chat") or {}).get("id")
    from_id = (msg.get("from") or {}).get("id")
    text = (msg.get("text") or "").strip()
    command = text.split()[0].split("@")[0].lower() if text.startswith("/") else ""
    if settings.telegram_chat_id is None:
        if command == "/start" and chat_id is not None:
            note = f"{chat_id}\nĐặt TELEGRAM_CHAT_ID={chat_id} trong file .env rồi khởi động lại server."
            await client.send_message(chat_id, render_html("Chat ID của bạn", note))
        return
    if not _authorized(settings, chat_id, from_id):
        return  # bỏ qua mọi chat khác
    async with write_lock:
        with session_scope() as s:
            if command in ("/start", "/help", ""):
                replies = [(render_html("Xin chào 👋", HELP), None)]
            elif command == "/status":
                replies = [(render_html(*status_text(s)), None)]
            elif command == "/goals":
                replies = [(render_html("🎯 Mục tiêu tháng này", goals_text(s)), None)]
            elif command == "/uncat":
                items = uncat_items(s)
                replies = items or [(render_html("🏷️ Giao dịch chưa phân loại", "Không còn giao dịch nào 🎉"), None)]
            else:
                replies = [(render_html("Lệnh không hỗ trợ", HELP), None)]
            s.commit()
    for text_html, markup in replies:
        await client.send_message(chat_id, text_html, reply_markup=markup, disable_notification=True)


def _apply_callback(s: Session, data: str, message_id: int | None) -> str:
    """Thực hiện hành động của nút bấm. Trả về câu trả lời ngắn."""
    parts = data.split(":")
    kind = parts[0]
    if kind == "a" and len(parts) == 3:
        acc = s.get(Account, int(parts[1]))
        if acc is None:
            return "Không tìm thấy tài khoản"
        include = parts[2] == "1"
        acc.confirmed = True
        acc.include_in_total = include
        s.add(acc)
        alert = s.exec(select(Alert).where(Alert.telegram_message_id == message_id)).first() if message_id else None
        if alert is not None:
            alert.message += "\n→ " + ("Đã tính vào tổng số dư ✅" if include else "Không tính vào tổng 🚫")
            alert.reply_markup_json = None
            alert.needs_edit = True
            s.add(alert)
        reevaluate_and_notify(s, reason="api_account")
        return "Đã cập nhật tài khoản"

    tx = s.get(Transaction, int(parts[1])) if len(parts) >= 2 and parts[1].isdigit() else None
    if tx is None:
        return "Không tìm thấy giao dịch"
    if kind == "c" and len(parts) == 3:
        tx_actions.set_category(s, tx, int(parts[2]))
        reply = "Đã phân loại"
    elif kind == "t":
        paired = tx_actions.mark_internal(s, tx)
        reply = "Đã ghép chuyển nội bộ" if paired else "Đã đánh dấu chuyển nội bộ"
    elif kind == "n":
        goal = tx_actions.assign_next_month(s, tx)
        reply = f"Đã tính cho {goal.name} tháng {goal.month[5:]}/{goal.month[:4]}"
    elif kind == "r":
        alert = s.exec(select(Alert).where(Alert.kind == "tx", Alert.transaction_id == tx.id)
                       .order_by(Alert.id.desc())).first()
        if alert is not None:
            rows = category_buttons(s, tx.id)
            rows.append([{"text": "↔️ Chuyển nội bộ", "callback_data": f"t:{tx.id}"}])
            alert.reply_markup_json = json.dumps({"inline_keyboard": rows}, ensure_ascii=False)
            alert.needs_edit = alert.telegram_message_id is not None
            s.add(alert)
        return "Chọn danh mục mới"
    else:
        return "Nút không hợp lệ"
    s.flush()
    reevaluate_and_notify(s, reason="recategorize", edit_tx=tx)
    return reply


async def handle_callback(client: TelegramClient, settings: Settings, cb: dict) -> None:
    from_id = (cb.get("from") or {}).get("id")
    msg = cb.get("message") or {}
    chat_id = (msg.get("chat") or {}).get("id")
    if not _authorized(settings, chat_id, from_id):
        return
    data = str(cb.get("data") or "")
    async with write_lock:
        with session_scope() as s:
            try:
                reply = _apply_callback(s, data, msg.get("message_id"))
                s.commit()
            except tx_actions.ActionError as exc:
                s.rollback()
                reply = str(exc)
            except (ValueError, IndexError):
                s.rollback()
                reply = "Nút không hợp lệ"
    wake_outbox()
    try:
        await client.answer_callback_query(cb["id"], reply)
    except TelegramError as exc:
        log.info("answerCallbackQuery lỗi: %s", exc.description)


async def handle_update(client: TelegramClient, settings: Settings, update: dict) -> None:
    if "callback_query" in update:
        await handle_callback(client, settings, update["callback_query"])
    elif "message" in update:
        await handle_message(client, settings, update["message"])


async def run_bot(client: TelegramClient, settings: Settings, stop: asyncio.Event) -> None:
    backoff = 1.0
    try:
        await client.delete_webhook()
        await client.set_my_commands()
    except TelegramError as exc:
        log.warning("Không khởi tạo được bot Telegram: %s", exc.description)
    with session_scope() as s:
        offset = kv_get(s, OFFSET_KEY)
    while not stop.is_set():
        try:
            updates = await client.get_updates(offset, timeout=30)
            backoff = 1.0
        except TelegramError as exc:
            wait = 30.0 if exc.status == 409 else min(backoff, 60.0)
            log.warning("getUpdates lỗi (%s), thử lại sau %.0fs", exc.description, wait)
            backoff = min(backoff * 2, 60.0)
            await asyncio.sleep(wait)
            continue
        for update in updates:
            offset = int(update["update_id"]) + 1
            try:
                await handle_update(client, settings, update)
            except Exception:  # noqa: BLE001
                log.exception("Lỗi xử lý update Telegram")
        if updates:
            async with write_lock:
                with session_scope() as s:
                    kv_set(s, OFFSET_KEY, offset)
                    s.commit()
