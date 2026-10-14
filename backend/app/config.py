"""Cấu hình đọc từ biến môi trường / file .env."""

from __future__ import annotations

from functools import lru_cache

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

MIN_SECRET_LEN = 32


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Bearer token cho app Flutter (bắt buộc, >= 32 ký tự).
    app_token: str = Field(min_length=MIN_SECRET_LEN)
    database_url: str = "sqlite:///./data/app.db"
    debug: bool = False
    enable_background: bool = True
    max_body_bytes: int = 64 * 1024

    # Webhook SePay: API key (header "Authorization: Apikey <key>") và/hoặc HMAC secret.
    sepay_api_key: str = ""
    sepay_hmac_secret: str = ""
    # Webhook Casso v2: "Khoá bảo mật" dùng để ký HMAC-SHA512.
    casso_secure_key: str = ""

    # Telegram
    telegram_bot_token: str = ""
    telegram_chat_id: int | None = None

    # Email (IMAP)
    imap_host: str = "imap.gmail.com"
    imap_port: int = 993
    imap_user: str = ""
    imap_password: str = ""
    imap_folder: str = "INBOX"
    email_poll_seconds: int = 120
    # "VCB:vietcombank.com.vn,MB:mbbank.com.vn" — domain người gửi/DKIM hợp lệ cho từng ngân hàng.
    email_bank_domains: str = "VCB:vietcombank.com.vn,MB:mbbank.com.vn"
    email_require_dkim: bool = True

    # Tên chủ tài khoản (không dấu cũng được) — giúp nhận ra chuyển khoản nội bộ giữa các TK của mình.
    owner_name: str = ""
    # Các chuỗi khác trong nội dung chuyển khoản cho biết đó là chuyển nội bộ (phân cách bằng dấu phẩy).
    internal_transfer_hints: str = ""

    # Giá trị mặc định cho cài đặt runtime (có thể đổi trong app).
    warning_percent: int = 10
    warning_min_amount: int = 500_000

    @field_validator("telegram_chat_id", mode="before")
    @classmethod
    def _empty_chat_id(cls, v):
        return None if v in ("", None) else v

    @property
    def bank_domains(self) -> dict[str, list[str]]:
        out: dict[str, list[str]] = {}
        for part in self.email_bank_domains.split(","):
            if ":" not in part:
                continue
            bank, domain = part.split(":", 1)
            bank, domain = bank.strip().upper(), domain.strip().lower()
            if bank and domain:
                out.setdefault(bank, []).append(domain)
        return out

    @property
    def hint_list(self) -> list[str]:
        return [h.strip() for h in self.internal_transfer_hints.split(",") if h.strip()]

    @property
    def sepay_enabled(self) -> bool:
        return bool(self.sepay_api_key or self.sepay_hmac_secret)

    @property
    def casso_enabled(self) -> bool:
        return bool(self.casso_secure_key)

    @property
    def telegram_enabled(self) -> bool:
        return bool(self.telegram_bot_token)

    @property
    def email_enabled(self) -> bool:
        return bool(self.imap_user and self.imap_password)


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore[call-arg]
