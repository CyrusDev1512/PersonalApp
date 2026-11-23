"""Windows desktop launcher; packaged assets are separate from private user data."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import time

from scripts.desktop_window import BrowserWindowTracker, focus_process, wait_for_window_close

from scripts.lab_server import make_server, protect_directory


def desktop_event(root, event, **fields):
    """Small lifecycle-only diagnostic ring; never accepts requests or credentials."""
    allowed = {'browser_pid', 'port', 'exception_type'}
    entry = {'event': event, 'time': int(time.time()), 'launcher_pid': os.getpid()}
    entry.update({key: value for key, value in fields.items() if key in allowed})
    try:
        path = root / 'desktop-events.jsonl'
        rows = path.read_text(encoding='utf-8').splitlines()[-63:] if path.exists() else []
        rows.append(json.dumps(entry))
        path.write_text('\n'.join(rows) + '\n', encoding='utf-8')
    except OSError:
        pass  # Diagnostics must never stop the app.


def asset_root():
    return Path(getattr(sys, "_MEIPASS", Path(__file__).resolve().parents[1]))


def data_root():
    """An in-repo EXE keeps the existing source vault; standalone ZIP uses AppData.

    Do not copy or merge either vault/journal. Require both source code and the
    existing database beside the EXE so ordinary extracted bundles stay portable.
    """
    beside = Path(sys.executable).resolve().parent if getattr(sys, 'frozen', False) else Path(__file__).resolve().parents[1]
    if ((beside / 'scripts/lab_server.py').is_file()
            and (beside / 'private/accounts.sqlite3').is_file()):
        return beside
    return Path(os.environ['LOCALAPPDATA']) / 'CommentLab'


def edge_path():
    for base in (os.environ.get("PROGRAMFILES(X86)"), os.environ.get("PROGRAMFILES"),
                 os.environ.get("LOCALAPPDATA")):
        if base:
            path = Path(base) / "Microsoft/Edge/Application/msedge.exe"
            if path.is_file():
                return path
    return None


def smoke_test(report_path):
    """Exercise the frozen runtime through loopback only; no user data or Facebook."""
    import urllib.request
    import urllib.error
    report = {"ok": False, "checks": []}
    try:
        frozen = bool(getattr(sys,'frozen',False))
        isolated = all(Path(p).resolve().is_relative_to(asset_root().resolve()) for p in sys.path)
        report['runtime'] = {'frozen':frozen, 'bundled_python':(asset_root()/'python312.dll').is_file(),
                             'isolated_import_paths':isolated}
        if frozen:
            assert isolated and report['runtime']['bundled_python']
        with tempfile.TemporaryDirectory(prefix="commentlab-smoke-") as temp:
            server = make_server(temp, port=0, asset_root=asset_root())
            worker = threading.Thread(target=server.serve_forever, daemon=True)
            worker.start()
            base = f"http://127.0.0.1:{server.server_port}"
            try:
                for path, mime in (("/", "text/html"), ("/app.js", "text/javascript"),
                                   ("/app.css", "text/css")):
                    with urllib.request.urlopen(base + path, timeout=10) as res:
                        assert res.status == 200 and mime in res.headers['Content-Type']
                        assert len(res.read()) > 100
                    report["checks"].append(path)
                with urllib.request.urlopen(base + "/api/state", timeout=10) as res:
                    state = json.load(res)
                assert not state['session']['saved'] and not state['history']
                headers = {'Content-Type': 'application/json', 'Origin': base,
                           'X-Lab-CSRF': state['csrf']}
                body = b'{}'
                req = urllib.request.Request(base + '/api/preview', data=body,
                                             headers={'Content-Type': 'application/json'})
                try:
                    urllib.request.urlopen(req, timeout=10)
                    raise AssertionError('CSRF bypass')
                except urllib.error.HTTPError as exc:
                    assert exc.code == 403
                report['checks'].append('CSRF rejection')
                assert not (Path(temp) / 'private/session.json').exists()
                body = json.dumps({'account_id': '123', 'name':'Fixture','cookies': [
                    {'name': 'c_user', 'value': '123'},
                    {'name': 'xs', 'value': 'synthetic-frozen-smoke-only'}]}).encode()
                req = urllib.request.Request(base + '/api/accounts/save', data=body, headers=headers)
                with urllib.request.urlopen(req, timeout=10) as res:
                    assert json.load(res)['session']['saved']
                with urllib.request.urlopen(base + '/api/state', timeout=10) as res:
                    assert json.load(res)['session']['saved']
                report['checks'].append('POST save session and reload state with isolated synthetic cookies')
                assert not (Path(temp) / 'private/session.json').exists()
                assert (Path(temp) / 'private/accounts.sqlite3').exists()
                report['checks'].append('DPAPI vault; no plaintext session')
                server.lab.sync.wait(5)
                from scripts.comment_probe import ProbeJournal
                journal=ProbeJournal(server.lab.state_dir)
                try:
                    pending={'operation_id':'smoke-review','actor_id':'123','target':{'post_id':'456'},
                             'status':'outcome_unknown','error_category':'unrecognized_response','write_attempts':1}
                    journal.reserve('smoke-review','smoke-review',pending,strict=True)
                    journal.finish('smoke-review',pending)
                    server.lab.store.block('123','unrecognized_response')
                    payload=json.dumps({'account_id':'123','revision':1,'operation_id':'smoke-review',
                                        'post_id':'456','confirm':True}).encode()
                    req=urllib.request.Request(base+'/api/history/skip-reviewed',data=payload,
                                               headers={'Content-Type':'application/json'})
                    try:
                        urllib.request.urlopen(req,timeout=10)
                        raise AssertionError('Review CSRF bypass')
                    except urllib.error.HTTPError as exc:
                        assert exc.code==403
                    req=urllib.request.Request(base+'/api/history/skip-reviewed',data=payload,headers=headers)
                    with urllib.request.urlopen(req,timeout=10) as res:
                        result=json.load(res)
                    assert result['can_continue'] and result['post_locked']
                    assert journal.get('smoke-review')['status']=='outcome_unknown' and journal.post_seen('456')
                    report['checks'].append('Review unknown outcome over HTTP; CSRF, original outcome and post lock preserved')
                finally:
                    journal.close()
                report['ok'] = True
            finally:
                server.lab.request_shutdown()
                server.lab.sync.wait(5)
                server.shutdown()
                server.server_close()
                worker.join(timeout=5)
    except Exception as exc:
        report['error_type'] = type(exc).__name__
    Path(report_path).write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    return 0 if report['ok'] else 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--smoke-test', metavar='REPORT')
    args = parser.parse_args()
    if args.smoke_test or os.environ.get('COMMENTLAB_NETWORK_DISABLED') == '1':
        import requests
        def offline_request(*args, **kwargs):
            raise requests.ConnectionError('Outbound network disabled for acceptance tests.')
        requests.sessions.Session.request = offline_request
    if args.smoke_test:
        return smoke_test(args.smoke_test)
    import msvcrt
    state_root = data_root()
    lock_file = None
    server = None
    browser = None
    owns_lock = False
    runtime_file = state_root / 'desktop-runtime.json'
    try:
        edge = edge_path()
        if not edge:
            raise RuntimeError('Cần Microsoft Edge để mở cửa sổ ứng dụng. Hãy cài Edge rồi mở lại.')
        # The source checkout already exists; only private subdirectories need ACLs.
        if (state_root / 'scripts/lab_server.py').is_file():
            state_root.mkdir(parents=True, exist_ok=True)
        else:
            protect_directory(state_root)
        lock_file = (state_root / 'desktop.lock').open('a+b')
        if lock_file.seek(0, 2) == 0:
            lock_file.write(b'0')
            lock_file.flush()
        lock_file.seek(0)
        try:
            msvcrt.locking(lock_file.fileno(), msvcrt.LK_NBLCK, 1)
            owns_lock = True
        except OSError:
            desktop_event(state_root, 'reuse_started')
            # Wait for the first instance to finish startup, then focus its window.
            for _ in range(150):
                try:
                    runtime = json.loads(runtime_file.read_text(encoding='utf-8'))
                    desktop_event(state_root, 'reuse_focusing', browser_pid=int(runtime['browser_pid']))
                    if focus_process(int(runtime['browser_pid'])):
                        desktop_event(state_root, 'reuse_ready')
                        return 0
                except (OSError, ValueError, KeyError, TypeError):
                    pass
                time.sleep(.2)
            raise RuntimeError('Ứng dụng đang khởi động hoặc bản cũ còn chạy. Đóng bản cũ rồi mở lại.')
        runtime_file.unlink(missing_ok=True)
        desktop_event(state_root, 'desktop_started')
        for filename in ('index.html', 'app.css', 'app.js'):
            if not (asset_root() / 'ui' / filename).is_file():
                raise RuntimeError('Thiếu file giao diện. Hãy giải nén đầy đủ cả thư mục _internal.')
        server = make_server(state_root, port=0, asset_root=asset_root())
        threading.Thread(target=server.serve_forever, daemon=True).start()
        address = f'http://127.0.0.1:{server.server_port}/'
        # A dedicated profile avoids handing the app to the user's normal browser.
        # Edge may still relaunch itself, so follow its descendant window owners.
        with tempfile.TemporaryDirectory(prefix='app-window-', dir=state_root,
                                         ignore_cleanup_errors=True) as profile:
            browser = subprocess.Popen([str(edge), '--app=' + address,
                                        '--user-data-dir=' + profile, '--no-first-run',
                                        '--no-default-browser-check', '--disable-background-mode',
                                        '--window-size=1280,800'],
                                       creationflags=subprocess.CREATE_NO_WINDOW)
            tracker = BrowserWindowTracker(browser.pid)
            def ready(pid):
                runtime_file.write_text(json.dumps({'browser_pid': pid, 'port': server.server_port,
                                                    'launcher_pid': os.getpid()}), encoding='utf-8')
                desktop_event(state_root, 'browser_ready', browser_pid=pid, port=server.server_port)
            try:
                wait_for_window_close(browser, ready, find_windows=tracker)
                desktop_event(state_root, 'app_window_closed', browser_pid=tracker.active_pid)
                server.lab.request_shutdown()
                # A closed UI must not interrupt an in-flight comment and leave an
                # avoidable unknown result. Finish it before releasing the lock.
                while server.lab.busy:
                    time.sleep(.2)
            finally:
                if browser.poll() is None:
                    try:
                        browser.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        browser.terminate()
                        browser.wait(timeout=10)
        return 0
    except Exception as exc:
        desktop_event(state_root, 'desktop_error' if owns_lock else 'reuse_error', exception_type=type(exc).__name__)
        import tkinter as tk
        from tkinter import messagebox
        window = tk.Tk()
        window.withdraw()
        message = str(exc) if isinstance(exc, RuntimeError) else 'Không mở được ứng dụng. Kiểm tra quyền ghi thư mục và giải nén đầy đủ rồi thử lại.'
        messagebox.showerror('Comment Lab', message)
        window.destroy()
        return 1
    finally:
        if server is not None:
            server.shutdown()
            server.server_close()
            desktop_event(state_root, 'backend_stopped')
        if owns_lock:
            runtime_file.unlink(missing_ok=True)
        if lock_file is not None:
            lock_file.close()


if __name__ == '__main__':
    raise SystemExit(main())
