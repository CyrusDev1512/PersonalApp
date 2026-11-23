"""Build with build/desktop-venv, smoke-test the EXE, then create the distributable ZIP."""
from importlib import metadata
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    node = shutil.which('node') or r'C:\Program Files\nodejs\node.exe'
    subprocess.run([node, '--check', str(ROOT / 'ui/app.js')], cwd=ROOT, check=True)
    subprocess.run([node, '--test', str(ROOT / 'tests/ui_workspace.test.cjs')], cwd=ROOT, check=True)
    subprocess.run([sys.executable, '-X', 'utf8', '-m', 'unittest', 'discover', '-s', 'tests', '-q'], cwd=ROOT, check=True)
    subprocess.run([sys.executable, '-m', 'PyInstaller', '--noconfirm', '--onedir', '--windowed',
                    '--name', 'CommentLab', '--paths', str(ROOT),
                    '--distpath', str(ROOT / 'dist'), '--workpath', str(ROOT / 'build/frozen'),
                    '--specpath', str(ROOT / 'build'), '--add-data', str(ROOT / 'ui') + ';ui',
                    '--exclude-module', 'playwright', '--exclude-module', 'playwright_stealth',
                    '--exclude-module', 'scripts.fb_browser', '--exclude-module', 'scripts.fb_messenger',
                    str(ROOT / 'desktop-entry.py')], cwd=ROOT, check=True)
    bundle = ROOT / 'dist/CommentLab'
    shutil.copy2(ROOT / 'DESKTOP-README.txt', bundle / 'DOC-TRUOC.txt')
    shutil.copy2(ROOT / 'LICENSE', bundle / 'LICENSE')
    licenses = []
    for name in ('requests', 'python-dotenv', 'certifi', 'charset-normalizer', 'idna', 'urllib3', 'pyinstaller'):
        package = metadata.distribution(name)
        licenses.append(f'\n=== {name} {package.version} ===\n')
        for file in package.files or []:
            if 'license' in str(file).lower() or 'copying' in str(file).lower():
                if package.locate_file(file).is_file():
                    licenses.append(package.locate_file(file).read_text(encoding='utf-8', errors='replace'))
    python_license = Path(sys.base_prefix) / 'LICENSE.txt'
    if python_license.exists():
        licenses.append('\n=== Python ===\n' + python_license.read_text(encoding='utf-8'))
    # Tcl/Tk runtime licenses live outside Python's LICENSE.txt.
    for path in (Path(sys.base_prefix) / 'tcl').glob('*/license.terms'):
        licenses.append('\n=== ' + path.parent.name + ' ===\n' + path.read_text(encoding='utf-8'))
    (bundle / 'THIRD-PARTY-LICENSES.txt').write_text('\n'.join(licenses), encoding='utf-8')
    freeze = subprocess.check_output([sys.executable, '-m', 'pip', 'freeze'], text=True)
    (bundle / 'build-environment.txt').write_text(f'Python {sys.version}\n' + freeze, encoding='utf-8')
    report = ROOT / 'dist/desktop-smoke.json'
    subprocess.run([str(bundle / 'CommentLab.exe'), '--smoke-test', str(report)], check=True, timeout=60)
    assert json.loads(report.read_text(encoding='utf-8'))['ok']
    # Only the frozen bundle is archived. The source, private sessions and journals are excluded.
    forbidden = {'.env', 'session.json', 'cookies.json', 'private', 'profiles', '.probe'}
    assert not any(p.name in forbidden or p.suffix in ('.sqlite3', '.db') for p in bundle.rglob('*'))
    archive = Path(shutil.make_archive(str(ROOT / 'dist/CommentLab-Windows-x64'), 'zip', ROOT / 'dist', 'CommentLab'))
    # Exercise the actual extracted distribution, never the in-repository EXE.
    subprocess.run([sys.executable, '-X', 'utf8', '-m', 'tests.portable_release',
                    str(archive), str(ROOT / 'dist/portable-acceptance.json')],
                   cwd=ROOT,check=True,timeout=240)
    with archive.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    archive.with_suffix('.sha256').write_text(f'{digest}  {archive.name}\n', encoding='ascii')
    print(json.dumps({'zip': str(archive), 'bytes': archive.stat().st_size, 'sha256': digest}))


if __name__ == '__main__':
    main()
