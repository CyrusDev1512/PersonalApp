"""Test adapter Casso V2: chữ ký bằng vector mẫu chính thức và chuẩn hoá payload."""

from __future__ import annotations

import copy
import hashlib
import hmac
import json
import random
from datetime import UTC, datetime
from pathlib import Path

import pytest

from app.config import Settings
from app.ingest.casso import NOT_CONFIGURED, parse_casso, verify_casso
from app.ingest.schema import AuthError, NormalizedTx, ParseError

FIXTURES = Path(__file__).parent / "fixtures"
# Vector chính thức (python.py/php.php/golang.go/java.java/dotnet.cs trong CassoHQ/casso-webhook-v2-verify-signature).
OFFICIAL = json.loads((FIXTURES / "casso_official_vpb_sample.json").read_text(encoding="utf-8"))
# Payload thật từ javascript.js (chữ ký upstream lỗi, xem _note trong fixture).
OFFICIAL_JS = json.loads((FIXTURES / "casso_official_mbb_sample.json").read_text(encoding="utf-8"))

RECEIVED_AT = datetime(2026, 10, 14, 3, 0, 0, tzinfo=UTC)  # 10:00 ICT ngày 14/10


def make_settings(key: str) -> Settings:
    return Settings(_env_file=None, app_token="x" * 32, casso_secure_key=key)


def raw(body, **dumps_kwargs) -> bytes:
    return json.dumps(body, **dumps_kwargs).encode("utf-8")


def sort_deep(obj):
    if isinstance(obj, dict):
        return {k: sort_deep(obj[k]) for k in sorted(obj)}
    if isinstance(obj, list):
        return [sort_deep(x) for x in obj]
    return obj


def sign(body, key: str, t: int = 1760410800000, ensure_ascii: bool = True) -> str:
    msg = f"{t}." + json.dumps(sort_deep(body), separators=(",", ":"), ensure_ascii=ensure_ascii)
    v1 = hmac.new(key.encode(), msg.encode("utf-8"), hashlib.sha512).hexdigest()
    return f"t={t},v1={v1}"


# ---------------------------------------------------------------------------
# verify_casso — vector chính thức
# ---------------------------------------------------------------------------


class TestOfficialVectors:
    key = OFFICIAL["checksum_key"]
    header = OFFICIAL["signature_header"]
    body = OFFICIAL["body"]

    def test_official_vector_accepted(self):
        verify_casso({"X-Casso-Signature": self.header}, raw(self.body), make_settings(self.key))

    def test_official_vector_compact_and_pretty_bodies(self):
        settings = make_settings(self.key)
        for body_bytes in (
            raw(self.body, separators=(",", ":")),
            raw(self.body, indent=2),
            raw(self.body, ensure_ascii=False),
            b"\n  " + raw(self.body) + b"\r\n",
        ):
            verify_casso({"X-Casso-Signature": self.header}, body_bytes, settings)

    def test_official_vector_key_order_irrelevant(self):
        rnd = random.Random(42)
        data_items = list(self.body["data"].items())
        rnd.shuffle(data_items)
        shuffled = {"data": dict(data_items), "error": 0}
        verify_casso({"X-Casso-Signature": self.header}, raw(shuffled), make_settings(self.key))

    @pytest.mark.parametrize("name", ["x-casso-signature", "X-CASSO-SIGNATURE", "X-Casso-Signature"])
    def test_header_name_case_insensitive(self, name):
        verify_casso({name: self.header}, raw(self.body), make_settings(self.key))

    def test_starlette_headers_mapping(self):
        from starlette.datastructures import Headers

        headers = Headers(raw=[(b"x-casso-signature", self.header.encode())])
        verify_casso(headers, raw(self.body), make_settings(self.key))

    def test_uppercase_hex_and_spaces_accepted(self):
        t, v1 = self.header.split(",")
        header = f" {t} , v1={v1.split('=', 1)[1].upper()} "
        verify_casso({"X-Casso-Signature": header}, raw(self.body), make_settings(self.key))

    @pytest.mark.parametrize(
        "mutate",
        [
            lambda b: b["data"].__setitem__("amount", 5990000),
            lambda b: b["data"].__setitem__("amount", -599000),
            lambda b: b["data"].__setitem__("accountNumber", "88888889"),
            lambda b: b["data"].__setitem__("description", "giao dich thu nghiem "),
            lambda b: b["data"].__setitem__("extra", 1),
            lambda b: b["data"].pop("virtualAccountName"),
            lambda b: b.__setitem__("error", 1),
            lambda b: b["data"].__setitem__("id", "0"),
        ],
    )
    def test_tampered_body_rejected(self, mutate):
        body = copy.deepcopy(self.body)
        mutate(body)
        with pytest.raises(AuthError):
            verify_casso({"X-Casso-Signature": self.header}, raw(body), make_settings(self.key))

    def test_tampered_signature_rejected(self):
        t, v1 = self.header.split(",")
        hexsig = v1.split("=", 1)[1]
        flipped = hexsig[:-1] + ("0" if hexsig[-1] != "0" else "1")
        with pytest.raises(AuthError):
            verify_casso({"X-Casso-Signature": f"{t},v1={flipped}"}, raw(self.body), make_settings(self.key))

    def test_tampered_timestamp_rejected(self):
        v1 = self.header.split(",")[1]
        with pytest.raises(AuthError):
            verify_casso({"X-Casso-Signature": f"t=1727948258789,{v1}"}, raw(self.body), make_settings(self.key))

    def test_wrong_key_rejected(self):
        with pytest.raises(AuthError) as exc:
            verify_casso({"X-Casso-Signature": self.header}, raw(self.body), make_settings(self.key[:-1] + "X"))
        assert str(exc.value) != NOT_CONFIGURED

    def test_empty_key_not_configured(self):
        with pytest.raises(AuthError) as exc:
            verify_casso({"X-Casso-Signature": self.header}, raw(self.body), make_settings(""))
        assert str(exc.value) == NOT_CONFIGURED

    def test_extra_v1_entries(self):
        # Nhiều v1 (vd. lúc xoay khoá): chỉ cần một cái khớp.
        bogus = "v1=" + "a" * 128
        header = f"{self.header},{bogus}"
        verify_casso({"X-Casso-Signature": header}, raw(self.body), make_settings(self.key))
        t, v1 = self.header.split(",")
        verify_casso({"X-Casso-Signature": f"{t},{bogus},{v1}"}, raw(self.body), make_settings(self.key))

    def test_js_sample_matches_js_reference_output(self):
        # Chữ ký code mẫu JS chính thức (Node 22) tự tính cho payload MBBank — cùng thuật toán với ta.
        body = OFFICIAL_JS["body"]
        header = f"t={OFFICIAL_JS['timestamp']},v1={OFFICIAL_JS['js_generated_v1']}"
        verify_casso({"X-Casso-Signature": header}, raw(body), make_settings(OFFICIAL_JS["checksum_key"]))

    def test_js_sample_upstream_signature_is_inconsistent(self):
        # Chữ ký in sẵn trong javascript.js không khớp ngay cả với code JS chính thức -> ta cũng từ chối.
        body = OFFICIAL_JS["body"]
        with pytest.raises(AuthError):
            verify_casso(
                {"X-Casso-Signature": OFFICIAL_JS["signature_header_upstream"]},
                raw(body),
                make_settings(OFFICIAL_JS["checksum_key"]),
            )


# ---------------------------------------------------------------------------
# verify_casso — header/body lỗi và các biến thể tuần tự hoá
# ---------------------------------------------------------------------------

KEY = "my-casso-secure-key-0123456789abcdef"


def tx_body(**data_overrides):
    data = {
        "id": 1234567,
        "reference": "FT26287000001",
        "description": "Thanh toán tiền phòng tháng 11",
        "amount": -3000000,
        "runningBalance": 7000000,
        "transactionDateTime": "2026-10-14 09:59:00",
        "accountNumber": "0123456789",
        "bankName": "Vietcombank",
        "bankAbbreviation": "VCB",
        "virtualAccountNumber": "",
        "virtualAccountName": "",
        "counterAccountName": "NGUYEN VAN B",
        "counterAccountNumber": "9704229999",
        "counterAccountBankId": "970422",
        "counterAccountBankName": "MBBank",
    }
    data.update(data_overrides)
    return {"error": 0, "data": data}


class TestVerify:
    @pytest.mark.parametrize("ensure_ascii", [True, False])
    def test_non_ascii_both_variants(self, ensure_ascii):
        body = tx_body()
        header = sign(body, KEY, ensure_ascii=ensure_ascii)
        verify_casso({"X-Casso-Signature": header}, raw(body, ensure_ascii=False), make_settings(KEY))
        verify_casso({"X-Casso-Signature": header}, raw(body, ensure_ascii=True), make_settings(KEY))

    def test_nested_and_list_data(self):
        body = {"error": 0, "data": [tx_body()["data"], tx_body(id=7, amount=50000)["data"]]}
        header = sign(body, KEY)
        verify_casso({"X-Casso-Signature": header}, raw(body), make_settings(KEY))

    def test_list_data_official_python_style(self):
        # Mẫu Python chính thức không sắp dict nằm trong list -> cũng chấp nhận.
        body = {"error": 0, "data": [{"z": 1, "a": 2}]}
        msg = "1760410800000." + json.dumps({"data": [{"z": 1, "a": 2}], "error": 0}, separators=(",", ":"))
        v1 = hmac.new(KEY.encode(), msg.encode(), hashlib.sha512).hexdigest()
        verify_casso({"X-Casso-Signature": f"t=1760410800000,v1={v1}"}, raw(body), make_settings(KEY))

    def test_leading_zero_timestamp_normalised(self):
        body = tx_body()
        header = sign(body, KEY, t=1760410800000).replace("t=", "t=00")
        verify_casso({"X-Casso-Signature": header}, raw(body), make_settings(KEY))

    def test_signature_from_other_key_rejected(self):
        body = tx_body()
        with pytest.raises(AuthError):
            verify_casso({"X-Casso-Signature": sign(body, "other")}, raw(body), make_settings(KEY))

    def test_sha256_signature_rejected(self):
        body = tx_body()
        msg = "1760410800000." + json.dumps(sort_deep(body), separators=(",", ":"))
        v1 = hmac.new(KEY.encode(), msg.encode(), hashlib.sha256).hexdigest()
        with pytest.raises(AuthError):
            verify_casso({"X-Casso-Signature": f"t=1760410800000,v1={v1}"}, raw(body), make_settings(KEY))

    @pytest.mark.parametrize(
        "header",
        [
            "",
            "   ",
            "garbage",
            "t=1760410800000",
            "v1=" + "a" * 128,
            "t=abc,v1=" + "a" * 128,
            "t=,v1=" + "a" * 128,
            "t=-1,v1=" + "a" * 128,
            "t=1.5,v1=" + "a" * 128,
            "t=١٢٣,v1=" + "a" * 128,
            "t=1,t=2,v1=" + "a" * 128,
            "t=1760410800000,v1=",
            "t=1760410800000,v1=" + "a" * 127,
            "t=1760410800000,v1=" + "a" * 129,
            "t=1760410800000,v1=" + "g" * 128,
            "t=1760410800000;v1=" + "a" * 128,
            "t=1760410800000,v1=" + "a" * 128 + ",junk",
            "t=" + "9" * 30 + ",v1=" + "a" * 128,
        ],
    )
    def test_malformed_header_rejected(self, header):
        with pytest.raises(AuthError) as exc:
            verify_casso({"X-Casso-Signature": header}, raw(tx_body()), make_settings(KEY))
        assert str(exc.value) != NOT_CONFIGURED

    def test_missing_header_rejected(self):
        with pytest.raises(AuthError):
            verify_casso({}, raw(tx_body()), make_settings(KEY))

    @pytest.mark.parametrize("body", [b"", b"not json", b"{", b"\xff\xfe\x00", b"[" * 100000])
    def test_invalid_body_rejected(self, body):
        with pytest.raises(AuthError):
            verify_casso({"X-Casso-Signature": "t=1,v1=" + "a" * 128}, body, make_settings(KEY))

    def test_empty_key_checked_before_header(self):
        with pytest.raises(AuthError) as exc:
            verify_casso({}, b"", make_settings(""))
        assert str(exc.value) == NOT_CONFIGURED


# ---------------------------------------------------------------------------
# parse_casso
# ---------------------------------------------------------------------------


class TestParse:
    def test_official_test_payload(self):
        txs = parse_casso(OFFICIAL["body"], RECEIVED_AT)
        assert len(txs) == 1
        tx = txs[0]
        assert isinstance(tx, NormalizedTx)
        assert tx.source == "casso"
        assert tx.external_id == "0"
        assert tx.is_test is True
        assert tx.direction == "in"
        assert tx.amount == 599000
        assert tx.balance_after == 25000000
        assert tx.bank == "VPB"
        assert tx.account_number == "88888888"
        assert tx.account_last4 == "8888"
        assert tx.reference_code == "MA_GIAO_DICH_THU_NGHIEM"
        assert tx.description == "giao dich thu nghiem"
        assert tx.counter_name == "NGUYEN VAN A"
        assert tx.counter_account == "8888888888"
        assert tx.meta["counter_bank_id"] == "970415"
        assert tx.meta["counter_bank_name"] == "VietinBank"
        assert tx.meta["bank_name"] == "VPBank"
        assert "virtual_account_number" not in tx.meta  # chuỗi rỗng bị bỏ
        # 15:06:37 giờ VN = 08:06:37 UTC
        assert tx.bank_time == datetime(2024, 10, 3, 8, 6, 37, tzinfo=UTC)
        assert tx.time_precision == "second"

    def test_official_mbbank_payload(self):
        (tx,) = parse_casso(OFFICIAL_JS["body"], RECEIVED_AT)
        assert tx.external_id == "218897"
        assert tx.is_test is False
        assert tx.bank == "MB"  # bankAbbreviation "MBB" -> MB
        assert tx.direction == "in"
        assert tx.amount == 16775000
        assert tx.balance_after == 16775000
        assert tx.reference_code == "FT24364030863634"
        assert tx.counter_name is None
        assert tx.counter_account is None
        assert tx.bank_time == datetime(2024, 12, 23, 0, 0, 0, tzinfo=UTC)

    def test_test_account_with_nonzero_id(self):
        (tx,) = parse_casso(tx_body(id=99, accountNumber="88888888"), RECEIVED_AT)
        assert tx.is_test is True
        (tx,) = parse_casso(tx_body(id="0"), RECEIVED_AT)
        assert tx.is_test is True

    def test_outgoing_negative_amount(self):
        (tx,) = parse_casso(tx_body(), RECEIVED_AT)
        assert tx.direction == "out"
        assert tx.amount == 3000000
        assert tx.balance_after == 7000000
        assert tx.bank == "VCB"
        assert tx.is_test is False
        assert tx.description == "Thanh toán tiền phòng tháng 11"
        assert tx.counter_account == "9704229999"
        assert tx.bank_time == datetime(2026, 10, 14, 2, 59, tzinfo=UTC)

    @pytest.mark.parametrize(
        "value, direction, amount",
        [
            ("-3000000", "out", 3000000),
            ("3.000.000", "in", 3000000),
            ("-3.000.000", "out", 3000000),
            (3000000.0, "in", 3000000),
            ("3000000.00", "in", 3000000),
        ],
    )
    def test_string_amounts(self, value, direction, amount):
        (tx,) = parse_casso(tx_body(amount=value), RECEIVED_AT)
        assert (tx.direction, tx.amount) == (direction, amount)

    @pytest.mark.parametrize("value", [0, "0", None, ""])
    def test_running_balance_unknown(self, value):
        (tx,) = parse_casso(tx_body(runningBalance=value), RECEIVED_AT)
        assert tx.balance_after is None

    def test_running_balance_missing(self):
        body = tx_body()
        del body["data"]["runningBalance"]
        (tx,) = parse_casso(body, RECEIVED_AT)
        assert tx.balance_after is None

    def test_bank_abbreviation_preferred_then_name(self):
        (tx,) = parse_casso(tx_body(bankAbbreviation="MBB", bankName="Vietcombank"), RECEIVED_AT)
        assert tx.bank == "MB"
        (tx,) = parse_casso(tx_body(bankAbbreviation="", bankName="MBBank"), RECEIVED_AT)
        assert tx.bank == "MB"
        (tx,) = parse_casso(tx_body(bankAbbreviation=None, bankName=None), RECEIVED_AT)
        assert tx.bank is None

    def test_data_list(self):
        body = {
            "error": 0,
            "data": [tx_body(id=1)["data"], tx_body(id=2, amount=0)["data"], tx_body(id=3, amount=50000)["data"]],
        }
        txs = parse_casso(body, RECEIVED_AT)
        assert [t.external_id for t in txs] == ["1", "3"]
        assert [t.direction for t in txs] == ["out", "in"]

    def test_zero_amount_only_raises(self):
        with pytest.raises(ParseError):
            parse_casso(tx_body(amount=0), RECEIVED_AT)
        with pytest.raises(ParseError):
            parse_casso({"error": 0, "data": [tx_body(amount=0)["data"]]}, RECEIVED_AT)

    def test_empty_list_raises(self):
        with pytest.raises(ParseError):
            parse_casso({"error": 0, "data": []}, RECEIVED_AT)

    @pytest.mark.parametrize("error", [1, -1, "1", True, None, "error"])
    def test_error_nonzero(self, error):
        body = tx_body()
        body["error"] = error
        with pytest.raises(ParseError):
            parse_casso(body, RECEIVED_AT)

    def test_error_missing_tolerated(self):
        body = tx_body()
        del body["error"]
        assert len(parse_casso(body, RECEIVED_AT)) == 1

    @pytest.mark.parametrize("data", [None, "x", 1, ["x"], [None]])
    def test_bad_data(self, data):
        with pytest.raises(ParseError):
            parse_casso({"error": 0, "data": data}, RECEIVED_AT)

    def test_missing_data(self):
        with pytest.raises(ParseError):
            parse_casso({"error": 0}, RECEIVED_AT)

    @pytest.mark.parametrize("value", [None, [], "x", 1])
    def test_payload_not_dict(self, value):
        with pytest.raises(ParseError):
            parse_casso(value, RECEIVED_AT)  # type: ignore[arg-type]

    def test_missing_id(self):
        body = tx_body()
        del body["data"]["id"]
        with pytest.raises(ParseError):
            parse_casso(body, RECEIVED_AT)

    @pytest.mark.parametrize("value", [None, "", "abc", -1, True, 1.5])
    def test_bad_id(self, value):
        with pytest.raises(ParseError):
            parse_casso(tx_body(id=value), RECEIVED_AT)

    @pytest.mark.parametrize("value", [None, "abc", True, [1], {"a": 1}, float("nan"), 10**16])
    def test_bad_amount(self, value):
        with pytest.raises(ParseError):
            parse_casso(tx_body(amount=value), RECEIVED_AT)

    def test_bad_amount_in_list_fails_whole_payload(self):
        body = {"error": 0, "data": [tx_body(id=1)["data"], tx_body(id=2, amount="abc")["data"]]}
        with pytest.raises(ParseError):
            parse_casso(body, RECEIVED_AT)

    def test_date_only_same_ict_day_uses_received_at(self):
        (tx,) = parse_casso(tx_body(transactionDateTime="2026-10-14"), RECEIVED_AT)
        assert tx.time_precision == "date"
        assert tx.bank_time == RECEIVED_AT

    def test_date_only_same_ict_day_across_utc_midnight(self):
        # 23:30 UTC ngày 13/10 = 06:30 ICT ngày 14/10 -> cùng ngày ICT với giao dịch.
        received = datetime(2026, 10, 13, 23, 30, tzinfo=UTC)
        (tx,) = parse_casso(tx_body(transactionDateTime="2026-10-14"), received)
        assert tx.bank_time == received
        assert tx.time_precision == "date"

    def test_date_only_naive_received_at_is_utc(self):
        (tx,) = parse_casso(tx_body(transactionDateTime="2026-10-14"), RECEIVED_AT.replace(tzinfo=None))
        assert tx.bank_time == RECEIVED_AT

    def test_date_only_other_day_uses_noon_ict(self):
        (tx,) = parse_casso(tx_body(transactionDateTime="2026-10-12"), RECEIVED_AT)
        assert tx.time_precision == "date"
        assert tx.bank_time == datetime(2026, 10, 12, 5, 0, tzinfo=UTC)  # 12:00 ICT

    def test_datetime_variants(self):
        (tx,) = parse_casso(tx_body(transactionDateTime="2026-10-14T09:59:00"), RECEIVED_AT)
        assert (tx.bank_time, tx.time_precision) == (datetime(2026, 10, 14, 2, 59, tzinfo=UTC), "second")
        (tx,) = parse_casso(tx_body(transactionDateTime="2026-10-14 09:59"), RECEIVED_AT)
        assert (tx.bank_time, tx.time_precision) == (datetime(2026, 10, 14, 2, 59, tzinfo=UTC), "minute")

    @pytest.mark.parametrize(
        "value",
        [
            None,
            "",
            "14/10/2026 09:59:00",
            "2026-02-30 10:00:00",
            "2026-13-01",
            "yesterday",
            "0001-01-01 00:00:00",
            1760410740000,
            ["2026-10-14"],
        ],
    )
    def test_bad_datetime(self, value):
        with pytest.raises(ParseError):
            parse_casso(tx_body(transactionDateTime=value), RECEIVED_AT)

    def test_empty_strings_become_none(self):
        (tx,) = parse_casso(
            tx_body(reference="", counterAccountName="", counterAccountNumber=" ", description=None), RECEIVED_AT
        )
        assert tx.reference_code is None
        assert tx.counter_name is None
        assert tx.counter_account is None
        assert tx.description == ""

    def test_virtual_account_in_meta(self):
        (tx,) = parse_casso(tx_body(virtualAccountNumber="VA123", virtualAccountName="SHOP"), RECEIVED_AT)
        assert tx.meta["virtual_account_number"] == "VA123"
        assert tx.meta["virtual_account_name"] == "SHOP"

    def test_account_number_as_int(self):
        (tx,) = parse_casso(tx_body(accountNumber=123456789), RECEIVED_AT)
        assert tx.account_number == "123456789"

    def test_extra_fields_tolerated(self):
        body = tx_body(somethingNew={"x": [1, 2]})
        body["meta"] = {"version": 2}
        assert len(parse_casso(body, RECEIVED_AT)) == 1

    @pytest.mark.parametrize(
        "field",
        [
            "reference",
            "description",
            "accountNumber",
            "bankName",
            "bankAbbreviation",
            "virtualAccountNumber",
            "counterAccountName",
            "counterAccountNumber",
            "counterAccountBankId",
            "counterAccountBankName",
        ],
    )
    @pytest.mark.parametrize("value", [{"a": 1}, [1], True, 1.5])
    def test_wrong_types_are_parse_errors(self, field, value):
        with pytest.raises(ParseError):
            parse_casso(tx_body(**{field: value}), RECEIVED_AT)
