"""Đọc email mới qua IMAP — chỉ đọc (`SELECT ... readonly`, `BODY.PEEK[]`), không bao giờ đánh dấu đã đọc.

Trạng thái lưu giữa các lần poll: `UIDVALIDITY` + UID cuối đã lấy. UID luôn được lọc `uid > last_uid` trong code vì
`UID SEARCH UID n:*` trả về thư cuối cùng ngay cả khi n lớn hơn UID lớn nhất.

Lỗi kết nối/giao thức không bị nuốt: để caller (email poller) ghi `last_error` và thử lại lần sau.
"""

from __future__ import annotations

import imaplib
import logging
import re
from collections.abc import Iterator, Sequence
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import date
from typing import Any

from app.config import Settings
from app.ingest.parsers.base import normalize_domain

logger = logging.getLogger(__name__)

IMAP_TIMEOUT_SECONDS = 30
DEFAULT_MAX_MESSAGES = 200
# Tên tháng tiếng Anh cố định theo RFC 3501 (không phụ thuộc locale).
_MONTHS = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
_DOMAIN_OK = re.compile(r"[a-z0-9](?:[a-z0-9.\-]*[a-z0-9])?")
_ATOM_OK = re.compile(r"[A-Za-z0-9_./\-\[\]]+")


@dataclass
class ImapState:
    uidvalidity: int | None = None
    last_uid: int | None = None


@dataclass
class FetchedMessage:
    uid: int
    raw: bytes


class ImapError(Exception):
    """Máy chủ IMAP trả NO/BAD cho một lệnh bắt buộc (SELECT, SEARCH)."""


# ---------------------------------------------------------------------------
# Kết nối
# ---------------------------------------------------------------------------


def _safe_logout(conn: Any) -> None:
    try:
        conn.logout()
    except Exception:  # dọn dẹp: lỗi gốc (nếu có) mới là lỗi cần báo
        logger.debug("IMAP logout lỗi", exc_info=True)


def make_imap_connection(settings: Settings) -> imaplib.IMAP4_SSL:
    """Mở kết nối IMAP over SSL và đăng nhập. Đăng nhập lỗi → đóng kết nối rồi raise lại."""
    conn = imaplib.IMAP4_SSL(settings.imap_host, settings.imap_port, timeout=IMAP_TIMEOUT_SECONDS)
    try:
        conn.login(settings.imap_user, settings.imap_password)
    except BaseException:
        _safe_logout(conn)
        raise
    return conn


@contextmanager
def imap_session(settings: Settings) -> Iterator[imaplib.IMAP4_SSL]:
    """`with imap_session(settings) as conn: ...` — luôn logout khi xong (kể cả khi lỗi)."""
    conn = make_imap_connection(settings)
    try:
        yield conn
    finally:
        _safe_logout(conn)


# ---------------------------------------------------------------------------
# Tiện ích phân tích phản hồi (máy chủ/thư viện có thể trả bytes hoặc str)
# ---------------------------------------------------------------------------


def _to_str(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes | bytearray | memoryview):
        return bytes(value).decode("utf-8", errors="replace")
    return str(value)


def _flatten(data: Any) -> list[str]:
    items = data if isinstance(data, list | tuple) else [data]
    out: list[str] = []
    for item in items:
        if isinstance(item, tuple):
            out.extend(_to_str(x) for x in item if not isinstance(x, bytes | bytearray) or len(x) < 4096)
        else:
            out.append(_to_str(item))
    return out


def _first_int(data: Any) -> int | None:
    for text in _flatten(data):
        m = re.search(r"\d+", text)
        if m:
            return int(m.group())
    return None


def _response_int(conn: Any, code: str) -> int | None:
    getter = getattr(conn, "response", None)
    if getter is None:
        return None
    _typ, data = getter(code)
    return _first_int(data)


def quote_mailbox(name: str) -> str:
    """'INBOX' giữ nguyên; '[Gmail]/All Mail' → '"[Gmail]/All Mail"'."""
    if len(name) >= 2 and name.startswith('"') and name.endswith('"'):
        return name
    if _ATOM_OK.fullmatch(name):
        return name
    return '"' + name.replace("\\", "\\\\").replace('"', '\\"') + '"'


def imap_date(d: date) -> str:
    """date(2026, 10, 1) → '01-Oct-2026'."""
    return f"{d.day:02d}-{_MONTHS[d.month - 1]}-{d.year:04d}"


def from_criteria(domains: Sequence[str]) -> list[str]:
    """FROM của nhiều domain nối bằng OR (tiền tố, nhị phân): OR OR FROM "a" FROM "b" FROM "c"."""
    cleaned: list[str] = []
    for d in domains:
        nd = normalize_domain(d)
        if nd and _DOMAIN_OK.fullmatch(nd) and nd not in cleaned:
            cleaned.append(nd)
    terms = [f'FROM "{d}"' for d in cleaned]
    return ["OR"] * (len(terms) - 1) + terms


def _status_values(conn: Any, folder: str) -> dict[str, int]:
    typ, data = conn.status(quote_mailbox(folder), "(UIDVALIDITY UIDNEXT)")
    if _to_str(typ).upper() != "OK":
        return {}
    text = " ".join(_flatten(data))
    return {k.upper(): int(v) for k, v in re.findall(r"(UIDVALIDITY|UIDNEXT)\s+(\d+)", text, re.I)}


def _search(conn: Any, *criteria: str) -> list[int]:
    typ, data = conn.uid("SEARCH", *criteria)
    if _to_str(typ).upper() != "OK":
        raise ImapError(f"UID SEARCH thất bại: {' '.join(_flatten(data))[:200]}")
    uids: set[int] = set()
    for text in _flatten(data):
        uids.update(int(tok) for tok in text.split() if tok.isdigit())
    return sorted(uids)


def _max_uid(conn: Any) -> int:
    """UID lớn nhất đang có (dùng khi máy chủ không báo UIDNEXT)."""
    uids = _search(conn, "UID", "*")
    return max(uids) if uids else 0


def _fetch_raw(conn: Any, uid: int) -> bytes | None:
    typ, data = conn.uid("FETCH", str(uid), "(BODY.PEEK[])")
    if _to_str(typ).upper() != "OK":
        logger.warning("IMAP UID FETCH %s trả về %s — bỏ qua thư này", uid, _to_str(typ))
        return None
    for item in data or []:
        if not (isinstance(item, tuple) and len(item) >= 2):
            continue
        head = _to_str(item[0]).upper()
        if "BODY[" not in head and "RFC822" not in head:
            continue
        m = re.search(r"\bUID (\d+)", head)
        if m and int(m.group(1)) != uid:
            continue
        body = item[1]
        return bytes(body) if isinstance(body, bytes | bytearray | memoryview) else _to_str(body).encode("utf-8")
    logger.warning("IMAP UID FETCH %s không có nội dung (thư đã bị xoá?) — bỏ qua", uid)
    return None


# ---------------------------------------------------------------------------
# Lấy thư mới
# ---------------------------------------------------------------------------


def fetch_new_messages(
    conn: Any,
    folder: str,
    state: ImapState,
    from_domains: Sequence[str],
    first_run_since: date | None,
    max_messages: int = DEFAULT_MAX_MESSAGES,
) -> tuple[list[FetchedMessage], ImapState]:
    """Thư mới (cũ nhất trước, tối đa `max_messages`) và trạng thái mới.

    - Chưa có trạng thái hoặc UIDVALIDITY đổi: có `first_run_since` → `UID SEARCH SINCE <ngày>` (backfill);
      không có → chỉ ghi nhận UID lớn nhất hiện tại, không lấy thư cũ.
    - Còn lại: `UID SEARCH UID <last_uid+1>:*`, lọc `uid > last_uid`.
    - Bị giới hạn bởi `max_messages` thì `last_uid` chỉ tiến tới thư cuối đã lấy; phần còn lại lấy ở lần sau.
    """
    limit = max(1, int(max_messages))
    typ, data = conn.select(quote_mailbox(folder), readonly=True)
    if _to_str(typ).upper() != "OK":
        raise ImapError(f"Không mở được thư mục {folder!r}: {' '.join(_flatten(data))[:200]}")

    uidvalidity = _response_int(conn, "UIDVALIDITY")
    uidnext = _response_int(conn, "UIDNEXT")
    if uidvalidity is None or uidnext is None:
        status = _status_values(conn, folder)
        uidvalidity = uidvalidity if uidvalidity is not None else status.get("UIDVALIDITY")
        uidnext = uidnext if uidnext is not None else status.get("UIDNEXT")
    if uidvalidity is None:
        uidvalidity = state.uidvalidity  # máy chủ không báo → giả định không đổi

    # UID lớn nhất tại thời điểm này (trước SEARCH) — thư đến sau đó sẽ có UID lớn hơn và được lấy lần sau.
    top = max(0, uidnext - 1) if uidnext is not None else _max_uid(conn)

    criteria = from_criteria(from_domains)
    changed = state.uidvalidity is not None and uidvalidity is not None and uidvalidity != state.uidvalidity
    if state.last_uid is None or changed:
        if changed:
            logger.warning(
                "UIDVALIDITY của %s đổi (%s → %s): đặt lại trạng thái", folder, state.uidvalidity, uidvalidity
            )
        if first_run_since is None:
            return [], ImapState(uidvalidity=uidvalidity, last_uid=top)
        floor = 0
        uids = _search(conn, "SINCE", imap_date(first_run_since), *criteria)
    else:
        floor = state.last_uid
        uids = _search(conn, "UID", f"{floor + 1}:*", *criteria)

    uids = [u for u in uids if u > floor]
    batch = uids[:limit]
    messages: list[FetchedMessage] = []
    for uid in batch:
        raw = _fetch_raw(conn, uid)
        if raw is not None:
            messages.append(FetchedMessage(uid=uid, raw=raw))

    # Bị giới hạn: dừng ở thư cuối đã lấy. Đã xét hết: tiến tới UID lớn nhất lúc SELECT để lần sau không tìm lại.
    last_uid = batch[-1] if len(uids) > len(batch) else max([floor, *batch, top])
    return messages, ImapState(uidvalidity=uidvalidity, last_uid=last_uid)
