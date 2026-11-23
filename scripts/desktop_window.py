"""Windows app-window lifecycle helpers, used by the shipped desktop application."""
import ctypes
from ctypes import wintypes
import time


class ProcessEntry(ctypes.Structure):
    _fields_ = [('dwSize', wintypes.DWORD), ('cntUsage', wintypes.DWORD),
                ('th32ProcessID', wintypes.DWORD), ('th32DefaultHeapID', ctypes.c_size_t),
                ('th32ModuleID', wintypes.DWORD), ('cntThreads', wintypes.DWORD),
                ('th32ParentProcessID', wintypes.DWORD), ('pcPriClassBase', wintypes.LONG),
                ('dwFlags', wintypes.DWORD), ('szExeFile', wintypes.WCHAR * 260)]


def process_snapshot():
    """Read PID/parent/executable names only; never command lines or browser data."""
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    kernel.CreateToolhelp32Snapshot.argtypes = [wintypes.DWORD, wintypes.DWORD]
    kernel.CreateToolhelp32Snapshot.restype = wintypes.HANDLE
    kernel.Process32FirstW.argtypes = [wintypes.HANDLE, ctypes.POINTER(ProcessEntry)]
    kernel.Process32NextW.argtypes = [wintypes.HANDLE, ctypes.POINTER(ProcessEntry)]
    kernel.CloseHandle.argtypes = [wintypes.HANDLE]
    snapshot = kernel.CreateToolhelp32Snapshot(2, 0)  # TH32CS_SNAPPROCESS
    if snapshot == ctypes.c_void_p(-1).value:
        raise ctypes.WinError(ctypes.get_last_error())
    try:
        entry = ProcessEntry()
        entry.dwSize = ctypes.sizeof(entry)
        rows = []
        found = kernel.Process32FirstW(snapshot, ctypes.byref(entry))
        while found:
            rows.append((entry.th32ProcessID, entry.th32ParentProcessID, entry.szExeFile))
            found = kernel.Process32NextW(snapshot, ctypes.byref(entry))
        if ctypes.get_last_error() != 18:  # ERROR_NO_MORE_FILES
            raise ctypes.WinError(ctypes.get_last_error())
        return rows
    finally:
        kernel.CloseHandle(snapshot)


class BrowserWindowTracker:
    """Follow Edge's relaunch descendants, not just the short-lived launcher PID."""
    def __init__(self, root_pid, snapshot=process_snapshot, find=None, exists=None):
        self.pids = {root_pid}
        self.active_pid = root_pid
        self.snapshot = snapshot
        self.find = find or windows_for_process
        self.exists = exists or window_exists
        self.handles = {}

    def __call__(self, _root_pid):
        rows = self.snapshot()
        # A child may precede its parent in the snapshot. Resolve the entire chain.
        while True:
            children = {pid for pid, parent, name in rows
                        if parent in self.pids and name.lower() == 'msedge.exe'}
            new = children - self.pids
            if not new:
                break
            self.pids.update(new)
        for pid in sorted(self.pids):
            owned = self.find(pid)
            if owned:
                self.active_pid = pid
                self.handles.update((hwnd, pid) for hwnd in owned)
        self.handles = {hwnd: pid for hwnd, pid in self.handles.items()
                        if self.exists(hwnd, pid)}
        if self.handles:
            self.active_pid = next(reversed(self.handles.values()))
        return list(self.handles)


def window_exists(hwnd, expected_pid):
    user = ctypes.WinDLL('user32', use_last_error=True)
    user.IsWindow.argtypes = [wintypes.HWND]
    user.GetWindowThreadProcessId.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
    owner = wintypes.DWORD()
    user.GetWindowThreadProcessId(hwnd, ctypes.byref(owner))
    return bool(user.IsWindow(hwnd)) and owner.value == expected_pid


def windows_for_process(pid):
    user = ctypes.WinDLL('user32', use_last_error=True)
    user.IsWindowVisible.argtypes = [wintypes.HWND]
    user.GetClassNameW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
    user.GetWindowThreadProcessId.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
    callback_type = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
    user.EnumWindows.argtypes = [callback_type, wintypes.LPARAM]
    result = []

    @callback_type
    def visit(hwnd, _):
        owner = wintypes.DWORD()
        user.GetWindowThreadProcessId(hwnd, ctypes.byref(owner))
        if owner.value == pid and user.IsWindowVisible(hwnd):
            class_name = ctypes.create_unicode_buffer(256)
            user.GetClassNameW(hwnd, class_name, len(class_name))
            if class_name.value == 'Chrome_WidgetWin_1':
                result.append(int(hwnd))
        return True

    user.EnumWindows(visit, 0)
    return result


def focus_process(pid):
    windows = windows_for_process(pid)
    if not windows:
        return False
    user = ctypes.WinDLL('user32', use_last_error=True)
    user.ShowWindowAsync.argtypes = [wintypes.HWND, ctypes.c_int]
    user.SetForegroundWindow.argtypes = [wintypes.HWND]
    # Edge can be busy at startup; never wait synchronously for its UI thread.
    user.ShowWindowAsync(windows[0], 9)  # SW_RESTORE; no new window.
    user.SetForegroundWindow(windows[0])
    return True


def wait_for_window_close(process, ready, find_windows=windows_for_process,
                          sleep=time.sleep, clock=time.monotonic, startup_timeout=30):
    deadline = clock() + startup_timeout
    seen = False
    current_pid = None
    missing_since = None
    while True:
        windows = find_windows(process.pid)
        if windows:
            owner_pid = getattr(find_windows, 'active_pid', process.pid)
            if owner_pid != current_pid:
                ready(owner_pid)
                current_pid = owner_pid
            seen = True
            missing_since = None
        elif seen:
            if missing_since is None:
                missing_since = clock()
            if clock() - missing_since >= 3:
                return
        elif clock() >= deadline:
            raise RuntimeError('Edge did not create an application window')
        sleep(.2)
