"""One read-only background queue. No session values in persisted job metadata."""
import copy
import json
import msvcrt
import threading
import time
import uuid

from scripts.remote_status import RemoteStop, diagnostic


class FileLease:
    def __init__(self, path):
        self.path, self.stream = path, None

    def acquire(self):
        stream = self.path.open('a+b')
        try:
            if stream.tell() == 0:
                stream.write(b'0'); stream.flush()
            stream.seek(0)
            msvcrt.locking(stream.fileno(), msvcrt.LK_NBLCK, 1)
        except OSError:
            stream.close()
            return False
        self.stream = stream
        return True

    def release(self):
        if self.stream:
            self.stream.seek(0)
            msvcrt.locking(self.stream.fileno(), msvcrt.LK_UNLCK, 1)
            self.stream.close()
            self.stream = None


class SyncJobs:
    LIVE = {'queued', 'running', 'stopping'}

    def __init__(self, lab, loader):
        self.lab, self.store, self.loader = lab, lab.store, loader
        self.thread = None
        self.closed = threading.Event()
        self.pending = []
        with self.store.connect() as db:
            db.execute('CREATE TABLE IF NOT EXISTS sync_jobs(actor TEXT PRIMARY KEY, payload TEXT NOT NULL)')
        # Do not mark a job belonging to another active process interrupted.
        lease = FileLease(lab.root / 'private/network.lock')
        if lease.acquire():
            try:
                for job in self.all():
                    if job['state'] in self.LIVE:
                        self.finish(job, 'interrupted', 'Đồng bộ bị gián đoạn. Bấm Đồng bộ để chạy lại.')
            finally:
                lease.release()

    def all(self):
        with self.store.connect() as db:
            return [json.loads(r['payload']) for r in db.execute('SELECT payload FROM sync_jobs')]

    def get(self, actor):
        return next((j for j in self.all() if j['account_id'] == actor), None)

    def write(self, job, expected=None):
        with self.store.connect() as db:
            db.execute('BEGIN IMMEDIATE')
            old = db.execute('SELECT payload FROM sync_jobs WHERE actor=?', (job['account_id'],)).fetchone()
            if expected and (not old or json.loads(old['payload'])['id'] != expected):
                return False
            db.execute('INSERT OR REPLACE INTO sync_jobs VALUES(?,?)', (job['account_id'], json.dumps(job, ensure_ascii=False)))
        return True

    def enqueue(self, account):
        with self.lab.lock:
            actor = account['account_id']
            old = self.get(actor)
            if old and old['state'] in self.LIVE and old['revision'] == account['revision']:
                return old
            job = dict(id=str(uuid.uuid4()), account_id=actor, revision=account['revision'],
                       state='queued', phase='queued', completed=0, total=None,
                       complete=False, updated=time.time(), message='Đang chờ đồng bộ nhóm.')
            self.write(job)
            self.pending.append(job)
            if not self.thread or not self.thread.is_alive():
                self.thread = threading.Thread(target=self.run, name='group-sync', daemon=True)
                self.thread.start()
            return copy.deepcopy(job)

    def valid(self, job):
        current = self.get(job['account_id'])
        account = self.store.account(job['account_id'])
        return (not self.closed.is_set() and account and account['revision'] == job['revision']
                and current and current['id'] == job['id'] and current['state'] in {'queued', 'running'})

    def finish(self, job, state, message, **extra):
        value = dict(job, state=state, message=message, updated=time.time(), **extra)
        self.write(value, expected=job['id'])

    def cancel(self, actor, job_id=None):
        with self.lab.lock:
            job = self.get(actor)
            if not job or (job_id and job['id'] != job_id):
                return False
            if job['state'] in self.LIVE:
                self.finish(job, 'stopping' if job['state']=='running' else 'cancelled', 'Đang dừng; chờ yêu cầu đọc hiện tại kết thúc.' if job['state']=='running' else 'Đã dừng đồng bộ. Giữ danh sách nhóm đã lưu.')
            return True

    def wait(self, timeout=5):
        thread = self.thread
        if thread:
            thread.join(timeout)

    def shutdown(self):
        self.closed.set()
        with self.lab.lock:
            for job in self.all():
                if job['state'] in self.LIVE:
                    self.finish(job, 'interrupted', 'Đồng bộ bị gián đoạn khi đóng app.')

    def run(self):
        while not self.closed.is_set():
            with self.lab.lock:
                if not self.pending:
                    self.thread = None
                    return
                job = self.pending.pop(0)
            lease = FileLease(self.lab.root / 'private/network.lock')
            while not self.closed.is_set():
                with self.lab.lock:
                    if not self.valid(job):
                        break
                if lease.acquire():
                    break
                self.closed.wait(.15)
            if not lease.stream:
                continue
            try:
                with self.lab.lock:
                    if not self.valid(job):
                        continue
                    job.update(state='running', phase='reading', message='Đang đọc nhóm đã tham gia…')
                    self.write(job, expected=job['id'])
                    cookies = self.store.cookies(job['account_id'])
                def cancelled():
                    with self.lab.lock:
                        return not self.valid(job)
                def progress(**values):
                    with self.lab.lock:
                        if not self.valid(job): return
                        job.update({k:v for k,v in values.items() if k in {'completed','pages_read','phase'}})
                        job['message'] = f"Đã đọc {job['completed']} nhóm · {job.get('pages_read', 0)} trang. " + ('Đang chuẩn bị trang tiếp theo…' if job['phase']=='resolving' else 'Đang đọc tiếp…')
                        job['updated'] = time.time()
                        self.write(job, expected=job['id'])
                result = self.loader(cookies, job['account_id'], cancelled=cancelled, progress=progress)
                cookies = None
                with self.lab.lock:
                    if not self.valid(job):
                        continue
                    # Revision + job check and group publication in one SQLite transaction.
                    job.update(pages_read=result.get('pages_read',job.get('pages_read',1)),
                               stop_reason=result.get('stop_reason','unknown'))
                    self.store.publish_joined(job, result['groups'], result['complete'] is True)
            except (Exception, SystemExit) as exc:
                with self.lab.lock:
                    if self.valid(job):
                        if isinstance(exc, RemoteStop) and exc.category in {'session_expired', 'verification_required', 'restricted'}:
                            self.store.block(job['account_id'], exc.category)
                        self.finish(job, 'unavailable', 'Chưa đồng bộ được. Giữ nhóm cũ; bạn có thể gắn link.',
                                    diagnostic=diagnostic(exc, 'sync'))
            finally:
                cookies = None
                with self.lab.lock:
                    current = self.get(job['account_id'])
                    if current and current['id']==job['id'] and current['state']=='stopping':
                        self.finish(current, 'cancelled', 'Đã dừng đồng bộ; giữ danh sách cũ.')
                lease.release()
