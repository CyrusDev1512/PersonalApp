import tempfile
import threading
import unittest
from unittest.mock import patch

from scripts.workspace_lab import WorkspaceLab
from scripts.remote_status import RemoteStop
from scripts.lab_server import LabError


RESULT = {'groups':[{'url':'https://www.facebook.com/groups/456/', 'name':'Fixture group'}], 'complete':False}


class BackgroundSyncTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.gate = threading.Event()
        self.entered = threading.Event()
        self.calls = []
        def read(cookies, actor, **kw):
            self.calls.append(actor)
            self.entered.set()
            self.gate.wait(4)
            return RESULT
        self.reader = patch('scripts.workspace_lab.load_joined', side_effect=read)
        self.reader.start()
        self.outbound = patch('requests.sessions.Session.request', side_effect=AssertionError('No network in tests'))
        self.outbound.start()
        self.lab = WorkspaceLab(self.tmp.name)

    def tearDown(self):
        self.lab.request_shutdown(); self.gate.set(); self.lab.sync.wait(5)
        self.reader.stop();self.outbound.stop();self.tmp.cleanup()

    def save(self, actor='123', xs='fixture', name='Account fixture'):
        return self.lab.save_account({'account_id':actor,'xs':xs,'name':name})

    def test_save_starts_background_without_busy_and_switch_does_not_cancel(self):
        state = self.save();self.assertTrue(self.entered.wait(2))
        self.assertFalse(state['busy']);self.assertFalse(self.lab.busy)
        self.save('999');self.lab.select_account({'account_id':'123'})
        self.lab.links({'account_id':'123','links':'https://facebook.com/groups/789/'})
        self.assertEqual(len(self.lab.state()['sync_jobs']),2)
        self.assertNotIn('fixture', str(self.lab.state()['sync_jobs']))
        self.gate.set();self.lab.sync.wait()
        self.assertEqual(self.calls,['123','999'])
        self.assertEqual(self.lab.sync.get('123')['state'],'partial')
        self.assertIsNone(self.lab.sync.get('123')['total'])
        self.assertEqual(len(self.lab.store.groups('123')),2)

    def test_duplicate_sync_rename_and_shared_network_lease(self):
        self.save();self.entered.wait(2)
        job=self.lab.sync.get('123')
        self.assertEqual(self.lab.sync_groups({'account_id':'123'})['job']['id'],job['id'])
        self.save(xs='',name='Renamed')
        self.assertEqual(self.lab.store.account('123')['revision'],job['revision'])
        with self.assertRaises(LabError):
            self.lab.load_links({'account_id':'123','links':'https://facebook.com/groups/456/'})
        self.assertFalse(self.lab.busy)
        self.gate.set();self.lab.sync.wait();self.assertEqual(len(self.calls),1)

    def test_replacement_session_rejects_old_result(self):
        self.save();self.entered.wait(2)
        old=self.lab.sync.get('123')
        self.save(xs='new-fixture')
        self.assertNotEqual(old['id'],self.lab.sync.get('123')['id'])
        self.assertFalse(self.lab.store.publish_joined(old,RESULT['groups'],True))
        self.gate.set();self.lab.sync.wait()
        self.assertEqual(self.lab.sync.get('123')['revision'],2)
        self.assertEqual(len(self.calls),2)

    def test_delete_readd_does_not_resurrect_old_groups(self):
        self.save();self.entered.wait(2);old=self.lab.sync.get('123')
        self.lab.delete_account({'account_id':'123','confirm':True})
        self.assertFalse(self.lab.store.publish_joined(old,RESULT['groups'],True))
        self.save(xs='different');self.assertFalse(self.lab.store.publish_joined(old,RESULT['groups'],True))
        self.gate.set();self.lab.sync.wait()

    def test_cancel_wrong_job_rejected_and_current_waits_for_read(self):
        self.save();self.entered.wait(2)
        with self.assertRaises(LabError):self.lab.stop_sync({'account_id':'123','job_id':'wrong'})
        self.lab.stop_sync({'account_id':'123','job_id':self.lab.sync.get('123')['id']})
        self.assertEqual(self.lab.sync.get('123')['state'],'stopping')
        self.gate.set();self.lab.sync.wait()
        self.assertEqual(self.lab.sync.get('123')['state'],'cancelled')
        self.assertEqual(self.lab.store.groups('123'),[])

    def test_shutdown_and_restart_do_not_resume_queue(self):
        self.save();self.entered.wait(2);self.save('999')
        self.lab.request_shutdown();self.gate.set();self.lab.sync.wait()
        reopened=WorkspaceLab(self.tmp.name)
        self.assertTrue(all(j['state']=='interrupted' for j in reopened.sync.all()))
        self.assertIsNone(reopened.sync.thread)
        reopened.request_shutdown()

    def test_sync_errors_only_block_proven_session_issue(self):
        self.gate.set()
        for category in ('permission_denied','network_error','unrecognized_response','verification_required'):
            with self.subTest(category=category), patch('scripts.workspace_lab.load_joined', side_effect=RemoteStop(category)):
                self.save(str(100+len(self.lab.store.accounts())))
                self.lab.sync.wait()
                account=self.lab.store.account(self.lab.store.active())
                self.assertEqual(bool(account['blocked']), category=='verification_required')

    def test_old_app_stops_remain_separate_from_session_signals(self):
        self.gate.set();self.save();self.lab.sync.wait()
        self.lab.store.block('123','unrecognized_response')
        a=self.lab.store.account('123')
        self.assertEqual(a['app_hold'],'unrecognized_response');self.assertEqual(a['session_issue'],'')
        self.lab.store.block('123','verification_required')
        a=self.lab.store.account('123')
        self.assertEqual(a['session_issue'],'verification_required')
        self.assertEqual(a['app_hold'],'unrecognized_response')


    def test_live_page_progress_and_cancel_keep_old_groups(self):
        def reader(cookies,actor,*,progress,cancelled):
            progress(completed=20,pages_read=1,phase='reading')
            self.entered.set();self.gate.wait(3)
            self.assertTrue(cancelled())
            return RESULT
        with patch('scripts.workspace_lab.load_joined',side_effect=reader):
            self.save();self.assertTrue(self.entered.wait(2))
            self.assertEqual(self.lab.sync.get('123')['completed'],20)
            self.assertFalse(self.lab.state()['busy'])
            self.lab.stop_sync({'account_id':'123','job_id':self.lab.sync.get('123')['id']})
            self.gate.set();self.lab.sync.wait()
        self.assertEqual(self.lab.store.groups('123'),[])
        self.assertEqual(self.lab.sync.get('123')['state'],'cancelled')
