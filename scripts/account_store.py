"""Windows-local account vault. Never serialize decrypted sessions to disk."""
import ctypes
from ctypes import wintypes
import json
import os
from pathlib import Path
import sqlite3
import time
from contextlib import contextmanager


def crypt(data, decrypt=False):
    if os.name != 'nt':
        raise OSError('Kho phiên yêu cầu Windows DPAPI.')
    class Blob(ctypes.Structure):
        _fields_ = [('size', wintypes.DWORD), ('data', ctypes.POINTER(ctypes.c_ubyte))]
    buf = ctypes.create_string_buffer(data)
    source = Blob(len(data), ctypes.cast(buf, ctypes.POINTER(ctypes.c_ubyte)))
    output = Blob()
    api = ctypes.windll.crypt32.CryptUnprotectData if decrypt else ctypes.windll.crypt32.CryptProtectData
    if not api(ctypes.byref(source), None, None, None, None, 1, ctypes.byref(output)):
        raise OSError('Không mở được kho phiên Windows. Không ghi đè dữ liệu.')
    try:
        return ctypes.string_at(output.data, output.size)
    finally:
        ctypes.windll.kernel32.LocalFree(output.data)


class AccountStore:
    def __init__(self, directory):
        self.path = Path(directory) / 'accounts.sqlite3'
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as db:
            db.executescript('''
                CREATE TABLE IF NOT EXISTS accounts(
                    actor TEXT PRIMARY KEY, name TEXT NOT NULL, secret BLOB NOT NULL,
                    revision INTEGER NOT NULL DEFAULT 1, updated REAL NOT NULL);
                CREATE TABLE IF NOT EXISTS blocks(actor TEXT PRIMARY KEY, reason TEXT NOT NULL);
                CREATE TABLE IF NOT EXISTS app_holds(actor TEXT PRIMARY KEY, reason TEXT NOT NULL);
                CREATE TABLE IF NOT EXISTS groups_saved(
                    actor TEXT NOT NULL, url TEXT NOT NULL, name TEXT NOT NULL,
                    source TEXT NOT NULL DEFAULT 'manual', state TEXT NOT NULL DEFAULT 'saved',
                    updated REAL NOT NULL, PRIMARY KEY(actor,url));
                CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY,value TEXT NOT NULL);
            ''')
            # Preserve every old stop, but distinguish an app hold from session evidence.
            db.execute("INSERT OR IGNORE INTO app_holds SELECT actor,reason FROM blocks WHERE reason NOT IN ('session_expired','verification_required','restricted')")
            db.execute("DELETE FROM blocks WHERE reason NOT IN ('session_expired','verification_required','restricted')")

    @contextmanager
    def connect(self):
        db = sqlite3.connect(self.path, timeout=10)
        db.row_factory = sqlite3.Row
        db.execute('PRAGMA synchronous=FULL')
        db.execute('PRAGMA secure_delete=ON')
        try:
            with db:
                yield db
        finally:
            db.close()

    def accounts(self):
        with self.connect() as db:
            return [dict(row) for row in db.execute('''SELECT a.actor account_id,a.name,a.revision,
                a.updated,COALESCE(b.reason,h.reason,'') blocked,
                COALESCE(b.reason,'') session_issue,COALESCE(h.reason,'') app_hold
                FROM accounts a LEFT JOIN blocks b ON b.actor=a.actor
                LEFT JOIN app_holds h ON h.actor=a.actor ORDER BY a.name,a.actor''')]

    def account(self, actor):
        return next((a for a in self.accounts() if a['account_id'] == actor), None)

    def save(self, actor, name, cookies):
        raw = json.dumps(cookies, ensure_ascii=False).encode()
        encrypted = crypt(raw)
        if crypt(encrypted, True) != raw:
            raise OSError('Không xác minh được dữ liệu mã hóa.')
        with self.connect() as db:
            db.execute('''INSERT INTO accounts(actor,name,secret,updated) VALUES(?,?,?,?)
                ON CONFLICT(actor) DO UPDATE SET name=excluded.name,secret=excluded.secret,
                revision=accounts.revision+1,updated=excluded.updated''',
                (actor, name, encrypted, time.time()))
        # Verify the durable value before deleting any legacy source.
        if self.cookies(actor) != cookies:
            raise OSError('Không đọc lại được phiên vừa lưu.')

    def rename(self, actor, name):
        with self.connect() as db:
            db.execute('UPDATE accounts SET name=?,updated=? WHERE actor=?', (name, time.time(), actor))

    def publish_joined(self, job, groups, complete):
        with self.connect() as db:
            db.execute('BEGIN IMMEDIATE')
            account = db.execute('SELECT revision FROM accounts WHERE actor=?', (job['account_id'],)).fetchone()
            current = db.execute('SELECT payload FROM sync_jobs WHERE actor=?', (job['account_id'],)).fetchone()
            current = json.loads(current['payload']) if current else {}
            if (not account or account['revision'] != job['revision'] or current.get('id') != job['id']
                    or current.get('state') != 'running'):
                return False
            for group in groups:
                db.execute('''INSERT INTO groups_saved(actor,url,name,source,state,updated)
                    VALUES(?,?,?,'sync','member',?) ON CONFLICT(actor,url) DO UPDATE SET
                    name=excluded.name,source='sync',state='member',updated=excluded.updated''',
                    (job['account_id'], group['url'], group['name'], time.time()))
            value = dict(job, state='completed' if complete else 'partial', phase='finished',
                         completed=len(groups), complete=complete, updated=time.time(),
                         message=f'Đã đồng bộ {len(groups)} nhóm · {job.get("pages_read", 1)} trang.' +
                         (' Đã đọc đến trang cuối.' if complete else ' Chưa đầy đủ: ' + {
                             'pagination_unavailable':'chưa nhận diện được truy vấn trang tiếp theo.',
                             'repeated_cursor':'nguồn lặp lại mốc phân trang.',
                             'page_limit':'đã chạm giới hạn bảo vệ của một lượt đọc.'
                         }.get(job.get('stop_reason'),'chưa xác minh được trang cuối.')))
            db.execute('UPDATE sync_jobs SET payload=? WHERE actor=?', (json.dumps(value, ensure_ascii=False), job['account_id']))
            return True

    def cookies(self, actor):
        with self.connect() as db:
            row = db.execute('SELECT secret FROM accounts WHERE actor=?', (actor,)).fetchone()
        if row is None:
            raise ValueError('Không tìm thấy tài khoản.')
        return json.loads(crypt(bytes(row['secret']), True))

    def remove(self, actor):
        with self.connect() as db:
            db.execute('DELETE FROM groups_saved WHERE actor=?', (actor,))
            db.execute('DELETE FROM accounts WHERE actor=?', (actor,))
        # Blocks intentionally survive removal and re-addition of the same identity.

    def block(self, actor, reason):
        if reason not in {'session_expired', 'verification_required', 'restricted'}:
            with self.connect() as db:
                db.execute('INSERT OR REPLACE INTO app_holds VALUES(?,?)', (actor, reason))
            return
        with self.connect() as db:
            previous = db.execute('SELECT reason FROM blocks WHERE actor=?', (actor,)).fetchone()
            durable = {'restricted', 'verification_required', 'unrecognized_response'}
            if previous and previous['reason'] in durable and reason not in durable:
                return
            db.execute('INSERT OR REPLACE INTO blocks VALUES(?,?)', (actor, reason))

    def clear_expired(self, actor):
        with self.connect() as db:
            db.execute("DELETE FROM blocks WHERE actor=? AND reason='session_expired'", (actor,))

    def groups(self, actor):
        with self.connect() as db:
            return [dict(row) for row in db.execute('SELECT * FROM groups_saved WHERE actor=? ORDER BY name', (actor,))]

    def save_group(self, actor, url, name, state='saved'):
        with self.connect() as db:
            db.execute('''INSERT INTO groups_saved(actor,url,name,state,updated) VALUES(?,?,?,?,?)
                ON CONFLICT(actor,url) DO UPDATE SET
                name=CASE WHEN groups_saved.source='sync' THEN groups_saved.name ELSE excluded.name END,
                state=CASE WHEN groups_saved.source='sync' THEN groups_saved.state ELSE excluded.state END,
                updated=excluded.updated''',
                (actor, url, name, state, time.time()))

    def save_joined(self, actor, groups):
        with self.connect() as db:
            for group in groups:
                db.execute('''INSERT INTO groups_saved(actor,url,name,source,state,updated)
                    VALUES(?,?,?,'sync','member',?) ON CONFLICT(actor,url) DO UPDATE SET
                    name=excluded.name,source='sync',state='member',updated=excluded.updated''',
                    (actor, group['url'], group['name'], time.time()))

    def active(self, actor=None):
        with self.connect() as db:
            if actor is not None:
                db.execute("INSERT OR REPLACE INTO settings VALUES('active',?)", (actor,))
            row = db.execute("SELECT value FROM settings WHERE key='active'").fetchone()
        return row['value'] if row else ''
