"""Adapter webhook Casso V2: kiểm tra chữ ký `X-Casso-Signature` và chuẩn hoá payload thành `NormalizedTx`.

Hàm thuần (không DB, không FastAPI) — route `POST /webhooks/casso` gọi `verify_casso` rồi `parse_casso`.

Payload (giờ Việt Nam, không có timezone; `amount < 0` là tiền ra):
    {"error": 0, "data": {"id": 218897, "reference": "FT24364030863634", "description": "...",
     "amount": 16775000, "runningBalance": 16775000, "transactionDateTime": "2024-12-23 07:00:00",
     "accountNumber": "123456789", "bankName": "MBBank", "bankAbbreviation": "MBB",
     "virtualAccountNumber": "", "virtualAccountName": "", "counterAccountName": "",
     "counterAccountNumber": "", "counterAccountBankId": "", "counterAccountBankName": ""}}

Chữ ký theo repo mẫu chính thức CassoHQ/casso-webhook-v2-verify-signature:
    msg = f"{t}." + json.dumps(<body đã sắp xếp key A→Z, đệ quy>, separators=(",", ":"))
    v1  = hex(HMAC-SHA512(key=<Khoá bảo mật>, msg))
"""

from __future__ import annotations

import hashlib
import hmac
import json
import math
import re
from collections.abc import Mapping
from datetime import UTC, datetime
from decimal import ROUND_HALF_UP, Decimal
from typing import Any

from app.clock import ICT, ensure_utc, ict_naive_to_utc, to_ict
from app.config import Settings
from app.ingest.banks import canonical_bank
from app.ingest.schema import AuthError, NormalizedTx, ParseError
from app.money import parse_vnd
from app.text import digits_only

SOURCE = "casso"
# Route so khớp chuỗi này để trả 404 thay vì 401.
NOT_CONFIGURED = "not configured"
SIGNATURE_HEADER = "x-casso-signature"
# Số TK của payload mẫu/thử nghiệm mà Casso gửi khi bấm "Gửi thử" (đi kèm id = 0).
TEST_ACCOUNT_NUMBER = "88888888"
# Chặn số tiền vô lý (tránh tràn INTEGER của SQLite): 10^15 đồng.
MAX_AMOUNT = 10**15

_TIMESTAMP = re.compile(r"[0-9]{1,20}")
_HEX_SHA512 = re.compile(r"[0-9a-f]{128}")
_PLAIN_NUMBER = re.compile(r"[+-]?[0-9]+(?:\.[0-9]{1,2})?")
_DATETIME_FORMATS = (
    ("%Y-%m-%d %H:%M:%S", "second"),
    ("%Y-%m-%dT%H:%M:%S", "second"),
    ("%Y-%m-%d %H:%M:%S.%f", "second"),
    ("%Y-%m-%d %H:%M", "minute"),
)


# ---------------------------------------------------------------------------
# Xác thực chữ ký
# ---------------------------------------------------------------------------


def _parse_signature_header(value: str) -> tuple[str, list[str]]:
    """'t=<ms>,v1=<hex>' -> (t, [chữ ký hex thường]). Sai định dạng -> AuthError."""
    ts: str | None = None
    sigs: list[str] = []
    for part in value.split(","):
        key, sep, val = part.strip().partition("=")
        if not sep:
            raise AuthError("X-Casso-Signature sai định dạng")
        key, val = key.strip().lower(), val.strip()
        if key == "t":
            if ts is not None or not _TIMESTAMP.fullmatch(val):
                raise AuthError("X-Casso-Signature: timestamp không hợp lệ")
            ts = val
        elif key == "v1":
            sig = val.lower()
            if not _HEX_SHA512.fullmatch(sig):
                raise AuthError("X-Casso-Signature: chữ ký v1 không hợp lệ")
            sigs.append(sig)
    if ts is None or not sigs:
        raise AuthError("X-Casso-Signature thiếu t hoặc v1")
    # Mẫu chính thức ép t về số nguyên trước khi ghép chuỗi (bỏ số 0 ở đầu nếu có).
    return str(int(ts)), sigs


def _sort_keys(obj: Any, *, into_lists: bool) -> Any:
    """Sắp xếp key A→Z đệ quy. `into_lists=False` giống hệt mẫu Python chính thức (không sắp dict nằm trong list)."""
    if isinstance(obj, dict):
        return {k: _sort_keys(obj[k], into_lists=into_lists) for k in sorted(obj)}
    if isinstance(obj, list) and into_lists:
        return [_sort_keys(x, into_lists=True) for x in obj]
    return obj


def _candidate_messages(ts: str, body: Any) -> list[bytes]:
    """Các cách tuần tự hoá hợp lệ: thoát/không thoát ký tự non-ASCII (Python/PHP vs JavaScript)."""
    out: dict[bytes, None] = {}
    for into_lists in (True, False):
        sorted_body = _sort_keys(body, into_lists=into_lists)
        for ensure_ascii in (True, False):
            dumped = json.dumps(sorted_body, separators=(",", ":"), ensure_ascii=ensure_ascii)
            out[f"{ts}.{dumped}".encode("utf-8", "surrogatepass")] = None
    return list(out)


def verify_casso(headers: Mapping[str, str], raw_body: bytes, settings: Settings) -> None:
    """Kiểm tra `X-Casso-Signature: t=<ms>,v1=<hex>` (HMAC-SHA512 với Khoá bảo mật); sai -> `AuthError`.

    Khoá rỗng -> `AuthError("not configured")`. Không kiểm tra cửa sổ thời gian (chống lặp bằng id giao dịch).
    """
    key = settings.casso_secure_key
    if not key:
        raise AuthError(NOT_CONFIGURED)
    lowered = {str(k).lower(): str(v) for k, v in headers.items()}
    header = lowered.get(SIGNATURE_HEADER, "").strip()
    if not header:
        raise AuthError("thiếu header X-Casso-Signature")
    ts, provided = _parse_signature_header(header)
    try:
        body = json.loads(raw_body)
        messages = _candidate_messages(ts, body)
    except (ValueError, RecursionError) as exc:  # JSONDecodeError/UnicodeDecodeError là ValueError
        raise AuthError("body không phải JSON hợp lệ") from exc
    key_bytes = key.encode("utf-8")
    for message in messages:
        expected = hmac.new(key_bytes, message, hashlib.sha512).hexdigest().encode("ascii")
        # Không thoát sớm theo từng chữ ký để thời gian so sánh không phụ thuộc vị trí khớp.
        if any([hmac.compare_digest(expected, sig.encode("ascii")) for sig in provided]):
            return
    raise AuthError("chữ ký Casso không khớp")


# ---------------------------------------------------------------------------
# Chuẩn hoá payload
# ---------------------------------------------------------------------------


def _opt_str(item: dict[str, Any], field: str) -> str | None:
    """Trường chuỗi tuỳ chọn; số nguyên được chuyển thành chuỗi; rỗng -> None; sai kiểu -> ParseError."""
    value = item.get(field)
    if value is None:
        return None
    if isinstance(value, bool) or not isinstance(value, str | int):
        raise ParseError(f"Casso: trường {field} sai kiểu ({type(value).__name__})")
    s = str(value).strip()
    return s or None


def _to_int(value: Any, field: str) -> int | None:
    """Số tiền có dấu dạng int, float hoặc chuỗi ('-50000', '50000.00', '50.000'). None/'' -> None."""
    if value is None:
        return None
    if isinstance(value, bool):
        raise ParseError(f"Casso: trường {field} sai kiểu (bool)")
    if isinstance(value, int):
        n = value
    elif isinstance(value, float):
        if not math.isfinite(value):
            raise ParseError(f"Casso: trường {field} không hợp lệ: {value!r}")
        n = round(value)
    elif isinstance(value, str):
        s = value.strip()
        if not s:
            return None
        if _PLAIN_NUMBER.fullmatch(s):
            n = int(Decimal(s).to_integral_value(rounding=ROUND_HALF_UP))
        else:
            parsed = parse_vnd(s)
            if parsed is None:
                raise ParseError(f"Casso: trường {field} không phải số tiền: {value!r}")
            n = -parsed if s.startswith("-") else parsed
    else:
        raise ParseError(f"Casso: trường {field} sai kiểu ({type(value).__name__})")
    if abs(n) > MAX_AMOUNT:
        raise ParseError(f"Casso: trường {field} quá lớn: {value!r}")
    return n


def _external_id(value: Any) -> str:
    if value is None:
        raise ParseError("Casso: thiếu trường id")
    if isinstance(value, bool):
        raise ParseError("Casso: trường id sai kiểu (bool)")
    if isinstance(value, int) and value >= 0:
        return str(value)
    if isinstance(value, str) and value.strip().isdigit() and value.strip().isascii():
        return str(int(value.strip()))
    raise ParseError(f"Casso: trường id không hợp lệ: {value!r}")


def _bank_time(value: Any, received_at: datetime) -> tuple[datetime, str]:
    """'YYYY-MM-DD HH:MM:SS' giờ VN -> (UTC, 'second').

    Chỉ có ngày 'YYYY-MM-DD' -> độ chính xác 'date': nếu trùng ngày (ICT) với lúc nhận thì lấy giờ nhận,
    còn không thì lấy 12:00 ICT của ngày đó.
    """
    if not isinstance(value, str) or not value.strip():
        raise ParseError(f"Casso: transactionDateTime không hợp lệ: {value!r}")
    s = value.strip()
    try:
        day = datetime.strptime(s, "%Y-%m-%d").date()
    except ValueError:
        day = None
    if day is not None:
        received = ensure_utc(received_at)
        if to_ict(received).date() == day:
            return received, "date"
        return datetime(day.year, day.month, day.day, 12, 0, tzinfo=ICT).astimezone(UTC), "date"
    for fmt, precision in _DATETIME_FORMATS:
        try:
            return ict_naive_to_utc(datetime.strptime(s, fmt)), precision
        except ValueError:
            continue
        except OverflowError:
            break
    raise ParseError(f"Casso: transactionDateTime không hợp lệ: {value!r}")


def _parse_item(item: Any, received_at: datetime) -> NormalizedTx | None:
    """Một giao dịch trong `data`; `amount == 0` -> None (bỏ qua)."""
    if not isinstance(item, dict):
        raise ParseError("Casso: phần tử data không phải object")
    external_id = _external_id(item.get("id"))

    amount = _to_int(item.get("amount"), "amount")
    if amount is None:
        raise ParseError(f"Casso: giao dịch {external_id} thiếu amount")
    if amount == 0:
        return None
    direction = "out" if amount < 0 else "in"

    bank_time, precision = _bank_time(item.get("transactionDateTime"), received_at)
    balance = _to_int(item.get("runningBalance"), "runningBalance")

    account_number = _opt_str(item, "accountNumber")
    bank_name = _opt_str(item, "bankName")
    bank_abbr = _opt_str(item, "bankAbbreviation")
    description = _opt_str(item, "description") or ""
    reference = _opt_str(item, "reference")
    counter_name = _opt_str(item, "counterAccountName")
    counter_account = _opt_str(item, "counterAccountNumber")

    meta: dict[str, Any] = {
        "bank_name": bank_name,
        "bank_abbreviation": bank_abbr,
        "virtual_account_number": _opt_str(item, "virtualAccountNumber"),
        "virtual_account_name": _opt_str(item, "virtualAccountName"),
        "counter_bank_id": _opt_str(item, "counterAccountBankId"),
        "counter_bank_name": _opt_str(item, "counterAccountBankName"),
    }
    is_test = external_id == "0" or digits_only(account_number) == TEST_ACCOUNT_NUMBER
    try:
        return NormalizedTx(
            source=SOURCE,
            external_id=external_id,
            direction=direction,
            amount=abs(amount),
            bank_time=bank_time,
            time_precision=precision,
            bank=canonical_bank(bank_abbr or bank_name),
            account_number=account_number,
            description=description,
            reference_code=reference,
            counter_account=counter_account,
            counter_name=counter_name,
            balance_after=balance,
            is_test=is_test,
            meta={k: v for k, v in meta.items() if v is not None},
        )
    except ValueError as exc:
        raise ParseError(f"Casso: {exc}") from exc


def parse_casso(payload: dict, received_at: datetime) -> list[NormalizedTx]:
    """Body webhook Casso V2 `{"error": 0, "data": {...} | [{...}, ...]}` -> danh sách `NormalizedTx`.

    `error != 0`, thiếu `data` hoặc không còn giao dịch nào (sau khi bỏ `amount == 0`) -> `ParseError`.
    Payload thử nghiệm (id 0 hoặc TK 88888888) vẫn được trả về với `is_test=True`.
    """
    if not isinstance(payload, dict):
        raise ParseError("Casso: payload không phải object JSON")
    error = payload.get("error", 0)
    if isinstance(error, bool) or error not in (0, "0"):
        raise ParseError(f"Casso: payload báo lỗi (error={error!r})")
    data = payload.get("data")
    if isinstance(data, dict):
        items: list[Any] = [data]
    elif isinstance(data, list):
        items = data
    else:
        raise ParseError("Casso: thiếu hoặc sai kiểu trường data")

    out: list[NormalizedTx] = []
    for item in items:
        tx = _parse_item(item, received_at)
        if tx is not None:
            out.append(tx)
    if not out:
        raise ParseError("Casso: không có giao dịch nào có số tiền khác 0")
    return out
