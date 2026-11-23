import json
import tempfile
import unittest
from unittest.mock import patch
from scripts.workspace_lab import WorkspaceLab
from scripts.comment_probe import ProbeJournal
from scripts.lab_server import LabError


class ReviewOutcomeTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        auto=patch.object(WorkspaceLab,'AUTO_SYNC',False);auto.start();self.addCleanup(auto.stop)
        network=patch('requests.sessions.Session.request',side_effect=AssertionError('No network'))
        network.start();self.addCleanup(network.stop)
        self.lab=WorkspaceLab(self.tmp.name);self.addCleanup(self.lab.request_shutdown)
        self.lab.save_account({'account_id':'123','name':'Fixture','xs':'fixture'})
        self.journal=ProbeJournal(self.lab.state_dir);self.addCleanup(self.journal.close)

    def pending(self,op='op',post='456',actor='123',reason='unrecognized_response',status='outcome_unknown'):
        r={'operation_id':op,'actor_id':actor,'target':{'post_id':post},'status':status,
           'write_attempts':1,'error_category':reason}
        self.journal.reserve(op,op,r,strict=True);self.journal.finish(op,r)
        self.lab.store.block(actor,reason)

    def skip(self,op='op',post='456',**extra):
        return self.lab.skip_reviewed_post(dict(account_id='123',revision=1,operation_id=op,post_id=post,confirm=True,**extra))

    def test_skip_keeps_unknown_original_and_permanent_cross_account_post_lock(self):
        self.pending();result=self.skip()
        self.assertTrue(result['can_continue']);self.assertTrue(result['post_locked'])
        r=self.journal.get('op');self.assertEqual(r['status'],'outcome_unknown')
        self.assertEqual(r['write_attempts'],1);self.assertEqual(r['operator_review']['action'],'skip_keep_duplicate_lock')
        self.assertTrue(self.journal.post_seen('456'))
        with self.assertRaises(ValueError):self.journal.reserve('other','new-text',dict(r,actor_id='999'),strict=True)
        self.lab.request_shutdown();reopened=WorkspaceLab(self.tmp.name)
        try:self.assertFalse(reopened.store.account('123')['blocked'])
        finally:reopened.request_shutdown()

    def test_multiple_unknowns_must_all_be_reviewed_even_different_causes(self):
        self.pending();self.pending('two','789',reason='network_error')
        self.assertFalse(self.skip('two','789')['can_continue'])
        self.assertTrue(self.skip()['can_continue'])

    def test_repeat_is_idempotent_and_never_resends(self):
        self.pending();first=self.skip();second=self.skip()
        self.assertEqual(first['review'],second['review']);self.assertTrue(second['can_continue'])

    def test_crashed_reserved_attempt_without_hold_still_prevents_continuation(self):
        self.pending();self.pending('crashed','789',status='reserved')
        with self.lab.store.connect() as db:db.execute('DELETE FROM app_holds')
        self.assertFalse(self.skip()['can_continue'])
        self.assertTrue(self.lab.store.account('123')['blocked'])
        self.assertTrue(self.skip('crashed','789')['can_continue'])

    def test_session_restriction_is_never_removed(self):
        for reason in ['restricted','verification_required','session_expired']:
            with self.subTest(reason=reason):
                self.pending(reason,reason)
                self.lab.store.block('123',reason)
                result=self.skip(reason,reason)
                self.assertFalse(result['can_continue'])
                self.assertTrue(self.lab.store.account('123')['session_issue'])

    def test_session_signal_on_operation_itself_cannot_be_skipped(self):
        self.pending(reason='verification_required')
        with self.assertRaises(LabError):self.skip()
        self.assertNotIn('operator_review',self.journal.get('op'))

    def test_other_hold_reason_remains(self):
        self.pending();self.lab.store.block('123','unexpected_other_issue')
        self.assertFalse(self.skip()['can_continue'])

    def test_wrong_owner_post_revision_or_missing_confirmation_rejected(self):
        self.pending()
        base=dict(account_id='123',revision=1,operation_id='op',post_id='456',confirm=True)
        for change in [dict(account_id='999'),dict(post_id='789'),dict(revision=2),dict(confirm=False),dict(revision=True)]:
            with self.subTest(change=change),self.assertRaises(LabError):self.lab.skip_reviewed_post({**base,**change})
        self.assertNotIn('operator_review',self.journal.get('op'))
        self.assertTrue(self.lab.store.account('123')['blocked'])

    def test_confirmed_result_cannot_be_changed(self):
        self.pending(status='confirmed_by_response')
        with self.assertRaises(LabError):self.skip()

    def test_during_send_or_sync_is_rejected(self):
        self.pending()
        with self.lab.operation():
            with self.assertRaises(LabError):self.skip()
        self.assertNotIn('operator_review',self.journal.get('op'))

    def test_failure_rolls_back_review_and_hold_together(self):
        self.pending()
        with self.lab.store.connect() as db:
            db.execute("CREATE TRIGGER deny_clear BEFORE DELETE ON app_holds BEGIN SELECT RAISE(ABORT,'fixture'); END")
        with self.assertRaises(Exception):self.skip()
        self.assertNotIn('operator_review',self.journal.get('op'))
        self.assertTrue(self.lab.store.account('123')['blocked'])
        self.assertTrue(self.journal.post_seen('456'))
