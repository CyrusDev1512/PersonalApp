"""Cài đặt người dùng chỉnh được trong app (lưu ở bảng KV)."""

from __future__ import annotations

from dataclasses import asdict, dataclass

from sqlmodel import Session

from app.config import get_settings
from app.db import kv_get, kv_set
from app.engine.evaluator import EvalSettings

KEY = "settings"


@dataclass
class RuntimeSettings:
    warning_percent: int = 10
    warning_min_amount: int = 500_000
    expected_income_amount: int = 0
    expected_income_day: int = 0
    notify_every_tx: bool = True

    def eval_settings(self) -> EvalSettings:
        return EvalSettings(
            warning_percent=self.warning_percent,
            warning_min_amount=self.warning_min_amount,
            expected_income_amount=self.expected_income_amount,
            expected_income_day=self.expected_income_day,
        )

    def to_dict(self) -> dict:
        return asdict(self)


def load(session: Session) -> RuntimeSettings:
    cfg = get_settings()
    base = RuntimeSettings(warning_percent=cfg.warning_percent, warning_min_amount=cfg.warning_min_amount)
    stored = kv_get(session, KEY, {}) or {}
    for k, v in stored.items():
        if hasattr(base, k):
            setattr(base, k, v)
    return base


def save(session: Session, values: dict) -> RuntimeSettings:
    current = load(session)
    for k, v in values.items():
        if hasattr(current, k) and v is not None:
            setattr(current, k, v)
    kv_set(session, KEY, current.to_dict())
    return current
