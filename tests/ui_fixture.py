"""Disposable browser-test server. All Facebook requests are forbidden."""
import hashlib
from pathlib import Path
import shutil
import sys
import tempfile
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from scripts.lab_server import ROOT, make_server
from scripts.comment_probe import ProbeJournal, attempt_fingerprint
from tests.test_batch import fixture_feed


def fake_probe(target, text, cookie_path, actor, directory, op):
    result = {"operation_id": op, "target": target, "actor_id": actor,
              "status": "outcome_unknown" if "TIMEOUT" in text else "confirmed_by_response",
              "write_attempts": 0, "note": "KẾT QUẢ GIẢ LẬP UI. Không gửi request Facebook."}
    if "TIMEOUT" not in text:
        result["comment_id"] = "fixture-comment-only"
    journal = ProbeJournal(directory)
    try:
        journal.reserve(op, attempt_fingerprint(actor, target['post_id'], text), result)
        journal.finish(op, result)
    finally:
        journal.close()
    return result


if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="comment-lab-ui-fixture-") as temp:
        shutil.copytree(ROOT / "ui", Path(temp) / "ui")
        html = Path(temp) / "ui" / "index.html"
        html.write_text(html.read_text(encoding="utf-8").replace("Thử bình luận Facebook", "FIXTURE — Không gửi Facebook"), encoding="utf-8")
        server = make_server(temp, 8791)
        print("UI fixture http://127.0.0.1:8791/ — no Facebook requests", flush=True)
        try:
            with patch("scripts.lab_server.probe", side_effect=fake_probe), patch('scripts.lab_server.load_recent_posts', side_effect=lambda group,count,*_:fixture_feed(count)), patch("requests.sessions.Session.request", side_effect=AssertionError("Facebook network forbidden")):
                server.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            server.server_close()
