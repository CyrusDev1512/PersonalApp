"""Loopback-only interface for the single-comment probe. No browser automation."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import re
import secrets
import sqlite3
import subprocess
import tempfile
import threading
import time
import uuid
import webbrowser
import copy

from scripts.comment_probe import ProbeJournal, parse_target, probe, read_personal_cookies
from scripts.group_feed import FeedError, load_recent_posts
from scripts.fb_session import COOKIE_KEYS

ROOT = Path(__file__).resolve().parents[1]
MAX_BODY = 2_200_000
UI_PROTOCOL = 'commentlab-local-20261019-4'
UI_ASSETS = {'/': ('index.html', 'text/html; charset=utf-8'),
             '/app.css': ('app.css', 'text/css; charset=utf-8'),
             '/app.js': ('app.js', 'text/javascript; charset=utf-8')}


def snapshot_assets(root):
    """Keep UI bytes paired with the backend loaded by this process."""
    result = {}
    for url, (filename, mime) in UI_ASSETS.items():
        path = Path(root) / 'ui' / filename
        if path.is_file():
            result[url] = (path.read_bytes(), mime)
    return result


class LabError(Exception):
    def __init__(self, message, status=400):
        super().__init__(message)
        self.status = status


def normalize_cookies(data, expected_id):
    if not isinstance(expected_id, str) or not re.fullmatch(r"[0-9]{1,30}", expected_id):
        raise LabError("ID tài khoản phải là số. Dùng giá trị c_user trong Chrome.")
    if not isinstance(data, list) or len(data) > 100:
        raise LabError("File phiên cần là danh sách JSON các cookie.")
    values = {}
    for item in data:
        if not isinstance(item, dict):
            raise LabError("Mỗi cookie phải có name và value.")
        domain = item.get("domain", "facebook.com")
        if not isinstance(domain, str):
            raise LabError("Domain cookie không hợp lệ.")
        domain = domain.lstrip(".").lower()
        if domain != "facebook.com" and not domain.endswith(".facebook.com"):
            continue
        name, value = item.get("name"), item.get("value")
        if not isinstance(name, str) or name not in COOKIE_KEYS:
            continue
        if not isinstance(value, str) or len(value) > 8192 or any(ord(c) < 32 or ord(c) > 126 for c in value):
            raise LabError("Giá trị cookie không hợp lệ. Sao chép nguyên giá trị, không giải mã URL.")
        if not value:
            continue
        if name in values and values[name] != value:
            raise LabError("File có nhiều phiên khác nhau. Hãy chỉ chọn một tài khoản.")
        expiry = item.get("expirationDate")
        if name in ("c_user", "xs") and isinstance(expiry, (int, float)) and expiry > 0 and expiry < time.time():
            raise LabError("File chứa cookie đã hết hạn. Hãy lấy lại từ Chrome đang đăng nhập.")
        values[name] = value
    if values.get("i_user"):
        raise LabError("Phiên đang dùng danh tính Page. Chuyển về trang cá nhân rồi lấy lại cookie.")
    if values.get("c_user") != expected_id or not values.get("xs"):
        raise LabError("Cần c_user khớp ID đã nhập và cookie xs không rỗng.")
    return [{"name": name, "value": value, "domain": ".facebook.com", "path": "/", "secure": True}
            for name, value in values.items()]


def protect_directory(path):
    path.mkdir(parents=True, exist_ok=True, mode=0o700)
    if os.name == "nt":
        # Limit newly generated credential files to the current Windows user.
        who = subprocess.run(["whoami", "/user", "/fo", "csv", "/nh"], capture_output=True, check=True, text=True)
        sid = re.search(r"S-1-\d+(?:-\d+)+", who.stdout)
        if not sid:
            raise OSError("Unable to determine Windows identity")
        subprocess.run(["icacls", str(path), "/inheritance:r", "/grant:r",
                        "*" + sid.group(0) + ":(OI)(CI)F"], capture_output=True, check=True)
    else:
        path.chmod(0o700)


class Lab:
    def __init__(self, root=ROOT, asset_root=None):
        self.root = Path(root)
        self.asset_root = Path(asset_root) if asset_root is not None else self.root
        self.cookie_path = self.root / "private" / "session.json"
        self.state_dir = self.root / ".probe"
        self.lock = threading.RLock()
        self.csrf = secrets.token_urlsafe(32)
        self.previews = {}
        self.busy = False
        self.batch_preview = None
        self.batch = None
        self.batch_cancel = threading.Event()
        self.batch_thread = None

    def session_info(self):
        if not self.cookie_path.exists():
            return {"saved": False}
        try:
            data = json.loads(self.cookie_path.read_text(encoding="utf-8"))
            actor = next(row["value"] for row in data if row.get("name") == "c_user")
            normalize_cookies(data, actor)
            return {"saved": True, "actor_id": actor,
                    "path": str(self.cookie_path), "verified_online": False}
        except (OSError, ValueError, TypeError, KeyError, StopIteration, AttributeError, LabError):
            return {"saved": False, "invalid_file": True}

    def history(self):
        path = self.state_dir / "attempts.sqlite3"
        if not path.exists():
            return []
        db = sqlite3.connect(path)
        try:
            return [json.loads(row[0]) for row in db.execute(
                "SELECT report FROM attempts ORDER BY rowid DESC LIMIT 20")]
        finally:
            db.close()

    def state(self):
        with self.lock:
            return {"session": self.session_info(), "busy": self.busy,
                    "csrf": self.csrf, "history": self.history(), 'batch': copy.deepcopy(self.batch)}

    def save_session(self, payload):
        data = normalize_cookies(payload.get("cookies"), payload.get("actor_id"))
        with self.lock:
            if self.busy:
                raise LabError("Đang gửi thử. Chờ kết quả trước khi đổi phiên.", 409)
            protect_directory(self.cookie_path.parent)
            name = None
            try:
                fd, name = tempfile.mkstemp(prefix="session-", suffix=".tmp", dir=self.cookie_path.parent)
                with os.fdopen(fd, "w", encoding="utf-8") as stream:
                    json.dump(data, stream, ensure_ascii=False)
                    stream.flush()
                    os.fsync(stream.fileno())
                # Validate the exact file that will be consumed by the probe.
                read_personal_cookies(name, payload["actor_id"])
                os.replace(name, self.cookie_path)
                self.previews.clear()
                self.batch_preview = None
            finally:
                if name and Path(name).exists():
                    Path(name).unlink()
            return {"session": self.session_info()}

    def forget_session(self):
        with self.lock:
            if self.busy:
                raise LabError("Đang gửi thử. Chờ kết quả trước khi gỡ phiên.", 409)
            self.cookie_path.unlink(missing_ok=True)
            self.previews.clear()
            self.batch_preview = None
            return {"session": {"saved": False}}

    def preview(self, payload):
        raw, body = payload.get("target"), payload.get("text")
        if not isinstance(raw, str) or len(raw) > 2048:
            raise LabError("Nhập link bài trong nhóm hoặc ID bài dạng số.")
        if not isinstance(body, str) or not body.strip() or len(body) > 10000:
            raise LabError("Bình luận cần từ 1 đến 10.000 ký tự.")
        try:
            target = parse_target(raw)
        except ValueError as exc:
            raise LabError(str(exc)) from None
        with self.lock:
            if self.busy:
                raise LabError("Đang gửi thử. Chờ kết quả hiện tại.", 409)
            self.previews = {key: val for key, val in self.previews.items() if val["expires"] > time.time()}
            if len(self.previews) >= 30:
                self.previews.pop(next(iter(self.previews)))
            info = self.session_info()
            op = str(uuid.uuid4())
            result = {"operation_id": op, "target": target, "text": body,
                      "actor_id": info.get("actor_id"), "status": "preview_only",
                      "network_requests": 0, "can_send": info["saved"]}
            self.previews[op] = dict(result, expires=time.time() + 600)
            return result

    def send(self, payload):
        if payload.get("confirm") is not True:
            raise LabError("Cần xác nhận gửi bình luận đã xem trước.")
        op = payload.get("operation_id")
        if not isinstance(op, str):
            raise LabError("Hãy xem trước nội dung trước khi gửi.")
        with self.lock:
            if self.busy:
                raise LabError("Đang có một lần gửi thử. Không gửi thêm.", 409)
            item = self.previews.pop(op, None)
            if not item or item["expires"] < time.time():
                raise LabError("Bản xem trước đã hết hạn hoặc đã dùng. Hãy kiểm tra lịch sử và xem trước lại.", 409)
            info = self.session_info()
            if not info["saved"] or info.get("actor_id") != item.get("actor_id"):
                raise LabError("Phiên đã thay đổi. Lưu phiên rồi xem trước lại.", 409)
            self.busy = True
        try:
            return self._attempt(item['target'], item['text'], item['actor_id'], op)
        finally:
            with self.lock:
                self.busy = False

    def _attempt(self, target, text, actor, op):
        try:
            return probe(target, text, self.cookie_path, actor, self.state_dir, op)
        except (Exception, SystemExit):
            # Never claim not_sent if the durable pre-POST reservation exists.
            try:
                old = next((row for row in self.history() if row.get("operation_id") == op), None)
            except Exception:
                return {"status": "outcome_unknown", "operation_id": op,
                        "note": "Không đọc được nhật ký. Kiểm tra bài Facebook trước khi thử tiếp."}
            if old:
                return old
            return {"status": "not_sent", "operation_id": op,
                    "note": "Chưa gửi bình luận: phiên không dùng được, nguồn đang lỗi hoặc lần thử trùng. Kiểm tra lịch sử; nếu phiên hết hạn, lấy lại phiên từ Chrome."}

    def load_batch(self, payload):
        body, limit = payload.get('text'), payload.get('count')
        if not isinstance(body, str) or not body.strip() or len(body) > 10000:
            raise LabError('Bình luận cần từ 1 đến 10.000 ký tự.')
        if type(limit) is not int or limit not in (10, 20):
            raise LabError('Chọn 10 hoặc 20 bài.')
        with self.lock:
            if self.busy:
                raise LabError('Đang xử lý. Chờ kết quả hiện tại.', 409)
            info = self.session_info()
            if not info['saved']:
                raise LabError('Lưu phiên cá nhân trước khi lấy bài trong nhóm.', 409)
            self.busy = True
            self.batch_preview = None
        try:
            try:
                result = load_recent_posts(payload.get('group'), limit, self.cookie_path, info['actor_id'])
            except FeedError as exc:
                raise LabError(str(exc)) from None
            except (ValueError, OSError):
                raise LabError('Không đọc được phiên. Lưu lại phiên rồi lấy danh sách bài.') from None
            protect_directory(self.state_dir)
            journal = ProbeJournal(self.state_dir)
            try:
                for post in result['posts']:
                    post['previous_attempt'] = bool(journal.find_attempt(info['actor_id'], post['post_id'], body))
                    post['selectable'] = post['can_comment'] and not post['previous_attempt']
            finally:
                journal.close()
            value = dict(result, operation_id=str(uuid.uuid4()), actor_id=info['actor_id'], text=body,
                         mode='batch', expires=time.time() + 600)
            with self.lock:
                self.batch_preview = copy.deepcopy(value)
            return value
        finally:
            with self.lock:
                self.busy = False

    def start_batch(self, payload):
        if payload.get('confirm') is not True:
            raise LabError('Cần xác nhận danh sách và nội dung đã xem trước.')
        selected = payload.get('post_ids')
        if (not isinstance(selected, list) or not 1 <= len(selected) <= 20
                or not all(isinstance(value, str) for value in selected) or len(set(selected)) != len(selected)):
            raise LabError('Chọn từ 1 đến 20 bài khác nhau trong danh sách xem trước.')
        with self.lock:
            if self.busy:
                raise LabError('Đang xử lý một lần gửi. Không gửi thêm.', 409)
            preview = self.batch_preview
            if (not preview or preview['expires'] < time.time()
                    or payload.get('operation_id') != preview['operation_id']):
                raise LabError('Danh sách đã hết hạn hoặc đã dùng. Hãy lấy bài và xem trước lại.', 409)
            info = self.session_info()
            if not info['saved'] or info['actor_id'] != preview['actor_id']:
                raise LabError('Phiên đã thay đổi. Hãy lấy bài và xem trước lại.', 409)
            allowed = {p['post_id']: p for p in preview['posts'] if p['selectable']}
            if any(post_id not in allowed for post_id in selected):
                raise LabError('Danh sách có bài không được chọn hoặc đã có trong lịch sử.')
            self.batch_cancel.clear()
            self.batch_preview = None  # One preview starts at most once, including duplicate clicks.
            self.batch = {'batch_id': preview['operation_id'], 'state': 'running', 'group': preview['group'],
                          'actor_id': preview['actor_id'], 'total': len(selected), 'completed': 0,
                          'items': [dict(p, status='pending', operation_id=str(uuid.uuid4()))
                                    for p in preview['posts'] if p['post_id'] in selected]}
            self.busy = True
            self.batch_thread = threading.Thread(target=self._batch_worker,
                                                args=(preview['text'],), daemon=True)
            try:
                self.batch_thread.start()
            except RuntimeError:
                self.batch['state'] = 'stopped'
                self.busy = False
                raise LabError('Không khởi động được lượt gửi. Hãy lấy bài và xem trước lại.', 409) from None
            return {'batch': copy.deepcopy(self.batch), 'busy': self.busy}

    def _batch_worker(self, text):
        try:
            for item in self.batch['items']:
                if self.batch_cancel.is_set():
                    break
                with self.lock:
                    item['status'] = 'sending'
                report = self._attempt(item['target'], text, self.batch['actor_id'], item['operation_id'])
                with self.lock:
                    item['status'] = report['status']
                    item['report'] = report
                    self.batch['completed'] += 1
                if (report['status'] != 'confirmed_by_response' or report.get('journal_update_failed')
                        or report.get('graphql_error_count')):
                    with self.lock:
                        self.batch['state'] = 'stopped'
                        self.batch['note'] = 'Đã dừng vì một bài chưa được xác nhận. Kiểm tra bài và lịch sử trước khi gửi tiếp.'
                    break
                if self.batch_cancel.wait(1):
                    break
            with self.lock:
                if self.batch['state'] != 'stopped':
                    self.batch['state'] = ('completed' if self.batch['completed'] == self.batch['total']
                                           else 'cancelled')
                for item in self.batch['items']:
                    if item['status'] == 'pending':
                        item['status'] = 'not_sent'
        except Exception:
            with self.lock:
                self.batch['state'] = 'stopped'
                self.batch['note'] = 'Lượt gửi đã dừng. Kiểm tra lịch sử và bài Facebook trước khi thử tiếp.'
                for item in self.batch['items']:
                    if item['status'] == 'sending':
                        item['status'] = 'outcome_unknown'
                    elif item['status'] == 'pending':
                        item['status'] = 'not_sent'
        finally:
            with self.lock:
                self.busy = False

    def stop_batch(self, payload):
        with self.lock:
            if not self.batch or payload.get('batch_id') != self.batch['batch_id']:
                raise LabError('Không có lượt gửi này.', 404)
            self.batch_cancel.set()
            if self.batch['state'] == 'running':
                self.batch['state'] = 'cancelling'
            return {'batch': copy.deepcopy(self.batch), 'busy': self.busy}

    def request_shutdown(self):
        self.batch_cancel.set()


class Handler(BaseHTTPRequestHandler):
    server_version = "CommentLab"

    def log_message(self, *_args):
        pass  # Never put request data or session values in logs.

    def response(self, status, data, content_type="application/json; charset=utf-8"):
        raw = json.dumps(data, ensure_ascii=False).encode() if isinstance(data, dict) else data
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'")
        self.send_header("X-Frame-Options", "DENY")
        self.end_headers()
        try:
            self.wfile.write(raw)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def allowed(self, mutation=False):
        port = self.server.server_address[1]
        host = f"127.0.0.1:{port}"
        if self.headers.get("Host") != host:
            return False
        if self.headers.get("Sec-Fetch-Site") not in (None, "same-origin", "none"):
            return False
        origin = self.headers.get("Origin")
        if origin and origin != "http://" + host:
            return False
        if mutation:
            return (origin == "http://" + host and secrets.compare_digest(
                self.headers.get("X-Lab-CSRF", ""), self.server.lab.csrf))
        return True

    def do_GET(self):
        if not self.allowed():
            return self.response(403, {"error": "Chỉ mở tool tại địa chỉ local hiển thị lúc khởi động."})
        if self.path == "/api/state":
            try:
                return self.response(200, dict(self.server.lab.state(), ui_protocol=UI_PROTOCOL))
            except Exception:
                return self.response(500, {"error": "Không đọc được dữ liệu local. Kiểm tra quyền thư mục và khởi động lại tool."})
        if self.path == '/api/batch/status':
            with self.server.lab.lock:
                return self.response(200, {'batch': copy.deepcopy(self.server.lab.batch), 'busy': self.server.lab.busy})
        if self.path not in UI_ASSETS:
            return self.response(404, {"error": "Không có đường dẫn này."})
        entry = self.server.ui_assets.get(self.path)
        if entry is None:
            return self.response(404, {"error": "Thiếu file giao diện."})
        return self.response(200, entry[0], entry[1])

    def do_POST(self):
        if not self.allowed(mutation=True):
            return self.response(403, {"error": "Phiên giao diện không hợp lệ. Tải lại trang local rồi thử lại."})
        try:
            if self.headers.get("Content-Type", "").split(";")[0] != "application/json":
                raise LabError("Chỉ nhận dữ liệu JSON.", 415)
            if self.headers.get("Transfer-Encoding"):
                raise LabError("Định dạng request không được hỗ trợ.")
            size = int(self.headers.get("Content-Length", "0"))
            if not 0 < size <= MAX_BODY:
                raise LabError("Dữ liệu quá lớn hoặc rỗng.", 413)
            self.connection.settimeout(10)
            data = json.loads(self.rfile.read(size))
            if not isinstance(data, dict):
                raise LabError("Dữ liệu phải là một đối tượng JSON.")
            actions = {"/api/session": self.server.lab.save_session,
                       "/api/forget": lambda _: self.server.lab.forget_session(),
                       "/api/preview": self.server.lab.preview,
                       "/api/send": self.server.lab.send,
                       '/api/batch/load': self.server.lab.load_batch,
                       '/api/batch/start': self.server.lab.start_batch,
                       '/api/batch/stop': self.server.lab.stop_batch}
            if hasattr(self.server.lab, 'store'):
                lab = self.server.lab
                actions = {key: lab.legacy_disabled for key in actions}
                actions.update({
                    '/api/accounts/save': lab.save_account,
                    '/api/accounts/select': lab.select_account,
                    '/api/accounts/delete': lab.delete_account,
                    '/api/accounts/recheck': lab.recheck,
                    '/api/history/skip-reviewed': lab.skip_reviewed_post,
                    '/api/groups/sync': lab.sync_groups,
                    '/api/groups/stop': lab.stop_sync,
                    '/api/links/check': lab.links,
                    '/api/links/load': lab.load_links,
                    '/api/send/direct': lab.send_direct,
                    '/api/history': lab.history_page,
                    '/api/review/prepare': lab.prepare,
                    '/api/review/send': lab.start_reviewed,
                    '/api/work/stop': lab.stop_work,
                })
            action = actions.get(self.path)
            if not action:
                raise LabError("Không có thao tác này.", 404)
            self.response(200, action(data))
        except LabError as exc:
            self.response(exc.status, {"error": str(exc)})
        except (ValueError, TypeError, UnicodeError):
            self.response(400, {"error": "Dữ liệu không hợp lệ. Kiểm tra định dạng link, file JSON và nội dung."})
        except Exception:
            self.response(500, {"error": "Không hoàn tất thao tác local. Kiểm tra quyền ghi thư mục. Nếu vừa gửi, kiểm tra lịch sử và bài Facebook trước khi gửi tiếp."})


def make_server(root=ROOT, port=8790, asset_root=None, *, lab_class=None):
    if lab_class is None:
        from scripts.workspace_lab import WorkspaceLab
        lab_class = WorkspaceLab
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    try:
        server.lab = lab_class(root, asset_root=asset_root)
        server.ui_assets = snapshot_assets(server.lab.asset_root)
    except Exception:
        server.server_close()
        raise
    return server


def main():
    parser = argparse.ArgumentParser(description="Comment Lab — local single-comment test")
    parser.add_argument("--port", type=int, default=8790)
    parser.add_argument("--open", action="store_true")
    args = parser.parse_args()
    missing = [name for name in ("index.html", "app.css", "app.js") if not (ROOT / "ui" / name).is_file()]
    if missing:
        print("Thieu file giao dien trong thu muc ui: " + ", ".join(missing))
        print("Can sao chep day du ban Comment Lab truoc khi khoi dong.")
        return 1
    try:
        server = make_server(port=args.port)
    except OSError:
        print("Khong mo duoc cong. Kiem tra tool dang chay hoac dung --port khac.")
        return 1
    address = f"http://127.0.0.1:{server.server_address[1]}/"
    print(f"Comment Lab: {address}", flush=True)
    if args.open:
        webbrowser.open(address)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
