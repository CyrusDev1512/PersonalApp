"""Temporary UI fixture; every external HTTP request is forbidden."""
import tempfile
import time
import argparse
from unittest.mock import patch
from scripts.lab_server import make_server, ROOT
from scripts.comment_probe import ProbeJournal, attempt_fingerprint, content_hash
from tests.test_workspace import feed


def fake_probe(target,text,cookies,actor,directory,op,**kw):
    result={'operation_id':op,'actor_id':actor,'target':target,'status':'reserved',
            'content_hash':content_hash(text),'created_at':time.time(),**(kw.get('context') or {}),'write_attempts':0,'note':'FIXTURE — không gửi Facebook.'}
    journal=ProbeJournal(directory)
    try:
        journal.reserve(op,attempt_fingerprint(actor,target['post_id'],text),result,strict=True)
        result['status']='outcome_unknown' if 'TIMEOUT' in text or 'VERIFY' in text else 'confirmed_by_response'
        if result['status']=='outcome_unknown':
            result['error_category']='verification_required' if 'VERIFY' in text else 'network_error'
        journal.finish(op,result)
    finally:
        journal.close()
    return result


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--port',type=int,default=8794)
    args=parser.parse_args()
    def joined(cookies, actor, **kw):
        time.sleep(6)
        return {'groups':[{'url':'https://www.facebook.com/groups/456/','name':'Nhóm thiết kế '+actor},
                          {'url':'https://www.facebook.com/groups/789/','name':'Góc chia sẻ '+actor}], 'complete':False, 'status':'partial'}
    with tempfile.TemporaryDirectory(prefix='CommentLab-multi-fixture-') as root, patch('scripts.workspace_lab.probe',side_effect=fake_probe), patch('scripts.workspace_lab.load_recent_posts',side_effect=feed), patch('scripts.workspace_lab.load_joined',side_effect=joined), patch('requests.sessions.Session.request',side_effect=AssertionError('External request forbidden')):
        server=make_server(root,args.port,asset_root=ROOT)
        server.lab.save_account({'account_id':'123','name':'Fixture Minh An','xs':'synthetic-fixture-only'})
        server.lab.save_account({'account_id':'456','name':'Fixture Thanh Ha','xs':'synthetic-fixture-only'})
        server.lab.select_account({'account_id':'123'})
        with_journal=ProbeJournal(server.lab.state_dir)
        pending={'operation_id':'fixture-pending','actor_id':'123','account_name':'Fixture Minh An',
                 'target':{'post_id':'1000','url':'https://www.facebook.com/groups/456/posts/1000/'},
                 'group_name':'Nhóm thiết kế','group_url':'https://www.facebook.com/groups/456/',
                 'status':'outcome_unknown','error_category':'unrecognized_response','write_attempts':1,
                 'created_at':time.time(),'note':'Dữ liệu giả kiểm thử xác nhận bỏ qua.'}
        with_journal.reserve('fixture-pending','fixture-pending',pending,strict=True)
        with_journal.finish('fixture-pending',pending);with_journal.close()
        server.lab.store.block('123','unrecognized_response')
        print(f'FIXTURE http://127.0.0.1:{args.port}/ — external requests forbidden',flush=True)
        try:
            server.serve_forever()
        finally:
            server.lab.request_shutdown();server.lab.sync.wait(10);server.server_close()
