"""Adapter webhook SePay: xác thực request và chuẩn hoá payload thành `NormalizedTx`.

Hàm thuần (không DB, không FastAPI) — route `POST /webhooks/sepay` gọi `verify_sepay` rồi `parse_sepay`.

Payload SePay (giờ Việt Nam, không có timezone):
    {"id": 92704, "gateway": "Vietcombank", "transactionDate": "2023-03-25 14:02:37",
     "accountNumber": "0123499999", "subAccount": null, "code": null, "content": "chuyen tien mua iphone",
     "transferType": "in", "transferAmount": 2277000, "accumulated": 19077000,
     "referenceCode": "MBVCB.3278907687", "description": ""}
Chi tiết lấy từ kết quả tìm kiếm + code bên thứ ba (chưa đối chiếu tài liệu gốc) nên adapter chịu được trường
thiếu/thừa và số tiền dạng chuỗi.
"""

from __future__ import annotations

import hashlib
import hmac
import math
import re
from collections.abc import Mapping
from datetime import datetime
from decimal import ROUND_HALF_UP, Decimal
from typing import Any

from app.clock import ensure_utc, ict_naive_to_utc
from app.config import Settings
from app.ingest.banks import canonical_bank
from app.ingest.schema import AuthError, NormalizedTx, ParseError
from app.money import parse_vnd

SOURCE = "sepay"
# Route so khớp chuỗi này để trả 404 thay vì 401.
NOT_CONFIGURED = "not configured"
# Lệch quá 5 phút giữa X-SePay-Timestamp và giờ server thì từ chối (chống replay).
MAX_CLOCK_SKEW_SECONDS = 300
# Chặn số tiền vô lý (tránh tràn INTEGER của SQLite): 10^15 đồng.
MAX_AMOUNT = 10**15

_AUTH_SCHEMES = ("apikey", "bearer")
_TIMESTAMP = re.compile(r"[0-9]{1,12}")
_HEX_SHA256 = re.compile(r"[0-9a-f]{64}")
_PLAIN_NUMBER = re.compile(r"[+-]?[0-9]+(?:\.[0-9]{1,2})?")
_DATETIME_FORMATS = (
    ("%Y-%m-%d %H:%M:%S", "second"),
    ("%Y-%m-%dT%H:%M:%S", "second"),
    ("%Y-%m-%d %H:%M", "minute"),
)


# ---------------------------------------------------------------------------
# Xác thực
# ---------------------------------------------------------------------------


def _lower_headers(headers: Mapping[str, str]) -> dict[str, str]:
    return {str(k).lower(): str(v) for k, v in headers.items()}


def _check_api_key(authorization: str | None, api_key: str) -> bool:
    """`Authorization: Apikey <KEY>` (hoặc `Bearer <KEY>`), scheme không phân biệt hoa thường."""
    if not authorization:
        return False
    parts = authorization.strip().split(None, 1)
    if len(parts) != 2 or parts[0].lower() not in _AUTH_SCHEMES:
        return False
    token = parts[1].strip()
    if not token:
        return False
    return hmac.compare_digest(token.encode("utf-8"), api_key.encode("utf-8"))


def _check_hmac(headers: dict[str, str], raw_body: bytes, secret: str, now: datetime) -> bool:
    """HMAC-SHA256 trên `b"{ts}." + raw_body`; header lỗi định dạng hoặc lệch giờ -> False."""
    ts_raw = headers.get("x-sepay-timestamp", "").strip()
    sig_raw = headers.get("x-sepay-signature", "").strip()
    if not _TIMESTAMP.fullmatch(ts_raw) or not sig_raw:
        return False
    if abs(ensure_utc(now).timestamp() - int(ts_raw)) > MAX_CLOCK_SKEW_SECONDS:
        return False
    scheme, sep, value = sig_raw.partition("=")
    if sep:
        if scheme.strip().lower() != "sha256":
            return False
        sig_raw = value.strip()
    provided = sig_raw.lower()
    if not _HEX_SHA256.fullmatch(provided):
        return False
    message = ts_raw.encode("ascii") + b"." + raw_body
    expected = hmac.new(secret.encode("utf-8"), message, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected.encode("ascii"), provided.encode("ascii"))


def verify_sepay(headers: Mapping[str, str], raw_body: bytes, settings: Settings, now: datetime) -> None:
    """Xác thực webhook SePay; sai/thiếu -> `AuthError`.

    Hai cách, mỗi cách chỉ bật khi secret tương ứng có giá trị (fail closed, không bao giờ ký HMAC bằng key rỗng):
    (A) API key `Authorization: Apikey <KEY>` (chấp nhận cả `Bearer <KEY>`);
    (B) HMAC-SHA256: `X-SePay-Timestamp` (giây unix) + `X-SePay-Signature: sha256=<hex>` trên `"{ts}." + body`.
    Chỉ cần một cách đạt. Không cấu hình cách nào -> `AuthError("not configured")`.
    """
    api_key = settings.sepay_api_key
    secret = settings.sepay_hmac_secret
    if not api_key and not secret:
        raise AuthError(NOT_CONFIGURED)
    h = _lower_headers(headers)
    if api_key and _check_api_key(h.get("authorization"), api_key):
        return
    if secret and _check_hmac(h, raw_body, secret, now):
        return
    raise AuthError("sai hoặc thiếu thông tin xác thực SePay")


# ---------------------------------------------------------------------------
# Chuẩn hoá payload
# ---------------------------------------------------------------------------


def _opt_str(payload: dict[str, Any], field: str) -> str | None:
    """Trường chuỗi tuỳ chọn; số nguyên được chuyển thành chuỗi; rỗng -> None; sai kiểu -> ParseError."""
    value = payload.get(field)
    if value is None:
        return None
    if isinstance(value, bool) or not isinstance(value, str | int):
        raise ParseError(f"SePay: trường {field} sai kiểu ({type(value).__name__})")
    s = str(value).strip()
    return s or None


def _to_int(value: Any, field: str) -> int | None:
    """Số tiền dạng int, float hoặc chuỗi ('2277000', '2277000.00', '2.277.000'). None/'' -> None."""
    if value is None:
        return None
    if isinstance(value, bool):
        raise ParseError(f"SePay: trường {field} sai kiểu (bool)")
    if isinstance(value, int):
        n = value
    elif isinstance(value, float):
        if not math.isfinite(value):
            raise ParseError(f"SePay: trường {field} không hợp lệ: {value!r}")
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
                raise ParseError(f"SePay: trường {field} không phải số tiền: {value!r}")
            n = -parsed if s.startswith("-") else parsed
    else:
        raise ParseError(f"SePay: trường {field} sai kiểu ({type(value).__name__})")
    if abs(n) > MAX_AMOUNT:
        raise ParseError(f"SePay: trường {field} quá lớn: {value!r}")
    return n


def _external_id(value: Any) -> str:
    if value is None:
        raise ParseError("SePay: thiếu trường id")
    if isinstance(value, bool):
        raise ParseError("SePay: trường id sai kiểu (bool)")
    if isinstance(value, int) and value >= 0:
        return str(value)
    if isinstance(value, str) and value.strip().isdigit() and value.strip().isascii():
        return str(int(value.strip()))
    raise ParseError(f"SePay: trường id không hợp lệ: {value!r}")


def _bank_time(value: Any) -> tuple[datetime, str]:
    """'YYYY-MM-DD HH:MM:SS' giờ Việt Nam -> (UTC, độ chính xác)."""
    if not isinstance(value, str) or not value.strip():
        raise ParseError(f"SePay: transactionDate không hợp lệ: {value!r}")
    s = value.strip()
    for fmt, precision in _DATETIME_FORMATS:
        try:
            return ict_naive_to_utc(datetime.strptime(s, fmt)), precision
        except ValueError:
            continue
        except OverflowError:
            break
    raise ParseError(f"SePay: transactionDate không hợp lệ: {value!r}")


def parse_sepay(payload: dict) -> NormalizedTx:
    """Payload webhook SePay -> `NormalizedTx`. Mọi lỗi dữ liệu đều là `ParseError`."""
    if not isinstance(payload, dict):
        raise ParseError("SePay: payload không phải object JSON")

    external_id = _external_id(payload.get("id"))

    direction = payload.get("transferType")
    if not isinstance(direction, str) or direction.strip().lower() not in ("in", "out"):
        raise ParseError(f"SePay: transferType không hợp lệ: {direction!r}")
    direction = direction.strip().lower()

    amount = _to_int(payload.get("transferAmount"), "transferAmount")
    if amount is None or amount <= 0:
        raise ParseError(f"SePay: transferAmount phải > 0: {payload.get('transferAmount')!r}")

    bank_time, precision = _bank_time(payload.get("transactionDate"))
    balance = _to_int(payload.get("accumulated"), "accumulated")

    gateway = _opt_str(payload, "gateway")
    account_number = _opt_str(payload, "accountNumber")
    sub_account = _opt_str(payload, "subAccount")
    code = _opt_str(payload, "code")
    content = _opt_str(payload, "content")
    description = _opt_str(payload, "description")
    reference = _opt_str(payload, "referenceCode")

    meta: dict[str, Any] = {
        "gateway": gateway,
        "content": content,
        "description": description,
        "code": code,
        "sub_account": sub_account,
    }
    try:
        return NormalizedTx(
            source=SOURCE,
            external_id=external_id,
            direction=direction,
            amount=amount,
            bank_time=bank_time,
            time_precision=precision,
            bank=canonical_bank(gateway),
            account_number=account_number or sub_account,
            description=content or description or "",
            reference_code=reference,
            balance_after=balance,
            meta={k: v for k, v in meta.items() if v is not None},
        )
    except ValueError as exc:
        raise ParseError(f"SePay: {exc}") from exc
