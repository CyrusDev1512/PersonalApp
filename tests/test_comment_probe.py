import contextlib
from concurrent.futures import ThreadPoolExecutor
import io
import json
from pathlib import Path
import sqlite3
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch
import uuid

import requests

from scripts import fb, fb_session, comment_probe as probe


def created(text="test message", comment_id="fixture-comment-id"):
    return {"data": {"comment_create": {"feedback_comment_edge": {
        "node": {"id": comment_id, "body": {"text": text}}}}}}


class ParserTests(unittest.TestCase):
    def parse(self, *chunks):
        return fb_session.parse_graphql_response("\n".join(json.dumps(c) for c in chunks))

    def test_pretty_json_and_prefix(self):
        self.assertEqual(fb_session.parse_graphql_response(" for (;;);" + json.dumps(created(), indent=2)), created())

    def test_later_root_data_not_lost(self):
        result = self.parse({"data": {"other": 1}, "is_final": False}, created(), {"is_final": True})
        self.assertEqual(result["data"]["comment_create"], created()["data"]["comment_create"])
        self.assertEqual(result["data"]["other"], 1)
        self.assertNotIn("_stream_incomplete", result)

    def test_deferred_body_patch(self):
        initial = created()
        del initial["data"]["comment_create"]["feedback_comment_edge"]["node"]["body"]
        result = self.parse(initial, {"path": ["comment_create", "feedback_comment_edge", "node"],
                                     "data": {"body": {"text": "test message"}}})
        self.assertEqual(result, created())

    def test_incremental_patch_and_final_flag(self):
        result = self.parse({"data": {}, "hasNext": True}, {"incremental": [
            {"path": ["comment_create"], "data": created()["data"]["comment_create"]}], "hasNext": False})
        self.assertEqual(result, created())

    def test_indexed_patch_and_streamed_items(self):
        result = self.parse({"data": {"nodes": [None]}},
            {"path": ["nodes", 0], "data": {"id": "a"}},
            {"path": ["nodes", 1], "items": [{"id": "b"}, {"id": "c"}]})
        self.assertEqual([n["id"] for n in result["data"]["nodes"]], ["a", "b", "c"])

    def test_late_errors_not_discarded(self):
        result = self.parse(created(), {"errors": [{"message": "fixture denial"}]})
        self.assertEqual(len(result["errors"]), 1)

    def test_incomplete_flag(self):
        result = self.parse(created(), {"hasNext": True})
        self.assertTrue(result["_stream_incomplete"])

    def test_malformed_tail_never_returns_partial_success(self):
        with self.assertRaises(ValueError):
            fb_session.parse_graphql_response(json.dumps(created()) + '\n{"data":')

    def test_invalid_shapes(self):
        for raw in ["", "<html>login</html>", "[]", "null", '{"path":"bad","data":{}}',
                    '{"path":[-1],"data":{}}', '{"data":{},"incremental":false}']:
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                fb_session.parse_graphql_response(raw)

    def test_graphql_request_merges_entire_response(self):
        wire = json.dumps({"data": {}}) + "\n" + json.dumps(created())
        with patch.object(fb_session, "_graphql_post", return_value=wire):
            result = fb_session.graphql_request(None, {}, "1", "fixture-doc", "fixture", {})
        self.assertEqual(result, created())

    def test_graphql_errors_do_not_print_raw_body(self):
        output = io.StringIO()
        with patch.object(fb_session, "_graphql_post", return_value=json.dumps({"errors": [{"message": "PRIVATE_RESPONSE_SENTINEL"}]})), contextlib.redirect_stderr(output):
            with self.assertRaises(SystemExit):
                fb_session.graphql_request(None, {}, "1", "fixture-doc", "fixture", {})
        self.assertNotIn("PRIVATE_RESPONSE_SENTINEL", output.getvalue())

    def test_transport_does_not_replay_redirect(self):
        session = Mock()
        session.post.return_value.status_code = 307
        session.post.return_value.text = "PRIVATE_RESPONSE_SENTINEL"
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            fb_session._graphql_post(session, {"fb_dtsg": "fixture"}, "1", "fixture", "fixture", {})
        self.assertEqual(session.post.call_count, 1)
        self.assertIs(session.post.call_args.kwargs["allow_redirects"], False)


class CommentTests(unittest.TestCase):
    def test_confirmed_comment(self):
        with patch.object(fb, "graphql_request", return_value=created()):
            self.assertTrue(fb._try_comment(None, {}, "1", "2", "test message")[0])

    def test_uncertain_result_is_not_retried_even_with_legacy_attempts(self):
        for payload in [created(text=""), {"data": {}}, {"errors": [{"message": "fixture"}]}]:
            with self.subTest(payload=payload), patch.object(fb, "graphql_request", return_value=payload) as write, contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit):
                    fb._create_comment(None, {}, "1", "2", "test message", attempts=3, delay=0)
                self.assertEqual(write.call_count, 1)

    def test_timeout_does_not_retry(self):
        with patch.object(fb, "graphql_request", side_effect=requests.Timeout) as write:
            with self.assertRaises(requests.Timeout):
                fb._create_comment(None, {}, "1", "2", "test message", attempts=3)
            self.assertEqual(write.call_count, 1)

    def test_exact_nonempty_text_and_complete_result_required(self):
        for payload, text in [(created(text="prefix test message"), "test message"),
                              (created(text=""), ""), (created(comment_id=None), "test message"),
                              ({**created(), "_stream_incomplete": True}, "test message"),
                              ({**created(), "errors": [{}]}, "test message")]:
            with patch.object(fb, "graphql_request", return_value=payload):
                self.assertFalse(fb._try_comment(None, {}, "1", "2", text)[0])

    def test_explicit_operation_token_is_preserved(self):
        with patch.object(fb, "graphql_request", return_value=created()) as write:
            fb._try_comment(None, {}, "1", "2", "test message", idempotence_token="fixture-operation")
        self.assertEqual(write.call_args.args[-1]["input"]["idempotence_token"], "fixture-operation")


class ProbeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.cookies = self.root / "cookies.json"
        self.cookies.write_text(json.dumps([
            {"name": "c_user", "value": "123", "domain": ".facebook.com"},
            {"name": "xs", "value": "SESSION_FIXTURE_ONLY", "domain": ".facebook.com"}
        ]), encoding="utf-8")
        self.target = probe.parse_target("https://www.facebook.com/groups/fixture/posts/456/?ref=fixture")
        self.operation_id = str(uuid.uuid4())
        # If a test misses a mock, fail closed rather than contact Facebook.
        self.network = patch("requests.sessions.Session.request", side_effect=AssertionError("NETWORK DISABLED IN TESTS"))
        self.network.start()
        self.addCleanup(self.network.stop)

    def run_probe(self, operation_id=None):
        return probe.probe(self.target, "test message", self.cookies, "123",
                           self.root / "state", operation_id or self.operation_id)

    def test_group_url_and_permalink_normalization(self):
        self.assertEqual(self.target["post_id"], "456")
        self.assertEqual(probe.parse_target("https://m.facebook.com/groups/789/permalink/456/")["group"], "789")
        self.assertEqual(probe.parse_target("456")["post_id"], "456")

    def test_untrusted_urls_and_unknown_ids_rejected(self):
        for value in ["https://facebook.com.evil.invalid/groups/1/posts/2/", "http://facebook.com/groups/1/posts/2/",
                      "https://user:pass@facebook.com/groups/1/posts/2/", "https://facebook.com/groups/1/posts/pfbidExample/",
                      "https://facebook.com/share/p/example/", "pfbidExample", "https://facebook.com:8000/groups/1/posts/2/"]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                probe.parse_target(value)

    def test_personal_identity_only(self):
        self.assertEqual(probe.read_personal_cookies(self.cookies, "123")["c_user"], "123")
        with self.assertRaises(ValueError):
            probe.read_personal_cookies(self.cookies, "999")
        data = json.loads(self.cookies.read_text())
        data.append({"name": "i_user", "value": "987"})
        self.cookies.write_text(json.dumps(data))
        with self.assertRaises(ValueError):
            probe.read_personal_cookies(self.cookies, "123")

    def test_non_facebook_cookies_not_accepted(self):
        self.cookies.write_text(json.dumps([{"name":"c_user","value":"123","domain":"evil.invalid"},
                                           {"name":"xs","value":"fixture","domain":"evil.invalid"}]))
        with self.assertRaises(ValueError):
            probe.read_personal_cookies(self.cookies, "123")

    def test_preview_does_not_read_credentials_or_network(self):
        output = io.StringIO()
        with patch.object(probe, "read_personal_cookies", side_effect=AssertionError), contextlib.redirect_stdout(output):
            code = probe.main(["--target", self.target["url"], "--text", "test message", "--cookies", "nonexistent.json"])
        self.assertEqual(code, 0)
        self.assertEqual(json.loads(output.getvalue())["network_requests"], 0)

    def test_confirmed_response_written_once_and_journal_survives_restart(self):
        with patch.object(probe, "fetch_tokens", return_value={}), patch.object(probe, "_try_comment", return_value=(True, created())) as write:
            result = self.run_probe()
            with self.assertRaises(ValueError):
                self.run_probe(operation_id=str(uuid.uuid4()))
        self.assertEqual(write.call_count, 1)
        self.assertEqual(result["status"], "confirmed_by_response")
        self.assertNotIn("SESSION_FIXTURE_ONLY", json.dumps(result))
        journal = probe.ProbeJournal(self.root / "state")
        self.addCleanup(journal.close)
        self.assertEqual(journal.get(self.operation_id)["status"], "confirmed_by_response")

    def test_timeout_is_unknown_and_blocks_second_write(self):
        with patch.object(probe, "fetch_tokens", return_value={}), patch.object(probe, "_try_comment", side_effect=requests.Timeout("PRIVATE_RESPONSE_SENTINEL")) as write:
            result = self.run_probe()
            with self.assertRaises(ValueError):
                self.run_probe()
        self.assertEqual(result["status"], "outcome_unknown")
        self.assertEqual(write.call_count, 1)
        self.assertNotIn("PRIVATE_RESPONSE_SENTINEL", json.dumps(result))
        self.assertEqual(result['diagnostic']['stage'], 'comment')
        journal = probe.ProbeJournal(self.root / 'state')
        try:
            self.assertEqual(journal.get(self.operation_id)['diagnostic'], result['diagnostic'])
        finally:
            journal.close()

    def test_history_names_reserved_before_post_and_secret_context_excluded(self):
        def send(*args, **kwargs):
            journal = probe.ProbeJournal(self.root / 'state')
            try:
                row = journal.get(self.operation_id)
                self.assertEqual(row['account_name'], 'Fixture An')
                self.assertEqual(row['group_name'], 'Fixture group')
                self.assertNotIn('xs', row)
            finally:
                journal.close()
            raise requests.Timeout()
        with patch.object(probe, 'fetch_tokens', return_value={}), patch.object(probe, '_try_comment', side_effect=send):
            report = probe.probe(self.target, 'test message', self.cookies, '123', self.root / 'state',
                                 self.operation_id, context={'account_name':'Fixture An', 'group_name':'Fixture group',
                                                            'xs':'DO_NOT_PERSIST'})
        self.assertEqual(report['status'], 'outcome_unknown')
        self.assertEqual(report['group_name'], 'Fixture group')
        self.assertNotIn('DO_NOT_PERSIST', json.dumps(report))

    def test_missing_response_text_is_unconfirmed_and_not_retried(self):
        with patch.object(probe, "fetch_tokens", return_value={}), patch.object(probe, "_try_comment", return_value=(False, created(text=""))) as write:
            result = self.run_probe()
        self.assertEqual(result["status"], "unconfirmed")
        self.assertEqual(write.call_count, 1)

    def test_journal_failure_after_post_is_not_reported_as_not_sent(self):
        with patch.object(probe, "fetch_tokens", return_value={}), patch.object(probe, "_try_comment", return_value=(True, created())), patch.object(probe.ProbeJournal, "finish", side_effect=sqlite3.OperationalError):
            result = self.run_probe()
        self.assertEqual(result["status"], "confirmed_by_response")
        self.assertTrue(result["journal_update_failed"])

    def test_preflight_failure_does_not_send(self):
        with patch.object(probe, "fetch_tokens", side_effect=SystemExit(1)), patch.object(probe, "_try_comment") as write:
            with self.assertRaises(SystemExit):
                self.run_probe()
        write.assert_not_called()

    def test_strict_preflight_failure_is_known_not_sent_without_post_lock(self):
        from scripts.remote_status import RemoteStop
        for exc, scope in [(RemoteStop('permission_denied','http_forbidden',403),'request'),
                           (RemoteStop('verification_required','verification_redirect'),'session'),
                           (requests.Timeout(),'unknown')]:
            with self.subTest(scope=scope), patch.object(probe,'fetch_tokens',side_effect=exc), patch.object(probe,'_try_comment') as write:
                result=probe.probe(self.target,'test message',self.cookies,'123',
                                   self.root/'state',str(uuid.uuid4()),strict=True)
            self.assertEqual(result['status'],'not_sent')
            self.assertEqual(result['write_attempts'],0)
            self.assertEqual(result['diagnostic']['scope'],scope)
            self.assertEqual(result['diagnostic']['stage'],'preflight')
            write.assert_not_called()
        with contextlib.closing(sqlite3.connect(self.root/'state'/'attempts.sqlite3')) as db:
            self.assertEqual(db.execute('SELECT count(*) FROM post_locks').fetchone()[0],0)

    def test_full_http_flow_merges_stream_without_browser(self):
        session = requests.Session()
        response = Mock(status_code=200, text="\n".join([json.dumps({"data":{},"is_final":False}), json.dumps(created()), json.dumps({"is_final":True})]))
        session.post = Mock(return_value=response)
        with patch.object(probe, "create_session", return_value=session), patch.object(probe, "fetch_tokens", return_value={"fb_dtsg":"TOKEN_FIXTURE_ONLY"}):
            result = self.run_probe()
        self.assertEqual(result["status"], "confirmed_by_response")
        self.assertEqual(session.post.call_count, 1)
        self.assertFalse(session.post.call_args.kwargs["allow_redirects"])
        variables = json.loads(session.post.call_args.kwargs["data"]["variables"])
        self.assertEqual(variables["input"]["actor_id"], "123")
        self.assertEqual(variables["input"]["idempotence_token"], "client:"+self.operation_id)
        self.assertFalse(any(name.startswith("playwright") for name in sys.modules))

    def test_concurrent_reservations_only_one_winner(self):
        # Precreate schema; two independent connections compete for one write.
        state = self.root / "parallel"
        initial = probe.ProbeJournal(state)
        initial.close()
        def reserve(_):
            journal = probe.ProbeJournal(state)
            try:
                journal.reserve(str(uuid.uuid4()), "same-fingerprint", {"status":"reserved"})
                return True
            except ValueError:
                return False
            finally:
                journal.close()
        with ThreadPoolExecutor(max_workers=2) as pool:
            self.assertEqual(sorted(pool.map(reserve, range(2))), [False, True])


if __name__ == "__main__":
    unittest.main()
