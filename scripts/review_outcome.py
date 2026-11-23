"""Operator acknowledgement keeps the original outcome and permanent post lock."""
import json
import sqlite3
import time
from contextlib import closing

UNKNOWN = {'reserved', 'outcome_unknown', 'unconfirmed'}
SESSION = {'session_expired', 'verification_required', 'restricted'}
APP_REASONS = {'unrecognized_response', 'network_error', 'remote_error', 'permission_denied'}
ACTION = 'skip_keep_duplicate_lock'


def eligible(report):
    return (report.get('status') in UNKNOWN
            and report.get('error_category') not in SESSION
            and (report.get('diagnostic') or {}).get('scope') != 'session'
            and bool((report.get('target') or {}).get('post_id')))


def reviewed(report):
    return (report.get('operator_review') or {}).get('action') == ACTION


def skip(journal_path, accounts_path, actor, revision, operation_id, post_id):
    if not journal_path.is_file():
        raise ValueError('Không tìm thấy lịch sử cần kiểm tra.')
    with closing(sqlite3.connect(journal_path, timeout=10)) as db:
        db.execute('PRAGMA synchronous=FULL')
        db.execute('ATTACH DATABASE ? AS vault', (str(accounts_path),))
        # Both SQLite files use rollback journals. The acknowledgement and hold
        # release commit together; a failure cannot release without recording it.
        with db:
            db.execute('BEGIN IMMEDIATE')
            account = db.execute('SELECT revision FROM vault.accounts WHERE actor=?', (actor,)).fetchone()
            if not account or account[0] != revision:
                raise ValueError('Tài khoản hoặc phiên đã thay đổi. Mở lại chi tiết để kiểm tra.')
            row = db.execute('SELECT report FROM attempts WHERE operation_id=?', (operation_id,)).fetchone()
            if not row:
                raise ValueError('Không tìm thấy lần gửi này.')
            report = json.loads(row[0])
            if report.get('actor_id') != actor or (report.get('target') or {}).get('post_id') != post_id:
                raise ValueError('Tài khoản hoặc bài không khớp lần gửi.')
            if not eligible(report):
                raise ValueError('Không thể bỏ qua lỗi phiên/xác minh/hạn chế hoặc kết quả đã xác định bằng thao tác này.')
            if not reviewed(report):
                report['operator_review'] = {'action': ACTION, 'at': time.time(), 'actor_id': actor}
                db.execute('UPDATE attempts SET report=? WHERE operation_id=?',
                           (json.dumps(report, ensure_ascii=False), operation_id))
            # Never delete this row, including legacy journals missing their lock.
            db.execute('INSERT OR IGNORE INTO post_locks VALUES(?,?)', (post_id, operation_id))
            remaining, acknowledged_reasons, pending_reason = 0, set(), 'unrecognized_response'
            for raw, in db.execute('SELECT report FROM attempts'):
                item = json.loads(raw)
                if item.get('actor_id') == actor and item.get('status') in UNKNOWN and not reviewed(item):
                    remaining += 1
                    pending_reason = item.get('error_category') or 'unrecognized_response'
                if item.get('actor_id') == actor and reviewed(item) and eligible(item):
                    acknowledged_reasons.add(item.get('error_category') or 'unrecognized_response')
            hold = db.execute('SELECT reason FROM vault.app_holds WHERE actor=?', (actor,)).fetchone()
            session = db.execute('SELECT reason FROM vault.blocks WHERE actor=?', (actor,)).fetchone()
            # A crash can leave a reserved operation before its hold was written.
            # Reviewing a different operation must not accidentally allow sending.
            if remaining and not hold:
                db.execute('INSERT INTO vault.app_holds VALUES(?,?)', (actor,pending_reason))
            # This button has no authority over authentication or platform restrictions.
            if remaining == 0 and not session and hold and hold[0] in APP_REASONS:
                if hold[0] in acknowledged_reasons:
                    db.execute('DELETE FROM vault.app_holds WHERE actor=? AND reason=?', (actor, hold[0]))
            blocked = bool(session or db.execute('SELECT 1 FROM vault.app_holds WHERE actor=?', (actor,)).fetchone())
            return {'review':report['operator_review'], 'remaining':remaining,
                    'can_continue':not blocked, 'post_locked':True}
