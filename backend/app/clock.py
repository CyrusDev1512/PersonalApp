"""Thời gian: lưu UTC, tính tháng theo giờ Việt Nam. `now()` có thể thay thế trong test."""

from __future__ import annotations

from collections.abc import Callable
from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

ICT = ZoneInfo("Asia/Ho_Chi_Minh")

_now_fn: Callable[[], datetime] | None = None


def now() -> datetime:
    """Thời điểm hiện tại (aware, UTC)."""
    if _now_fn is not None:
        return ensure_utc(_now_fn())
    return datetime.now(UTC)


def set_now(fn: Callable[[], datetime] | None) -> None:
    global _now_fn
    _now_fn = fn


def ensure_utc(dt: datetime) -> datetime:
    """Datetime naive được hiểu là UTC."""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt.astimezone(UTC)


def to_ict(dt: datetime) -> datetime:
    return ensure_utc(dt).astimezone(ICT)


def ict_naive_to_utc(dt: datetime) -> datetime:
    """Giờ ngân hàng (giờ VN, không có tz) -> UTC."""
    if dt.tzinfo is not None:
        return dt.astimezone(UTC)
    return dt.replace(tzinfo=ICT).astimezone(UTC)


def month_of(dt: datetime) -> str:
    return to_ict(dt).strftime("%Y-%m")


def current_month() -> str:
    return month_of(now())


def today_ict() -> date:
    return to_ict(now()).date()


def parse_month(month: str) -> tuple[int, int]:
    y, m = month.split("-")
    year, mon = int(y), int(m)
    if not (1 <= mon <= 12 and 2000 <= year <= 2100):
        raise ValueError(f"tháng không hợp lệ: {month}")
    return year, mon


def is_valid_month(month: str) -> bool:
    try:
        parse_month(month)
    except (ValueError, AttributeError):
        return False
    return len(month) == 7


def shift_month(month: str, delta: int) -> str:
    year, mon = parse_month(month)
    idx = year * 12 + (mon - 1) + delta
    return f"{idx // 12:04d}-{idx % 12 + 1:02d}"


def next_month(month: str) -> str:
    return shift_month(month, 1)


def prev_month(month: str) -> str:
    return shift_month(month, -1)


def month_bounds_utc(month: str) -> tuple[datetime, datetime]:
    """[đầu tháng, đầu tháng sau) theo giờ VN, trả về UTC."""
    year, mon = parse_month(month)
    start = datetime(year, mon, 1, tzinfo=ICT)
    ny, nm = parse_month(next_month(month))
    end = datetime(ny, nm, 1, tzinfo=ICT)
    return start.astimezone(UTC), end.astimezone(UTC)


def days_in_month(month: str) -> int:
    start, end = month_bounds_utc(month)
    return round((end - start) / timedelta(days=1))


def start_of_day_utc(d: date) -> datetime:
    return datetime.combine(d, time(0, 0), tzinfo=ICT).astimezone(UTC)


def iso_z(dt: datetime | None) -> str | None:
    """ISO-8601 UTC có hậu tố Z (định dạng thời gian của API)."""
    if dt is None:
        return None
    return ensure_utc(dt).strftime("%Y-%m-%dT%H:%M:%SZ")
