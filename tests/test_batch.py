import copy
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch

from scripts.comment_probe import ProbeJournal, attempt_fingerprint
from scripts.lab_server import Lab, LabError
from scripts.group_feed import FeedError


def fixture_feed(count=10):
    return {'group': {'slug':'fixture', 'id':'456', 'url':'https://www.facebook.com/groups/fixture/'},
            'sorting':'CHRONOLOGICAL', 'requested_count':count, 'actual_count':count,
            'posts':[{'post_id':str(1000-i), 'created_at':1700000000-i, 'excerpt':'Fixture post',
                      'can_comment':True, 'target':{'post_id':str(1000-i), 'group':'456',
                      'url':f'https://www.facebook.com/groups/456/posts/{1000-i}/'}} for i in range(count)]}


class BatchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.lab = Lab(self.temp.name)
        self.protect = patch('scripts.lab_server.protect_directory', side_effect=lambda p:p.mkdir(parents=True, exist_ok=True))
        self.protect.start(); self.addCleanup(self.protect.stop)
        self.lab.save_session({'actor_id':'123','cookies':[{'name':'c_user','value':'123'}, {'name':'xs','value':'synthetic-only'}]})
        self.reader = patch('scripts.lab_server.load_recent_posts', side_effect=lambda group,count,*_:copy.deepcopy(fixture_feed(count)))
        self.reader.start(); self.addCleanup(self.reader.stop)
        self.wait = patch.object(self.lab.batch_cancel, 'wait', side_effect=lambda _:self.lab.batch_cancel.is_set())
        self.wait.start(); self.addCleanup(self.wait.stop)
        self.network = patch('requests.sessions.Session.request', side_effect=AssertionError('No network in unit tests'))
        self.network.start(); self.addCleanup(self.network.stop)

    def preview(self, text='Same comment', count=10):
        return self.lab.load_batch({'group':'456','text':text,'count':count})

    def start(self, preview, selected=None):
        return self.lab.start_batch({'operation_id':preview['operation_id'], 'confirm':True,
                                    'post_ids': selected or [p['post_id'] for p in preview['posts']]})

    def join(self):
        self.lab.batch_thread.join(timeout=5)
        self.assertFalse(self.lab.batch_thread.is_alive())

    def test_common_content_and_preview_targets_are_frozen(self):
        preview = self.preview(count=20)
        with patch.object(self.lab,'_attempt',return_value={'status':'confirmed_by_response'}) as send:
            self.start(preview)
            self.join()
        self.assertEqual(send.call_count,20)
        self.assertTrue(all(call.args[1]=='Same comment' for call in send.call_args_list))
        self.assertEqual(self.lab.batch['state'],'completed')
        self.assertEqual(self.lab.batch['completed'],20)
        self.assertEqual(len({call.args[3] for call in send.call_args_list}),20)
        with self.assertRaises(LabError):
            self.start(preview)

    def test_selected_subset_only_and_no_injected_target(self):
        preview=self.preview()
        with self.assertRaises(LabError):
            self.start(preview,['999999'])
        with self.assertRaises(LabError):
            self.start(preview,['1000','1000'])
        with patch.object(self.lab,'_attempt',return_value={'status':'confirmed_by_response'}) as send:
            self.start(preview,['998','1000']);self.join()
        self.assertEqual([call.args[0]['post_id'] for call in send.call_args_list],['1000','998'])

    def test_previous_reserved_attempt_blocks_same_actor_post_and_content(self):
        journal=ProbeJournal(self.lab.state_dir)
        journal.reserve('old-operation',attempt_fingerprint('123','1000','Same comment'),{'status':'reserved'})
        journal.close()
        preview=self.preview()
        self.assertFalse(preview['posts'][0]['selectable'])
        with self.assertRaises(LabError):self.start(preview,['1000'])
        self.assertTrue(self.preview(text='A different comment')['posts'][0]['selectable'])

    def test_unknown_result_stops_remaining_posts(self):
        preview=self.preview()
        with patch.object(self.lab,'_attempt',return_value={'status':'outcome_unknown'}) as send:
            self.start(preview);self.join()
        self.assertEqual(send.call_count,1)
        self.assertEqual(self.lab.batch['state'],'stopped')
        self.assertEqual([p['status'] for p in self.lab.batch['items'][1:]],['not_sent']*9)

    def test_journal_failure_stops_even_when_comment_response_confirms(self):
        preview=self.preview()
        with patch.object(self.lab,'_attempt',return_value={'status':'confirmed_by_response','journal_update_failed':True}) as send:
            self.start(preview);self.join()
        self.assertEqual(send.call_count,1)
        self.assertEqual(self.lab.batch['state'],'stopped')

    def test_graphql_errors_stop_batch_despite_partial_confirmation(self):
        preview=self.preview()
        with patch.object(self.lab,'_attempt',return_value={'status':'confirmed_by_response','graphql_error_count':1}) as send:
            self.start(preview);self.join()
        self.assertEqual(send.call_count,1)
        self.assertEqual(self.lab.batch['state'],'stopped')

    def test_cancel_waits_for_current_post_and_never_starts_next(self):
        preview=self.preview();entered=threading.Event();release=threading.Event()
        def sender(*_):
            entered.set();release.wait(timeout=4)
            return {'status':'confirmed_by_response'}
        with patch.object(self.lab,'_attempt',side_effect=sender) as send:
            self.start(preview);self.assertTrue(entered.wait(timeout=2))
            self.lab.stop_batch({'batch_id':preview['operation_id']})
            with self.assertRaises(LabError):self.lab.forget_session()
            release.set();self.join()
        self.assertEqual(send.call_count,1)
        self.assertEqual(self.lab.batch['state'],'cancelled')
        self.assertFalse(self.lab.busy)

    def test_desktop_shutdown_requests_batch_stop(self):
        self.lab.request_shutdown()
        self.assertTrue(self.lab.batch_cancel.is_set())

    def test_expired_or_changed_session_preview_rejected(self):
        preview=self.preview();self.lab.batch_preview['expires']=0
        with self.assertRaises(LabError):self.start(preview)
        preview=self.preview();self.lab.forget_session()
        with self.assertRaises(LabError):self.start(preview)

    def test_bad_count_empty_comment_no_session_and_reader_failure(self):
        for count in (0,30,'20',True):
            with self.assertRaises(LabError):self.preview(count=count)
        with self.assertRaises(LabError):self.preview(text=' ')
        with patch('scripts.lab_server.load_recent_posts',side_effect=FeedError('No access')):
            with self.assertRaises(LabError):self.preview()
        self.assertFalse(self.lab.busy)
        self.assertIsNone(self.lab.batch_preview)
        self.lab.forget_session()
        with self.assertRaises(LabError):self.preview()

    def test_cannot_overlap_single_send_with_batch(self):
        preview=self.preview();self.lab.busy=True
        with self.assertRaises(LabError):self.start(preview)
        with self.assertRaises(LabError):self.lab.load_batch({'group':'456','text':'x','count':10})
