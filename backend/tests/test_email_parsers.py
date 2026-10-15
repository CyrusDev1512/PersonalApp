"""Parser email (chung + VCB + MB) trên văn bản tổng hợp."""

from __future__ import annotations

import random
from datetime import datetime

import pytest

from app.ingest.parsers.base import ParsedTx, domain_matches
from app.ingest.parsers.generic import GenericParser, fold, html_to_text, prepare
from app.ingest.parsers.mb import MbParser
from app.ingest.parsers.registry import GENERIC, build_parsers, parser_for, parser_for_domain
from app.ingest.parsers.vcb import VcbParser

generic = GenericParser()


def one(text: str, subject: str = "", parser=generic) -> ParsedTx:
    txs = parser.parse(subject, text)
    assert len(txs) == 1, txs
    return txs[0]


# ---------------------------------------------------------------------------
# Số tiền
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("text", "amount", "direction"),
    [
        ("Số tiền: 1.000.000 VND", 1_000_000, None),
        ("So tien: 1,000,000 VND", 1_000_000, None),
        ("Số tiền: 1.000.000,00 VND", 1_000_000, None),
        ("Số tiền: 1,000,000.00 VND", 1_000_000, None),
        ("Số tiền: 250000", 250_000, None),
        ("Số tiền giao dịch: 5 000 000 VND", 5_000_000, None),
        ("PS: +50.000đ", 50_000, "in"),
        ("GD: -500,000VND", 500_000, "out"),
        ("Phát sinh: \u2212120.000 VND", 120_000, "out"),
        ("Phát sinh: + 75.000 VNĐ", 75_000, "in"),
        ("Số tiền (VND): -30.000", 30_000, "out"),
        ("Giao dịch: +2.000.000 đồng", 2_000_000, "in"),
        ("Amount: 250,000 VND", 250_000, None),
        ("Số tiền:\n1.500.000 VND", 1_500_000, None),
        ("SỐ TIỀN: 99.000 VND", 99_000, None),
    ],
)
def test_amount_formats(text, amount, direction):
    tx = one(text)
    assert tx.amount == amount
    assert tx.direction == direction


def test_label_priority_and_denied_labels():
    text = (
        "Mã GD: 123456789\n"
        "Thời gian giao dịch: 14/10/2026 10:20\n"
        "Phí giao dịch: 11.000 VND\n"
        "Số tiền phí: 22.000 VND\n"
        "Số tiền bằng chữ: Hai trăm nghìn đồng\n"
        "Số tiền: 200.000 VND\n"
    )
    assert one(text).amount == 200_000


def test_gd_label_after_ma_gd():
    tx = one("Mã GD: 987654321 | GD: +1,000VND")
    assert (tx.amount, tx.direction) == (1_000, "in")


def test_signed_money_without_label_is_last_resort():
    tx = one("Tai khoan 0011xxx789 vua bien dong +300,000VND luc 14/10/2026 10:00")
    assert (tx.amount, tx.direction) == (300_000, "in")


@pytest.mark.parametrize(
    "text",
    [
        "",
        "   \n\n",
        "Xin chào, đây là email quảng cáo. Hoàn tiền 10% cho thẻ ghi nợ.",
        "Thời gian giao dịch: 14/10/2026 10:20:30",
        "Số tiền phí: 11.000 VND",
        "Số tài khoản: 0011001234567",
        "Số tiền: 0 VND",
        "Số tiền: 0011001234567",
        "Số tiền: 12/10/2026",
        "GD: 10:20",
    ],
)
def test_no_amount_returns_empty(text):
    assert generic.parse("", text) == []


def test_garbage_never_raises():
    rng = random.Random(1234)
    alphabet = "0123456789.,:+-|/<>đĐăâêôơưáàảãạ VNDSTGsdtkND\n\t&;#x"
    for _ in range(300):
        junk = "".join(rng.choice(alphabet) for _ in range(rng.randint(0, 400)))
        for parser in (generic, VcbParser(), MbParser()):
            result = parser.parse(junk[:20], junk)
            assert isinstance(result, list)
            for tx in result:
                assert tx.amount > 0
    huge = "9" * 100_000 + " Số tiền: " + "1," * 50_000
    assert isinstance(generic.parse("", huge), list)
    assert generic.parse(None, None) == []  # type: ignore[arg-type]
    assert isinstance(generic.parse("", "<" * 5000 + "<td>" * 5000 + "&#xffffffff;"), list)


# ---------------------------------------------------------------------------
# Chiều giao dịch
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("text", "subject", "direction"),
    [
        ("Loại giao dịch: Ghi có\nSố tiền: 100.000 VND", "", "in"),
        ("Loại giao dịch: Ghi nợ\nSố tiền: 100.000 VND", "", "out"),
        ("Type: Credit\nAmount: 100,000 VND", "", "in"),
        ("Type: Debit\nAmount: 100,000 VND", "", "out"),
        ("Số tiền ghi có: 100.000 VND", "", "in"),
        ("Số tiền: 100.000 VND (nhận tiền)", "", "in"),
        ("Số tiền: 100.000 VND", "Thông báo nhận tiền", "in"),
        ("Số tiền: 100.000 VND", "Số dư tài khoản tăng", "in"),
        ("Số tiền: 100.000 VND", "Thanh toán thành công", "out"),
        ("Số tiền: 100.000 VND", "Rút tiền ATM", "out"),
        ("Số tiền: 100.000 VND\nNội dung: chuyen tien di", "", "out"),
        # Từ khoá tiền ra thắng nhãn có dấu? Không — dấu luôn được ưu tiên.
        ("Loại giao dịch: Ghi có\nSố tiền: -100.000 VND", "", "out"),
    ],
)
def test_direction(text, subject, direction):
    assert one(text, subject).direction == direction


@pytest.mark.parametrize(
    "footer",
    [
        "Giao dịch thành công. Tên người nhận: TRAN THI B.",
        "Mở thẻ ghi nợ quốc tế ngay hôm nay! Công ty TNHH Mẫu, tầng 5.",
        "Quý khách nhận được email này vì đã đăng ký dịch vụ.",
        "Xác nhận giao dịch. Giám đốc chi nhánh.",
    ],
)
def test_footer_words_do_not_decide_direction(footer):
    tx = one(f"Số tiền: 100.000 VND\n{footer}", subject="Thông báo giao dịch")
    assert tx.direction is None


# ---------------------------------------------------------------------------
# Số dư, TK, thời gian, mã tham chiếu, nội dung
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("line", "balance"),
    [
        ("SD: 6,500,000VND", 6_500_000),
        ("Số dư: 6.500.000 VND", 6_500_000),
        ("Số dư cuối: 6.500.000,00 VND", 6_500_000),
        ("Số dư khả dụng: 6,500,000 VND", 6_500_000),
        ("Số dư TK 0011001234567: 6.500.000 VND", 6_500_000),
        ("SD TK 0011001234567: 6.500.000 VND", 6_500_000),
        ("Available balance: 6,500,000 VND", 6_500_000),
        ("Balance: 6,500,000", 6_500_000),
        ("Số dư đầu: 5.000.000 VND", None),
        ("Số dư: 0 VND", None),
        ("", None),
    ],
)
def test_balance(line, balance):
    tx = one(f"Số tiền: -100.000 VND\n{line}")
    assert tx.balance_after == balance


@pytest.mark.parametrize(
    ("line", "hint"),
    [
        ("Số tài khoản: 0011001234567", "0011001234567"),
        ("Tài khoản: 123xxx456", "123xxx456"),
        ("TK 0xxx1234", "0xxx1234"),
        ("TK: ******1234", "xxxxxx1234"),
        ("Account: 0011XXXX4567", "0011xxxx4567"),
        ("Tên tài khoản: NGUYEN VAN A", None),
    ],
)
def test_account_hint(line, hint):
    assert one(f"{line}\nSố tiền: -100.000 VND").account_hint == hint


def test_counter_account_depends_on_direction():
    text = "Tài khoản nguồn: 0011001234567\nTài khoản người hưởng: 0123456789\nSố tiền: -3.000.000 VND"
    tx = one(text)
    assert (tx.account_hint, tx.counter_account) == ("0011001234567", "0123456789")
    text_in = "Tài khoản nhận: 0011001234567\nTài khoản chuyển: 0123456789\nSố tiền: +3.000.000 VND"
    tx = one(text_in)
    assert (tx.account_hint, tx.counter_account) == ("0011001234567", "0123456789")


@pytest.mark.parametrize(
    ("line", "when", "precision"),
    [
        ("Thời gian: 14/10/2026 10:20:30", datetime(2026, 10, 14, 10, 20, 30), "second"),
        ("Thời gian: 14/10/2026 10:20", datetime(2026, 10, 14, 10, 20), "minute"),
        ("Ngày: 14-10-2026", datetime(2026, 10, 14), "date"),
        ("Lúc 10:20 14/10/2026", datetime(2026, 10, 14, 10, 20), "minute"),
        ("08:05:11 ngày 14/10/2026", datetime(2026, 10, 14, 8, 5, 11), "second"),
        ("luc 14-10-2026 08:05:11.", datetime(2026, 10, 14, 8, 5, 11), "second"),
        ("14/10/26 10:20", datetime(2026, 10, 14, 10, 20), "minute"),
        ("2026-10-14 10:20:30", datetime(2026, 10, 14, 10, 20, 30), "second"),
        ("Ngày: 31/02/2026", None, None),
        ("Không có thời gian", None, None),
    ],
)
def test_time_formats(line, when, precision):
    tx = one(f"Số tiền: -100.000 VND\n{line}")
    assert (tx.when, tx.when_precision) == (when, precision)


def test_time_prefers_full_datetime_over_date_only():
    text = "Áp dụng từ 01/10/2026\nSố tiền: -100.000 VND\nThời gian giao dịch: 14/10/2026 10:20"
    assert one(text).when == datetime(2026, 10, 14, 10, 20)


def test_date_inside_description_ignored():
    text = "Số tiền: -100.000 VND\nNội dung: tra tien hang ngay 01/09/2026\nNgày: 14/10/2026"
    assert one(text).when == datetime(2026, 10, 14)


@pytest.mark.parametrize(
    ("line", "ref"),
    [
        ("Số tham chiếu: FT26287123456", "FT26287123456"),
        ("Mã giao dịch: 5012ABCD1234.", "5012ABCD1234"),
        ("Số GD: 998877", "998877"),
        ("Ref: MBVCB.12345678", "MBVCB.12345678"),
        ("Số tham chiếu: KHONGCOSO", None),
    ],
)
def test_reference(line, ref):
    assert one(f"Số tiền: -100.000 VND\n{line}").reference_code == ref


@pytest.mark.parametrize(
    ("line", "description"),
    [
        ("Nội dung: Chuyển tiền phòng tháng 11", "Chuyển tiền phòng tháng 11"),
        ("ND: COM TAM SANG", "COM TAM SANG"),
        ("Mô tả: GRAB*FOOD", "GRAB*FOOD"),
        ("Content: APPLE.COM/BILL", "APPLE.COM/BILL"),
        ("Nội dung giao dịch:\nTIEN DIEN T10", "TIEN DIEN T10"),
        ("Nội dung: TIEN NHA Số tham chiếu: FT123456", "TIEN NHA"),
        ("Quý khách vừa giao dịch với nội dung như sau", ""),
    ],
)
def test_description(line, description):
    assert one(f"Số tiền: -100.000 VND\n{line}").description == description


def test_amount_inside_description_not_used():
    tx = one("Nội dung: tra lai 50.000 VND tien thua\nSố tiền: -200.000 VND")
    assert tx.amount == 200_000
    assert generic.parse("", "ND: hoan 50.000 VND") == []


def test_accent_free_text():
    text = (
        "So TK: 0123456789\nSo tien: +1.000.000 VND\nSo du: 2.000.000 VND\nNoi dung: luong T10\nNgay 14/10/2026 09:00"
    )
    tx = one(text)
    assert (tx.amount, tx.direction, tx.balance_after, tx.account_hint) == (1_000_000, "in", 2_000_000, "0123456789")
    assert tx.description == "luong T10"


# ---------------------------------------------------------------------------
# Chuẩn hoá văn bản / HTML
# ---------------------------------------------------------------------------


def test_html_to_text_rows_cells_and_noise():
    html = (
        "<html><head><title>T</title><style>.a{}</style></head><body>"
        "<p>Xin&nbsp;chào<br>Quý&amp;khách</p>"
        "<table><tr><td>Số tiền</td><td> <b>1,000,000</b> VND</td></tr>"
        "<tr><td></td><td></td></tr><tr><th>Số dư</th><td>2,000,000 VND</td></tr></table>"
        "<script>alert('Số tiền: 9 VND')</script></body></html>"
    )
    assert html_to_text(html) == "Xin chào\nQuý&khách\nSố tiền | 1,000,000 VND\nSố dư | 2,000,000 VND"


def test_html_detected_in_parse():
    tx = one("<div>Số tiền: <b>-45.000</b> VND</div><div>Số dư: 1.000.000 VND</div>")
    assert (tx.amount, tx.direction, tx.balance_after) == (45_000, "out", 1_000_000)


def test_fold_keeps_length_and_strips_accents():
    s = "Số dư khả dụng: Đồng ý — Nguyễn Văn Ánh \u0301lẻ"
    assert len(fold(s)) == len(s)
    assert fold("Số dư khả dụng Đ") == "So du kha dung D"


def test_prepare_normalizes_nfd_and_spaces():
    nfd = "So\u0302\u0301 tie\u0302\u0300n:\u00a0\u00a0 100.000\u200b VND\r\n\r\n"
    doc = prepare(nfd)
    assert doc.text == "Số tiền: 100.000 VND"
    assert one(nfd).amount == 100_000


# ---------------------------------------------------------------------------
# VCB / MB
# ---------------------------------------------------------------------------


def test_vcb_sms_style():
    text = (
        "SD TK 0011004xxxxxx +2,500,000VND luc 14-10-2026 08:05:11. SD 12,500,000VND. "
        "Ref MBVCB.12345678.CT tu 0123456789 NGUYEN VAN B"
    )
    tx = one(text, parser=VcbParser())
    assert (tx.direction, tx.amount, tx.balance_after) == ("in", 2_500_000, 12_500_000)
    assert tx.account_hint == "0011004xxxxxx"
    assert (tx.when, tx.when_precision) == (datetime(2026, 10, 14, 8, 5, 11), "second")
    assert tx.reference_code == "MBVCB.12345678"
    assert tx.description.startswith("MBVCB.12345678.CT tu 0123456789")


def test_vcb_sms_style_multiple_and_debit():
    text = (
        "SD TK 0011004xxxxxx -45,000VND luc 14-10-2026 07:30:00. SD 1,955,000VND. Ref COM TAM\n"
        "SD TK 0011004xxxxxx -55,000VND luc 14-10-2026 12:10:00. SD 1,900,000VND. Ref BUN BO"
    )
    txs = VcbParser().parse("", text)
    assert [(t.direction, t.amount, t.balance_after, t.description) for t in txs] == [
        ("out", 45_000, 1_955_000, "COM TAM"),
        ("out", 55_000, 1_900_000, "BUN BO"),
    ]


def test_vcb_receipt_defaults_to_out():
    text = "Tài khoản nguồn: 0011001234567\nTài khoản người hưởng: 0123456789\nSố tiền: 3.000.000 VND"
    assert generic.parse("Biên lai chuyển tiền qua tài khoản", text)[0].direction is None
    tx = one(text, "Biên lai chuyển tiền qua tài khoản", parser=VcbParser())
    assert (tx.direction, tx.account_hint, tx.counter_account) == ("out", "0011001234567", "0123456789")


def test_vcb_falls_back_to_generic_format():
    tx = one("Số tài khoản: 0011001234567\nSố tiền: +1,000,000 VND\nSố dư cuối: 11,000,000 VND", parser=VcbParser())
    assert (tx.direction, tx.amount, tx.balance_after) == ("in", 1_000_000, 11_000_000)


def test_mb_line_format():
    text = "MB thong bao: TK 0xxx1234|GD: -500,000VND 14/10/26 10:20|SD: 6,500,000VND|ND: THANH TOAN QR GRABFOOD"
    tx = one(text, parser=MbParser())
    assert (tx.direction, tx.amount, tx.balance_after, tx.account_hint) == ("out", 500_000, 6_500_000, "0xxx1234")
    assert (tx.when, tx.when_precision) == (datetime(2026, 10, 14, 10, 20), "minute")
    assert tx.description == "THANH TOAN QR GRABFOOD"


def test_mb_multiple_lines_each_a_tx():
    text = (
        "Thông báo biến động số dư\n"
        "TK 0xxx1234|GD: -45,000VND 14/10/26 07:30|SD: 6,955,000VND|ND: COM TAM SANG\n"
        "TK 0xxx1234|GD: +1,000,000VND 14/10/26 08:00|SD: 7,955,000VND|ND: ME CHUYEN TIEN\n"
    )
    txs = MbParser().parse("", text)
    assert [(t.direction, t.amount, t.balance_after, t.description) for t in txs] == [
        ("out", 45_000, 6_955_000, "COM TAM SANG"),
        ("in", 1_000_000, 7_955_000, "ME CHUYEN TIEN"),
    ]


def test_mb_single_line_fills_missing_fields_from_whole_text():
    text = "TK 0xxx1234|GD: -120,000VND|SD: 6,380,000VND|ND: GRAB\nThời gian: 14/10/2026 15:30:00\nMã GD: FT26287000001"
    tx = one(text, parser=MbParser())
    assert (tx.when, tx.reference_code) == (datetime(2026, 10, 14, 15, 30), "FT26287000001")


def test_mb_falls_back_to_generic_table():
    tx = one("Tài khoản: 0123456789\nSố tiền giao dịch: +1.200.000 VND\nSố dư: 7.700.000 VND", parser=MbParser())
    assert (tx.direction, tx.amount, tx.balance_after) == ("in", 1_200_000, 7_700_000)


# ---------------------------------------------------------------------------
# Registry / domain
# ---------------------------------------------------------------------------


def test_registry_parser_for():
    assert isinstance(parser_for("VCB"), VcbParser)
    assert isinstance(parser_for("Vietcombank"), VcbParser)
    assert isinstance(parser_for("MB"), MbParser)
    assert isinstance(parser_for("MBBank"), MbParser)
    assert parser_for("TCB") is GENERIC
    assert parser_for(None) is GENERIC


def test_registry_domains_from_settings():
    parsers = build_parsers({"VCB": ["vcb-alt.example"], "MB": ["mbbank.com.vn", "mb-alt.example"]})
    vcb = parser_for("VCB", parsers)
    assert vcb.domains == ["vcb-alt.example"]
    assert vcb.matches("mail.vcb-alt.example")
    assert not vcb.matches("vietcombank.com.vn")
    assert parser_for_domain("x.mb-alt.example", parsers).bank == "MB"
    assert parser_for_domain("unknown.example", parsers) is None
    # Mặc định
    assert parser_for("VCB").domains == ["vietcombank.com.vn"]
    assert parser_for_domain("info.vietcombank.com.vn").bank == "VCB"


@pytest.mark.parametrize(
    ("domain", "ok"),
    [
        ("vietcombank.com.vn", True),
        ("info.vietcombank.com.vn", True),
        ("INFO.Vietcombank.COM.VN.", True),
        ("evilvietcombank.com.vn", False),
        ("vietcombank.com.vn.evil.example", False),
        ("com.vn", False),
        ("", False),
    ],
)
def test_domain_matches(domain, ok):
    assert domain_matches(domain, ["vietcombank.com.vn"]) is ok
