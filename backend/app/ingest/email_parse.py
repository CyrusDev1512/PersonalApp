"""Đọc một email thô (RFC 822) thành các `NormalizedTx`.

Các bước: xác định ngân hàng theo domain người gửi (cho phép domain con) → kiểm tra `Authentication-Results`
(dkim=pass / dmarc=pass với domain thuộc allowlist của chính ngân hàng đó) → lấy phần văn bản (ưu tiên text/plain,
sau đó HTML) → parser theo ngân hàng → `NormalizedTx`.

Chỉ tin header `Authentication-Results` **trên cùng** (do máy chủ nhận cuối cùng, vd. Gmail, chèn vào): người gửi
giả mạo có thể tự thêm các header như vậy vào thư của họ nhưng chúng luôn nằm bên dưới.

Hàm thuần, không bao giờ raise: lỗi bất ngờ → `unparsed` kèm lý do.
"""

from __future__ import annotations

import email
import email.policy
import email.utils
import hashlib
import logging
import re
from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from email.message import EmailMessage, Message

from app.clock import ensure_utc, ict_naive_to_utc, to_ict
from app.ingest.banks import canonical_bank
from app.ingest.parsers.base import BankParser, ParsedTx, domain_matches, normalize_domain
from app.ingest.parsers.generic import html_to_text
from app.ingest.parsers.registry import parser_for
from app.ingest.schema import NormalizedTx

logger = logging.getLogger(__name__)

SOURCE = "email"
# Giờ trong nội dung lệch quá xa header Date → nhiều khả năng đọc nhầm một ngày khác trong email.
MAX_BODY_DATE_SKEW = timedelta(days=3)
MAX_EXTERNAL_ID = 200

_COMMENT = re.compile(r"\([^()]*\)")
_METHOD_RESULT = re.compile(r"\s*([a-z0-9_.-]+)\s*=\s*([a-z]+)", re.I)
_PROPERTY = re.compile(r"\b([a-z]+\.[a-z0-9_-]+)\s*=\s*\"?([^\s;\"]+)", re.I)


@dataclass
class EmailParseResult:
    status: str  # parsed | unparsed | ignored
    txs: list[NormalizedTx] = field(default_factory=list)
    reason: str | None = None  # sender | auth | no amount | direction | error: ...
    bank: str | None = None
    message_id: str | None = None
    subject: str | None = None


# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------


def _header(msg: Message, name: str) -> str | None:
    try:
        value = msg.get(name)
    except Exception:  # header lỗi định dạng
        logger.debug("Không đọc được header %s", name, exc_info=True)
        return None
    if value is None:
        return None
    return str(value)


def _message_id(msg: Message, raw: bytes) -> str:
    value = (_header(msg, "Message-ID") or "").strip().strip("<>").strip()
    if not value:
        return hashlib.sha256(raw).hexdigest()
    if len(value) > MAX_EXTERNAL_ID:
        return hashlib.sha256(value.encode("utf-8", "replace")).hexdigest()
    return value


def _from_address(msg: Message) -> str | None:
    """Địa chỉ người gửi duy nhất; nhiều header From hoặc nhiều địa chỉ → None (không tin)."""
    try:
        values = msg.get_all("From") or []
    except Exception:
        return None
    if len(values) != 1:
        return None
    header = values[0]
    addresses: list[str] = []
    parsed = getattr(header, "addresses", None)
    if parsed is not None:
        addresses = [a.addr_spec for a in parsed if getattr(a, "addr_spec", "")]
    else:
        addresses = [addr for _, addr in email.utils.getaddresses([str(header)]) if addr]
    if len(addresses) != 1 or "@" not in addresses[0]:
        return None
    return addresses[0].strip()


def _bank_for_domain(domain: str, bank_domains: Mapping[str, Sequence[str]]) -> tuple[str, list[str]] | None:
    """Ngân hàng có domain cho phép khớp dài nhất (domain bằng hoặc là domain cha của người gửi)."""
    best: tuple[int, str, list[str]] | None = None
    for bank, domains in bank_domains.items():
        allowed = [normalize_domain(d) for d in domains if normalize_domain(d)]
        for d in allowed:
            if domain_matches(domain, [d]) and (best is None or len(d) > best[0]):
                best = (len(d), bank, allowed)
    if best is None:
        return None
    return canonical_bank(best[1]) or best[1], best[2]


def auth_results_pass(value: str, allowed: Sequence[str]) -> bool:
    """Một header Authentication-Results có dkim=pass (header.d/header.i) hoặc dmarc=pass (header.from)
    với domain thuộc `allowed` hay không."""
    cleaned = _COMMENT.sub(" ", value or "")
    for part in cleaned.split(";"):
        m = _METHOD_RESULT.match(part)
        if not m or m.group(2).lower() != "pass":
            continue
        method = m.group(1).lower()
        props = {k.lower(): v for k, v in _PROPERTY.findall(part[m.end() :])}
        if method == "dkim":
            domain = props.get("header.d") or props.get("header.i", "").rpartition("@")[2]
        elif method == "dmarc":
            domain = props.get("header.from", "")
        else:
            continue
        if domain and domain_matches(domain, allowed):
            return True
    return False


def _auth_ok(msg: Message, allowed: Sequence[str]) -> bool:
    try:
        headers = msg.get_all("Authentication-Results") or []
    except Exception:
        return False
    if not headers:
        return False
    return auth_results_pass(str(headers[0]), allowed)


def _date_header(msg: Message) -> datetime | None:
    value = _header(msg, "Date")
    if not value:
        return None
    try:
        dt = email.utils.parsedate_to_datetime(value)
    except (TypeError, ValueError, IndexError):
        return None
    if dt is None:
        return None
    return ensure_utc(dt)  # "-0000" (không rõ múi giờ) → hiểu là UTC


# ---------------------------------------------------------------------------
# Nội dung
# ---------------------------------------------------------------------------


def _part_text(part: Message) -> str:
    try:
        content = part.get_content() if isinstance(part, EmailMessage) else part.get_payload(decode=True)
    except (LookupError, UnicodeError, ValueError, AssertionError, KeyError):
        content = part.get_payload(decode=True)
    if isinstance(content, bytes):
        charset = part.get_content_charset() or "utf-8"
        try:
            return content.decode(charset, errors="replace")
        except LookupError:
            return content.decode("utf-8", errors="replace")
    return content if isinstance(content, str) else ""


def _body_texts(msg: Message) -> list[str]:
    """Các ứng viên văn bản theo thứ tự ưu tiên: text/plain, rồi HTML đã bóc thẻ."""
    out: list[str] = []
    seen: set[int] = set()
    if isinstance(msg, EmailMessage):
        for subtype in ("plain", "html"):
            try:
                part = msg.get_body(preferencelist=(subtype,))
            except Exception:
                part = None
            if part is None or id(part) in seen:
                continue
            seen.add(id(part))
            text = _part_text(part)
            if subtype == "html" or part.get_content_subtype() == "html":
                text = html_to_text(text)
            if text.strip():
                out.append(text)
    if not out:  # cấu trúc MIME lạ: lấy mọi phần text/*
        for part in msg.walk():
            if part.get_content_maintype() != "text" or id(part) in seen:
                continue
            text = _part_text(part)
            if part.get_content_subtype() == "html":
                text = html_to_text(text)
            if text.strip():
                out.append(text)
    return out


# ---------------------------------------------------------------------------
# ParsedTx -> NormalizedTx
# ---------------------------------------------------------------------------


def _bank_time(tx: ParsedTx, header_dt: datetime | None, received_at: datetime) -> tuple[datetime, str]:
    if tx.when is not None and tx.when_precision in ("second", "minute", "date"):
        body_dt = ict_naive_to_utc(tx.when)
        if header_dt is not None and abs(body_dt - header_dt) > MAX_BODY_DATE_SKEW:
            return header_dt, "approx"
        if tx.when_precision == "date":
            # Chỉ có ngày: header Date cùng ngày (giờ VN) chính xác hơn.
            if header_dt is not None and to_ict(header_dt).date() == tx.when.date():
                return header_dt, "approx"
            return body_dt, "date"
        return body_dt, tx.when_precision
    if header_dt is not None:
        return header_dt, "approx"
    return ensure_utc(received_at), "approx"


def _account_fields(hint: str | None) -> tuple[str | None, str | None]:
    """(số TK đầy đủ nếu toàn chữ số, 4 số cuối nếu nhìn thấy)."""
    hint = (hint or "").strip()
    number = hint if hint.isdigit() and len(hint) >= 6 else None
    last4 = hint[-4:] if len(hint) >= 4 and hint[-4:].isdigit() else None
    return number, last4


def _to_normalized(
    txs: list[ParsedTx],
    *,
    message_id: str,
    bank: str,
    header_dt: datetime | None,
    received_at: datetime,
    meta: dict[str, str],
) -> list[NormalizedTx]:
    out: list[NormalizedTx] = []
    for n, tx in enumerate(txs, start=1):
        bank_time, precision = _bank_time(tx, header_dt, received_at)
        account_number, last4 = _account_fields(tx.account_hint)
        out.append(
            NormalizedTx(
                source=SOURCE,
                external_id=message_id if len(txs) == 1 else f"{message_id}#{n}",
                direction=tx.direction or "",  # đã kiểm tra ở parse_email_message
                amount=tx.amount,
                bank_time=bank_time,
                time_precision=precision,
                bank=bank,
                account_number=account_number,
                account_last4=last4,
                description=tx.description or "",
                reference_code=tx.reference_code,
                counter_account=tx.counter_account,
                balance_after=tx.balance_after,
                meta=dict(meta),
            )
        )
    return out


def parse_email_message(
    raw: bytes,
    bank_domains: Mapping[str, Sequence[str]],
    require_dkim: bool,
    received_at: datetime,
    *,
    parsers: Sequence[BankParser] | None = None,
) -> EmailParseResult:
    """Email thô → `EmailParseResult` (parsed / unparsed / ignored). Không bao giờ raise."""
    message_id: str | None = None
    subject: str | None = None
    bank: str | None = None
    try:
        raw = bytes(raw)
        message_id = hashlib.sha256(raw).hexdigest()
        msg = email.message_from_bytes(raw, policy=email.policy.default)
        message_id = _message_id(msg, raw)
        subject = (_header(msg, "Subject") or "").strip() or None

        sender = _from_address(msg)
        found = _bank_for_domain(sender.rpartition("@")[2], bank_domains) if sender else None
        if found is None:
            return EmailParseResult("ignored", reason="sender", message_id=message_id, subject=subject)
        bank, allowed = found
        if require_dkim and not _auth_ok(msg, allowed):
            return EmailParseResult("ignored", reason="auth", bank=bank, message_id=message_id, subject=subject)

        parser = parser_for(bank, parsers)
        parsed: list[ParsedTx] = []
        for text in _body_texts(msg):
            parsed = parser.parse(subject or "", text)
            if parsed:
                break
        if not parsed:
            return EmailParseResult("unparsed", reason="no amount", bank=bank, message_id=message_id, subject=subject)
        if any(tx.direction not in ("in", "out") for tx in parsed):
            return EmailParseResult("unparsed", reason="direction", bank=bank, message_id=message_id, subject=subject)

        txs = _to_normalized(
            parsed,
            message_id=message_id,
            bank=bank,
            header_dt=_date_header(msg),
            received_at=received_at,
            meta={"email_from": sender or "", "email_subject": subject or "", "parser": parser.bank},
        )
        return EmailParseResult("parsed", txs=txs, bank=bank, message_id=message_id, subject=subject)
    except Exception as exc:  # không để một email lạ làm dừng cả đợt poll
        logger.warning("Lỗi khi đọc email %s", message_id, exc_info=True)
        reason = f"error: {type(exc).__name__}: {exc}"[:300]
        return EmailParseResult("unparsed", reason=reason, bank=bank, message_id=message_id, subject=subject)
