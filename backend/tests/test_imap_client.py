"""fetch_new_messages với máy chủ IMAP giả (không kết nối mạng, không đọc hộp thư thật)."""

from __future__ import annotations

import imaplib
import shlex
from dataclasses import dataclass
from datetime import UTC, date, datetime
from pathlib import Path

import pytest

from app.config import Settings
from app.ingest import imap_client
from app.ingest.email_parse import parse_email_message
from app.ingest.imap_client import (
    FetchedMessage,
    ImapError,
    ImapState,
    fetch_new_messages,
    from_criteria,
    imap_date,
    imap_session,
    make_imap_connection,
    quote_mailbox,
)

FIXTURES = Path(__file__).parent / "fixtures" / "emails"
DOMAINS = ["vietcombank.com.vn", "mbbank.com.vn"]
_MONTHS = {
    m: i for i, m in enumerate(("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"), 1)
}


@dataclass
class FakeMsg:
    sender: str
    internal_date: date
    raw: bytes


class FakeImap:
    """Mô phỏng phần IMAP mà imap_client dùng, kể cả các "tật" của máy chủ thật.

    - `UID SEARCH UID n:*` trả về thư có UID lớn nhất kể cả khi n > UID lớn nhất.
    - Có thể trả bytes (như imaplib) hoặc str; có thể không gửi UIDVALIDITY/UIDNEXT khi SELECT.
    """

    def __init__(
        self,
        messages: dict[int, FakeMsg],
        *,
        uidvalidity: int = 1000,
        uidnext: int | None = None,
        report_in_select: bool = True,
        as_bytes: bool = True,
    ) -> None:
        self.messages = messages
        self.uidvalidity = uidvalidity
        self.uidnext = uidnext if uidnext is not None else max(messages, default=0) + 1
        self.report_in_select = report_in_select
        self.as_bytes = as_bytes
        self.commands: list[tuple] = []
        self._untagged: dict[str, list] = {}
        self.logged_out = False

    def _enc(self, s: str):
        return s.encode() if self.as_bytes else s

    # --- lệnh IMAP ---
    def select(self, mailbox: str = "INBOX", readonly: bool = False):
        self.commands.append(("SELECT", mailbox, readonly))
        if self.report_in_select:
            self._untagged = {
                "UIDVALIDITY": [self._enc(str(self.uidvalidity))],
                "UIDNEXT": [self._enc(str(self.uidnext))],
            }
        return "OK", [self._enc(str(len(self.messages)))]

    def response(self, code: str):
        return code, self._untagged.pop(code.upper(), [None])

    def status(self, mailbox: str, names: str):
        self.commands.append(("STATUS", mailbox, names))
        return "OK", [self._enc(f"{mailbox} (UIDVALIDITY {self.uidvalidity} UIDNEXT {self.uidnext})")]

    def uid(self, command: str, *args: str):
        command = command.upper()
        self.commands.append(("UID", command, *args))
        if command == "SEARCH":
            uids = self._search(shlex.split(" ".join(args)))
            return "OK", [self._enc(" ".join(map(str, uids)))]
        if command == "FETCH":
            uid = int(args[0])
            msg = self.messages.get(uid)
            if msg is None:
                return "OK", [None]
            head = f"{uid} (UID {uid} BODY[] {{{len(msg.raw)}}}"
            return "OK", [(self._enc(head), msg.raw), self._enc(")")]
        if command == "STORE":
            raise AssertionError("không được đổi cờ thư")
        raise AssertionError(f"lệnh không mong đợi: {command}")

    def logout(self):
        self.logged_out = True
        return "BYE", [b"bye"]

    # --- tìm kiếm ---
    def _search(self, tokens: list[str]) -> list[int]:
        preds = []
        while tokens:
            preds.append(self._parse(tokens))
        return sorted(uid for uid, m in self.messages.items() if all(p(uid, m) for p in preds))

    def _parse(self, tokens: list[str]):
        tok = tokens.pop(0).upper()
        if tok == "OR":
            a, b = self._parse(tokens), self._parse(tokens)
            return lambda uid, m: a(uid, m) or b(uid, m)
        if tok == "FROM":
            needle = tokens.pop(0).lower()
            return lambda uid, m: needle in m.sender.lower()
        if tok == "SINCE":
            d, mon, y = tokens.pop(0).split("-")
            since = date(int(y), _MONTHS[mon], int(d))
            return lambda uid, m: m.internal_date >= since
        if tok == "UID":
            spec = tokens.pop(0)
            top = max(self.messages, default=0)
            lo_s, _, hi_s = spec.partition(":")
            lo = top if lo_s == "*" else int(lo_s)
            hi = lo if not hi_s else (top if hi_s == "*" else int(hi_s))
            lo, hi = min(lo, hi), max(lo, hi)  # RFC 3501: n:* với n > max nghĩa là max:n
            return lambda uid, m: lo <= uid <= hi
        if tok == "ALL":
            return lambda uid, m: True
        raise AssertionError(f"tiêu chí không hỗ trợ: {tok}")

    # --- tiện cho assert ---
    def fetched_uids(self) -> list[int]:
        return [int(c[2]) for c in self.commands if c[:2] == ("UID", "FETCH")]

    def searches(self) -> list[tuple]:
        return [c[2:] for c in self.commands if c[:2] == ("UID", "SEARCH")]


def vcb(n: int, d: date = date(2026, 10, 14)) -> FakeMsg:
    return FakeMsg("noreply@info.vietcombank.com.vn", d, f"raw-vcb-{n}".encode())


def mb(n: int, d: date = date(2026, 10, 14)) -> FakeMsg:
    return FakeMsg("noreply@mbbank.com.vn", d, f"raw-mb-{n}".encode())


def other(n: int, d: date = date(2026, 10, 14)) -> FakeMsg:
    return FakeMsg("newsletter@shop.example", d, f"raw-other-{n}".encode())


def assert_read_only(fake: FakeImap) -> None:
    assert all(c[2] is True for c in fake.commands if c[0] == "SELECT")
    fetches = [c for c in fake.commands if c[:2] == ("UID", "FETCH")]
    assert all(c[3] == "(BODY.PEEK[])" for c in fetches)
    assert not any(c[:2] == ("UID", "STORE") for c in fake.commands)


# ---------------------------------------------------------------------------
# Lần chạy đầu
# ---------------------------------------------------------------------------


def test_first_run_with_since_backfills_matching_messages():
    fake = FakeImap(
        {
            1: vcb(1, date(2026, 9, 30)),
            2: vcb(2, date(2026, 10, 1)),
            3: other(3, date(2026, 10, 2)),
            4: mb(4, date(2026, 10, 5)),
            5: vcb(5, date(2026, 10, 14)),
        },
        uidnext=9,
    )
    msgs, state = fetch_new_messages(fake, "INBOX", ImapState(), DOMAINS, date(2026, 10, 1))
    assert [m.uid for m in msgs] == [2, 4, 5]
    assert msgs[0] == FetchedMessage(uid=2, raw=b"raw-vcb-2")
    assert state == ImapState(uidvalidity=1000, last_uid=8)  # UIDNEXT - 1: lần sau không tìm lại
    assert fake.searches() == [
        ("SINCE", "01-Oct-2026", "OR", 'FROM "vietcombank.com.vn"', 'FROM "mbbank.com.vn"'),
    ]
    assert_read_only(fake)


def test_first_run_without_since_records_position_only():
    fake = FakeImap({1: vcb(1), 2: vcb(2), 7: mb(7)})
    msgs, state = fetch_new_messages(fake, "INBOX", ImapState(), DOMAINS, None)
    assert msgs == []
    assert state == ImapState(uidvalidity=1000, last_uid=7)
    assert fake.fetched_uids() == []
    assert fake.searches() == []


def test_first_run_with_since_and_nothing_found_still_sets_state():
    fake = FakeImap({1: other(1), 2: other(2)})
    msgs, state = fetch_new_messages(fake, "INBOX", ImapState(), DOMAINS, date(2026, 10, 1))
    assert msgs == []
    assert state == ImapState(uidvalidity=1000, last_uid=2)


# ---------------------------------------------------------------------------
# Lần chạy sau
# ---------------------------------------------------------------------------


def test_incremental_fetches_only_new_matching():
    fake = FakeImap({1: vcb(1), 2: vcb(2), 3: vcb(3), 4: other(4), 5: mb(5), 6: vcb(6)})
    msgs, state = fetch_new_messages(fake, "INBOX", ImapState(1000, 3), DOMAINS, date(2026, 10, 1))
    assert [m.uid for m in msgs] == [5, 6]
    assert state == ImapState(1000, 6)
    assert fake.searches() == [("UID", "4:*", "OR", 'FROM "vietcombank.com.vn"', 'FROM "mbbank.com.vn"')]
    assert_read_only(fake)


def test_uid_range_quirk_returns_last_message_but_it_is_filtered():
    fake = FakeImap({1: vcb(1), 2: vcb(2), 3: vcb(3)})
    msgs, state = fetch_new_messages(fake, "INBOX", ImapState(1000, 3), DOMAINS, None)
    assert msgs == []
    assert state == ImapState(1000, 3)
    assert fake.fetched_uids() == []
    # Máy chủ thật trả UID 3 cho "4:*" — kiểm tra fake mô phỏng đúng tật này.
    assert fake._search(["UID", "4:*"]) == [3]


def test_uidvalidity_change_resets_and_backfills():
    fake = FakeImap({1: vcb(1, date(2026, 10, 2)), 2: vcb(2, date(2026, 9, 1)), 3: mb(3)}, uidvalidity=2000)
    msgs, state = fetch_new_messages(fake, "INBOX", ImapState(1000, 500), DOMAINS, date(2026, 10, 1))
    assert [m.uid for m in msgs] == [1, 3]
    assert state == ImapState(2000, 3)


def test_uidvalidity_change_without_since_only_resets():
    fake = FakeImap({1: vcb(1), 2: vcb(2)}, uidvalidity=2000)
    msgs, state = fetch_new_messages(fake, "INBOX", ImapState(1000, 500), DOMAINS, None)
    assert msgs == []
    assert state == ImapState(2000, 2)


def test_max_messages_cap_oldest_first_and_resume():
    fake = FakeImap({uid: vcb(uid) for uid in range(1, 8)}, uidnext=20)
    state = ImapState(1000, 1)
    msgs, state = fetch_new_messages(fake, "INBOX", state, DOMAINS, None, max_messages=2)
    assert [m.uid for m in msgs] == [2, 3]
    assert state == ImapState(1000, 3)  # chỉ tiến tới thư cuối đã lấy
    msgs, state = fetch_new_messages(fake, "INBOX", state, DOMAINS, None, max_messages=2)
    assert [m.uid for m in msgs] == [4, 5]
    msgs, state = fetch_new_messages(fake, "INBOX", state, DOMAINS, None, max_messages=2)
    assert [m.uid for m in msgs] == [6, 7]
    assert state == ImapState(1000, 19)  # đã hết: nhảy tới UIDNEXT - 1
    assert fake.fetched_uids() == [2, 3, 4, 5, 6, 7]


def test_first_run_backfill_capped():
    fake = FakeImap({uid: vcb(uid) for uid in range(1, 6)})
    msgs, state = fetch_new_messages(fake, "INBOX", ImapState(), DOMAINS, date(2026, 10, 1), max_messages=3)
    assert [m.uid for m in msgs] == [1, 2, 3]
    assert state == ImapState(1000, 3)
    msgs, state = fetch_new_messages(fake, "INBOX", state, DOMAINS, date(2026, 10, 1), max_messages=3)
    assert [m.uid for m in msgs] == [4, 5]
    assert state == ImapState(1000, 5)


def test_input_state_not_mutated():
    fake = FakeImap({1: vcb(1), 2: vcb(2)})
    state = ImapState(1000, 1)
    fetch_new_messages(fake, "INBOX", state, DOMAINS, None)
    assert state == ImapState(1000, 1)


# ---------------------------------------------------------------------------
# Độ bền với phản hồi máy chủ
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("as_bytes", [True, False])
def test_str_or_bytes_responses_and_status_fallback(as_bytes):
    fake = FakeImap({1: vcb(1), 2: vcb(2), 3: vcb(3)}, report_in_select=False, as_bytes=as_bytes, uidnext=10)
    msgs, state = fetch_new_messages(fake, "INBOX", ImapState(1000, 1), DOMAINS, None)
    assert [m.uid for m in msgs] == [2, 3]
    assert all(isinstance(m.raw, bytes) for m in msgs)
    assert state == ImapState(1000, 9)
    assert ("STATUS", "INBOX", "(UIDVALIDITY UIDNEXT)") in fake.commands


def test_no_uidnext_anywhere_uses_max_uid_search():
    fake = FakeImap({1: vcb(1), 4: vcb(4)}, report_in_select=False)
    fake.status = lambda mailbox, names: ("NO", [b"STATUS not supported"])  # type: ignore[method-assign]
    msgs, state = fetch_new_messages(fake, "INBOX", ImapState(), DOMAINS, None)
    assert msgs == []
    assert state == ImapState(None, 4)
    assert ("UID", "4:*") not in fake.searches()
    assert ("UID", "*") in fake.searches()


def test_vanished_message_is_skipped():
    fake = FakeImap({1: vcb(1), 2: vcb(2), 3: vcb(3)})
    original = fake.uid

    def flaky_uid(command, *args):
        if command.upper() == "FETCH" and args[0] == "2":
            fake.commands.append(("UID", "FETCH", *args))
            return "OK", [b"2 (FLAGS (\\Seen))"]
        return original(command, *args)

    fake.uid = flaky_uid  # type: ignore[method-assign]
    msgs, state = fetch_new_messages(fake, "INBOX", ImapState(1000, 0), DOMAINS, None)
    assert [m.uid for m in msgs] == [1, 3]
    assert state == ImapState(1000, 3)


def test_no_from_filter_when_no_domains():
    fake = FakeImap({1: vcb(1), 2: other(2)})
    msgs, _ = fetch_new_messages(fake, "INBOX", ImapState(1000, 0), [], None)
    assert [m.uid for m in msgs] == [1, 2]
    assert fake.searches() == [("UID", "1:*")]


def test_folder_with_space_is_quoted():
    fake = FakeImap({1: vcb(1)})
    fetch_new_messages(fake, "[Gmail]/All Mail", ImapState(1000, 0), DOMAINS, None)
    assert fake.commands[0] == ("SELECT", '"[Gmail]/All Mail"', True)


def test_select_failure_raises():
    fake = FakeImap({1: vcb(1)})
    fake.select = lambda mailbox, readonly=False: ("NO", [b"Mailbox does not exist"])  # type: ignore[method-assign]
    with pytest.raises(ImapError):
        fetch_new_messages(fake, "Missing", ImapState(), DOMAINS, None)


def test_search_failure_raises():
    fake = FakeImap({1: vcb(1)})
    fake.uid = lambda command, *args: ("BAD", [b"Could not parse command"])  # type: ignore[method-assign]
    with pytest.raises(ImapError):
        fetch_new_messages(fake, "INBOX", ImapState(1000, 0), DOMAINS, None)


def test_connection_errors_propagate():
    fake = FakeImap({1: vcb(1)})

    def boom(command, *args):
        raise imaplib.IMAP4.abort("socket error: EOF")

    fake.uid = boom  # type: ignore[method-assign]
    with pytest.raises(imaplib.IMAP4.abort):
        fetch_new_messages(fake, "INBOX", ImapState(1000, 0), DOMAINS, None)


# ---------------------------------------------------------------------------
# Tiện ích
# ---------------------------------------------------------------------------


def test_from_criteria():
    assert from_criteria([]) == []
    assert from_criteria(["A.example"]) == ['FROM "a.example"']
    assert from_criteria(["a.example", "b.example", "c.example", "a.example"]) == [
        "OR", "OR", 'FROM "a.example"', 'FROM "b.example"', 'FROM "c.example"',
    ]  # fmt: skip
    assert from_criteria(['evil" OR ALL', "@ok.example", ""]) == ['FROM "ok.example"']


def test_imap_date_and_quote():
    assert imap_date(date(2026, 10, 1)) == "01-Oct-2026"
    assert imap_date(date(2026, 5, 31)) == "31-May-2026"
    assert quote_mailbox("INBOX") == "INBOX"
    assert quote_mailbox("[Gmail]/All Mail") == '"[Gmail]/All Mail"'
    assert quote_mailbox('a"b') == '"a\\"b"'
    assert quote_mailbox('"Already quoted"') == '"Already quoted"'


# ---------------------------------------------------------------------------
# Kết nối (IMAP4_SSL giả)
# ---------------------------------------------------------------------------


class FakeSSL:
    instances: list[FakeSSL] = []
    fail_login = False

    def __init__(self, host, port, timeout=None):
        self.args = (host, port, timeout)
        self.login_args = None
        self.logged_out = False
        FakeSSL.instances.append(self)

    def login(self, user, password):
        if FakeSSL.fail_login:
            raise imaplib.IMAP4.error("[AUTHENTICATIONFAILED] Invalid credentials")
        self.login_args = (user, password)
        return "OK", [b"logged in"]

    def logout(self):
        self.logged_out = True
        return "BYE", [b""]


@pytest.fixture
def fake_ssl(monkeypatch):
    FakeSSL.instances = []
    FakeSSL.fail_login = False
    monkeypatch.setattr(imap_client.imaplib, "IMAP4_SSL", FakeSSL)
    return FakeSSL


def _settings() -> Settings:
    return Settings(
        app_token="x" * 32, imap_host="imap.example.invalid", imap_port=993, imap_user="u@example.invalid",
        imap_password="app-password",
    )  # fmt: skip


def test_make_imap_connection(fake_ssl):
    conn = make_imap_connection(_settings())
    assert conn.args == ("imap.example.invalid", 993, 30)
    assert conn.login_args == ("u@example.invalid", "app-password")
    assert not conn.logged_out


def test_make_imap_connection_login_failure_logs_out(fake_ssl):
    fake_ssl.fail_login = True
    with pytest.raises(imaplib.IMAP4.error):
        make_imap_connection(_settings())
    assert fake_ssl.instances[0].logged_out


def test_imap_session_logs_out_even_on_error(fake_ssl):
    with pytest.raises(RuntimeError), imap_session(_settings()) as conn:
        assert conn.login_args
        raise RuntimeError("poll failed")
    assert fake_ssl.instances[0].logged_out


# ---------------------------------------------------------------------------
# Tích hợp: IMAP giả + parse_email_message trên email mẫu tổng hợp
# ---------------------------------------------------------------------------


def test_fetch_then_parse_fixtures():
    names = ["vcb_credit_table_html", "mb_line_out", "vcb_dkim_fail", "other_sender", "mb_multi"]
    messages = {}
    for uid, name in enumerate(names, start=1):
        sender = "noreply@example.com" if name == "other_sender" else "noreply@vietcombank.com.vn"
        if name.startswith("mb_"):
            sender = "noreply@mbbank.com.vn"
        messages[uid] = FakeMsg(sender, date(2026, 10, 14), (FIXTURES / f"{name}.eml").read_bytes())
    fake = FakeImap(messages)
    msgs, state = fetch_new_messages(fake, "INBOX", ImapState(), DOMAINS, date(2026, 10, 1))
    assert [m.uid for m in msgs] == [1, 2, 3, 5]
    received = datetime(2026, 10, 14, 9, 0, tzinfo=UTC)
    bank_domains = {"VCB": ["vietcombank.com.vn"], "MB": ["mbbank.com.vn"]}
    results = [parse_email_message(m.raw, bank_domains, True, received) for m in msgs]
    assert [(r.status, r.reason, len(r.txs)) for r in results] == [
        ("parsed", None, 1),
        ("parsed", None, 1),
        ("ignored", "auth", 0),
        ("parsed", None, 2),
    ]
    assert state == ImapState(1000, 5)
