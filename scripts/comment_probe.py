"""Single-comment HTTP probe. Offline preview by default; no browser imports."""
import argparse
import contextlib
import hashlib
import io
import json
from pathlib import Path
import re
import sqlite3
import sys
from urllib.parse import urlparse
import uuid
import time
import unicodedata

import requests

from scripts.fb import _try_comment
from scripts.fb_session import COOKIE_KEYS, create_session, fetch_tokens
from scripts.remote_status import RemoteStop, check_response, check_graphql, diagnostic


def parse_target(raw):
    raw = raw.strip()
    if re.fullmatch(r"[0-9]{1,30}", raw):
        return {"post_id": raw, "group": None, "url": None}
    url = urlparse(raw)
    if (url.scheme != "https" or url.hostname not in
            {"facebook.com", "www.facebook.com", "m.facebook.com", "web.facebook.com"}
            or url.username or url.password or url.port not in (None, 443)):
        raise ValueError("Chỉ nhận ID bài dạng số hoặc link HTTPS facebook.com.")
    match = re.fullmatch(r"/groups/([A-Za-z0-9._-]+)/(?:posts|permalink)/([0-9]{1,30})/?", url.path)
    if not match:
        raise ValueError("Cần link /groups/<nhóm>/posts/<ID số>/ hoặc /permalink/<ID số>/. Link share/pfbid chưa được hỗ trợ; không đoán ID.")
    group, post = match.groups()
    return {"post_id": post, "group": group,
            "url": f"https://www.facebook.com/groups/{group}/posts/{post}/"}


def read_personal_cookies(path, expected_user_id):
    # An explicit local file only: never scan a browser profile or cookie DB.
    if isinstance(path, list):
        data = path
    else:
        with Path(path).open(encoding="utf-8-sig") as stream:
            data = json.load(stream)
    if not isinstance(data, list):
        raise ValueError("File phiên phải là JSON dạng danh sách cookie.")
    cookies = {}
    for item in data:
        if not isinstance(item, dict):
            raise ValueError("Định dạng file phiên không hợp lệ.")
        domain = str(item.get("domain", "")).lstrip(".").lower()
        if domain and domain != "facebook.com" and not domain.endswith(".facebook.com"):
            continue
        name = item.get("name")
        value = item.get("value")
        if name in COOKIE_KEYS and isinstance(value, str) and value:
            if name in cookies and cookies[name] != value:
                raise ValueError("File chứa nhiều phiên không nhất quán; dừng để tránh sai danh tính.")
            cookies[name] = value
    if not cookies.get("c_user", "").isascii() or not cookies.get("c_user", "").isdigit() or not cookies.get("xs"):
        raise ValueError("Thiếu phiên Facebook cá nhân hợp lệ.")
    if cookies.get("i_user"):
        raise ValueError("Phiên đang có danh tính Page/chuyển tài khoản. Bản thử này chỉ nhận phiên cá nhân.")
    if cookies["c_user"] != expected_user_id:
        raise ValueError("Danh tính trong file không khớp tài khoản cá nhân đã chọn.")
    return cookies


class ProbeJournal:
    """Persist a reservation BEFORE the POST, including across crashes/processes."""
    def __init__(self, directory):
        directory = Path(directory)
        directory.mkdir(parents=True, exist_ok=True)
        self.db = sqlite3.connect(directory / "attempts.sqlite3", timeout=10)
        self.db.execute("PRAGMA synchronous=FULL")
        self.db.execute("""CREATE TABLE IF NOT EXISTS attempts (
            operation_id TEXT PRIMARY KEY, fingerprint TEXT UNIQUE NOT NULL,
            state TEXT NOT NULL, report TEXT NOT NULL)""")
        self.db.commit()
        self.db.execute('CREATE TABLE IF NOT EXISTS post_locks(post_id TEXT PRIMARY KEY, operation_id TEXT NOT NULL)')
        self.db.commit()

    def reserve(self, operation_id, fingerprint, report, strict=False):
        try:
            with self.db:
                if strict:
                    # Lock and migrate old reports in the same transaction as the reservation.
                    self.db.execute('BEGIN IMMEDIATE')
                    self._backfill_locks()
                    self.db.execute('INSERT INTO post_locks VALUES(?,?)', (report['target']['post_id'], operation_id))
                self.db.execute("INSERT INTO attempts VALUES (?, ?, ?, ?)",
                    (operation_id, fingerprint, "reserved", json.dumps(report, ensure_ascii=False)))
        except sqlite3.IntegrityError:
            raise ValueError("Lần thử hoặc cùng tài khoản/bài/nội dung đã được ghi nhận. Không gửi lại; kiểm tra bài và báo cáo cũ trước.") from None

    def finish(self, operation_id, report):
        with self.db:
            self.db.execute("UPDATE attempts SET state=?, report=? WHERE operation_id=?",
                (report["status"], json.dumps(report, ensure_ascii=False), operation_id))

    def get(self, operation_id):
        row = self.db.execute("SELECT report FROM attempts WHERE operation_id=?", (operation_id,)).fetchone()
        if not row:
            raise ValueError("Không có lần thử này trong nhật ký.")
        return json.loads(row[0])

    def find_attempt(self, actor, post_id, text):
        row = self.db.execute('SELECT report FROM attempts WHERE fingerprint=?',
                              (attempt_fingerprint(actor, post_id, text),)).fetchone()
        return json.loads(row[0]) if row else None

    def _backfill_locks(self):
        for op, raw in self.db.execute('SELECT operation_id,report FROM attempts').fetchall():
            report = json.loads(raw)
            post_id = (report.get('target') or {}).get('post_id')
            if post_id and report.get('status') != 'not_sent':
                self.db.execute('INSERT OR IGNORE INTO post_locks VALUES(?,?)', (post_id, op))

    def post_seen(self, post_id):
        with self.db:
            self._backfill_locks()
        return self.db.execute('SELECT 1 FROM post_locks WHERE post_id=?', (post_id,)).fetchone() is not None

    def content_seen(self, text):
        digest = content_hash(text)
        for raw, in self.db.execute('SELECT report FROM attempts'):
            if json.loads(raw).get('content_hash') == digest:
                return True
        return False

    def close(self):
        self.db.close()


def attempt_fingerprint(actor, post_id, text):
    return hashlib.sha256(json.dumps([actor, post_id, text], ensure_ascii=False).encode()).hexdigest()


def content_hash(text):
    value = ' '.join(unicodedata.normalize('NFKC', text).split()).casefold()
    return hashlib.sha256(value.encode()).hexdigest()


def probe(target, text, cookie_path, expected_user_id, state_dir, operation_id, *, strict=False, context=None):
    cookies = read_personal_cookies(cookie_path, expected_user_id)
    session = create_session(cookies)
    if strict:
        session.hooks['response'].append(lambda response, **_: check_response(response))
    # Scope credentials to Facebook. Do not forward session values to an
    # unrelated host if a read-only login request redirects there.
    session.cookies.clear()
    for key, value in cookies.items():
        session.cookies.set(key, value, domain=".facebook.com", path="/", secure=True)
    fingerprint = attempt_fingerprint(expected_user_id, target['post_id'], text)
    report = {"operation_id": operation_id, "status": "preflight", "target": target,
              "actor_id": expected_user_id, "text_sha256": hashlib.sha256(text.encode()).hexdigest(),
              "write_attempts": 0, "browser_used": False}
    report['created_at'] = time.time()
    report['content_hash'] = content_hash(text)
    # Snapshot labels before reservation/POST, so renaming or deleting an account
    # later cannot erase the identity shown in history. Never include cookies.
    for key in ('account_name', 'group_name', 'group_url'):
        value = (context or {}).get(key)
        if isinstance(value, str):
            report[key] = value[:2048 if key == 'group_url' else 300]
    journal = ProbeJournal(state_dir)
    try:
        # Drop upstream diagnostic output, which can include response details.
        # The only output is our allowlisted structured result.
        try:
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                tokens = fetch_tokens(session)
        except (Exception, SystemExit) as exc:
            if not strict:
                raise
            report.update(status='not_sent', diagnostic=diagnostic(exc, 'preflight'),
                          error_category=exc.category if isinstance(exc, RemoteStop) else 'network_error'
                          if isinstance(exc, requests.RequestException) else 'unrecognized_response',
                          note='Dừng ở bước chuẩn bị; chưa gửi bình luận.')
            # No reservation/POST has happened; do not fabricate an unknown write.
            return report
        report["status"] = "reserved"
        journal.reserve(operation_id, fingerprint, report, strict=strict)
        report["write_attempts"] = 1
        try:
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                ok, data = _try_comment(session, tokens, expected_user_id,
                    target["post_id"], text, idempotence_token="client:" + operation_id)
            if strict:
                check_graphql(data)
            node = (((data.get("data") or {}).get("comment_create") or {})
                    .get("feedback_comment_edge") or {}).get("node") or {}
            report["status"] = "confirmed_by_response" if ok else "unconfirmed"
            comment_id = node.get("id")
            if isinstance(comment_id, str) and re.fullmatch(r"[A-Za-z0-9_:=+/-]{1,512}", comment_id):
                report["comment_id"] = comment_id
            report["graphql_error_count"] = len(data.get("errors") or [])
            report["stream_incomplete"] = bool(data.get("_stream_incomplete"))
            report["note"] = ("Facebook trả ID và đúng nội dung; còn cần kiểm tra hiển thị/duyệt trong nhóm."
                if ok else "Chưa xác nhận kết quả. Có thể đã gửi; kiểm tra bài trước, không tự chạy lại.")
        except (Exception, SystemExit) as exc:
            report["status"] = "outcome_unknown"
            report['diagnostic'] = diagnostic(exc, 'comment')
            report['error_category'] = (exc.category if isinstance(exc, RemoteStop)
                                        else 'network_error' if isinstance(exc, requests.RequestException)
                                        else 'unrecognized_response')
            report["note"] = "Lỗi sau khi bắt đầu gửi. Có thể đã đăng; không tự gửi lại. Kiểm tra bài trong nhóm."
        try:
            journal.finish(operation_id, report)
        except (sqlite3.Error, OSError):
            # Reservation remains durable. Never mislabel a completed POST as
            # "not sent" merely because recording its outcome failed.
            report["journal_update_failed"] = True
            report["note"] += " Nhật ký chưa cập nhật được; giữ mã lần thử và kiểm tra bài, không gửi lại."
        return report
    finally:
        journal.close()
        session.close()


def main(argv=None):
    parser = argparse.ArgumentParser(description="Test một bình luận qua HTTP. Mặc định chỉ xem trước, không truy cập Facebook.")
    parser.add_argument("--target", help="Link bài trong group hoặc ID bài dạng số")
    message = parser.add_mutually_exclusive_group()
    message.add_argument("--text", help="Nội dung một bình luận")
    message.add_argument("--message-file", help="File UTF-8 chứa nội dung đã duyệt")
    parser.add_argument("--cookies", help="Đường dẫn file phiên cục bộ; không dán cookie vào lệnh")
    parser.add_argument("--expected-user-id", help="ID tài khoản cá nhân đã chọn")
    parser.add_argument("--send", action="store_true", help="Gửi thật đúng một lần")
    parser.add_argument("--operation-id", help="UUID lần thử; tự tạo nếu bỏ trống")
    parser.add_argument("--state-dir", default=str(Path(__file__).resolve().parents[1] / ".probe"))
    parser.add_argument("--report", help="Đọc báo cáo theo UUID; không truy cập Facebook")
    args = parser.parse_args(argv)
    try:
        if args.report:
            journal = ProbeJournal(args.state_dir)
            try:
                result = journal.get(str(uuid.UUID(args.report)))
            finally:
                journal.close()
            print(json.dumps(result, ensure_ascii=False, indent=2))
            return 0
        if not args.target:
            raise ValueError("Cần --target.")
        target = parse_target(args.target)
        text = Path(args.message_file).read_text(encoding="utf-8-sig") if args.message_file else args.text
        if not isinstance(text, str) or not text.strip() or len(text) > 10000:
            raise ValueError("Nội dung phải có từ 1 đến 10.000 ký tự.")
        operation_id = str(uuid.UUID(args.operation_id)) if args.operation_id else str(uuid.uuid4())
        if not args.send:
            print(json.dumps({"status": "preview_only", "target": target, "text": text,
                "operation_id": operation_id, "network_requests": 0,
                "note": "Chưa gửi. Luồng group chưa được xác minh trên Facebook thật."}, ensure_ascii=False, indent=2))
            return 0
        if not args.cookies or not args.expected_user_id:
            raise ValueError("Gửi thật cần --cookies và --expected-user-id để xác nhận đúng tài khoản.")
        if not re.fullmatch(r"[0-9]{1,30}", args.expected_user_id):
            raise ValueError("ID tài khoản cá nhân phải là số.")
        result = probe(target, text, args.cookies, args.expected_user_id, args.state_dir, operation_id)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0 if result["status"] == "confirmed_by_response" else 3
    except ValueError as exc:
        # JSON decode errors can include document fragments. Never echo them.
        message = "File JSON không hợp lệ." if isinstance(exc, json.JSONDecodeError) else str(exc)
        print(json.dumps({"status": "not_sent", "reason": message}, ensure_ascii=False))
        return 2
    except (OSError, SystemExit, requests.RequestException, sqlite3.Error):
        print(json.dumps({"status": "not_sent", "reason": "Không hoàn tất đọc file hoặc kiểm tra phiên; chưa gửi bình luận."}, ensure_ascii=False))
        return 2


if __name__ == "__main__":
    sys.exit(main())
