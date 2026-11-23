"""Run the frozen EXE with isolated fake data and the real installed Edge.

No Facebook requests or user profile reads. Terminate only browser processes
descended from this test EXE; do not close or inspect the user's browser windows.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import urllib.request

from scripts.desktop_window import process_snapshot, windows_for_process
from scripts.lab_server import UI_PROTOCOL


def request(base, path, body=None, csrf=None):
    headers = {}
    raw = None
    if body is not None:
        raw = json.dumps(body).encode()
        headers = {'Content-Type': 'application/json', 'Origin': base, 'X-Lab-CSRF': csrf}
    req = urllib.request.Request(base + path, data=raw, headers=headers)
    with urllib.request.urlopen(req, timeout=5) as res:
        assert res.status == 200
        return json.load(res)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('exe', type=Path)
    parser.add_argument('report', type=Path)
    parser.add_argument('--expect-broken', action='store_true')
    parser.add_argument('--clean-environment', action='store_true')
    args = parser.parse_args()
    report = {'ok': False, 'checks': [], 'observations': []}
    known = set()
    app = None
    env = os.environ.copy()
    env['COMMENTLAB_NETWORK_DISABLED'] = '1'
    if args.clean_environment:
        for key in list(env):
            if key.upper().startswith('PYTHON') or key.upper() in {'VIRTUAL_ENV','CONDA_PREFIX','CONDA_DEFAULT_ENV'}:
                env.pop(key)
        env['PATH'] = str(Path(os.environ['SystemRoot'])/'System32')
        report['clean_environment'] = True
    with tempfile.TemporaryDirectory(prefix='CommentLab-acceptance-', ignore_cleanup_errors=True) as temp:
        env['LOCALAPPDATA'] = temp
        runtime_path = Path(temp) / 'CommentLab/desktop-runtime.json'
        def snapshot():
            rows = process_snapshot()
            while True:
                new = {pid for pid, parent, name in rows
                       if parent in known and name.lower() == 'msedge.exe'} - known
                if not new:
                    break
                known.update(new)
            browsers = [(pid, parent) for pid, parent, name in rows
                        if pid in known and name.lower() == 'msedge.exe']
            visible = [pid for pid, _ in browsers if windows_for_process(pid)]
            return browsers, visible
        def cleanup_browsers():
            browsers, _ = snapshot()
            live = {pid for pid, _ in browsers}
            roots = [pid for pid, parent in browsers if parent not in live]
            for pid in roots:
                subprocess.run(['taskkill', '/PID', str(pid), '/T', '/F'],
                               capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            app = subprocess.Popen([str(args.exe.resolve())], env=env, cwd=temp,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
            known.add(app.pid)
            start = time.monotonic()
            runtime = None
            last = None
            for _ in range(300):
                browsers, visible = snapshot()
                if runtime_path.exists():
                    runtime = json.loads(runtime_path.read_text())
                observation = {'app_alive': app.poll() is None, 'edges': browsers,
                               'window_pids': visible,
                               'recorded_browser_pid': (runtime or {}).get('browser_pid')}
                if observation != last:
                    report['observations'].append(dict(seconds=round(time.monotonic()-start, 2), **observation))
                    last = observation
                if app.poll() is not None:
                    break
                if runtime and visible and time.monotonic()-start > 8:
                    break
                time.sleep(.1)
            if args.expect_broken:
                # Wait for the browser compatibility relaunch to settle.
                for _ in range(80):
                    snapshot()
                    if app.poll() is not None:
                        break
                    time.sleep(.1)
                browsers, visible = snapshot()
                report['old_exe_exit'] = app.poll()
                report['orphaned_edge_window'] = bool(visible) and app.poll() is not None
                report['live_browser_pids'] = visible
                report['recorded_browser_pid'] = (runtime or {}).get('browser_pid')
                report['ok'] = report['orphaned_edge_window']
                return
            assert app.poll() is None and runtime, 'EXE exited before app was ready'
            base = 'http://127.0.0.1:' + str(runtime['port'])
            state = request(base, '/api/state')
            assert state['ui_protocol'] == UI_PROTOCOL
            with urllib.request.urlopen(base+'/app.js', timeout=5) as response:
                assert ("const UI_PROTOCOL='"+UI_PROTOCOL+"'").encode() in response.read()
            report['checks'].append('shipped UI and backend protocol match on actual EXE port')
            assert not state['session']['saved']
            # Exercise the exact failing endpoint with synthetic credentials only.
            saved = request(base, '/api/accounts/save', {'account_id': '123', 'name':'Fixture', 'cookies': [
                {'name': 'c_user', 'value': '123'},
                {'name': 'xs', 'value': 'synthetic-desktop-acceptance-only'}]}, state['csrf'])
            assert saved['session']['saved']
            assert (Path(temp)/'CommentLab/private/accounts.sqlite3').is_file()
            assert not (Path(temp)/'CommentLab/private/session.json').exists()
            report['checks'].append('real frozen EXE: POST session saved to isolated data directory')
            preview = request(base, '/api/links/check', {'account_id':'123','links':'https://www.facebook.com/groups/456/'}, state['csrf'])
            assert preview['rows'][0]['valid']
            report['checks'].append('manual group link validation after account save; zero Facebook requests')
            assert request(base, '/api/history', {'offset':0}, state['csrf'])['items'] == []
            try:
                request(base, '/api/send/direct', {'text':'','count':50,'confirm':True}, state['csrf'])
                raise AssertionError('Empty direct send accepted')
            except urllib.error.HTTPError as exc:
                assert exc.code == 400, 'New frontend route missing in frozen backend'
            report['checks'].append('history and direct-send routes present in frozen backend; invalid send rejected before network')
            second = subprocess.run([str(args.exe.resolve())], env=env, cwd=temp, timeout=40,
                                    creationflags=subprocess.CREATE_NO_WINDOW)
            assert second.returncode == 0
            assert json.loads(runtime_path.read_text())['launcher_pid'] == app.pid
            _, visible = snapshot()
            assert len(visible) == 1
            report['checks'].append('second EXE launch reuses one server and one app window')
            # Cover delayed relaunch, idle and later POST, rather than immediate startup only.
            for _ in range(30):
                assert app.poll() is None, 'backend died while Edge remained open'
                state = request(base, '/api/state')
                assert state['session']['saved']
                snapshot()
                time.sleep(1)
            saved = request(base, '/api/accounts/save', {'account_id': '123', 'name':'Fixture', 'cookies': [
                {'name': 'c_user', 'value': '123'},
                {'name': 'xs', 'value': 'synthetic-desktop-acceptance-only'}]}, state['csrf'])
            assert saved['session']['saved']
            report['checks'].append('backend and Save session remain available after 30 seconds idle')
            # Destroy only this test browser process tree: lifecycle must release backend/port.
            cleanup_browsers()
            app.wait(timeout=20)
            assert app.returncode == 0
            assert not runtime_path.exists()
            try:
                request(base, '/api/state')
                raise AssertionError('backend survived window/process shutdown')
            except (OSError, urllib.error.URLError):
                pass
            report['checks'].append('test browser shutdown stops EXE and loopback server')
            # Reopen the same isolated data to check persistence, then clean up again.
            app = subprocess.Popen([str(args.exe.resolve())], env=env, cwd=temp,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
            known.add(app.pid)
            for _ in range(300):
                snapshot()
                if runtime_path.exists():
                    runtime = json.loads(runtime_path.read_text())
                    if runtime['launcher_pid'] == app.pid:
                        break
                time.sleep(.1)
            base = 'http://127.0.0.1:' + str(runtime['port'])
            assert request(base, '/api/state')['session']['saved']
            report['checks'].append('reopening preserves saved fixture session')
            report['ok'] = True
        except Exception as exc:
            events=Path(temp)/'CommentLab/desktop-events.jsonl'
            if events.exists(): report['lifecycle_events']=events.read_text().splitlines()
            report['error_type'] = type(exc).__name__
            report['error'] = str(exc)[:200]
        finally:
            cleanup_browsers()
            if app and app.poll() is None:
                try:
                    app.wait(timeout=15)
                except subprocess.TimeoutExpired:
                    app.terminate()
                    app.wait(timeout=10)
            args.report.write_text(json.dumps(report, indent=2), encoding='utf-8')
            # Keep detailed process observations in the report, not the console.
            print(json.dumps({key: value for key, value in report.items() if key != 'observations'}, indent=2))
    if not report['ok']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
