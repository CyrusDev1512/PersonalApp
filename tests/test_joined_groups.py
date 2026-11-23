import json
import unittest
from scripts.joined_groups import parse_joined
from scripts.group_feed import FeedError


def page(next_page=True, actor='123', state='MEMBER'):
    return '<script type="application/json">'+json.dumps([
        {'queryName':'GroupsCometJoinsRootQuery','actorID':actor},
        {'viewer':{'all_joined_groups':{'tab_groups_list':{
            'edges':[{'node':{'__typename':'Group','id':'456','name':'Fixture','viewer_join_state':state}}],
            'page_info':{'has_next_page':next_page,'end_cursor':'opaque' if next_page else None}}}}},
        {'viewer':{'recommended_groups':{'tab_groups_list':{'edges':[{'node':{'id':'999','name':'Ignore'}}]}}}}
    ])+'</script>'


class JoinedGroupsTests(unittest.TestCase):
    def test_partial_page_does_not_claim_complete_or_include_recommendations(self):
        result=parse_joined(page(),'123')
        self.assertFalse(result['complete'])
        self.assertEqual(result['status'],'partial')
        self.assertEqual(result['groups'],[{'name':'Fixture','url':'https://www.facebook.com/groups/456/'}])

    def test_end_pagination_required_for_complete(self):
        self.assertTrue(parse_joined(page(False),'123')['complete'])
        with self.assertRaises(FeedError):parse_joined(page().replace('"has_next_page": true','"unknown_flag": true'),'123')

    def test_wrong_actor_pending_membership_and_no_source_fail_closed(self):
        for html in (page(actor='other'),page(state='REQUESTED'),'<html>login</html>'):
            with self.assertRaises(FeedError):parse_joined(html,'123')


from unittest.mock import Mock, patch
from scripts.joined_groups import load_joined
from scripts import joined_pagination
from scripts.remote_status import RemoteStop


def response(html):
    return Mock(status_code=200, text=html, headers={})


def next_page(ids=('789',), more=False, cursor=None):
    return {'data':{'viewer':{'all_joined_groups':{'tab_groups_list':{
        'edges':[{'node':{'__typename':'Group','id':gid,'name':'Fixture '+gid,'viewer_join_state':'MEMBER'}} for gid in ids],
        'page_info':{'has_next_page':more,'end_cursor':cursor}}}}}}


class JoinedPaginationTests(unittest.TestCase):
    def setUp(self):
        self.session=Mock()
        html=page().replace('"actorID": "123"','"actorID": "123", "variables": {"ordering":["integrity_signals"],"scale":2}')
        self.session.get.return_value=response(html)
        self.patches=[patch('scripts.joined_groups.create_session',return_value=self.session),
            patch('scripts.joined_groups.tokens_from',return_value={'fb_dtsg':'fixture'}),
            patch('scripts.joined_pagination.resolve',return_value='1234'),
            patch('requests.sessions.Session.request',side_effect=AssertionError('No external network'))]
        for p in self.patches:p.start();self.addCleanup(p.stop)

    def load(self, **kw):
        return load_joined([{'name':'c_user','value':'123'},{'name':'xs','value':'fixture'}],'123',**kw)

    def test_all_pages_deduplicate_and_final_flag_required(self):
        self.session.post.side_effect=[response(json.dumps(next_page(('456','789'),True,'second'))),
            response(json.dumps(next_page(('999',),False)))]
        progress=[]
        result=self.load(progress=lambda **p:progress.append(p))
        self.assertTrue(result['complete']);self.assertEqual(len(result['groups']),3)
        self.assertEqual(result['pages_read'],3);self.assertEqual(result['stop_reason'],'exhausted')
        self.assertEqual(progress[-1]['completed'],3)
        calls=self.session.post.call_args_list
        self.assertEqual([json.loads(c.kwargs['data']['variables'])['cursor'] for c in calls],['opaque','second'])
        self.assertTrue(all(not c.kwargs['allow_redirects'] for c in calls))
        self.session.close.assert_called_once()

    def test_cursor_loop_and_limit_are_partial(self):
        self.session.post.return_value=response(json.dumps(next_page(('789',),True,'opaque')))
        result=self.load();self.assertFalse(result['complete']);self.assertEqual(result['stop_reason'],'repeated_cursor')
        self.assertEqual(self.session.post.call_count,1)
        with patch('scripts.joined_groups.MAX_PAGES',1):
            result=self.load();self.assertEqual(result['stop_reason'],'page_limit')

    def test_stop_between_pages_makes_no_further_requests(self):
        flag=[False]
        def progress(**p):
            if p['pages_read']==2:flag[0]=True
        self.session.post.return_value=response(json.dumps(next_page(('789',),True,'second')))
        with self.assertRaises(FeedError):self.load(cancelled=lambda:flag[0],progress=progress)
        self.assertEqual(self.session.post.call_count,1)

    def test_bad_page_never_claims_complete(self):
        bad=[{'data':{'viewer':{'recommended_groups':{}}}},
             dict(next_page(),hasNext=True),
             next_page(('789',),True,''),
             {'errors':[{'message':'Please confirm your identity'}]}]
        for payload in bad:
            with self.subTest(payload=payload):
                self.session.post.return_value=response(json.dumps(payload))
                with self.assertRaises((FeedError,RemoteStop)):self.load()

    def test_unavailable_query_keeps_verified_first_page_as_partial(self):
        with patch('scripts.joined_pagination.resolve',return_value=None):result=self.load()
        self.assertFalse(result['complete']);self.assertEqual(result['stop_reason'],'pagination_unavailable')
        self.session.post.assert_not_called()

    def test_empty_terminal_page_is_complete(self):
        self.session.post.return_value=response(json.dumps(next_page(())))
        result=self.load();self.assertTrue(result['complete']);self.assertEqual(len(result['groups']),1)

    def test_query_metadata_requires_joined_read_shape(self):
        name=joined_pagination.QUERY
        q='__d("'+name+'.graphql",[],function(){'+','.join('kind:"LocalArgument",name:"'+a+'"' for a in sorted(joined_pagination.ARGS))+' operationKind:"query" alias:"all_joined_groups" name:"tab_groups_list" name:"viewer_join_state"});'
        op='__d("'+name+'_facebookRelayOperation",[],function(){a.exports="1234"});'
        self.assertEqual(joined_pagination.metadata(q+op),('1234',True))
        self.assertFalse(joined_pagination.metadata((q+op).replace('operationKind:"query"','operationKind:"mutation"'))[1])
        self.assertFalse(joined_pagination.metadata((q+op).replace('all_joined_groups','recommended_groups'))[1])
