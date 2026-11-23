from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from scripts.desktop import asset_root, data_root, edge_path
from scripts.lab_server import Lab
from scripts.desktop_window import BrowserWindowTracker, wait_for_window_close, focus_process
from unittest.mock import Mock


class DesktopTests(unittest.TestCase):
    def test_in_repo_exe_reuses_existing_vault_without_moving_data(self):
        with tempfile.TemporaryDirectory() as root:
            folder = Path(root)
            (folder / 'scripts').mkdir()
            (folder / 'scripts/lab_server.py').touch()
            (folder / 'private').mkdir()
            (folder / 'private/accounts.sqlite3').write_bytes(b'fixture existing vault')
            with patch('sys.executable', str(folder/'CommentLab.exe')), patch('sys.frozen', True, create=True):
                self.assertEqual(data_root(), folder.resolve())
            self.assertEqual((folder/'private/accounts.sqlite3').read_bytes(), b'fixture existing vault')

    def test_standalone_bundle_uses_appdata_even_if_database_beside_it(self):
        with tempfile.TemporaryDirectory() as root, tempfile.TemporaryDirectory() as appdata:
            folder = Path(root)
            (folder/'private').mkdir()
            (folder/'private/accounts.sqlite3').touch()
            with patch('sys.executable', str(folder/'CommentLab.exe')), patch('sys.frozen', True, create=True), patch.dict('os.environ', LOCALAPPDATA=appdata):
                self.assertEqual(data_root(), Path(appdata)/'CommentLab')

    def test_separate_assets_do_not_move_private_data(self):
        with tempfile.TemporaryDirectory() as data, tempfile.TemporaryDirectory() as assets:
            lab = Lab(data, asset_root=assets)
            self.assertEqual(lab.cookie_path, Path(data) / 'private/session.json')
            self.assertEqual(lab.state_dir, Path(data) / '.probe')
            self.assertEqual(lab.asset_root, Path(assets))
            self.assertEqual(Lab(data).asset_root, Path(data))

    def test_frozen_asset_root(self):
        with patch('sys._MEIPASS', 'C:/test/frozen', create=True):
            self.assertEqual(asset_root(), Path('C:/test/frozen'))

    def test_no_edge_has_browser_fallback(self):
        with patch.dict('os.environ', {}, clear=True):
            self.assertIsNone(edge_path())


class WindowLifecycleTests(unittest.TestCase):
    def run_lifecycle(self, observations, exit_code=None, timeout=4):
        process = Mock(pid=123)
        process.poll.return_value = exit_code
        now = [0.0]
        values = iter(observations)
        last = [[]]
        def find(_):
            last[0] = next(values, last[0])
            return last[0]
        def sleep(delay):
            now[0] += delay
        ready = Mock()
        wait_for_window_close(process, ready, find, sleep, lambda: now[0], timeout)
        return ready

    def test_reopening_restores_window_without_waiting_for_edge_ui(self):
        api=Mock()
        with patch('scripts.desktop_window.windows_for_process',return_value=[77]), patch('scripts.desktop_window.ctypes.WinDLL',return_value=api):
            self.assertTrue(focus_process(123))
        api.ShowWindowAsync.assert_called_once_with(77,9)
        api.ShowWindow.assert_not_called()
        api.SetForegroundWindow.assert_called_once_with(77)

    def test_startup_then_window_close_returns(self):
        ready = self.run_lifecycle([[], [], [45], [45], []])
        ready.assert_called_once_with(123)

    def test_transient_missing_window_does_not_exit(self):
        ready = self.run_lifecycle([[45], [], [], [45], [45], []])
        ready.assert_called_once_with(123)

    def test_browser_start_failure_is_not_success(self):
        with self.assertRaises(RuntimeError):
            self.run_lifecycle([[]], exit_code=1)

    def test_no_window_startup_times_out(self):
        with self.assertRaises(RuntimeError):
            self.run_lifecycle([[]])

    def test_launcher_exit_before_child_window_is_not_app_exit(self):
        ready = self.run_lifecycle([[], [], [45], [45], []], exit_code=0)
        ready.assert_called_once_with(123)

    def test_window_owner_relaunch_updates_ready_metadata(self):
        process = Mock(pid=123)
        finder = Mock()
        now = [0.0]
        observations = iter([(123, [45]), (456, [67]), (456, [])])
        last = [(456, [])]
        def find(_):
            last[0] = next(observations, last[0])
            finder.active_pid, windows = last[0]
            return windows
        finder.side_effect = find
        ready = Mock()
        wait_for_window_close(process, ready, finder,
                              lambda seconds: now.__setitem__(0, now[0] + seconds),
                              lambda: now[0])
        self.assertEqual([call.args[0] for call in ready.call_args_list], [123, 456])


class BrowserTreeTests(unittest.TestCase):
    def test_relaunch_descendant_survives_dead_parent(self):
        # Snapshot order is deliberately child-first; original Edge PID is gone.
        rows = [(300, 200, 'msedge.exe'), (200, 100, 'msedge.exe'),
                (400, 1, 'msedge.exe'), (500, 100, 'unrelated.exe')]
        tracker = BrowserWindowTracker(100, snapshot=lambda: rows,
                                       find=lambda pid: [77] if pid == 300 else [],
                                       exists=lambda hwnd, pid: pid == 300)
        self.assertEqual(tracker(100), [77])
        self.assertEqual(tracker.active_pid, 300)
        self.assertEqual(tracker.pids, {100, 200, 300})

    def test_hidden_window_still_keeps_backend_alive(self):
        visible = [True]
        exists = [True]
        tracker = BrowserWindowTracker(100, snapshot=lambda: [(100, 1, 'msedge.exe')],
                                       find=lambda _: [77] if visible[0] else [],
                                       exists=lambda *_: exists[0])
        self.assertEqual(tracker(100), [77])
        visible[0] = False
        self.assertEqual(tracker(100), [77])
        exists[0] = False
        self.assertEqual(tracker(100), [])

    def test_new_browser_owner_replaces_destroyed_window(self):
        rows = [(100, 1, 'msedge.exe')]
        live = {100: [77]}
        tracker = BrowserWindowTracker(100, snapshot=lambda: rows,
                                       find=lambda pid: live.get(pid, []),
                                       exists=lambda hwnd, pid: hwnd in live.get(pid, []))
        self.assertEqual(tracker(100), [77])
        rows[:] = [(200, 100, 'msedge.exe')]
        live.clear()
        live[200] = [88]
        self.assertEqual(tracker(100), [88])
        self.assertEqual(tracker.active_pid, 200)
