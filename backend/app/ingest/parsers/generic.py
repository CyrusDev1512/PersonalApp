"""Parser email chung: đọc số tiền, số dư, TK, thời gian, mã tham chiếu và nội dung từ thông báo biến động số dư.

Không phụ thuộc bố cục của một ngân hàng cụ thể:
1. Văn bản được chuẩn hoá (NFC, bóc HTML bằng `html.parser`, gọn khoảng trắng). Ô bảng `<td>` được nối bằng " | " để
   nhãn và giá trị cùng nằm trên một dòng; `<br>`/`<tr>`/thẻ khối thành xuống dòng.
2. Tạo bản bỏ dấu (`fold`) **cùng độ dài** với bản gốc: so nhãn/từ khoá trên bản bỏ dấu (không phân biệt hoa thường),
   lấy giá trị (nội dung, mã tham chiếu, số TK) từ bản gốc ở đúng vị trí đó.
3. Nhãn được thử theo thứ tự ưu tiên (vd. "Số tiền" trước "GD"), nhãn đứng sau các từ như "Mã", "Số", "Phí", "Thời gian"
   bị bỏ qua (tránh "Mã GD", "Phí giao dịch"...).

Không bao giờ raise với input rác: `GenericParser.parse` trả `[]` khi không đọc được số tiền.
"""

from __future__ import annotations

import logging
import re
import unicodedata
from collections.abc import Iterator, Sequence
from dataclasses import dataclass
from datetime import datetime
from html.parser import HTMLParser

from app.ingest.parsers.base import BankParser, ParsedTx
from app.money import parse_vnd
from app.text import strip_accents

logger = logging.getLogger(__name__)

MAX_MARKUP_CHARS = 1_000_000
MAX_TEXT_CHARS = 200_000
MAX_DESCRIPTION = 500
# Chặn số tiền vô lý (tránh tràn INTEGER của SQLite): 10^15 đồng.
MAX_AMOUNT = 10**15

Span = tuple[int, int]

# ---------------------------------------------------------------------------
# Chuẩn hoá văn bản
# ---------------------------------------------------------------------------

_BLOCK_TAGS = frozenset(
    {
        "address", "article", "aside", "blockquote", "br", "caption", "center", "dd", "div", "dl", "dt",
        "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6", "header", "hr", "li", "main", "ol", "p",
        "pre", "section", "table", "tbody", "tfoot", "thead", "tr", "ul",
    }
)  # fmt: skip
_CELL_TAGS = frozenset({"td", "th"})
_SKIP_TAGS = frozenset({"script", "style", "noscript", "template", "title"})

_HTML_HINT = re.compile(r"<\s*/?\s*(?:html|body|div|table|tr|td|p|br|span|font|meta|center|b|strong)\b", re.I)
_INVISIBLE = dict.fromkeys(map(ord, "\u200b\u200c\u200d\u2060\ufeff\u00ad"), None)
_SPACES = re.compile(r"[ \t\f\v\u00a0\u1680\u2000-\u200a\u202f\u205f\u3000]+")
_PIPES = re.compile(r"[ \t]*\|(?:[ \t]*\|)*[ \t]*")


class _TextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self._skip = 0

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag in _SKIP_TAGS:
            self._skip += 1
        elif tag in _BLOCK_TAGS:
            self.parts.append("\n")
        elif tag in _CELL_TAGS:
            self.parts.append(" | ")

    def handle_endtag(self, tag: str) -> None:
        if tag in _SKIP_TAGS:
            self._skip = max(0, self._skip - 1)
        elif tag in _BLOCK_TAGS:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if not self._skip:
            self.parts.append(data)


def normalize_text(text: str | None) -> str:
    """NFC, bỏ ký tự vô hình, gọn khoảng trắng; mỗi dòng không rỗng giữ nguyên thứ tự."""
    if not text:
        return ""
    text = unicodedata.normalize("NFC", str(text)[:MAX_TEXT_CHARS])
    text = text.translate(_INVISIBLE).replace("\r\n", "\n").replace("\r", "\n")
    lines: list[str] = []
    for raw in text.split("\n"):
        line = _SPACES.sub(" ", raw)
        line = _PIPES.sub(" | ", line).strip(" |")
        if line:
            lines.append(line)
    return "\n".join(lines)


def html_to_text(markup: str | None) -> str:
    """Bóc thẻ HTML, giữ xuống dòng cho thẻ khối/`<br>`, nối ô bảng bằng " | "."""
    if not markup:
        return ""
    parser = _TextExtractor()
    try:
        parser.feed(str(markup)[:MAX_MARKUP_CHARS])
        parser.close()
    except Exception:  # html.parser rất dễ tính; phòng hờ để không bao giờ làm hỏng luồng email
        logger.warning("Không bóc được HTML, dùng phần đã đọc", exc_info=True)
    return normalize_text("".join(parser.parts))


def looks_like_html(text: str) -> bool:
    return bool(_HTML_HINT.search(text[:MAX_MARKUP_CHARS]))


_FOLD_CACHE: dict[str, str] = {}


def fold(text: str) -> str:
    """Bỏ dấu từng ký tự, **giữ nguyên độ dài** để vị trí trên bản bỏ dấu khớp với bản gốc."""
    if text.isascii():
        return text
    out: list[str] = []
    for ch in text:
        if ch < "\x80":
            out.append(ch)
            continue
        folded = _FOLD_CACHE.get(ch)
        if folded is None:
            base = strip_accents(ch)
            folded = base if len(base) == 1 else ch
            if len(_FOLD_CACHE) < 10_000:
                _FOLD_CACHE[ch] = folded
        out.append(folded)
    return "".join(out)


@dataclass(frozen=True)
class Doc:
    """Văn bản đã chuẩn hoá + bản bỏ dấu cùng độ dài."""

    text: str
    folded: str

    @classmethod
    def from_normalized(cls, text: str) -> Doc:
        return cls(text, fold(text))

    def slice(self, start: int, end: int) -> Doc:
        return Doc(self.text[start:end], self.folded[start:end])

    def line_bounds(self, pos: int) -> Span:
        start = self.text.rfind("\n", 0, pos) + 1
        end = self.text.find("\n", pos)
        return start, (len(self.text) if end < 0 else end)

    def lines(self) -> Iterator[Span]:
        pos = 0
        while pos <= len(self.text):
            end = self.text.find("\n", pos)
            if end < 0:
                end = len(self.text)
            if end > pos:
                yield pos, end
            pos = end + 1


def prepare(text: str | None) -> Doc:
    """Văn bản thuần hoặc HTML -> `Doc`."""
    raw = "" if text is None else str(text)
    normalized = html_to_text(raw) if looks_like_html(raw) else normalize_text(raw)
    return Doc.from_normalized(normalized)


# ---------------------------------------------------------------------------
# Mẫu regex (áp lên bản bỏ dấu, IGNORECASE)
# ---------------------------------------------------------------------------

SIGN_PATTERN = r"[+\-\u2212\u2013]"
# 1.000.000 | 1,000,000 | 1.000.000,00 | 1 000 000 | 1000000 | 1000000,00
NUM_PATTERN = (
    r"(?:\d{1,3}(?P<sep>[.,])\d{3}(?:(?P=sep)\d{3})*(?:[.,]\d{2})?"
    r"|\d{1,3}(?: \d{3})+"
    r"|\d+(?:[.,]\d{2})?)"
)
_NEGATIVE_SIGNS = "-\u2212\u2013"

_AMOUNT_VALUE = re.compile(
    rf"(?P<sign1>{SIGN_PATTERN})?[ \t]*(?:VND[ \t]*)?(?P<sign2>{SIGN_PATTERN})?[ \t]*(?P<num>{NUM_PATTERN})"
    r"(?![.,]?\d)(?:[ \t]*(?P<cur>VND|dong|d)(?![a-z0-9])|(?![a-z0-9/:]))",
    re.I,
)
# Số tiền có dấu và đơn vị ở bất kỳ đâu ("+2,500,000VND") — phương án cuối khi không có nhãn.
_SIGNED_MONEY = re.compile(
    rf"(?<![\w.,+\-])(?P<sign1>{SIGN_PATTERN})[ \t]?(?P<num>{NUM_PATTERN})(?![.,]?\d)"
    r"[ \t]*(?P<cur>VND|dong|d)(?![a-z0-9])",
    re.I,
)
# Phân cách giữa nhãn và giá trị: ":", "|", "=", "(VND)", hoặc giá trị nằm ở dòng kế tiếp.
_SEP = re.compile(r"[ \t]*(?:\((?:VND|d)\)[ \t]*)?(?:[:：=|][ \t]*)?(?:\n[ \t]*(?:[:：|][ \t]*)?)?", re.I)
# Như trên nhưng bắt buộc có phân cách rõ ràng (dùng cho nội dung, vốn là văn bản tự do).
_DELIM = re.compile(r"[ \t]*(?:\((?:VND|d)\)[ \t]*)?(?:[:：=|][ \t]*(?:\n[ \t]*)?|\n[ \t]*)", re.I)

_AMOUNT_LABELS = tuple(
    re.compile(p, re.I)
    for p in (
        r"\bso tien(?: (?:giao dich|gd|ghi co|ghi no|chuyen khoan|chuyen|nhan|thanh toan|rut|bien dong|phat sinh))?\b"
        r"(?! ?(?:phi|bang chu|thue|vat|toi thieu|toi da|con lai))",
        r"\bphat sinh(?: (?:tang|giam|no|co))?\b",
        r"\b(?:transaction )?amount\b",
        r"\bps\b",
        r"\bgd\b",
        r"\bgiao dich\b",
        r"\bbien dong(?: so du)?\b",
        r"\bso du (?:tang|giam|thay doi)\b",
    )
)
# Nhãn số tiền đứng sau các từ này là nhãn khác ("Mã GD", "Phí giao dịch", "Thời gian giao dịch"...).
_AMOUNT_DENY_BEFORE = re.compile(
    r"\b(?:ma|so|loai|ngay|gio|thoi gian|kenh|hinh thuc|noi dung|nd|lenh|phi|trang thai|ket qua|tham chieu|id|"
    r"han muc|ten|thong bao|tai khoan)[ \t]*$",
    re.I,
)
_FEE_BEFORE = re.compile(r"\b(?:phi|thue|vat)\b[^\n|]{0,30}$", re.I)

_BALANCE_LABELS = tuple(
    re.compile(p, re.I)
    for p in (
        r"\bso du cuoi(?: ky)?\b",
        r"\bso du kha dung\b",
        r"\bso du (?:hien tai|moi|sau giao dich|sau gd)\b",
        r"\bso du (?:tai khoan|tk)\b",
        r"\bso du\b(?! ?(?:dau|truoc|toi thieu|ban dau|thay doi|tang|giam|bien dong))",
        r"\bsd tk\b",
        r"\bsd\b",
        r"\b(?:available|ending|current|closing|ledger) balance\b",
        r"\bbalance\b",
    )
)
# Số TK chen giữa nhãn số dư và giá trị ("Số dư TK 0011001234567: 12.000.000").
_ACCT_SKIP = re.compile(
    r"[ \t]*(?:(?:so tk|tk|tai khoan)[ \t]*)?(?:[:：][ \t]*)?(?P<acct>[0-9xX*•]{4,30})(?![0-9a-z])", re.I
)

_ACCOUNT = re.compile(
    r"\b(?:so tai khoan|tai khoan|so tk|stk|tk|account(?: number| no)?|acct)\b\.?"
    r"(?P<qual>(?:[ \t]+[a-z/]+){0,4}?)"
    r"[ \t]*(?:[:：=|][ \t]*)?(?:\n[ \t]*)?"
    r"(?P<acct>[0-9xX*•]{4,30})(?![0-9a-z])",
    re.I,
)
_QUAL_COUNTER = re.compile(r"\b(?:doi ung|counter(?:party)?)\b", re.I)
_QUAL_RECEIVER = re.compile(r"\b(?:huong|nhan|den|ghi co|beneficiary|payee|creditor|to)\b", re.I)
_QUAL_SENDER = re.compile(r"\b(?:nguon|chuyen|gui|ghi no|trich no|tu|from|debit|source)\b", re.I)

_D = r"(?P<d>\d{1,2})(?P<s1>[/\-.])(?P<m>\d{1,2})(?P=s1)(?P<y>\d{4}|\d{2})(?!\d)"
_T = r"(?P<H>\d{1,2})[:h](?P<M>\d{2})(?::(?P<S>\d{2}))?(?!\d)"
_DT_DATE_FIRST = re.compile(rf"(?<![\d/.\-]){_D}(?:[ \t]*,?[ \t]*(?:luc|at|vao luc|-)?[ \t]*{_T})?", re.I)
_DT_TIME_FIRST = re.compile(rf"(?<![\d:]){_T}[ \t]*,?[ \t]*(?:ngay|date|-)?[ \t]*{_D}", re.I)
_DT_ISO = re.compile(
    r"(?<!\d)(?P<y>\d{4})-(?P<m>\d{2})-(?P<d>\d{2})(?:[T ](?P<H>\d{2}):(?P<M>\d{2})(?::(?P<S>\d{2}))?)?(?!\d)"
)
_TIME_LABEL_BEFORE = re.compile(r"\b(?:thoi gian|ngay|gio|luc|time|date|vao)\b[^\n]{0,30}$", re.I)

_REF_LABEL = re.compile(
    r"\b(?:so tham chieu|ma tham chieu|ma giao dich|ma gd|so giao dich|so gd|so lenh(?: giao dich)?|"
    r"so but toan|ma but toan|reference(?: no| code| number)?|ref(?: no)?|trace(?: no)?|transaction id|txn id)\b\.?",
    re.I,
)
_REF_VALUE = re.compile(r"(?P<ref>[A-Za-z0-9][A-Za-z0-9._\-/]{2,59})")

_DESC_LABEL = re.compile(
    r"\b(?:noi dung(?: giao dich| chuyen khoan| chuyen tien| thanh toan| ck)?|dien giai|mo ta|nd|content|"
    r"description|remarks?|details)\b",
    re.I,
)
_DESC_STOP = re.compile(
    r"\n|\||[ \t]+(?:so tien|so du|sd|thoi gian|ngay gd|ngay giao dich|ma gd|ma giao dich|so tham chieu|so gd|"
    r"tai khoan|tk|ps|gd|ref|phi)[ \t]*[:：]",
    re.I,
)

# Từ khoá chiều giao dịch. "Mạnh" được tìm trong cả email; "yếu" chỉ trên dòng chứa số tiền và tiêu đề
# (vì "nhận", "cộng", "tăng"... xuất hiện khắp nơi trong chân email: "người nhận", "thành công", "tầng 5").
_IN_STRONG = re.compile(
    r"(?<!the )\bghi co\b|\bcredit(?:ed)?\b(?! card)|\bnhan tien\b|\bnhan chuyen khoan\b|\btien vao\b"
    r"|\bduoc cong\b|\bcong tien\b|\bso du tang\b|\bbien dong tang\b|\bphat sinh (?:tang|co)\b",
    re.I,
)
_OUT_STRONG = re.compile(
    r"(?<!the )\bghi no\b|\bdebit(?:ed)?\b(?! card)|\bchuyen tien di\b|\bchuyen khoan di\b|\bbi tru\b|\btru tien\b"
    r"|\bda tru\b|\bso du giam\b|\bbien dong giam\b|\brut tien\b|\btien ra\b|\bphat sinh (?:giam|no)\b",
    re.I,
)
_IN_WEAK = re.compile(
    r"(?<!nguoi )(?<!ben )(?<!ca )(?<!tk )(?<!khoan )(?<!hang )(?<!xac )(?<!ghi )(?<!tiep )(?<!chap )\bnhan\b"
    r"(?! (?:vien|dan|vat|hieu|su|thuc|xet|thay|ban|dien|dang|dinh|lai|thong bao|email|tin))"
    r"|(?<!thanh )\bcong\b(?! (?:ty|nghe|dong|viec|tac|khai|ich|an|bo|cu|chung|suat|trinh|thuc|nhan|thanh|doan"
    r"|hoa|ly|bang|cong|dan))"
    r"|(?<!qua )\btang\b(?! ?(?:\d|qua|thuong|cuong))"
    r"|\bhoan tien\b|\brefund(?:ed)?\b",
    re.I,
)
_OUT_WEAK = re.compile(
    r"\btru\b(?! (?:so|khi|di|truong))|\bgiam\b(?! (?:doc|sat|dinh|gia))|\bthanh toan\b|\brut\b",
    re.I,
)


# ---------------------------------------------------------------------------
# Trích từng trường
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class AmountHit:
    amount: int
    sign: str | None
    start: int
    end: int


def _inside(pos: int, spans: Sequence[Span]) -> bool:
    return any(s <= pos < e for s, e in spans)


def amount_from_match(m: re.Match[str]) -> int | None:
    """Số tiền (int > 0) từ match có nhóm `num`; None nếu giống số TK (bắt đầu bằng 0) hoặc vô lý."""
    num = m.group("num")
    if num is None or re.fullmatch(r"0\d+", num):
        return None
    value = parse_vnd(num)
    if value is None or value <= 0 or value >= MAX_AMOUNT:
        return None
    return value


def _match_sign(m: re.Match[str]) -> str | None:
    groups = m.groupdict()
    return groups.get("sign1") or groups.get("sign2") or None


def _looks_like_account(token: str) -> bool:
    if any(ch in token for ch in "xX*•"):
        return any(ch.isdigit() for ch in token)
    return token.isdigit() and (token.startswith("0") or len(token) >= 10)


def _label_values(
    doc: Doc,
    label_re: re.Pattern[str],
    value_re: re.Pattern[str],
    *,
    deny_before: re.Pattern[str] | None = None,
    exclude: Sequence[Span] = (),
    skip_account: bool = False,
    sep: re.Pattern[str] = _SEP,
) -> Iterator[re.Match[str]]:
    """Các giá trị (match trên bản bỏ dấu) đứng ngay sau nhãn, theo thứ tự xuất hiện."""
    folded = doc.folded
    for lm in label_re.finditer(folded):
        if _inside(lm.start(), exclude):
            continue
        if deny_before is not None and deny_before.search(folded, max(0, lm.start() - 30), lm.start()):
            continue
        positions = [lm.end()]
        if skip_account:
            am = _ACCT_SKIP.match(folded, lm.end())
            if am and _looks_like_account(am.group("acct")):
                positions.insert(0, am.end())
        for pos in positions:
            sm = sep.match(folded, pos)
            if sm is None:
                continue
            vm = value_re.match(folded, sm.end())
            if vm is not None:
                yield vm
                break


def find_amount(doc: Doc, exclude: Sequence[Span] = ()) -> AmountHit | None:
    for label_re in _AMOUNT_LABELS:
        for vm in _label_values(doc, label_re, _AMOUNT_VALUE, deny_before=_AMOUNT_DENY_BEFORE, exclude=exclude):
            amount = amount_from_match(vm)
            if amount:
                return AmountHit(amount, _match_sign(vm), vm.start("num"), vm.end())
    for vm in _SIGNED_MONEY.finditer(doc.folded):
        if _inside(vm.start(), exclude):
            continue
        # Cửa sổ ngắn phía trước (regex không vượt qua xuống dòng/"|"): tránh O(n^2) trên dòng rất dài.
        if _FEE_BEFORE.search(doc.folded, max(0, vm.start() - 60), vm.start()):
            continue
        amount = amount_from_match(vm)
        if amount:
            return AmountHit(amount, _match_sign(vm), vm.start("num"), vm.end())
    return None


def find_balance(doc: Doc, exclude: Sequence[Span] = ()) -> int | None:
    for label_re in _BALANCE_LABELS:
        for vm in _label_values(doc, label_re, _AMOUNT_VALUE, exclude=exclude, skip_account=True):
            if _match_sign(vm):
                # Có dấu +/- là số tiền phát sinh ("SD TK 0011xxx +500,000VND"), không phải số dư.
                continue
            value = amount_from_match(vm)
            if value:
                return value
    return None


def _clean_account(token: str) -> str:
    return re.sub(r"[xX*•]", "x", token)


def find_accounts(
    doc: Doc, exclude: Sequence[Span] = (), direction: str | None = None
) -> tuple[str | None, str | None]:
    """(TK của mình, TK đối ứng). Nhãn kèm "người hưởng"/"nguồn"... được hiểu theo chiều giao dịch."""
    plain: list[str] = []
    receiver: list[str] = []
    sender: list[str] = []
    counter: list[str] = []
    for m in _ACCOUNT.finditer(doc.folded):
        if _inside(m.start(), exclude):
            continue
        token = doc.text[m.start("acct") : m.end("acct")]
        if not any(ch.isdigit() for ch in token):
            continue
        token = _clean_account(token)
        qual = m.group("qual") or ""
        if _QUAL_COUNTER.search(qual):
            counter.append(token)
        elif _QUAL_RECEIVER.search(qual):
            receiver.append(token)
        elif _QUAL_SENDER.search(qual):
            sender.append(token)
        else:
            plain.append(token)
    if direction == "in":
        own_side, other_side = receiver, sender
    else:  # "out" hoặc chưa rõ: biên lai chuyển tiền thường ghi TK nguồn là của mình
        own_side, other_side = sender, receiver
    own = (plain or own_side or [None])[0]
    other = next((t for t in counter + other_side + (own_side if plain else []) if t != own), None)
    return own, other


def _datetime_from(m: re.Match[str]) -> tuple[datetime, str] | None:
    try:
        day, month = int(m.group("d")), int(m.group("m"))
        year_raw = m.group("y")
        year = int(year_raw) + (2000 if len(year_raw) == 2 else 0)
        if not 2000 <= year <= 2100:
            return None
        groups = m.groupdict()
        if groups.get("H") is not None and groups.get("M") is not None:
            second = groups.get("S")
            dt = datetime(year, month, day, int(groups["H"]), int(groups["M"]), int(second or 0))
            return dt, ("second" if second is not None else "minute")
        return datetime(year, month, day), "date"
    except (ValueError, TypeError):
        return None


def find_time(doc: Doc, exclude: Sequence[Span] = ()) -> tuple[datetime | None, str | None]:
    """Thời điểm giao dịch (giờ VN, naive) + độ chính xác: second | minute | date."""
    best: tuple[tuple[int, int, int], datetime, str] | None = None
    for regex in (_DT_DATE_FIRST, _DT_TIME_FIRST, _DT_ISO):
        for m in regex.finditer(doc.folded):
            if _inside(m.start(), exclude):
                continue
            parsed = _datetime_from(m)
            if parsed is None:
                continue
            dt, precision = parsed
            labelled = bool(_TIME_LABEL_BEFORE.search(doc.folded, max(0, m.start() - 50), m.start()))
            score = (0 if precision == "date" else 1, 1 if labelled else 0, -m.start())
            if best is None or score > best[0]:
                best = (score, dt, precision)
    if best is None:
        return None, None
    return best[1], best[2]


def find_reference(doc: Doc, exclude: Sequence[Span] = ()) -> str | None:
    for vm in _label_values(doc, _REF_LABEL, _REF_VALUE, exclude=exclude):
        value = doc.text[vm.start("ref") : vm.end("ref")].rstrip(".-/_")
        if len(value) >= 3 and any(ch.isdigit() for ch in value):
            return value
    return None


def find_description(doc: Doc) -> tuple[str, Span | None]:
    folded = doc.folded
    for lm in _DESC_LABEL.finditer(folded):
        sm = _DELIM.match(folded, lm.end())
        if sm is None:
            continue
        start = sm.end()
        stop = _DESC_STOP.search(folded, start)
        end = stop.start() if stop else len(folded)
        value = doc.text[start:end].strip(" \t.;,-")
        if value:
            return value[:MAX_DESCRIPTION], (lm.start(), end)
    return "", None


def detect_direction(sign: str | None, amount_line: str, subject: str, body: str) -> str | None:
    """Dấu +/- → từ khoá trên dòng số tiền → tiêu đề → từ khoá mạnh trong cả email. Không chắc → None."""
    if sign:
        return "out" if sign in _NEGATIVE_SIGNS else "in"
    for text, weak in ((amount_line, True), (subject, True), (body, False)):
        if not text:
            continue
        has_in = bool(_IN_STRONG.search(text)) or (weak and bool(_IN_WEAK.search(text)))
        has_out = bool(_OUT_STRONG.search(text)) or (weak and bool(_OUT_WEAK.search(text)))
        if has_in != has_out:
            return "in" if has_in else "out"
    return None


def extract(doc: Doc, subject: str = "", *, default_direction: str | None = None) -> ParsedTx | None:
    """Một giao dịch từ `doc`; None nếu không thấy số tiền."""
    description, desc_span = find_description(doc)
    exclude: list[Span] = [desc_span] if desc_span else []
    hit = find_amount(doc, exclude)
    if hit is None:
        return None
    line_start, line_end = doc.line_bounds(hit.start)
    subject_folded = fold(normalize_text(subject))
    direction = detect_direction(hit.sign, doc.folded[line_start:line_end], subject_folded, doc.folded)
    if direction is None:
        direction = default_direction
    when, precision = find_time(doc, exclude)
    account, counter = find_accounts(doc, exclude, direction)
    return ParsedTx(
        direction=direction,
        amount=hit.amount,
        balance_after=find_balance(doc, exclude),
        account_hint=account,
        when=when,
        when_precision=precision,
        description=description,
        reference_code=find_reference(doc, exclude),
        counter_account=counter,
    )


class GenericParser(BankParser):
    """Parser dự phòng cho mọi ngân hàng."""

    bank = "GENERIC"

    def matches(self, from_domain: str) -> bool:
        return False

    def parse(self, subject: str, text: str) -> list[ParsedTx]:
        try:
            tx = extract(prepare(text), subject or "")
        except Exception:  # input rác không được làm hỏng luồng email
            logger.warning("Parser email chung gặp lỗi, coi như không đọc được", exc_info=True)
            return []
        return [tx] if tx else []
