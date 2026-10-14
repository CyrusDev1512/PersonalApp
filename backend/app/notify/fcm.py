"""Client Firebase Cloud Messaging HTTP v1 tối giản (httpx + JWT service account, không cần firebase-admin)."""

from __future__ import annotations

import asyncio
import json
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import httpx
import jwt

from app.config import Settings

SCOPE = "https://www.googleapis.com/auth/firebase.messaging"
DEFAULT_TOKEN_URI = "https://oauth2.googleapis.com/token"
TOKEN_REFRESH_MARGIN = 300  # làm mới access token trước khi hết hạn 5 phút

# Lỗi cho biết token thiết bị không còn dùng được -> xoá thiết bị
DEAD_TOKEN_CODES = {"UNREGISTERED", "SENDER_ID_MISMATCH"}


class FcmConfigError(Exception):
    """Service account thiếu/sai."""


class FcmError(Exception):
    def __init__(self, message: str, *, status: int | None = None, code: str | None = None,
                 retry_after: int | None = None, dead_token: bool = False):
        super().__init__(message)
        self.message = message
        self.status = status
        self.code = code
        self.retry_after = retry_after
        self.dead_token = dead_token

    @property
    def retryable(self) -> bool:
        return self.status is None or self.status == 429 or self.status >= 500


@dataclass
class ServiceAccount:
    client_email: str
    private_key: str
    private_key_id: str | None
    project_id: str
    token_uri: str = DEFAULT_TOKEN_URI

    @classmethod
    def from_dict(cls, data: dict) -> ServiceAccount:
        try:
            return cls(client_email=data["client_email"], private_key=data["private_key"],
                       private_key_id=data.get("private_key_id"), project_id=data.get("project_id", ""),
                       token_uri=data.get("token_uri") or DEFAULT_TOKEN_URI)
        except (KeyError, TypeError) as exc:
            raise FcmConfigError(f"Service account thiếu trường {exc}") from None

    @classmethod
    def load(cls, settings: Settings) -> ServiceAccount:
        if settings.fcm_service_account_json:
            raw = settings.fcm_service_account_json
        elif settings.fcm_service_account_file:
            try:
                raw = Path(settings.fcm_service_account_file).read_text(encoding="utf-8")
            except OSError as exc:
                raise FcmConfigError(f"Không đọc được file service account: {exc.strerror}") from None
        else:
            raise FcmConfigError("Chưa cấu hình FCM")
        try:
            data = json.loads(raw)
        except ValueError:
            raise FcmConfigError("Service account không phải JSON hợp lệ") from None
        return cls.from_dict(data)


def _parse_error(resp: httpx.Response) -> FcmError:
    status = resp.status_code
    retry_after = resp.headers.get("retry-after")
    retry = int(retry_after) if retry_after and retry_after.isdigit() else None
    try:
        err = resp.json().get("error") or {}
    except ValueError:
        err = {}
    message = str(err.get("message") or f"HTTP {status}")
    code = err.get("status")
    dead = False
    for detail in err.get("details") or []:
        if not isinstance(detail, dict):
            continue
        if detail.get("errorCode"):
            code = detail["errorCode"]
        for violation in detail.get("fieldViolations") or []:
            if isinstance(violation, dict) and str(violation.get("field", "")).startswith("message.token"):
                dead = True
    dead = dead or code in DEAD_TOKEN_CODES
    return FcmError(message[:300], status=status, code=code, retry_after=retry, dead_token=dead)


class FcmClient:
    def __init__(self, sa: ServiceAccount, project_id: str | None = None, client: httpx.AsyncClient | None = None):
        self.sa = sa
        self.project_id = project_id or sa.project_id
        if not self.project_id:
            raise FcmConfigError("Thiếu FCM_PROJECT_ID")
        self._client = client or httpx.AsyncClient(timeout=httpx.Timeout(15.0))
        self._token: str | None = None
        self._token_exp = 0.0
        self._lock = asyncio.Lock()

    async def aclose(self) -> None:
        await self._client.aclose()

    def _assertion(self, now: float) -> str:
        claims = {"iss": self.sa.client_email, "scope": SCOPE, "aud": self.sa.token_uri, "iat": int(now),
                  "exp": int(now) + 3600}
        headers = {"kid": self.sa.private_key_id} if self.sa.private_key_id else None
        return jwt.encode(claims, self.sa.private_key, algorithm="RS256", headers=headers)

    async def access_token(self, *, force: bool = False) -> str:
        async with self._lock:
            now = time.time()
            if not force and self._token and now < self._token_exp - TOKEN_REFRESH_MARGIN:
                return self._token
            try:
                resp = await self._client.post(self.sa.token_uri, data={
                    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer", "assertion": self._assertion(now)})
            except httpx.HTTPError as exc:
                raise FcmError(f"network: {type(exc).__name__}") from None
            if resp.status_code != 200:
                raise FcmError(f"OAuth token lỗi HTTP {resp.status_code}", status=resp.status_code)
            data = resp.json()
            self._token = data["access_token"]
            self._token_exp = now + int(data.get("expires_in", 3600))
            return self._token

    async def send(self, message: dict[str, Any]) -> str:
        """Gửi một message (dict theo FCM v1). Trả về message name. Lỗi -> FcmError."""
        url = f"https://fcm.googleapis.com/v1/projects/{self.project_id}/messages:send"
        for attempt in range(2):
            token = await self.access_token(force=attempt > 0)
            try:
                resp = await self._client.post(url, json={"message": message},
                                               headers={"Authorization": f"Bearer {token}"})
            except httpx.HTTPError as exc:
                raise FcmError(f"network: {type(exc).__name__}") from None
            if resp.status_code == 401 and attempt == 0:
                continue  # access token hết hạn sớm: lấy token mới rồi thử lại một lần
            if resp.status_code == 200:
                return str(resp.json().get("name", ""))
            raise _parse_error(resp)
        raise FcmError("Không xác thực được với FCM", status=401)


def build_message(token: str, *, title: str, body: str, data: dict[str, str], tag: str) -> dict[str, Any]:
    return {
        "token": token,
        "notification": {"title": title[:200], "body": body[:1000]},
        "data": {k: "" if v is None else str(v) for k, v in data.items()},
        "android": {"priority": "HIGH", "ttl": "86400s",
                    "notification": {"channel_id": "alerts", "tag": tag}},
        "apns": {"headers": {"apns-priority": "10"}},
    }
