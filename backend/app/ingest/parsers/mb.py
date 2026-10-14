"""Gợi ý riêng cho email MB Bank, sau đó dùng parser chung.

Các dạng đã tính tới (mẫu tổng hợp trong tests/fixtures/emails, chưa đối chiếu email thật):
- "Thông báo biến động số dư" dạng dòng, các trường cách nhau bởi "|":
  "TK 0xxx1234|GD: -500,000VND 14/10/26 10:20|SD: 6,500,000VND|ND: THANH TOAN QR"
  Một email có thể có nhiều dòng như vậy → mỗi dòng một giao dịch.
- Bảng nhãn/giá trị (Tài khoản, Số tiền giao dịch, Số dư, Thời gian, Nội dung, Mã giao dịch) → parser chung.
"""

from __future__ import annotations

import logging
import re

from app.ingest.parsers.base import BankParser, ParsedTx
from app.ingest.parsers.generic import SIGN_PATTERN, GenericParser, extract, prepare

logger = logging.getLogger(__name__)

_GD_FIELD = re.compile(rf"\bGD[ \t]*:?[ \t]*{SIGN_PATTERN}?[ \t]*\d", re.I)


class MbParser(BankParser):
    bank = "MB"
    default_domains = ("mbbank.com.vn",)

    def parse(self, subject: str, text: str) -> list[ParsedTx]:
        try:
            doc = prepare(text)
            txs: list[ParsedTx] = []
            for start, end in doc.lines():
                line = doc.slice(start, end)
                if "|" not in line.text or not _GD_FIELD.search(line.folded):
                    continue
                tx = extract(line, subject or "")
                if tx:
                    txs.append(tx)
            if len(txs) == 1:
                # Chỉ một dòng: lấy thêm thời gian / TK / mã tham chiếu nằm ngoài dòng đó (nếu có).
                whole = extract(doc, subject or "")
                tx = txs[0]
                if whole and whole.amount == tx.amount:
                    if tx.when is None:
                        tx.when, tx.when_precision = whole.when, whole.when_precision
                    tx.account_hint = tx.account_hint or whole.account_hint
                    tx.reference_code = tx.reference_code or whole.reference_code
                    tx.balance_after = tx.balance_after or whole.balance_after
            if txs:
                return txs
        except Exception:
            logger.warning("Parser MB gặp lỗi, chuyển sang parser chung", exc_info=True)
        return GenericParser().parse(subject, text)
