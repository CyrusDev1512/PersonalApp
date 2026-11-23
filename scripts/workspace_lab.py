"""Multi-account workbench; serialized work and reviewed, immutable sends."""
from contextlib import contextmanager
import copy
import json
import msvcrt
import os
import sqlite3
import threading
import time
import uuid
from urllib.parse import urlparse

import requests

from scripts.account_store import AccountStore
from scripts.comment_probe import ProbeJournal, content_hash, parse_target, probe
from scripts.group_feed import FeedError, parse_group, load_recent_posts
from scripts.lab_server import Lab, LabError, normalize_cookies, protect_directory
from scripts.remote_status import RemoteStop, diagnostic
from scripts.joined_groups import load_joined
from scripts.sync_jobs import SyncJobs, FileLease
from scripts import review_outcome


ERRORS = {
    'session_expired': 'Phiên hết hạn. Cập nhật phiên rồi kiểm tra lại.',
    'verification_required': 'App tạm dừng gửi do dấu hiệu yêu cầu xác minh phiên. Kiểm tra trực tiếp trên Facebook; chưa kết luận tài khoản bị khóa.',
    'restricted': 'App tạm dừng gửi do dấu hiệu hạn chế thao tác. Không đồng nghĩa tài khoản đã bị khóa.',
    'permission_denied': 'Yêu cầu tại nguồn này bị từ chối truy cập. Chưa đủ bằng chứng kết luận lỗi toàn tài khoản.',
    'network_error': 'Mất kết nối. Nếu đã bắt đầu gửi, kiểm tra bài trước khi tiếp tục.',
    'remote_error': 'Nguồn chưa phản hồi bình thường. Lượt đã dừng.',
    'unrecognized_response': 'App chưa xác định được phản hồi nên tạm dừng gửi. Chưa có bằng chứng Facebook khóa tài khoản; kiểm tra kết quả bài đã xử lý.',
}


def parse_links(raw):
    if not isinstance(raw, str) or len(raw) > 40000:
        raise LabError('Danh sách link không hợp lệ.')
    lines = [(i + 1, s.strip()) for i, s in enumerate(raw.splitlines()) if s.strip()]
    if not 1 <= len(lines) <= 50:
        raise LabError('Nhập từ 1 đến 50 link, mỗi dòng một link.')
    seen, rows = set(), []
    for line, value in lines:
        row = {'line': line, 'url': value, 'valid': False}
        try:
            u = urlparse(value)
            if u.scheme != 'https':
                raise ValueError('Chỉ nhận link HTTPS nhóm hoặc bài trong nhóm.')
            group = parse_group(value)
            if '/posts/' in u.path or '/permalink/' in u.path:
                target = parse_target(value)
                key = 'post:' + target['post_id']
                row.update(kind='post', target=target)
            else:
                key = 'group:' + group['slug'].lower()
                row.update(kind='group')
            row.update(group=group, key=key)
            if key in seen:
                row['error'] = 'Link trùng trong danh sách.'
            else:
                seen.add(key)
                row['valid'] = True
        except (ValueError, TypeError):
            row['error'] = 'Chưa hỗ trợ link này. Dùng /groups/nhóm/ hoặc /groups/nhóm/posts/ID-số/.'
        rows.append(row)
    return rows


class WorkspaceLab(Lab):
    AUTO_SYNC = True
    def __init__(self, root, asset_root=None):
        super().__init__(root, asset_root)
        protect_directory(self.root / 'private')
        protect_directory(self.state_dir)
        self.store = AccountStore(self.root / 'private')
        self.migration_error = ''
        self.read_job = None
        self.sync_job = None
        self.draft = None
        self.work_file = None
        self.network_lease = None
        self.account_views = {}
        self.sync = SyncJobs(self, lambda cookies, actor, **kw: load_joined(cookies, actor, **kw))
        try:
            with self.operation():
                if self.cookie_path.exists():
                    data = json.loads(self.cookie_path.read_text(encoding='utf-8-sig'))
                    actor = next(x['value'] for x in data if x.get('name') == 'c_user')
                    cookies = normalize_cookies(data, actor)
                    if self.store.account(actor) is None:
                        self.store.save(actor, actor, cookies)
                    else:
                        # An interrupted migration must not overwrite a newer session.
                        self.store.cookies(actor)
                    self.store.active(actor)
                    self.cookie_path.unlink()
        except Exception:
            self.migration_error = 'Chưa chuyển được phiên cũ. File cũ được giữ; kiểm tra quyền Windows trước khi tiếp tục.'

    def acquire(self, network=True):
        if self.busy:
            raise LabError('Đang xử lý. Chờ kết quả hoặc bấm Dừng.', 409)
        stream = (self.root / 'private' / 'work.lock').open('a+b')
        try:
            if stream.tell() == 0:
                stream.write(b'0')
                stream.flush()
            stream.seek(0)
            msvcrt.locking(stream.fileno(), msvcrt.LK_NBLCK, 1)
        except OSError:
            stream.close()
            raise LabError('Một cửa sổ khác đang xử lý. Chờ lượt đó kết thúc.', 409) from None
        if network:
            lease = FileLease(self.root / 'private/network.lock')
            if not lease.acquire():
                stream.seek(0); msvcrt.locking(stream.fileno(), msvcrt.LK_UNLCK, 1); stream.close()
                raise LabError('Đang đồng bộ nhóm. Bạn vẫn có thể soạn nội dung; chờ đồng bộ xong hoặc bấm Dừng trước khi đọc/gửi.', 409)
            self.network_lease = lease
        self.work_file = stream
        self.busy = True
        self.batch_cancel.clear()

    def release(self):
        if self.network_lease:
            self.network_lease.release()
            self.network_lease = None
        if self.work_file:
            self.work_file.seek(0)
            msvcrt.locking(self.work_file.fileno(), msvcrt.LK_UNLCK, 1)
            self.work_file.close()
            self.work_file = None
        self.busy = False

    @contextmanager
    def operation(self, network=False):
        with self.lock:
            self.acquire(network=network)
        try:
            yield
        finally:
            with self.lock:
                self.release()

    def actor(self, payload, sending=False):
        actor = payload.get('account_id')
        if not isinstance(actor, str):
            raise LabError('Chọn tài khoản trước.')
        account = self.store.account(actor)
        if not account:
            raise LabError('Không tìm thấy tài khoản.', 404)
        if sending and account['blocked']:
            raise LabError(ERRORS.get(account['blocked'], 'App đang tạm dừng gửi để kiểm tra.'), 409)
        return account

    def invalidate(self):
        self.draft = None
        self.read_job = None
        self.batch = None
        self.previews.clear()
        self.batch_preview = None

    def state(self):
        with self.lock:
            accounts = self.store.accounts()
            active = self.store.active()
            if not any(a['account_id'] == active for a in accounts):
                active = accounts[0]['account_id'] if accounts else ''
            return {'accounts': accounts, 'active_account_id': active,
                    'groups': self.store.groups(active), 'csrf': self.csrf, 'busy': self.busy,
                    'app_version':'2026.10.19.4', 'data_directory':str(self.root),
                    'history': self.history(), 'batch': copy.deepcopy(self.batch),
                    'read_job': copy.deepcopy(self.read_job), 'migration_error': self.migration_error,
                    'sync_job': self.sync.get(active), 'sync_jobs': self.sync.all(),
                    'network_busy': any(j['state']=='running' for j in self.sync.all()),
                    'session': {'saved': bool(active), 'actor_id': active, 'verified_online': False}}

    def history(self):
        return self.history_page({})['items']

    def history_page(self, payload):
        offset = payload.get('offset', 0)
        if type(offset) is not int or not 0 <= offset <= 1_000_000:
            raise LabError('Trang lịch sử không hợp lệ.')
        path = self.state_dir / 'attempts.sqlite3'
        if not path.exists():
            return {'items': [], 'offset':offset, 'has_more':False}
        db = sqlite3.connect(path, timeout=10)
        try:
            raw = db.execute('SELECT report FROM attempts ORDER BY rowid DESC LIMIT 51 OFFSET ?', (offset,)).fetchall()
        finally:
            db.close()
        accounts = {a['account_id']:a['name'] for a in self.store.accounts()}
        groups = {}
        items = []
        for row, in raw[:50]:
            report = json.loads(row)
            report['can_skip_after_review'] = review_outcome.eligible(report)
            actor = report.get('actor_id')
            if not report.get('account_name'):
                report['account_name'] = accounts.get(actor) or 'Tài khoản đã xóa / chưa lưu tên'
                report['account_name_is_current'] = actor in accounts
            target = report.get('target') or {}
            source = report.get('group_url') or (f"https://www.facebook.com/groups/{target['group']}/" if target.get('group') else '')
            report['group_url'] = source
            if not report.get('group_name'):
                if actor not in groups:
                    groups[actor] = {g['url']:g['name'] for g in self.store.groups(actor)}
                name = groups[actor].get(source)
                report['group_name'] = name if name and name != target.get('group') else 'Chưa lưu tên nhóm'
            items.append(report)
        return {'items':items,'offset':offset,'has_more':len(raw)>50}

    def skip_reviewed_post(self, payload):
        if payload.get('confirm') is not True:
            raise LabError('Xác nhận bạn đã kiểm tra đúng bài trước khi bỏ qua.')
        if not isinstance(payload.get('operation_id'),str) or not isinstance(payload.get('post_id'),str):
            raise LabError('Thiếu mã lần gửi hoặc mã bài.')
        if type(payload.get('revision')) is not int:
            raise LabError('Thiếu phiên bản tài khoản.')
        # Also wait for background network reads, so a new session signal cannot
        # arrive between the operator's confirmation and this transaction.
        with self.operation(network=True):
            a = self.actor(payload)
            try:
                result = review_outcome.skip(self.state_dir/'attempts.sqlite3', self.store.path,
                    a['account_id'], payload['revision'], payload['operation_id'], payload['post_id'])
            except ValueError as exc:
                raise LabError(str(exc),409) from None
            result['message'] = ('Đã bỏ qua bài này và giữ chống trùng. Tài khoản có thể dùng tiếp; không tự tiếp tục lượt cũ.'
                if result['can_continue'] else 'Đã ghi nhận bỏ qua và giữ chống trùng. Tài khoản vẫn tạm dừng vì còn lần chưa xử lý hoặc lỗi khác.')
            return result

    def send_direct(self, payload):
        text, count = payload.get('text'), payload.get('count', 10)
        if not isinstance(text, str) or not 1 <= len(text.strip()) <= 10000:
            raise LabError('Nhập nội dung từ 1 đến 10.000 ký tự.')
        if type(count) is not int or count not in (10, 20, 50):
            raise LabError('Chọn tối đa 10, 20 hoặc 50 bài trong lượt.')
        if payload.get('confirm') is not True:
            raise LabError('Bấm Gửi để bắt đầu.')
        rows = parse_links(payload.get('links'))
        invalid = [r for r in rows if not r['valid'] and r.get('error') != 'Link trùng trong danh sách.']
        if invalid:
            raise LabError('Sửa link không hợp lệ tại dòng ' + ', '.join(str(r['line']) for r in invalid) + ' trước khi gửi.')
        with self.lock:
            self.acquire()
            try:
                a = self.actor(payload, sending=True)
                cookies = self.store.cookies(a['account_id'])
                self.invalidate()
                self.read_job = {'state':'running','mode':'send','account_id':a['account_id'],
                                 'completed':0,'total':len(rows),'rows':copy.deepcopy(rows)}
                self.batch_thread = threading.Thread(target=self._direct_worker, args=(a,cookies,rows,count,text), daemon=True)
                self.batch_thread.start()
            except Exception:
                self.release()
                raise
        return {'started':True}

    def _direct_worker(self, a, cookies, rows, count, text):
        try:
            # Keep the cross-process lock from reading to the final POST. A lost
            # browser connection cannot start a second worker or change identity.
            self._read(a, cookies, rows, count, release_work=False)
            if self.batch_cancel.is_set() or not self.draft:
                if self.batch_cancel.is_set() and self.read_job:
                    self.read_job.update(state='stopped', error='Đã dừng; chưa gửi bình luận.')
                    self.draft = None
                return
            if self.store.account(a['account_id'])['revision'] != a['revision']:
                raise LabError('Phiên đã thay đổi; lượt đã dừng.')
            items = [dict(p,text=text,status='pending',operation_id=str(uuid.uuid4()))
                     for p in self.draft['posts'] if not p['blocked']]
            with self.lock:
                self.batch = {'batch_id':str(uuid.uuid4()),'account_id':a['account_id'],
                              'state':'running','items':items,'total':len(items),'completed':0,
                              'skipped':len(self.draft['posts'])-len(items),
                              'sources':copy.deepcopy(self.read_job['rows'])}
                self.draft = None
                self.read_job = None
                if not items:
                    self.batch.update(state='completed',note='Không có bài mới được phép gửi; các bài trùng hoặc thiếu quyền đã được bỏ qua.')
                    return
            self._send_reviewed(a, cookies, release_work=False)
        except Exception:
            with self.lock:
                if self.batch:
                    self.batch.update(state='stopped',note='Lượt đã dừng do lỗi local; kiểm tra lịch sử trước khi thử lại.')
                elif self.read_job:
                    self.read_job.update(state='stopped',error='Không hoàn tất chuẩn bị gửi; chưa gửi bình luận.')
        finally:
            with self.lock:
                self.release()

    def save_account(self, payload):
        name, actor = payload.get('name', ''), payload.get('account_id')
        if not isinstance(name, str) or not 1 <= len(name.strip()) <= 60:
            raise LabError('Tên gợi nhớ cần từ 1 đến 60 ký tự.')
        with self.operation(), self.lock:
            previous = self.store.account(actor)
            cookies = payload.get('cookies')
            if cookies is None:
                xs = payload.get('xs')
                if xs == '' and self.store.account(actor):
                    cookies = self.store.cookies(actor)
                    extra = payload.get('extra', {})
                    if not isinstance(extra, dict):
                        raise LabError('Cookie bổ sung không hợp lệ.')
                    for key in ('datr', 'fr', 'sb'):
                        if extra.get(key):
                            cookies = [c for c in cookies if c['name'] != key]
                            cookies.append({'name': key, 'value': extra[key]})
                else:
                    cookies = [{'name': 'c_user', 'value': actor}, {'name': 'xs', 'value': xs}]
                    extra = payload.get('extra', {})
                    if not isinstance(extra, dict):
                        raise LabError('Cookie bổ sung không hợp lệ.')
                    cookies.extend({'name': k, 'value': extra[k]} for k in ('datr', 'fr', 'sb') if extra.get(k))
            cookies = normalize_cookies(cookies, actor)
            changed = not previous or self.store.cookies(actor) != cookies
            if changed:
                self.sync.cancel(actor)
                self.store.save(actor, name.strip(), cookies)
                self.account_views.pop(actor, None)
            else:
                self.store.rename(actor, name.strip())
            self._remember_view()
            if changed:
                self.account_views.pop(actor, None)
            self.store.active(actor)
            self._restore_view(actor)
            if changed:
                self.invalidate()
            if changed and self.AUTO_SYNC:
                self.sync.enqueue(self.store.account(actor))
        return self.state()

    def select_account(self, payload):
        with self.operation():
            a = self.actor(payload)
            if self.store.active() != a['account_id']:
                self._remember_view()
                self.store.active(a['account_id'])
                self._restore_view(a['account_id'])
        return self.state()

    def delete_account(self, payload):
        if payload.get('confirm') is not True:
            raise LabError('Xác nhận xóa phiên và nhóm đã lưu; lịch sử vẫn được giữ.')
        with self.operation(), self.lock:
            a = self.actor(payload)
            self.sync.cancel(a['account_id'])
            self.account_views.pop(a['account_id'], None)
            self.store.remove(a['account_id'])
            remaining = self.store.accounts()
            self.store.active(remaining[0]['account_id'] if remaining else '')
            self.invalidate()
        return self.state()

    def links(self, payload):
        with self.operation():
            a = self.actor(payload)
            rows = parse_links(payload.get('links'))
            for row in rows:
                if row['valid']:
                    g = row['group']
                    self.store.save_group(a['account_id'], g['url'], g['slug'])
            return {'rows': rows, 'groups': self.store.groups(a['account_id'])}

    def _remember_view(self):
        actor = self.store.active()
        if actor:
            self.account_views[actor] = (self.draft, self.read_job, self.batch)

    def _restore_view(self, actor):
        self.draft, self.read_job, self.batch = self.account_views.get(actor, (None, None, None))

    def sync_groups(self, payload):
        with self.lock:
            account = self.actor(payload)
            return {'started': True, 'job': self.sync.enqueue(account)}

    def stop_sync(self, payload):
        with self.lock:
            a = self.actor(payload)
            if not isinstance(payload.get('job_id'), str) or not self.sync.cancel(a['account_id'], payload['job_id']):
                raise LabError('Không tìm thấy công việc đồng bộ này.', 404)
            return {'stopping': True}

    def request_shutdown(self):
        super().request_shutdown()
        self.sync.shutdown()

    def recheck(self, payload):
        with self.operation(network=True):
            a = self.actor(payload)
            groups = self.store.groups(a['account_id'])
            if not groups:
                raise LabError('Lưu một link nhóm trước khi kiểm tra phiên.')
            try:
                load_recent_posts(groups[0]['url'], 10, self.store.cookies(a['account_id']), a['account_id'], strict=True)
            except (Exception, SystemExit) as exc:
                category = self.category(exc)
                if category in {'session_expired', 'verification_required', 'restricted'}:
                    self.store.block(a['account_id'], category)
                raise LabError(ERRORS.get(category, ERRORS['unrecognized_response']), 409) from None
            self.store.clear_expired(a['account_id'])
            blocked = self.store.account(a['account_id'])['blocked']
            return {'message': ('Đọc nhóm thành công. Thao tác gửi trước vẫn chưa được xác minh; xem Lịch sử và kiểm tra bài. Kiểm tra phiên không xóa khóa chống gửi trùng.'
                                if blocked else 'Phiên đọc nhóm hợp lệ. Quyền bình luận vẫn được kiểm tra theo từng bài.')}

    @staticmethod
    def category(exc):
        if isinstance(exc, RemoteStop):
            return exc.category
        if isinstance(exc, requests.RequestException):
            return 'network_error'
        return 'unrecognized_response'

    def load_links(self, payload):
        count = payload.get('count', 10)
        if type(count) is not int or count not in (10, 20, 50):
            raise LabError('Chọn tối đa 10, 20 hoặc 50 bài trong lượt.')
        rows = parse_links(payload.get('links'))
        with self.lock:
            self.acquire()
            try:
                a = self.actor(payload, sending=True)
                cookies = self.store.cookies(a['account_id'])
                self.invalidate()
                self.read_job = {'state': 'running', 'account_id': a['account_id'], 'completed': 0, 'total': len(rows), 'rows': copy.deepcopy(rows)}
                worker = threading.Thread(target=self._read, args=(a, cookies, rows, count), daemon=True)
                self.batch_thread = worker
                worker.start()
            except Exception:
                self.release()
                raise
        return {'started': True}

    def _read(self, a, cookies, rows, count, *, release_work=True):
        posts, cached = {}, {}
        stopped = False
        try:
            for row in rows:
                if self.batch_cancel.is_set():
                    stopped = True
                    break
                if not row['valid']:
                    with self.lock:
                        self.read_job['completed'] += 1
                    continue
                try:
                    group = row['group']
                    if group['url'] not in cached:
                        cached[group['url']] = load_recent_posts(group['url'], count, cookies, a['account_id'], strict=True,
                                                                 cancelled=self.batch_cancel.is_set)
                    result = cached[group['url']]
                    known = next((g for g in self.store.groups(a['account_id']) if g['url'] == group['url']), {})
                    resolved_name = (result.get('group') or {}).get('name') or known.get('name')
                    if resolved_name == group['slug']:
                        resolved_name = None
                    self.store.save_group(a['account_id'], group['url'], resolved_name or group['slug'], 'readable')
                    candidates = result['posts']
                    if row['kind'] == 'post':
                        candidates = [p for p in candidates if p['post_id'] == row['target']['post_id']]
                        if not candidates:
                            raise FeedError('Không đọc được nội dung bài này trong danh sách mới nhất. Chưa đưa vào lượt gửi.')
                    for p in candidates:
                        if p.get('excerpt'):
                            posts.setdefault(p['post_id'], dict(p, source=group['url'], group_name=resolved_name))
                    if not any(p.get('excerpt') for p in candidates):
                        raise FeedError('Không đọc được nội dung chữ; chưa đưa bài vào lượt gửi.')
                    row['result'] = 'Đã đọc'
                    if result.get('complete') is False:
                        row['error'] = f"Chỉ đọc được {result.get('actual_count', len(candidates))}/{count} bài; chưa đọc hết trang tiếp theo."
                except RemoteStop as exc:
                    row['diagnostic'] = diagnostic(exc, 'read')
                    row['error'] = ERRORS.get(exc.category, ERRORS['unrecognized_response'])
                    if exc.category != 'permission_denied':
                        if exc.category in {'session_expired','verification_required','restricted'}:
                            self.store.block(a['account_id'], exc.category)
                        stopped = True
                        break
                except FeedError as exc:
                    row['diagnostic'] = diagnostic(exc, 'read')
                    row['error'] = str(exc)
                    if self.batch_cancel.is_set():
                        stopped = True
                        break
                    # A read/parser failure stops this run, not future account use.
                    # No comment mutation has been attempted in this phase.
                    if not str(exc).startswith(('Không đọc được nội dung', 'Không lấy được bài')):
                        stopped = True
                        break
                except Exception as exc:
                    row['diagnostic'] = diagnostic(exc, 'read')
                    category = self.category(exc)
                    if category in {'session_expired','verification_required','restricted'}:
                        self.store.block(a['account_id'], category)
                    row['error'] = ERRORS.get(category, ERRORS['unrecognized_response'])
                    stopped = True
                    break
                finally:
                    with self.lock:
                        self.read_job['completed'] += 1
                        self.read_job['rows'] = copy.deepcopy(rows)
            items = sorted(posts.values(), key=lambda p: p['created_at'], reverse=True)[:count]
            journal = ProbeJournal(self.state_dir)
            try:
                for p in items:
                    p['blocked'] = journal.post_seen(p['post_id']) or not p['can_comment']
            finally:
                journal.close()
            with self.lock:
                self.draft = {'id': str(uuid.uuid4()), 'account_id': a['account_id'], 'revision': a['revision'],
                              'expires': time.time() + 600, 'posts': items} if not stopped else None
                self.read_job.update(state='stopped' if stopped else 'completed', rows=rows,
                                     posts=items, available=len(posts), requested_count=count, draft_id=self.draft['id'] if self.draft else None)
        except Exception:
            with self.lock:
                self.read_job.update(state='stopped', error='Không hoàn tất đọc dữ liệu; chưa tạo bản duyệt.')
        finally:
            if release_work:
                with self.lock:
                    self.release()

    def prepare(self, payload):
        with self.operation():
            a = self.actor(payload, sending=True)
            draft = self.draft
            if (not draft or payload.get('draft_id') != draft['id'] or draft['account_id'] != a['account_id']
                    or draft['revision'] != a['revision'] or draft['expires'] < time.time()):
                raise LabError('Bản đọc đã hết hạn hoặc phiên thay đổi. Lấy bài lại.', 409)
            submitted = payload.get('items')
            if not isinstance(submitted, list) or not 1 <= len(submitted) <= 50:
                raise LabError('Chọn từ 1 đến 50 bài.')
            by_id = {p['post_id']: p for p in draft['posts']}
            frozen, seen, warnings = [], set(), []
            journal = ProbeJournal(self.state_dir)
            try:
                for row in submitted:
                    if not isinstance(row, dict):
                        raise LabError('Mục duyệt không hợp lệ.')
                    post_id, text = row.get('post_id'), row.get('text')
                    if not isinstance(post_id, str) or post_id not in by_id or post_id in seen:
                        raise LabError('Bài không thuộc danh sách hoặc bị trùng.')
                    p = by_id[post_id]
                    if p['blocked'] or journal.post_seen(post_id):
                        raise LabError('Bài đã có lần xử lý hoặc không được bình luận.', 409)
                    if not isinstance(text, str) or not 1 <= len(text.strip()) <= 10000:
                        raise LabError('Nhập nội dung từ 1 đến 10.000 ký tự.')
                    seen.add(post_id)
                    if journal.content_seen(text):
                        warnings.append(post_id)
                    frozen.append(dict(p, text=text, status='pending', operation_id=str(uuid.uuid4())))
            finally:
                journal.close()
            op = str(uuid.uuid4())
            self.previews = {op: {'account_id': a['account_id'], 'revision': a['revision'],
                                  'items': frozen, 'expires': time.time() + 600, 'warnings': warnings}}
            return {'operation_id': op, 'count': len(frozen), 'reused_content': warnings}

    def start_reviewed(self, payload):
        with self.lock:
            self.acquire()
            try:
                a = self.actor(payload, sending=True)
                if payload.get('confirm') is not True:
                    raise LabError('Bấm Gửi để bắt đầu.')
                op = payload.get('operation_id')
                value = self.previews.get(op) if isinstance(op, str) else None
                if (not value or value['account_id'] != a['account_id'] or value['revision'] != a['revision']
                        or value['expires'] < time.time()):
                    raise LabError('Bản duyệt đã dùng, hết hạn hoặc phiên thay đổi.', 409)
                cookies = self.store.cookies(a['account_id'])
                self.previews.pop(op)
                self.draft = None
                self.read_job = None
                self.batch = {'batch_id': op, 'account_id': a['account_id'], 'state': 'running',
                              'items': value['items'], 'total': len(value['items']), 'completed': 0}
                self.batch_thread = threading.Thread(target=self._send_reviewed, args=(a, cookies), daemon=True)
                self.batch_thread.start()
            except Exception:
                self.release()
                raise
        return {'started': True}

    def _send_reviewed(self, a, cookies, *, release_work=True):
        try:
            for item in self.batch['items']:
                if self.batch_cancel.is_set():
                    break
                if item.get('can_comment') is False:
                    item['status'] = 'not_sent'
                    item['report'] = {'status':'not_sent','write_attempts':0,
                        'diagnostic':{'scope':'request','stage':'preflight','evidence':'target_not_commentable'},
                        'note':'Bài không có quyền bình luận; chưa gửi yêu cầu.'}
                    self.batch['completed'] += 1
                    continue
                with self.lock:
                    item['status'] = 'sending'
                try:
                    report = probe(item['target'], item['text'], cookies, a['account_id'],
                                   self.state_dir, item['operation_id'], strict=True,
                                   context={'account_name':a['name'], 'group_name':item.get('group_name'),
                                            'group_url':item.get('source')})
                except (Exception, SystemExit) as exc:
                    report = {'status': 'outcome_unknown', 'error_category': self.category(exc),
                              'diagnostic': diagnostic(exc, 'preflight'),
                              'note': 'Lượt đã dừng. Kiểm tra lịch sử và bài Facebook.'}
                with self.lock:
                    item['status'] = report['status']
                    item['report'] = report
                    self.batch['completed'] += 1
                if report['status'] != 'confirmed_by_response' or report.get('graphql_error_count') or report.get('journal_update_failed'):
                    category = report.get('error_category', 'unrecognized_response')
                    if category in {'session_expired','verification_required','restricted'} or not (report['status']=='not_sent' and report.get('write_attempts')==0):
                        self.store.block(a['account_id'], category)
                    with self.lock:
                        self.batch['state'] = 'stopped'
                        self.batch['note'] = ERRORS.get(category, ERRORS['unrecognized_response'])
                    break
                if self.batch_cancel.wait(1):
                    break
            with self.lock:
                if self.batch['state'] == 'running':
                    self.batch['state'] = 'completed' if self.batch['completed'] == self.batch['total'] else 'cancelled'
        except Exception:
            with self.lock:
                self.batch['state'] = 'stopped'
                self.batch['note'] = 'Lượt dừng do lỗi local. Kiểm tra lịch sử trước khi tiếp tục.'
        finally:
            with self.lock:
                for item in self.batch['items']:
                    if item['status'] == 'pending':
                        item['status'] = 'not_sent'
                    elif item['status'] == 'sending':
                        item['status'] = 'outcome_unknown'
                if release_work:
                    self.release()

    def stop_work(self, payload):
        with self.lock:
            job = (self.read_job if (self.read_job or {}).get('state') == 'running' else self.batch)
            if not job or payload.get('account_id') != job.get('account_id'):
                raise LabError('Sai tài khoản đang xử lý.')
            self.batch_cancel.set()
        return {'stopping': True}

    # Legacy write paths are not reachable from the HTTP router; cannot bypass review.
    def legacy_disabled(self, payload=None):
        raise LabError('Giao diện đã cập nhật. Tải lại trang và duyệt theo tài khoản.', 409)
