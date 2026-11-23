import http.client
import contextlib
import io
import json
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch

from scripts.lab_server import Lab, LabError, ROOT, UI_PROTOCOL, main, make_server, normalize_cookies


COOKIES = [{"name": "c_user", "value": "123", "domain": ".facebook.com"},
           {"name": "xs", "value": "synthetic-test-only", "domain": ".facebook.com"}]


class LabTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.lab = Lab(self.temp.name)
        self.protect = patch("scripts.lab_server.protect_directory", side_effect=lambda p: p.mkdir(parents=True, exist_ok=True))
        self.protect.start()

    def tearDown(self):
        self.protect.stop()
        self.temp.cleanup()

    def save(self):
        return self.lab.save_session({"actor_id": "123", "cookies": COOKIES})

    def preview(self):
        return self.lab.preview({"target": "https://www.facebook.com/groups/44/posts/55/", "text": "Kiểm thử"})

    def test_session_saved_without_secret_in_response(self):
        result = self.save()
        self.assertTrue(result["session"]["saved"])
        self.assertNotIn("synthetic-test-only", json.dumps(self.lab.state()))
        self.assertFalse(result["session"]["verified_online"])

    def test_no_session_offline_preview(self):
        with patch("requests.sessions.Session.request", side_effect=AssertionError("Network forbidden")):
            result = self.preview()
        self.assertEqual(result["network_requests"], 0)
        self.assertFalse(result["can_send"])

    def test_one_preview_can_only_send_once(self):
        self.save()
        preview = self.preview()
        payload = {"operation_id": preview["operation_id"], "confirm": True}
        with patch("scripts.lab_server.probe", return_value={"status": "confirmed_by_response"}) as sender:
            self.lab.send(payload)
            with self.assertRaises(LabError):
                self.lab.send(payload)
        self.assertEqual(sender.call_count, 1)

    def test_send_uses_frozen_preview_not_extra_payload(self):
        self.save()
        preview = self.preview()
        with patch("scripts.lab_server.probe", return_value={"status": "unconfirmed"}) as sender:
            self.lab.send({"operation_id": preview["operation_id"], "confirm": True, "text": "Changed", "target": "999"})
        self.assertEqual(sender.call_args.args[0]["post_id"], "55")
        self.assertEqual(sender.call_args.args[1], "Kiểm thử")

    def test_session_change_invalidates_preview(self):
        self.save()
        preview = self.preview()
        self.save()
        with self.assertRaises(LabError):
            self.lab.send({"operation_id": preview["operation_id"], "confirm": True})

    def test_expired_preview_rejected(self):
        self.save()
        p = self.preview()
        self.lab.previews[p["operation_id"]]["expires"] = 0
        with self.assertRaises(LabError):
            self.lab.send({"operation_id": p["operation_id"], "confirm": True})

    def test_forget_only_deletes_session_and_preserves_journal(self):
        self.save()
        self.lab.state_dir.mkdir()
        marker = self.lab.state_dir / "keep.txt"
        marker.write_text("keep")
        self.lab.forget_session()
        self.assertFalse(self.lab.cookie_path.exists())
        self.assertTrue(marker.exists())

    def test_busy_rejects_session_change_and_new_send(self):
        self.save()
        self.lab.busy = True
        for action in [self.save, self.lab.forget_session, lambda: self.lab.send({"operation_id": "x", "confirm": True})]:
            with self.assertRaises(LabError) as ctx:
                action()
            self.assertEqual(ctx.exception.status, 409)

    def test_malformed_inputs(self):
        for value in [123, None, [], {}, "", "x" * 10001]:
            with self.assertRaises(LabError):
                self.lab.preview({"target": "456", "text": value})

    def test_session_validation(self):
        for cookies, actor in [([], "123"), (COOKIES, "999"), (COOKIES, 123),
                               (COOKIES + [{"name": "i_user", "value": "456"}], "123"),
                               (COOKIES + [{"name": "xs", "value": "different"}], "123")]:
            with self.assertRaises(LabError):
                normalize_cookies(cookies, actor)

    def test_foreign_cookies_ignored(self):
        result = normalize_cookies(COOKIES + [{"name": "xs", "value": "foreign", "domain": "evil.test"}], "123")
        self.assertEqual(len(result), 2)

    def test_failure_before_post_clears_busy(self):
        self.save()
        p = self.preview()
        with patch("scripts.lab_server.probe", side_effect=SystemExit(1)):
            result = self.lab.send({"operation_id": p["operation_id"], "confirm": True})
        self.assertEqual(result["status"], "not_sent")
        self.assertFalse(self.lab.busy)

    def test_reservation_failure_never_claims_not_sent(self):
        self.save()
        p = self.preview()
        old = {"operation_id": p["operation_id"], "status": "reserved"}
        with patch("scripts.lab_server.probe", side_effect=RuntimeError("secret")), patch.object(self.lab, "history", return_value=[old]):
            result = self.lab.send({"operation_id": p["operation_id"], "confirm": True})
        self.assertEqual(result["status"], "reserved")
        self.assertNotIn("secret", json.dumps(result))

    def test_launcher_refuses_incomplete_ui(self):
        with patch("scripts.lab_server.ROOT", Path(self.temp.name)), patch("sys.argv", ["lab_server"]), patch("scripts.lab_server.make_server") as factory, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(main(), 1)
            factory.assert_not_called()


class HTTPTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.server = make_server(self.temp.name, port=0, lab_class=Lab, asset_root=ROOT)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.port = self.server.server_address[1]

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()
        self.temp.cleanup()

    def request(self, method, path, data=None, headers=None):
        conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=5)
        conn.request(method, path, json.dumps(data) if data is not None else None, headers or {})
        response = conn.getresponse()
        status, hdrs, body = response.status, dict(response.getheaders()), response.read()
        conn.close()
        return status, hdrs, json.loads(body)

    def headers(self):
        return {"Content-Type": "application/json", "Origin": f"http://127.0.0.1:{self.port}", "X-Lab-CSRF": self.server.lab.csrf}

    def test_csrf_and_host_and_origin(self):
        good = self.headers()
        for headers in [{}, dict(good, Origin="https://evil.test"), dict(good, Host="evil.test"), dict(good, **{"X-Lab-CSRF": "wrong"}), dict(good, **{"Sec-Fetch-Site": "cross-site"})]:
            self.assertEqual(self.request("POST", "/api/preview", {"target": "1", "text": "x"}, headers)[0], 403)

    def test_valid_offline_preview_and_security_headers(self):
        status, hdrs, body = self.request("POST", "/api/preview", {"target": "1", "text": "<script>not executed</script>"}, self.headers())
        self.assertEqual(status, 200)
        self.assertEqual(body["network_requests"], 0)
        self.assertIn("frame-ancestors 'none'", hdrs["Content-Security-Policy"])

    def test_private_paths_not_served(self):
        for path in ["/private/session.json", "/../scripts/lab_server.py", "/.probe/attempts.sqlite3"]:
            self.assertEqual(self.request("GET", path)[0], 404)

    def test_array_input_400(self):
        self.assertEqual(self.request("POST", "/api/preview", [], self.headers())[0], 400)

    def test_batch_routes_keep_csrf_and_origin_checks(self):
        for route in ('load', 'start', 'stop'):
            self.assertEqual(self.request('POST', '/api/batch/' + route, {}, {})[0], 403)

    def test_batch_status_is_serializable_and_missing_session_blocks_load(self):
        status, _, body = self.request('GET', '/api/batch/status')
        self.assertEqual((status, body), (200, {'batch': None, 'busy': False}))
        self.assertEqual(self.request('POST', '/api/batch/load', {'group':'456', 'count':10, 'text':'test'}, self.headers())[0], 409)

    def test_real_ui_assets_are_present_and_served(self):
        for url, mime, marker in [("/", "text/html", "CommentLab"),
                                 ("/app.css", "text/css", ":root"),
                                 ("/app.js", "text/javascript", "preview")]:
            conn = http.client.HTTPConnection("127.0.0.1", self.port, timeout=5)
            conn.request("GET", url)
            result = conn.getresponse()
            self.assertEqual(result.status, 200)
            self.assertTrue(result.getheader("Content-Type").startswith(mime))
            self.assertIn(marker, result.read().decode("utf-8"))
            conn.close()

    def test_state_advertises_ui_protocol(self):
        status, _, body = self.request('GET', '/api/state')
        self.assertEqual(status, 200)
        self.assertEqual(body['ui_protocol'], UI_PROTOCOL)

    def test_running_backend_keeps_original_ui_after_disk_update(self):
        with tempfile.TemporaryDirectory() as root:
            ui = Path(root) / 'ui'
            ui.mkdir()
            (ui / 'app.js').write_bytes(b'original UI')
            server = make_server(root, port=0, lab_class=Lab)
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            try:
                (ui / 'app.js').write_bytes(b'incompatible new UI')
                conn = http.client.HTTPConnection('127.0.0.1', server.server_port)
                conn.request('GET', '/app.js')
                res = conn.getresponse()
                self.assertEqual(res.status, 200)
                self.assertEqual(res.read(), b'original UI')
                conn.close()
            finally:
                server.shutdown()
                server.server_close()
                thread.join()


if __name__ == "__main__":
    unittest.main()
