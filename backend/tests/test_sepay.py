"""Test adapter SePay: xác thực (API key / HMAC, fail closed) và chuẩn hoá payload."""

from __future__ import annotations

import hashlib
import hmac
import json
from datetime import UTC, datetime, timedelta

import pytest
from starlette.datastructures import Headers

from app.config import Settings
from app.ingest.schema import AuthError, NormalizedTx, ParseError
from app.ingest.sepay import NOT_CONFIGURED, parse_sepay, verify_sepay

API_KEY = "sepay-api-key-0123456789abcdef"
SECRET = "sepay-hmac-secret-0123456789abcdef"
NOW = datetime(2026, 10, 14, 3, 0, 0, tzinfo=UTC)
BODY = json.dumps(
    {"id": 92704, "gateway": "Vietcombank", "transferAmount": 3500000, "content": "RÚT TIỀN ATM"},
    ensure_ascii=False,
).encode("utf-8")


def make_settings(api_key: str = "", secret: str = "") -> Settings:
    return Settings(_env_file=None, app_token="x" * 32, sepay_api_key=api_key, sepay_hmac_secret=secret)


def sign(body: bytes, ts: int, secret: str = SECRET) -> str:
    return hmac.new(secret.encode(), f"{ts}.".encode() + body, hashlib.sha256).hexdigest()


def hmac_headers(body: bytes = BODY, ts: int | None = None, secret: str = SECRET) -> dict[str, str]:
    ts = int(NOW.timestamp()) if ts is None else ts
    return {"X-SePay-Timestamp": str(ts), "X-SePay-Signature": f"sha256={sign(body, ts, secret)}"}


# ---------------------------------------------------------------------------
# verify_sepay — API key
# ---------------------------------------------------------------------------


class TestApiKey:
    def test_apikey_ok(self):
        verify_sepay({"Authorization": f"Apikey {API_KEY}"}, BODY, make_settings(api_key=API_KEY), NOW)

    def test_bearer_prefix_ok(self):
        verify_sepay({"Authorization": f"Bearer {API_KEY}"}, BODY, make_settings(api_key=API_KEY), NOW)

    @pytest.mark.parametrize("scheme", ["apikey", "APIKEY", "ApiKey", "bearer", "BEARER"])
    def test_scheme_case_insensitive(self, scheme):
        verify_sepay({"Authorization": f"{scheme} {API_KEY}"}, BODY, make_settings(api_key=API_KEY), NOW)

    @pytest.mark.parametrize("name", ["authorization", "AUTHORIZATION", "AuThOrIzAtIoN"])
    def test_header_name_case_insensitive(self, name):
        verify_sepay({name: f"Apikey {API_KEY}"}, BODY, make_settings(api_key=API_KEY), NOW)

    def test_starlette_headers_mapping(self):
        headers = Headers(raw=[(b"authorization", f"Apikey {API_KEY}".encode())])
        verify_sepay(headers, BODY, make_settings(api_key=API_KEY), NOW)

    def test_surrounding_whitespace_ok(self):
        verify_sepay({"Authorization": f"  Apikey   {API_KEY}  "}, BODY, make_settings(api_key=API_KEY), NOW)

    @pytest.mark.parametrize(
        "value",
        [
            "Apikey wrong-key",
            f"Apikey {API_KEY}x",
            f"Apikey {API_KEY[:-1]}",
            f"Basic {API_KEY}",
            f"Token {API_KEY}",
            API_KEY,  # thiếu scheme
            "Apikey",
            "Apikey ",
            "",
        ],
    )
    def test_bad_key_rejected(self, value):
        with pytest.raises(AuthError) as exc:
            verify_sepay({"Authorization": value}, BODY, make_settings(api_key=API_KEY), NOW)
        assert str(exc.value) != NOT_CONFIGURED

    def test_missing_header_rejected(self):
        with pytest.raises(AuthError):
            verify_sepay({}, BODY, make_settings(api_key=API_KEY), NOW)

    def test_not_configured(self):
        with pytest.raises(AuthError) as exc:
            verify_sepay({"Authorization": f"Apikey {API_KEY}"}, BODY, make_settings(), NOW)
        assert str(exc.value) == NOT_CONFIGURED

    def test_not_configured_even_with_empty_key_header(self):
        with pytest.raises(AuthError) as exc:
            verify_sepay({"Authorization": "Apikey "}, BODY, make_settings(), NOW)
        assert str(exc.value) == NOT_CONFIGURED

    def test_api_key_disabled_when_only_hmac_configured(self):
        # API key rỗng -> cách (A) tắt; header "Apikey " (key rỗng) không được qua.
        with pytest.raises(AuthError):
            verify_sepay({"Authorization": "Apikey "}, BODY, make_settings(secret=SECRET), NOW)
        with pytest.raises(AuthError):
            verify_sepay({"Authorization": "Apikey anything"}, BODY, make_settings(secret=SECRET), NOW)

    def test_unicode_key(self):
        key = "khoá-bí-mật-🔑"
        verify_sepay({"Authorization": f"Apikey {key}"}, BODY, make_settings(api_key=key), NOW)
        with pytest.raises(AuthError):
            verify_sepay({"Authorization": "Apikey khoa-bi-mat-🔑"}, BODY, make_settings(api_key=key), NOW)


# ---------------------------------------------------------------------------
# verify_sepay — HMAC
# ---------------------------------------------------------------------------


class TestHmac:
    def test_hmac_ok(self):
        verify_sepay(hmac_headers(), BODY, make_settings(secret=SECRET), NOW)

    def test_header_names_case_insensitive(self):
        headers = {k.lower(): v for k, v in hmac_headers().items()}
        verify_sepay(headers, BODY, make_settings(secret=SECRET), NOW)
        headers = {k.upper(): v for k, v in hmac_headers().items()}
        verify_sepay(headers, BODY, make_settings(secret=SECRET), NOW)

    def test_uppercase_hex_and_prefix_ok(self):
        ts = int(NOW.timestamp())
        headers = {"X-SePay-Timestamp": str(ts), "X-SePay-Signature": f"SHA256={sign(BODY, ts).upper()}"}
        verify_sepay(headers, BODY, make_settings(secret=SECRET), NOW)

    def test_bare_hex_without_prefix_ok(self):
        ts = int(NOW.timestamp())
        headers = {"X-SePay-Timestamp": str(ts), "X-SePay-Signature": sign(BODY, ts)}
        verify_sepay(headers, BODY, make_settings(secret=SECRET), NOW)

    def test_within_window_ok(self):
        for delta in (-300, -299, 0, 299, 300):
            ts = int(NOW.timestamp()) + delta
            verify_sepay(hmac_headers(ts=ts), BODY, make_settings(secret=SECRET), NOW)

    @pytest.mark.parametrize("delta", [-301, 301, -3600, 86400])
    def test_expired_rejected(self, delta):
        ts = int(NOW.timestamp()) + delta
        with pytest.raises(AuthError):
            verify_sepay(hmac_headers(ts=ts), BODY, make_settings(secret=SECRET), NOW)

    def test_naive_now_treated_as_utc(self):
        verify_sepay(hmac_headers(), BODY, make_settings(secret=SECRET), NOW.replace(tzinfo=None))

    def test_wrong_secret_rejected(self):
        with pytest.raises(AuthError):
            verify_sepay(hmac_headers(secret="other-secret"), BODY, make_settings(secret=SECRET), NOW)

    def test_tampered_body_rejected(self):
        headers = hmac_headers()
        with pytest.raises(AuthError):
            verify_sepay(headers, BODY.replace(b"3500000", b"350000"), make_settings(secret=SECRET), NOW)

    def test_signature_bound_to_timestamp(self):
        ts = int(NOW.timestamp())
        headers = {"X-SePay-Timestamp": str(ts + 1), "X-SePay-Signature": f"sha256={sign(BODY, ts)}"}
        with pytest.raises(AuthError):
            verify_sepay(headers, BODY, make_settings(secret=SECRET), NOW)

    @pytest.mark.parametrize(
        "ts, sig",
        [
            ("abc", None),
            ("", None),
            ("-1", None),
            ("1.5", None),
            ("١٧٦٠٤١٠٨٠٠", None),  # chữ số Unicode
            ("99999999999999999999999", None),
            (None, "sha256="),
            (None, "sha256=zz"),
            (None, "sha256=" + "g" * 64),
            (None, "sha256=" + "a" * 63),
            (None, "sha512=" + "a" * 64),
            (None, ""),
        ],
    )
    def test_malformed_headers_rejected(self, ts, sig):
        headers = hmac_headers()
        if ts is not None:
            headers["X-SePay-Timestamp"] = ts
        if sig is not None:
            headers["X-SePay-Signature"] = sig
        with pytest.raises(AuthError):
            verify_sepay(headers, BODY, make_settings(secret=SECRET), NOW)

    def test_missing_headers_rejected(self):
        for missing in ("X-SePay-Timestamp", "X-SePay-Signature"):
            headers = hmac_headers()
            del headers[missing]
            with pytest.raises(AuthError):
                verify_sepay(headers, BODY, make_settings(secret=SECRET), NOW)

    def test_hmac_disabled_when_only_api_key_configured(self):
        # Không bao giờ tính HMAC bằng key rỗng: chữ ký với secret "" không được qua.
        with pytest.raises(AuthError):
            verify_sepay(hmac_headers(secret=""), BODY, make_settings(api_key=API_KEY), NOW)


class TestBothMethods:
    def test_either_method_passes(self):
        settings = make_settings(api_key=API_KEY, secret=SECRET)
        verify_sepay({"Authorization": f"Apikey {API_KEY}"}, BODY, settings, NOW)
        verify_sepay(hmac_headers(), BODY, settings, NOW)

    def test_bad_api_key_but_good_hmac_passes(self):
        settings = make_settings(api_key=API_KEY, secret=SECRET)
        headers = {"Authorization": "Apikey wrong", **hmac_headers()}
        verify_sepay(headers, BODY, settings, NOW)

    def test_good_api_key_with_malformed_hmac_passes(self):
        settings = make_settings(api_key=API_KEY, secret=SECRET)
        headers = {"Authorization": f"Apikey {API_KEY}", "X-SePay-Timestamp": "abc", "X-SePay-Signature": "x"}
        verify_sepay(headers, BODY, settings, NOW)

    def test_both_bad_rejected(self):
        settings = make_settings(api_key=API_KEY, secret=SECRET)
        headers = {"Authorization": "Apikey wrong", **hmac_headers(secret="wrong")}
        with pytest.raises(AuthError) as exc:
            verify_sepay(headers, BODY, settings, NOW)
        assert str(exc.value) != NOT_CONFIGURED


# ---------------------------------------------------------------------------
# parse_sepay
# ---------------------------------------------------------------------------


def payload(**overrides):
    base = {
        "id": 92704,
        "gateway": "Vietcombank",
        "transactionDate": "2026-10-14 09:59:00",
        "accountNumber": "0123456789",
        "subAccount": None,
        "code": None,
        "content": "RUT TIEN ATM",
        "transferType": "out",
        "transferAmount": 3500000,
        "accumulated": 6500000,
        "referenceCode": "FT26287123456",
        "description": "BankAPINotify RUT TIEN ATM",
    }
    base.update(overrides)
    return base


class TestParse:
    def test_full_payload_out(self):
        tx = parse_sepay(payload())
        assert isinstance(tx, NormalizedTx)
        assert tx.source == "sepay"
        assert tx.external_id == "92704"
        assert tx.direction == "out"
        assert tx.amount == 3500000
        assert tx.bank_time == datetime(2026, 10, 14, 2, 59, 0, tzinfo=UTC)
        assert tx.time_precision == "second"
        assert tx.bank == "VCB"
        assert tx.account_number == "0123456789"
        assert tx.account_last4 == "6789"
        assert tx.description == "RUT TIEN ATM"
        assert tx.reference_code == "FT26287123456"
        assert tx.balance_after == 6500000
        assert tx.is_test is False
        assert tx.meta["content"] == "RUT TIEN ATM"
        assert tx.meta["description"] == "BankAPINotify RUT TIEN ATM"
        assert tx.meta["gateway"] == "Vietcombank"

    def test_full_payload_in_mb(self):
        tx = parse_sepay(
            payload(
                id=5001,
                gateway="MBBank",
                transferType="in",
                transferAmount=15000000,
                accumulated=21500000,
                content="CT TNHH ABC tra luong T10",
                code="LUONG",
                transactionDate="2026-10-05 00:30:15",
            )
        )
        assert tx.direction == "in"
        assert tx.amount == 15000000
        assert tx.bank == "MB"
        assert tx.balance_after == 21500000
        assert tx.meta["code"] == "LUONG"
        # 00:30 ngày 5/10 giờ VN = 17:30 ngày 4/10 UTC.
        assert tx.bank_time == datetime(2026, 10, 4, 17, 30, 15, tzinfo=UTC)

    def test_bank_time_aware_utc(self):
        tx = parse_sepay(payload())
        assert tx.bank_time.utcoffset() == timedelta(0)

    @pytest.mark.parametrize("value", [0, "0", None, "", 0.0])
    def test_accumulated_unknown(self, value):
        assert parse_sepay(payload(accumulated=value)).balance_after is None

    def test_accumulated_missing(self):
        p = payload()
        del p["accumulated"]
        assert parse_sepay(p).balance_after is None

    def test_accumulated_string(self):
        assert parse_sepay(payload(accumulated="6.500.000")).balance_after == 6500000
        assert parse_sepay(payload(accumulated="6500000.00")).balance_after == 6500000

    @pytest.mark.parametrize(
        "value, expected",
        [
            ("3500000", 3500000),
            (" 3500000 ", 3500000),
            ("3500000.00", 3500000),
            ("3.500.000", 3500000),
            ("3,500,000", 3500000),
            ("3.500.000đ", 3500000),
            (3500000.0, 3500000),
            ("+3500000", 3500000),
        ],
    )
    def test_string_and_float_amounts(self, value, expected):
        assert parse_sepay(payload(transferAmount=value)).amount == expected

    @pytest.mark.parametrize(
        "value", [0, "0", -1000, "-1000", None, "", "abc", float("nan"), float("inf"), True, [1], {"v": 1}, 10**16]
    )
    def test_bad_amount(self, value):
        with pytest.raises(ParseError):
            parse_sepay(payload(transferAmount=value))

    def test_missing_amount(self):
        p = payload()
        del p["transferAmount"]
        with pytest.raises(ParseError):
            parse_sepay(p)

    def test_missing_id(self):
        p = payload()
        del p["id"]
        with pytest.raises(ParseError):
            parse_sepay(p)

    @pytest.mark.parametrize("value", [None, "", "abc", -5, True, 1.5, [1], "١٢"])
    def test_bad_id(self, value):
        with pytest.raises(ParseError):
            parse_sepay(payload(id=value))

    def test_string_id(self):
        assert parse_sepay(payload(id="92704")).external_id == "92704"

    @pytest.mark.parametrize(
        "value",
        [
            None,
            "",
            "14/10/2026 09:59:00",
            "2026-13-01 00:00:00",
            "2026-10-14",
            "not a date",
            "0001-01-01 00:00:00",  # tràn khi đổi sang UTC
            1760410740,
            ["2026-10-14 09:59:00"],
        ],
    )
    def test_bad_date(self, value):
        with pytest.raises(ParseError):
            parse_sepay(payload(transactionDate=value))

    def test_missing_date(self):
        p = payload()
        del p["transactionDate"]
        with pytest.raises(ParseError):
            parse_sepay(p)

    def test_date_variants(self):
        tx = parse_sepay(payload(transactionDate="2026-10-14T09:59:00"))
        assert tx.bank_time == datetime(2026, 10, 14, 2, 59, tzinfo=UTC)
        assert tx.time_precision == "second"
        tx = parse_sepay(payload(transactionDate="2026-10-14 09:59"))
        assert tx.bank_time == datetime(2026, 10, 14, 2, 59, tzinfo=UTC)
        assert tx.time_precision == "minute"

    @pytest.mark.parametrize("value", ["IN", " Out ", "in"])
    def test_transfer_type_case(self, value):
        assert parse_sepay(payload(transferType=value)).direction == value.strip().lower()

    @pytest.mark.parametrize("value", [None, "", "credit", 1, True])
    def test_bad_transfer_type(self, value):
        with pytest.raises(ParseError):
            parse_sepay(payload(transferType=value))

    def test_description_prefers_content(self):
        assert parse_sepay(payload(content="A", description="B")).description == "A"
        assert parse_sepay(payload(content="", description="B")).description == "B"
        assert parse_sepay(payload(content=None, description="B")).description == "B"
        assert parse_sepay(payload(content=None, description=None)).description == ""

    def test_sub_account_fallback(self):
        tx = parse_sepay(payload(accountNumber=None, subAccount="VQR0123456789"))
        assert tx.account_number == "0123456789"
        assert tx.meta["sub_account"] == "VQR0123456789"
        tx = parse_sepay(payload(accountNumber="", subAccount="999888"))
        assert tx.account_number == "999888"
        # Có accountNumber thì ưu tiên accountNumber.
        assert parse_sepay(payload(subAccount="999888")).account_number == "0123456789"

    def test_account_number_as_int(self):
        assert parse_sepay(payload(accountNumber=123456789)).account_number == "123456789"

    def test_no_account_number(self):
        tx = parse_sepay(payload(accountNumber=None, subAccount=None))
        assert tx.account_number is None
        assert tx.account_last4 is None

    @pytest.mark.parametrize("value", ["", None, "   "])
    def test_empty_reference(self, value):
        assert parse_sepay(payload(referenceCode=value)).reference_code is None

    def test_unknown_gateway(self):
        assert parse_sepay(payload(gateway="Ngân hàng Lạ")).bank == "NGANHANGLA"
        assert parse_sepay(payload(gateway=None)).bank is None

    def test_extra_and_missing_optional_fields(self):
        p = {
            "id": 1,
            "transactionDate": "2026-10-14 09:59:00",
            "transferType": "in",
            "transferAmount": 1000,
            "somethingNew": {"nested": [1, 2, 3]},
        }
        tx = parse_sepay(p)
        assert tx.amount == 1000
        assert tx.bank is None
        assert tx.description == ""
        assert tx.balance_after is None

    @pytest.mark.parametrize(
        "field", ["gateway", "accountNumber", "subAccount", "code", "content", "description", "referenceCode"]
    )
    @pytest.mark.parametrize("value", [{"a": 1}, [1], True, 1.5])
    def test_wrong_types_are_parse_errors(self, field, value):
        with pytest.raises(ParseError):
            parse_sepay(payload(**{field: value}))

    @pytest.mark.parametrize("value", [None, [], "x", 1, [payload()]])
    def test_payload_not_dict(self, value):
        with pytest.raises(ParseError):
            parse_sepay(value)  # type: ignore[arg-type]
