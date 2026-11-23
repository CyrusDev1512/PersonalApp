import json
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch, Mock
import urllib.request
import urllib.error

from scripts.account_store import crypt
from scripts.comment_probe import ProbeJournal, attempt_fingerprint, probe
from scripts.lab_server import LabError, make_server
from scripts.remote_status import RemoteStop, check_response
from scripts.workspace_lab import WorkspaceLab, parse_links


def feed(raw, limit, cookies, actor, **kw):
    group = '456' if '456' in raw else '789'
    offset = 0 if group == '456' else 10
    return {'group': {'id':group,'name':'Nhóm fixture '+group}, 'posts': [{'post_id': str(1000+i+offset), 'created_at': 10000-i-offset,
                      'excerpt': 'Fixture content', 'can_comment': True,
                      'target': {'post_id':str(1000+i+offset),'group':group,
                                 'url':f'https://www.facebook.com/groups/{group}/posts/{1000+i+offset}/'}}
                     for i in range(limit)]}


class WorkspaceTests(unittest.TestCase):
    def setUp(self):
        gate=patch.object(WorkspaceLab, 'AUTO_SYNC', False);gate.start();self.addCleanup(gate.stop)
        self.tmp = tempfile.TemporaryDirectory()
        self.lab = WorkspaceLab(self.tmp.name)
        self.lab.save_account({'name':'Fixture A','account_id':'123','xs':'synthetic-only'})

    def tearDown(self):
        if self.lab.batch_thread:
            self.lab.batch_cancel.set()
            self.lab.batch_thread.join(5)
        self.lab.request_shutdown();self.lab.sync.wait()
        self.tmp.cleanup()

    def load(self, links='https://www.facebook.com/groups/456/', count=10):
        with patch('scripts.workspace_lab.load_recent_posts', side_effect=feed):
            self.lab.load_links({'account_id':'123','links':links,'count':count})
            self.lab.batch_thread.join(5)
        self.assertFalse(self.lab.busy)
        return self.lab.draft

    def prepare(self, n=1):
        d=self.load()
        return self.lab.prepare({'account_id':'123','draft_id':d['id'],
                                'items':[{'post_id':p['post_id'],'text':'reply '+str(i),'approved':True}
                                         for i,p in enumerate(d['posts'][:n])]})

    def test_vault_encrypted_and_blank_update_and_identity_separation(self):
        raw=(Path(self.tmp.name)/'private/accounts.sqlite3').read_bytes()
        self.assertNotIn(b'synthetic-only',raw)
        self.assertNotIn('synthetic-only',json.dumps(self.lab.state()))
        self.lab.save_account({'name':'Renamed','account_id':'123','xs':''})
        self.assertEqual(self.lab.store.cookies('123')[1]['value'],'synthetic-only')
        self.lab.save_account({'name':'New','account_id':'999','xs':'another-fixture'})
        self.assertEqual(len(self.lab.store.accounts()),2)
        self.assertEqual(self.lab.store.groups('999'),[])

    def test_migration_and_restart_idempotent(self):
        p=Path(self.tmp.name)/'private/session.json'
        p.write_text(json.dumps([{'name':'c_user','value':'888'},{'name':'xs','value':'fixture-migrate'}]))
        new=WorkspaceLab(self.tmp.name)
        self.assertFalse(p.exists())
        self.assertEqual(len(new.store.accounts()),2)
        self.assertEqual(len(WorkspaceLab(self.tmp.name).store.accounts()),2)

    def test_failed_dpapi_migration_preserves_source(self):
        p=Path(self.tmp.name)/'private/session.json'
        p.write_text(json.dumps([{'name':'c_user','value':'888'},{'name':'xs','value':'fixture'}]))
        with patch('scripts.account_store.crypt',side_effect=OSError('failure')):
            new=WorkspaceLab(self.tmp.name)
        self.assertTrue(p.exists())
        self.assertTrue(new.migration_error)
        self.assertIsNone(new.store.account('888'))

    def test_dpapi_wrong_blob_fails_and_never_overwrites(self):
        with self.assertRaises(OSError):crypt(b'not-a-dpapi-blob',True)
        with patch('scripts.account_store.crypt',side_effect=OSError()):
            with self.assertRaises(OSError):self.lab.save_account({'account_id':'123','name':'Bad','xs':'new'})
        self.assertEqual(self.lab.store.account('123')['name'],'Fixture A')

    def test_remove_readd_preserves_block_and_history(self):
        self.lab.store.block('123','restricted')
        self.lab.delete_account({'account_id':'123','confirm':True})
        self.lab.save_account({'account_id':'123','name':'Again','xs':'fixture'})
        self.assertEqual(self.lab.store.account('123')['blocked'],'restricted')
        with self.assertRaises(LabError):self.load()

    def test_two_instances_share_busy_lock(self):
        other=WorkspaceLab(self.tmp.name)
        with self.lab.operation():
            with self.assertRaises(LabError):other.select_account({'account_id':'123'})
        other.select_account({'account_id':'123'})

    def test_switch_clears_other_account_sync_notice(self):
        self.lab.sync_job = {'account_id':'123','state':'partial','message':'old'}
        self.lab.save_account({'account_id':'999','name':'Other','xs':'fixture'})
        self.assertIsNone(self.lab.state()['sync_job'])

    def test_select_current_account_keeps_draft(self):
        d=self.load()
        self.lab.select_account({'account_id':'123'})
        self.assertEqual(self.lab.draft['id'],d['id'])

    def test_permission_failure_is_per_group(self):
        def source(url, *args, **kwargs):
            if '456' in url:
                raise RemoteStop('permission_denied')
            return feed(url, *args, **kwargs)
        with patch('scripts.workspace_lab.load_recent_posts',side_effect=source) as read:
            self.lab.load_links({'account_id':'123','links':'https://www.facebook.com/groups/456/\nhttps://www.facebook.com/groups/789/','count':10})
            self.lab.batch_thread.join(5)
        self.assertEqual(read.call_count,2)
        self.assertEqual(self.lab.read_job['state'],'completed')
        self.assertEqual(len(self.lab.draft['posts']),10)
        self.assertFalse(self.lab.store.account('123')['blocked'])

    def test_wrong_actor_expiry_and_double_send_never_post_again(self):
        self.lab.save_account({'account_id':'999','name':'Other','xs':'fixture'})
        self.lab.select_account({'account_id':'123'})
        preview=self.prepare()
        with self.assertRaises(LabError):
            self.lab.start_reviewed({'account_id':'999','operation_id':preview['operation_id'],'confirm':True})
        self.lab.previews[preview['operation_id']]['expires']=0
        with self.assertRaises(LabError):
            self.lab.start_reviewed({'account_id':'123','operation_id':preview['operation_id'],'confirm':True})
        preview=self.prepare()
        with patch('scripts.workspace_lab.probe',return_value={'status':'confirmed_by_response'}) as send:
            payload={'account_id':'123','operation_id':preview['operation_id'],'confirm':True}
            self.lab.start_reviewed(payload)
            self.lab.batch_thread.join(5)
            with self.assertRaises(LabError): self.lab.start_reviewed(payload)
            self.assertEqual(send.call_count,1)

    def test_link_rows_validation_and_duplicate_aliases(self):
        rows=parse_links('https://www.facebook.com/groups/a/posts/12/\nhttps://facebook.com/groups/a/permalink/12/?x=1\nhttps://evil.test/groups/a/\nhttps://facebook.com/page\nhttps://facebook.com/groups/a/')
        self.assertEqual([r['valid'] for r in rows],[True,False,False,False,True])
        with self.assertRaises(LabError):parse_links('\n'.join(['https://facebook.com/groups/a/']*51))

    def test_multi_group_total_limit_and_dedup(self):
        d=self.load('https://www.facebook.com/groups/456/\nhttps://www.facebook.com/groups/789/',20)
        self.assertEqual(len(d['posts']),20)
        self.assertEqual(len(set(p['post_id'] for p in d['posts'])),20)
        self.assertEqual(self.lab.read_job['available'],30)

    def test_direct_link_only_target_and_missing_not_faked(self):
        d=self.load('https://www.facebook.com/groups/456/posts/1003/')
        self.assertEqual([p['post_id'] for p in d['posts']],['1003'])
        d=self.load('https://www.facebook.com/groups/456/posts/222/')
        self.assertEqual(d['posts'],[])
        self.assertIn('Không đọc',self.lab.read_job['rows'][0]['error'])

    def test_sync_honest_unavailable_keeps_manual_groups(self):
        self.lab.links({'account_id':'123','links':'https://facebook.com/groups/456/'})
        with patch('scripts.workspace_lab.load_joined', side_effect=ValueError('changed')):
            self.lab.sync_groups({'account_id':'123'})
            self.lab.sync.wait()
        result = self.lab.sync.get('123')
        self.assertEqual(result['state'],'unavailable')
        self.assertFalse(result['complete'])
        self.assertEqual(len(self.lab.store.groups('123')),1)

    def test_session_revision_invalidates_preview(self):
        v=self.prepare()
        self.lab.save_account({'account_id':'123','name':'Changed','xs':'new-fixture'})
        with self.assertRaises(LabError):self.lab.start_reviewed({'account_id':'123','operation_id':v['operation_id'],'confirm':True})

    def test_preview_does_not_require_approval_but_rejects_injected_or_duplicate_posts(self):
        d=self.load()
        for items in [[{'post_id':'other','text':'hi'}],
                      [{'post_id':'1000','text':''}],
                      [{'post_id':'1000','text':'a'},{'post_id':'1000','text':'b'}]]:
            with self.assertRaises(LabError):self.lab.prepare({'account_id':'123','draft_id':d['id'],'items':items})
        result=self.lab.prepare({'account_id':'123','draft_id':d['id'],'items':[
            {'post_id':'1000','text':'common'},{'post_id':'1001','text':'common'}]})
        self.assertEqual(result['count'],2)

    def test_stop_unknown_blocks_account_and_never_next(self):
        v=self.prepare(2)
        with patch('scripts.workspace_lab.probe',return_value={'status':'outcome_unknown','error_category':'verification_required'}) as sender:
            self.lab.start_reviewed({'account_id':'123','operation_id':v['operation_id'],'confirm':True})
            self.lab.batch_thread.join(5)
        self.assertEqual(sender.call_count,1)
        self.assertEqual(self.lab.batch['items'][1]['status'],'not_sent')
        self.assertEqual(WorkspaceLab(self.tmp.name).store.account('123')['blocked'],'verification_required')

    def test_inflight_cancel_and_busy_session_edit(self):
        v=self.prepare(2)
        entered,release=threading.Event(),threading.Event()
        def send(*args,**kwargs):
            entered.set();release.wait(3);return {'status':'confirmed_by_response'}
        with patch('scripts.workspace_lab.probe',side_effect=send) as sender:
            self.lab.start_reviewed({'account_id':'123','operation_id':v['operation_id'],'confirm':True})
            self.assertTrue(entered.wait(2))
            with self.assertRaises(LabError):self.lab.save_account({'account_id':'123','name':'x','xs':'x'})
            self.lab.stop_work({'account_id':'123'});release.set();self.lab.batch_thread.join(5)
        self.assertEqual(sender.call_count,1)
        self.assertEqual(self.lab.batch['state'],'cancelled')

    def test_legacy_reservation_blocks_other_actor_and_new_text(self):
        j=ProbeJournal(self.lab.state_dir)
        report={'status':'reserved','target':{'post_id':'1000'},'actor_id':'999'}
        j.reserve('old',attempt_fingerprint('999','1000','old'),report);j.close()
        d=self.load()
        self.assertTrue(d['posts'][0]['blocked'])
        with self.assertRaises(LabError):self.lab.prepare({'account_id':'123','draft_id':d['id'],'items':[{'post_id':'1000','text':'different','approved':True}]})

    def test_strict_reservation_atomic_across_actors(self):
        j=ProbeJournal(self.lab.state_dir);k=ProbeJournal(self.lab.state_dir)
        report={'status':'reserved','target':{'post_id':'1000'},'actor_id':'123'}
        j.reserve('one','fp-one',report,strict=True)
        with self.assertRaises(ValueError):k.reserve('two','fp-two',dict(report,actor_id='999'),strict=True)
        j.close();k.close()

    def test_read_checkpoint_stops_other_groups(self):
        with patch('scripts.workspace_lab.load_recent_posts',side_effect=RemoteStop('verification_required')) as reader:
            self.lab.load_links({'account_id':'123','links':'https://facebook.com/groups/456/\nhttps://facebook.com/groups/789/','count':10})
            self.lab.batch_thread.join(3)
        self.assertEqual(reader.call_count,1)
        self.assertIsNone(self.lab.draft)

    def test_direct_fifty_posts_without_preview_and_duplicate_restart(self):
        from tests.workspace_fixture import fake_probe
        payload={'account_id':'123','links':'https://www.facebook.com/groups/456/','count':50,'text':'Common fixture text','confirm':True}
        with patch('scripts.workspace_lab.load_recent_posts',side_effect=feed), patch('scripts.workspace_lab.probe',side_effect=fake_probe) as sender, patch.object(self.lab.batch_cancel,'wait',return_value=False):
            self.lab.send_direct(payload);self.lab.batch_thread.join(10)
            self.assertFalse(self.lab.busy)
            self.assertEqual(sender.call_count,50)
            self.assertEqual(self.lab.batch['completed'],50)
            self.assertEqual(self.lab.batch['state'],'completed')
            self.lab.save_account({'account_id':'123','name':'Renamed','xs':''})
            self.lab.delete_account({'account_id':'123','confirm':True})
            history=self.lab.history()
            self.assertEqual(len(history),50)
            self.assertEqual(history[0]['account_name'],'Fixture A')
            self.assertEqual(history[0]['group_name'],'Nhóm fixture 456')
            self.assertIn('/groups/456/',history[0]['group_url'])
            self.lab.save_account({'account_id':'999','name':'Other','xs':'fixture'})
            self.lab.send_direct(dict(payload,account_id='999',text='Changed text'))
            self.lab.batch_thread.join(10)
            self.assertEqual(sender.call_count,50)
            self.assertEqual(self.lab.batch['skipped'],50)

    def test_direct_read_error_does_not_start_sending(self):
        with patch('scripts.workspace_lab.load_recent_posts',side_effect=RemoteStop('verification_required')),patch('scripts.workspace_lab.probe') as sender:
            self.lab.send_direct({'account_id':'123','links':'https://facebook.com/groups/456/','count':50,'text':'hi','confirm':True})
            self.lab.batch_thread.join(5)
            sender.assert_not_called()
            self.assertEqual(self.lab.read_job['state'],'stopped')
            self.assertFalse(self.lab.busy)

    def test_direct_error_after_two_posts_stops_remaining_forty_seven(self):
        from tests.workspace_fixture import fake_probe
        calls = []
        def send(target, text, *args, **kwargs):
            calls.append(target['post_id'])
            return fake_probe(target, 'VERIFY' if len(calls) == 3 else text, *args, **kwargs)
        with patch('scripts.workspace_lab.load_recent_posts', side_effect=feed), patch('scripts.workspace_lab.probe', side_effect=send), patch.object(self.lab.batch_cancel, 'wait', return_value=False):
            self.lab.send_direct({'account_id':'123','links':'https://facebook.com/groups/456/','count':50,'text':'hi','confirm':True})
            self.lab.batch_thread.join(5)
        self.assertEqual(len(calls), 3)
        self.assertEqual(self.lab.batch['state'], 'stopped')
        self.assertTrue(all(item['status'] == 'not_sent' for item in self.lab.batch['items'][3:]))
        self.assertEqual(WorkspaceLab(self.tmp.name).store.account('123')['blocked'], 'verification_required')

    def test_direct_cancel_during_read_and_busy_switch(self):
        entered,release=threading.Event(),threading.Event()
        def read(*args,**kw):entered.set();release.wait(3);return feed(*args,**kw)
        with patch('scripts.workspace_lab.load_recent_posts',side_effect=read),patch('scripts.workspace_lab.probe') as sender:
            payload={'account_id':'123','links':'https://facebook.com/groups/456/','count':50,'text':'hi','confirm':True}
            self.lab.send_direct(payload);self.assertTrue(entered.wait(2))
            with self.assertRaises(LabError):self.lab.send_direct(payload)
            with self.assertRaises(LabError):self.lab.select_account({'account_id':'123'})
            self.lab.stop_work({'account_id':'123'});release.set();self.lab.batch_thread.join(5)
            sender.assert_not_called();self.assertFalse(self.lab.busy)

    def test_direct_validation_no_partial_send_for_bad_input(self):
        with patch('scripts.workspace_lab.load_recent_posts') as read:
            for change in ({'text':''},{'text':123},{'text':'x'*10001},{'count':51},{'count':True},{'confirm':False},{'links':'https://facebook.com/groups/456/\nhttps://evil.test/'}):
                payload={'account_id':'123','links':'https://facebook.com/groups/456/','count':50,'text':'hi','confirm':True}
                with self.assertRaises(LabError):self.lab.send_direct(dict(payload,**change))
            read.assert_not_called()

    def test_history_pagination_and_legacy_name_fallback(self):
        j=ProbeJournal(self.lab.state_dir)
        for i in range(51):
            report={'status':'reserved','actor_id':'123','target':{'post_id':str(i),'group':'456','url':f'https://www.facebook.com/groups/456/posts/{i}/'}}
            j.reserve(str(i),str(i),report)
        j.close()
        page=self.lab.history_page({})
        self.assertEqual(len(page['items']),50);self.assertTrue(page['has_more'])
        self.assertEqual(page['items'][0]['account_name'],'Fixture A')
        self.assertTrue(page['items'][0]['account_name_is_current'])
        self.assertEqual(page['items'][0]['group_name'],'Chưa lưu tên nhóm')
        self.assertEqual(len(self.lab.history_page({'offset':50})['items']),1)
        with self.assertRaises(LabError):self.lab.history_page({'offset':-1})

    def test_response_classes(self):
        for code,loc,expected in [(429,'','restricted'),(302,'/checkpoint/','verification_required'),(302,'/login/','session_expired'),(403,'','permission_denied'),(500,'','remote_error')]:
            r=Mock(status_code=code,headers={'Location':loc},text='')
            with self.assertRaises(RemoteStop) as e:check_response(r)
            self.assertEqual(e.exception.category,expected)

    def test_recheck_expired_cannot_clear_prior_restriction(self):
        self.lab.store.block('123','restricted')
        self.lab.store.block('123','session_expired')
        self.lab.store.clear_expired('123')
        self.assertEqual(self.lab.store.account('123')['blocked'],'restricted')

    def test_sync_partial_persists_source_and_stop_preserves_old_groups(self):
        result={'groups':[{'url':'https://www.facebook.com/groups/456/','name':'Fixture joined'}],
                'status':'partial','complete':False}
        with patch('scripts.workspace_lab.load_joined',return_value=result):
            self.lab.sync_groups({'account_id':'123'});self.lab.sync.wait()
        self.assertEqual(self.lab.sync.get('123')['state'],'partial')
        g=self.lab.store.groups('123')[0]
        self.assertEqual((g['source'],g['state']),('sync','member'))
        self.lab.store.save_group('123',g['url'],'456','readable')
        self.assertEqual(self.lab.store.groups('123')[0]['name'],'Fixture joined')
        entered,release=threading.Event(),threading.Event()
        def sync(*a, **kw):entered.set();release.wait(2);return dict(result,groups=[])
        with patch('scripts.workspace_lab.load_joined',side_effect=sync):
            self.lab.sync_groups({'account_id':'123'});entered.wait(2)
            self.lab.stop_sync({'account_id':'123','job_id':self.lab.sync.get('123')['id']});release.set();self.lab.sync.wait()
        self.assertEqual(self.lab.sync.get('123')['state'],'cancelled')
        self.assertEqual(len(self.lab.store.groups('123')),1)


    def test_read_parser_failure_stops_run_without_persistent_account_hold(self):
        from scripts.group_feed import FeedError
        with patch('scripts.workspace_lab.load_recent_posts',side_effect=FeedError('Cấu trúc đã thay đổi')):
            self.lab.load_links({'account_id':'123','links':'https://facebook.com/groups/456/','count':10})
            self.lab.batch_thread.join(3)
        self.assertFalse(self.lab.store.account('123')['blocked'])
        self.assertEqual(self.lab.read_job['state'],'stopped')


class WorkspaceHTTPTests(unittest.TestCase):
    def setUp(self):
        gate=patch.object(WorkspaceLab, 'AUTO_SYNC', False);gate.start();self.addCleanup(gate.stop)

    def test_real_router_protects_new_and_disables_legacy_paths(self):
        with tempfile.TemporaryDirectory() as folder:
            server=make_server(folder,port=0)
            worker=threading.Thread(target=server.serve_forever,daemon=True);worker.start()
            base=f'http://127.0.0.1:{server.server_port}'
            def post(path,data,csrf=True):
                headers={'Content-Type':'application/json','Origin':base}
                if csrf:headers['X-Lab-CSRF']=server.lab.csrf
                req=urllib.request.Request(base+path,data=json.dumps(data).encode(),headers=headers)
                return urllib.request.urlopen(req,timeout=3)
            try:
                for path in ['/api/accounts/save','/api/accounts/delete','/api/links/load','/api/review/send','/api/send/direct','/api/history']:
                    with self.assertRaises(urllib.error.HTTPError) as e:post(path,{},False)
                    self.assertEqual(e.exception.code,403)
                with post('/api/accounts/save',{'account_id':'123','name':'Fixture','xs':'synthetic'}) as r:
                    self.assertNotIn('synthetic',r.read().decode())
                for path in ['/api/session','/api/send','/api/batch/start']:
                    with self.assertRaises(urllib.error.HTTPError) as e:post(path,{})
                    self.assertEqual(e.exception.code,409)
            finally:
                server.shutdown();server.server_close();worker.join(3)
