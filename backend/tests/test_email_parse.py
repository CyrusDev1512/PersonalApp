"""parse_email_message trên các email tổng hợp trong tests/fixtures/emails (không phải email thật)."""

from __future__ import annotations

import hashlib
from datetime import UTC, datetime
from email.message import EmailMessage
from pathlib import Path

import pytest

from app.ingest.email_parse import EmailParseResult, auth_results_pass, parse_email_message
from app.ingest.parsers.base import BankParser, ParsedTx

FIXTURES = Path(__file__).parent / "fixtures" / "emails"
BANK_DOMAINS = {"VCB": ["vietcombank.com.vn"], "MB": ["mbbank.com.vn"]}
RECEIVED_AT = datetime(2026, 10, 14, 9, 0, tzinfo=UTC)
GOOD_AUTH = "mx.google.com; dkim=pass header.d=vietcombank.com.vn; dmarc=pass header.from=vietcombank.com.vn"


def load(name: str) -> bytes:
    return (FIXTURES / f"{name}.eml").read_bytes()


def parse(raw: bytes, *, require_dkim: bool = True, bank_domains=None, **kw) -> EmailParseResult:
    return parse_email_message(raw, bank_domains or BANK_DOMAINS, require_dkim, RECEIVED_AT, **kw)


def utc(*args) -> datetime:
    return datetime(*args, tzinfo=UTC)


def make_email(
    body: str = "Số tiền: -100.000 VND\nThời gian: 14/10/2026 10:20:30",
    *,
    sender: str = "Vietcombank <noreply@vietcombank.com.vn>",
    auth: tuple[str, ...] = (GOOD_AUTH,),
    date: str | None = "Wed, 14 Oct 2026 10:21:00 +0700",
    message_id: str | None = "<abc-123@example.invalid>",
    subject: str = "Thông báo giao dịch",
    html: bool = False,
    extra: tuple[tuple[str, str], ...] = (),
) -> bytes:
    msg = EmailMessage()
    for value in auth:
        msg["Authentication-Results"] = value
    for key, value in extra:
        msg[key] = value
    msg["From"] = sender
    msg["To"] = "nguoidung@example.invalid"
    msg["Subject"] = subject
    if date:
        msg["Date"] = date
    if message_id:
        msg["Message-ID"] = message_id
    msg.set_content(body, subtype="html" if html else "plain")
    return msg.as_bytes()


# ---------------------------------------------------------------------------
# Email mẫu tổng hợp
# ---------------------------------------------------------------------------

# name -> (bank, direction, amount, balance, account_number, last4, bank_time_utc, precision, ref, counter, desc)
PARSED = {
    "vcb_credit_table_html": (
        "VCB", "in", 1_000_000, 11_000_000, "0011001234567", "4567", utc(2026, 10, 14, 3, 20, 30), "second",
        "5123ABC987", None, "NGUYEN VAN B chuyen tien an trua",
    ),
    "vcb_receipt_transfer_out": (
        "VCB", "out", 3_000_000, None, "0011001234567", "4567", utc(2026, 10, 14, 2, 15), "minute",
        "5012ABCD1234", "0123456789", "NGUYEN VAN A chuyen tien tro thang 10",
    ),
    "vcb_sms_style_in": (
        "VCB", "in", 2_500_000, 12_500_000, None, None, utc(2026, 10, 14, 1, 5, 11), "second",
        "MBVCB.12345678", None, "MBVCB.12345678.CT tu 0123456789 NGUYEN VAN B toi 0011004xxxxxx NGUYEN VAN A",
    ),
    "vcb_debit_decimals_qp": (
        "VCB", "out", 250_000, 9_750_000, None, "4567", utc(2026, 10, 14, 5, 1, 2), "second",
        None, None, "THANH TOAN HOA DON DIEN EVN",
    ),
    "vcb_dmarc_only": (
        "VCB", "out", 75_000, None, "0011001234567", "4567", utc(2026, 10, 14, 11, 30), "second",
        None, None, "GRAB*RIDE",
    ),
    "vcb_plain_points_to_html": (
        "VCB", "out", 3_500_000, 6_500_000, "0011001234567", "4567", utc(2026, 10, 14, 13, 5), "second",
        None, None, "RUT TIEN ATM",
    ),
    "mb_line_out": (
        "MB", "out", 500_000, 6_500_000, None, "1234", utc(2026, 10, 14, 3, 20), "minute",
        None, None, "THANH TOAN QR GRABFOOD",
    ),
    "mb_line_in_no_balance": (
        "MB", "in", 5_000_000, None, None, "1234", utc(2026, 10, 14, 2, 0), "minute",
        None, None, "CTY ABC TRA LUONG T10",
    ),
    "mb_html_base64": (
        "MB", "in", 1_200_000, 7_700_000, "0123456789", "6789", utc(2026, 10, 14, 4, 45), "second",
        "FT26287123456", None, "TRAN THI B hoan tien an trua",
    ),
    "mb_keyword_direction": (
        "MB", "out", 150_000, None, "0123456789", "6789", utc(2026, 10, 14, 3, 20), "minute",
        None, None, "PHI DICH VU SMS BANKING",
    ),
    "mb_multiple_auth_results": (
        "MB", "out", 200_000, 6_300_000, None, "1234", utc(2026, 10, 14, 6, 0), "minute",
        None, None, "DIEN THOAI",
    ),
    "mb_date_header_fallback": (
        "MB", "out", 120_000, 6_380_000, None, "1234", utc(2026, 10, 14, 8, 30), "approx",
        None, None, "GRAB",
    ),
    "mb_no_date_received_fallback": (
        "MB", "out", 80_000, 6_300_000, None, "1234", RECEIVED_AT, "approx",
        None, None, "CAFE",
    ),
}  # fmt: skip


@pytest.mark.parametrize("name", sorted(PARSED))
def test_fixture_parsed(name):
    bank, direction, amount, balance, number, last4, when, precision, ref, counter, desc = PARSED[name]
    result = parse(load(name))
    assert (result.status, result.reason, result.bank) == ("parsed", None, bank)
    assert result.message_id == f"synthetic-{name}@example.invalid"
    assert result.subject
    assert len(result.txs) == 1
    tx = result.txs[0]
    assert tx.source == "email"
    assert tx.external_id == f"synthetic-{name}@example.invalid"
    assert tx.bank == bank
    assert (tx.direction, tx.amount, tx.balance_after) == (direction, amount, balance)
    assert (tx.account_number, tx.account_last4) == (number, last4)
    assert (tx.bank_time, tx.time_precision) == (when, precision)
    assert tx.bank_time.tzinfo is not None
    assert (tx.reference_code, tx.counter_account, tx.description) == (ref, counter, desc)
    assert tx.meta["email_from"].endswith(("vietcombank.com.vn", "mbbank.com.vn"))


@pytest.mark.parametrize(
    ("name", "status", "reason"),
    [
        ("forged_sender_lookalike", "ignored", "sender"),
        ("other_sender", "ignored", "sender"),
        ("vcb_dkim_fail", "ignored", "auth"),
        ("vcb_dkim_other_domain", "ignored", "auth"),
        ("vcb_forged_auth_results_below", "ignored", "auth"),
        ("vcb_garbage_promo", "unparsed", "no amount"),
        ("vcb_direction_unknown", "unparsed", "direction"),
    ],
)
def test_fixture_not_parsed(name, status, reason):
    result = parse(load(name))
    assert (result.status, result.reason, result.txs) == (status, reason, [])
    assert result.message_id == f"synthetic-{name}@example.invalid"


def test_fixture_multi_tx_suffix():
    result = parse(load("mb_multi"))
    assert result.status == "parsed"
    assert [t.external_id for t in result.txs] == [
        "synthetic-mb_multi@example.invalid#1",
        "synthetic-mb_multi@example.invalid#2",
    ]
    assert [(t.amount, t.balance_after, t.bank_time) for t in result.txs] == [
        (45_000, 6_955_000, utc(2026, 10, 14, 0, 30)),
        (55_000, 6_900_000, utc(2026, 10, 14, 5, 10)),
    ]


def test_fixture_missing_message_id_uses_sha256():
    raw = load("vcb_missing_message_id")
    result = parse(raw)
    digest = hashlib.sha256(raw).hexdigest()
    assert result.status == "parsed"
    assert result.message_id == digest
    assert result.txs[0].external_id == digest
    assert (result.txs[0].amount, result.txs[0].direction) == (30_000, "out")


def test_all_fixtures_never_raise_with_or_without_dkim():
    names = sorted(p.stem for p in FIXTURES.glob("*.eml"))
    assert len(names) >= 20
    for name in names:
        for require in (True, False):
            result = parse(load(name), require_dkim=require)
            assert result.status in ("parsed", "unparsed", "ignored")


# ---------------------------------------------------------------------------
# Người gửi / xác thực
# ---------------------------------------------------------------------------


def test_dkim_not_required_accepts_failed_auth():
    result = parse(load("vcb_dkim_fail"), require_dkim=False)
    assert result.status == "parsed"
    assert (result.txs[0].direction, result.txs[0].amount) == ("in", 9_000_000)


def test_sender_check_applies_even_without_dkim():
    assert parse(load("forged_sender_lookalike"), require_dkim=False).reason == "sender"


def test_missing_auth_results_ignored():
    assert parse(make_email(auth=())).reason == "auth"
    assert parse(make_email(auth=()), require_dkim=False).status == "parsed"


def test_dkim_of_other_bank_not_accepted():
    raw = make_email(auth=("mx.google.com; dkim=pass header.d=mbbank.com.vn; dmarc=pass header.from=mbbank.com.vn",))
    assert parse(raw).reason == "auth"


def test_dkim_header_i_subdomain_accepted():
    raw = make_email(auth=("mx.google.com; dkim=pass header.i=@mail.vietcombank.com.vn header.s=s",))
    assert parse(raw).status == "parsed"


def test_auth_comment_cannot_smuggle_pass():
    value = "mx.google.com; dkim=fail (dkim=pass header.d=vietcombank.com.vn) header.d=vietcombank.com.vn"
    assert not auth_results_pass(value, ["vietcombank.com.vn"])
    assert auth_results_pass("mx; DKIM=Pass Header.D=VietcomBank.com.vn", ["vietcombank.com.vn"])
    assert not auth_results_pass("mx; spf=pass smtp.mailfrom=vietcombank.com.vn", ["vietcombank.com.vn"])


@pytest.mark.parametrize(
    "sender",
    [
        "noreply@vietcombank.com.vn.attacker.example",
        "noreply@fakevietcombank.com.vn",
        "Vietcombank noreply@vietcombank.com.vn <attacker@evil.example>",
        "noreply@vietcombank.com.vn, other@vietcombank.com.vn",
        "not-an-address",
    ],
)
def test_sender_rejected(sender):
    assert parse(make_email(sender=sender)).reason == "sender"


def test_multiple_from_headers_rejected():
    raw = make_email()
    head, sep, body = raw.partition(b"\n\n")
    raw = head + b"\nFrom: Attacker <a@evil.example>" + sep + body
    assert parse(raw).reason == "sender"


def test_custom_bank_domains_and_canonical_code():
    raw = make_email(
        sender="Ngan hang <alerts@notify.vcb-alt.example>",
        auth=("mx.google.com; dkim=pass header.d=vcb-alt.example",),
    )
    result = parse(raw, bank_domains={"Vietcombank": ["vcb-alt.example"]})
    assert (result.status, result.bank, result.txs[0].bank) == ("parsed", "VCB", "VCB")


# ---------------------------------------------------------------------------
# Thời gian
# ---------------------------------------------------------------------------


def test_body_time_far_from_date_header_uses_header():
    raw = make_email("Số tiền: -100.000 VND\nThời gian: 01/01/2026 10:00:00")
    tx = parse(raw).txs[0]
    assert (tx.bank_time, tx.time_precision) == (utc(2026, 10, 14, 3, 21), "approx")


def test_date_only_body_same_day_uses_header():
    tx = parse(make_email("Số tiền: -100.000 VND\nNgày: 14/10/2026")).txs[0]
    assert (tx.bank_time, tx.time_precision) == (utc(2026, 10, 14, 3, 21), "approx")


def test_date_only_body_other_day_keeps_date():
    tx = parse(make_email("Số tiền: -100.000 VND\nNgày: 13/10/2026")).txs[0]
    assert (tx.bank_time, tx.time_precision) == (utc(2026, 10, 12, 17, 0), "date")


def test_invalid_date_header_falls_back_to_received_at():
    tx = parse(make_email("Số tiền: -100.000 VND", date="not a date")).txs[0]
    assert (tx.bank_time, tx.time_precision) == (RECEIVED_AT, "approx")


def test_naive_received_at_is_utc():
    raw = make_email("Số tiền: -100.000 VND", date=None)
    tx = parse_email_message(raw, BANK_DOMAINS, True, datetime(2026, 10, 14, 9, 0)).txs[0]
    assert tx.bank_time == RECEIVED_AT


# ---------------------------------------------------------------------------
# Không bao giờ raise
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "raw",
    [
        b"",
        b"\x00\xff\xfe garbage \x80\x81",
        b"From: noreply@vietcombank.com.vn\n\n",
        b"From: noreply@vietcombank.com.vn\nContent-Type: text/plain; charset=unknown-xyz\n\nS\xe1 ti\xe1n: -1.000 VND",
        b"From: noreply@vietcombank.com.vn\nContent-Type: multipart/mixed; boundary=x\n\n--x\n--x--",
        b"From: =?utf-8?b?!!!?= <noreply@vietcombank.com.vn>\nSubject: =?bad?=\nMessage-ID: \n\nGD: -1,000VND",
    ],
)
def test_malformed_input_never_raises(raw):
    for require in (True, False):
        result = parse(raw, require_dkim=require)
        assert result.status in ("parsed", "unparsed", "ignored")
        assert result.message_id


def test_unknown_charset_still_parsed():
    raw = (
        b"From: noreply@vietcombank.com.vn\nMessage-ID: <x@y>\n"
        b"Content-Type: text/plain; charset=unknown-xyz\n\nGD: -1,000VND 14/10/26 10:20"
    )
    result = parse(raw, require_dkim=False)
    assert result.status == "parsed"
    assert (result.txs[0].amount, result.txs[0].direction) == (1_000, "out")


class _BoomParser(BankParser):
    bank = "VCB"

    def parse(self, subject: str, text: str) -> list[ParsedTx]:
        raise RuntimeError("boom")


class _BadAmountParser(BankParser):
    bank = "VCB"

    def parse(self, subject: str, text: str) -> list[ParsedTx]:
        return [ParsedTx(direction="out", amount=-5)]


def test_parser_exception_becomes_unparsed():
    result = parse(make_email(), parsers=[_BoomParser()])
    assert result.status == "unparsed"
    assert result.reason == "error: RuntimeError: boom"
    assert (result.bank, result.message_id) == ("VCB", "abc-123@example.invalid")


def test_invalid_parsed_tx_becomes_unparsed():
    result = parse(make_email(), parsers=[_BadAmountParser()])
    assert result.status == "unparsed"
    assert result.reason.startswith("error: ValueError")
