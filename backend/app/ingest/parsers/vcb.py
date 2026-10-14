"""Gợi ý riêng cho email Vietcombank, sau đó dùng parser chung.

Các dạng đã tính tới (mẫu tổng hợp trong tests/fixtures/emails, chưa đối chiếu email thật):
- Kiểu SMS: "SD TK 0011004xxxxxx +2,500,000VND luc 14-10-2026 08:05:11. SD 12,500,000VND. Ref MBVCB.123.CT tu ..."
  (số tiền đứng ngay sau số TK, nội dung nằm sau "Ref").
- "Thông báo giao dịch": bảng nhãn/giá trị (Số tài khoản, Thời gian giao dịch, Số tiền, Số dư cuối, Nội dung...)
  → parser chung đọc được.
- "Biên lai chuyển tiền": biên lai VCB chỉ gửi cho người chuyển → không thấy chiều thì coi là tiền ra.
"""

from __future__ import annotations

import logging
import re

from app.ingest.parsers.base import BankParser, ParsedTx
from app.ingest.parsers.generic import (
    NUM_PATTERN,
    SIGN_PATTERN,
    Doc,
    GenericParser,
    amount_from_match,
    detect_direction,
    extract,
    find_balance,
    find_time,
    fold,
    normalize_text,
    prepare,
)

logger = logging.getLogger(__name__)

_SMS_HEAD = re.compile(
    rf"\bS(?:D|O DU) TK(?: VCB)?[ \t]+(?P<acct>[0-9xX*•]{{4,30}})[ \t]*(?P<sign1>{SIGN_PATTERN})[ \t]*"
    rf"(?P<num>{NUM_PATTERN})(?![.,]?\d)[ \t]*(?:VND|d)?(?![a-z0-9])",
    re.I,
)
_REF_TAIL = re.compile(r"\bRef\b[ \t]*:?[ \t]*(?P<desc>[^\n]+)", re.I)
_REF_CODE = re.compile(r"(?P<code>[A-Za-z0-9]+(?:\.[A-Za-z0-9]*\d[A-Za-z0-9]*)+)")
_OUT_HINTS = re.compile(
    r"\bbien lai\b|\bquy khach da chuyen\b|\blenh chuyen tien\b|\bchuyen tien thanh cong\b|\bchuyen khoan thanh cong\b",
    re.I,
)
_MAX_SEGMENT = 800


_REF_TOKEN = re.compile(r"\bRef\b", re.I)


def _inside_description(folded: str, pos: int) -> bool:
    """Đầu dòng SMS nằm sau "Ref" trên cùng dòng = nằm trong nội dung chuyển khoản do người gửi tự gõ."""
    line_start = folded.rfind("\n", 0, pos) + 1
    return _REF_TOKEN.search(folded, line_start, pos) is not None


def _parse_sms_style(doc: Doc, subject_folded: str) -> list[ParsedTx]:
    heads = [m for m in _SMS_HEAD.finditer(doc.folded) if not _inside_description(doc.folded, m.start())]
    txs: list[ParsedTx] = []
    for i, m in enumerate(heads):
        amount = amount_from_match(m)
        if not amount:
            continue
        end = heads[i + 1].start() if i + 1 < len(heads) else len(doc.text)
        seg = doc.slice(m.start(), min(end, m.start() + _MAX_SEGMENT))
        when, precision = find_time(seg)
        description = ""
        reference = None
        ref = _REF_TAIL.search(seg.folded)
        if ref:
            description = seg.text[ref.start("desc") : ref.end("desc")].strip(" \t.;,")
            code = _REF_CODE.match(description)
            reference = code.group("code") if code else None
        line_start, line_end = seg.line_bounds(0)
        direction = detect_direction(m.group("sign1"), seg.folded[line_start:line_end], subject_folded, seg.folded)
        txs.append(
            ParsedTx(
                direction=direction,
                amount=amount,
                balance_after=find_balance(seg),
                account_hint=re.sub(r"[xX*•]", "x", doc.text[m.start("acct") : m.end("acct")]),
                when=when,
                when_precision=precision,
                description=description[:500],
                reference_code=reference,
            )
        )
    return txs


class VcbParser(BankParser):
    bank = "VCB"
    default_domains = ("vietcombank.com.vn",)

    def parse(self, subject: str, text: str) -> list[ParsedTx]:
        try:
            doc = prepare(text)
            subject_folded = fold(normalize_text(subject or ""))
            txs = _parse_sms_style(doc, subject_folded)
            if txs:
                return txs
            hint = "out" if _OUT_HINTS.search(subject_folded + "\n" + doc.folded) else None
            tx = extract(doc, subject or "", default_direction=hint)
            return [tx] if tx else []
        except Exception:
            logger.warning("Parser VCB gặp lỗi, chuyển sang parser chung", exc_info=True)
            return GenericParser().parse(subject, text)
