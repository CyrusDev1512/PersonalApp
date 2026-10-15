"""Client Telegram Bot API tối giản (httpx)."""

from __future__ import annotations

import html
import logging
from typing import Any

import httpx

log = logging.getLogger(__name__)

MAX_TEXT = 4000


class TelegramError(Exception):
    def __init__(self, description: str, status: int | None = None, retry_after: int | None = None):
        super().__init__(description)
        self.description = description
        self.status = status
        self.retry_after = retry_after

    @property
    def not_modified(self) -> bool:
        return "message is not modified" in self.description.lower()

    @property
    def permanent(self) -> bool:
        """Lỗi không nên thử lại (sai chat id, tin quá cũ để sửa, ...)."""
        d = self.description.lower()
        return self.status in (400, 403) and not self.not_modified and "too many requests" not in d


def render_html(title: str, message: str) -> str:
    text = f"<b>{html.escape(title)}</b>\n{html.escape(message)}"
    if len(text) > MAX_TEXT:
        text = text[: MAX_TEXT - 1] + "…"
    return text


class TelegramClient:
    def __init__(self, token: str, client: httpx.AsyncClient | None = None,
                 base_url: str = "https://api.telegram.org"):
        if not token:
            raise ValueError("Thiếu TELEGRAM_BOT_TOKEN")
        self._token = token
        self._client = client or httpx.AsyncClient(timeout=httpx.Timeout(15.0, read=45.0))
        self._base = base_url.rstrip("/")

    async def aclose(self) -> None:
        await self._client.aclose()

    async def call(self, method: str, payload: dict[str, Any] | None = None, *, timeout: float | None = None) -> Any:
        url = f"{self._base}/bot{self._token}/{method}"
        try:
            kwargs: dict[str, Any] = {"json": payload or {}}
            if timeout is not None:
                kwargs["timeout"] = timeout
            resp = await self._client.post(url, **kwargs)
        except httpx.HTTPError as exc:
            # Không log URL (có chứa token)
            raise TelegramError(f"network: {type(exc).__name__}") from None
        try:
            data = resp.json()
        except ValueError:
            raise TelegramError(f"HTTP {resp.status_code}", resp.status_code) from None
        if not data.get("ok"):
            params = data.get("parameters") or {}
            raise TelegramError(str(data.get("description") or f"HTTP {resp.status_code}"), resp.status_code,
                                params.get("retry_after"))
        return data.get("result")

    async def send_message(self, chat_id: int, text: str, *, reply_markup: dict | None = None,
                           disable_notification: bool = False) -> int:
        payload: dict[str, Any] = {"chat_id": chat_id, "text": text, "parse_mode": "HTML",
                                   "disable_web_page_preview": True, "disable_notification": disable_notification}
        if reply_markup:
            payload["reply_markup"] = reply_markup
        result = await self.call("sendMessage", payload)
        return int(result["message_id"])

    async def edit_message_text(self, chat_id: int, message_id: int, text: str, *,
                                reply_markup: dict | None = None) -> None:
        payload: dict[str, Any] = {"chat_id": chat_id, "message_id": message_id, "text": text, "parse_mode": "HTML",
                                   "disable_web_page_preview": True,
                                   "reply_markup": reply_markup or {"inline_keyboard": []}}
        await self.call("editMessageText", payload)

    async def answer_callback_query(self, callback_query_id: str, text: str | None = None) -> None:
        payload: dict[str, Any] = {"callback_query_id": callback_query_id}
        if text:
            payload["text"] = text[:190]
        await self.call("answerCallbackQuery", payload)

    async def get_updates(self, offset: int | None, timeout: int = 30) -> list[dict]:
        payload: dict[str, Any] = {"timeout": timeout, "allowed_updates": ["message", "callback_query"]}
        if offset is not None:
            payload["offset"] = offset
        return list(await self.call("getUpdates", payload, timeout=timeout + 10) or [])

    async def delete_webhook(self) -> None:
        await self.call("deleteWebhook", {"drop_pending_updates": False})

    async def set_my_commands(self) -> None:
        await self.call("setMyCommands", {"commands": [
            {"command": "status", "description": "Tình hình số dư và mục tiêu"},
            {"command": "goals", "description": "Danh sách mục tiêu tháng này"},
            {"command": "uncat", "description": "Giao dịch chưa phân loại"},
            {"command": "help", "description": "Hướng dẫn"},
        ]})
