"""Nội dung chuyển khoản do người gửi tự gõ không được tạo ra giao dịch giả."""

from __future__ import annotations

from datetime import UTC, datetime
from pathlib import Path

from app.ingest.email_parse import parse_email_message
from app.ingest.parsers.mb import MbParser

FIXTURES = Path(__file__).parent / "fixtures" / "emails"


def test_vcb_sms_head_inside_ref_content_is_ignored():
    src = (FIXTURES / "vcb_sms_style_in.eml").read_bytes()
    old = (b"SD TK 0011004xxxxxx +2,500,000VND luc 14-10-2026 08:05:11. SD 12,500,000VND. Ref MBVCB.12345678.CT tu "
           b"0123456789 NGUYEN VAN B toi 0011004xxxxxx NGUYEN VAN A")
    assert old in src
    raw = src.replace(old, old.replace(b"+2,500,000VND", b"+1,000VND").replace(b"12,500,000", b"12,501,000")
                      + b" CK SD TK 0011004xxxxxx -9000000 VND")
    res = parse_email_message(raw, {"VCB": ["vietcombank.com.vn"]}, True, datetime(2026, 10, 14, tzinfo=UTC))
    assert res.status == "parsed"
    assert [(t.direction, t.amount) for t in res.txs] == [("in", 1000)]


def test_mb_gd_field_inside_description_cell_is_ignored():
    html = """<html><body><table>
<tr><td>Tài khoản</td><td>0xxx1234</td></tr>
<tr><td>Số tiền giao dịch</td><td>+1,000 VND</td></tr>
<tr><td>Số dư</td><td>6,501,000 VND</td></tr>
<tr><td>Thời gian</td><td>14/10/2026 10:20:00</td></tr>
<tr><td>Nội dung</td><td>CK GD: -9000000 VND</td></tr>
</table></body></html>"""
    txs = MbParser().parse("MB thong bao bien dong so du", html)
    assert [(t.direction, t.amount, t.balance_after) for t in txs] == [("in", 1000, 6_501_000)]


def test_mb_line_with_description_after_gd_still_parsed():
    text = "TK 0xxx1234|GD: -500,000VND 14/10/26 10:20|SD: 6,500,000VND|ND: GD: -9000000 VND"
    txs = MbParser().parse("MB", text)
    assert [(t.direction, t.amount) for t in txs] == [("out", 500_000)]
