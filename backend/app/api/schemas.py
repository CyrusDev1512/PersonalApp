"""Body request của API."""

from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator

from app import clock


class GoalCreate(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    type: Literal["reserve", "budget"]
    amount: int = Field(gt=0, le=100_000_000_000)
    category_id: int | None = None
    month: str | None = None
    repeat_monthly: bool = True
    opening_spent: int = Field(default=0, ge=0)

    @field_validator("month")
    @classmethod
    def _month(cls, v: str | None) -> str | None:
        if v is not None and not clock.is_valid_month(v):
            raise ValueError("month phải có dạng YYYY-MM")
        return v


class GoalUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=80)
    type: Literal["reserve", "budget"] | None = None
    amount: int | None = Field(default=None, gt=0, le=100_000_000_000)
    category_id: int | None = None
    repeat_monthly: bool | None = None
    opening_spent: int | None = Field(default=None, ge=0)


class CategoryCreate(BaseModel):
    name: str = Field(min_length=1, max_length=40)
    kind: Literal["expense", "income", "transfer"] = "expense"
    icon: str | None = Field(default=None, max_length=8)


class RuleCreate(BaseModel):
    pattern: str = Field(min_length=2, max_length=80)
    direction: Literal["out", "in", "any"] = "out"


class TxUpdate(BaseModel):
    category_id: int | None = None
    goal_id: int | None = None
    for_next_month: bool | None = None
    excluded: bool | None = None
    remember_rule: bool = False
    rule_pattern: str | None = Field(default=None, max_length=80)


class TxCreate(BaseModel):
    direction: Literal["in", "out"] = "out"
    amount: int = Field(gt=0, le=100_000_000_000)
    description: str = Field(default="", max_length=300)
    category_id: int | None = None
    bank_time: datetime | None = None
    account_id: int | None = None
    affects_balance: bool = False


class AccountCreate(BaseModel):
    bank: str = Field(min_length=1, max_length=16)
    name: str = Field(min_length=1, max_length=60)
    account_number: str | None = Field(default=None, max_length=32)
    include_in_total: bool = True
    balance: int | None = None


class AccountUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=60)
    account_number: str | None = Field(default=None, max_length=32)
    include_in_total: bool | None = None
    confirmed: bool | None = None
    balance: int | None = None


class SettingsUpdate(BaseModel):
    warning_percent: int | None = Field(default=None, ge=0, le=100)
    warning_min_amount: int | None = Field(default=None, ge=0, le=1_000_000_000)
    expected_income_amount: int | None = Field(default=None, ge=0, le=100_000_000_000)
    expected_income_day: int | None = Field(default=None, ge=0, le=31)
    notify_every_tx: bool | None = None


class DeviceRegister(BaseModel):
    token: str = Field(min_length=10, max_length=4096)
    platform: Literal["android", "ios"] = "android"
    app_version: str | None = Field(default=None, max_length=32)
