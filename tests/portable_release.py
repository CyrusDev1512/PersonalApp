"""Test the exact ZIP outside the repository with no Python/venv in app env."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import zipfile


def check(archive, report_path):
    report = {'ok':False, 'zip_sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}
    env = os.environ.copy()
    for key in list(env):
        if key.upper().startswith('PYTHON') or key.upper() in {'VIRTUAL_ENV','CONDA_PREFIX','CONDA_DEFAULT_ENV'}:
            env.pop(key)
    env['PATH'] = str(Path(os.environ['SystemRoot'])/'System32')
    env['COMMENTLAB_NETWORK_DISABLED'] = '1'
    with tempfile.TemporaryDirectory(prefix='CommentLab ZIP thử-', ignore_cleanup_errors=True) as temp:
        root = Path(temp)
        env['LOCALAPPDATA'] = str(root/'data')
        cwd = root/'empty';cwd.mkdir()
        with zipfile.ZipFile(archive) as z:
            for name in z.namelist():
                target=(root/name).resolve()
                assert target.is_relative_to(root.resolve()), 'Unsafe ZIP path'
            z.extractall(root)
        bundle=root/'CommentLab';exe=bundle/'CommentLab.exe'
        forbidden={'private','profiles','.probe','.venv','venv','.git','session.json','cookies.json','.env'}
        assert not any(p.name in forbidden or p.suffix in {'.db','.sqlite3'} for p in bundle.rglob('*'))
        assert not (bundle/'scripts').exists()
        smoke=root/'smoke.json'
        subprocess.run([str(exe),'--smoke-test',str(smoke)],env=env,cwd=cwd,check=True,timeout=60)
        report['smoke']=json.loads(smoke.read_text(encoding='utf-8'))
        assert report['smoke']['ok'] and all(report['smoke']['runtime'].values())
        desktop=root/'desktop.json'
        subprocess.run([sys.executable,'-X','utf8','-m','tests.desktop_acceptance',str(exe),str(desktop),'--clean-environment'],
                       cwd=Path(__file__).resolve().parents[1],check=True,timeout=150)
        report['desktop']=json.loads(desktop.read_text(encoding='utf-8'))
        assert report['desktop']['ok']
        report.update(ok=True, no_repo=True, no_python_or_venv_in_app_environment=True,
                      separate_physical_machine_tested=False)
    report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print('Extracted ZIP acceptance: PASS (isolated folder, bundled runtime, real Edge).')


if __name__=='__main__':
    check(Path(sys.argv[1]).resolve(),Path(sys.argv[2]).resolve())
