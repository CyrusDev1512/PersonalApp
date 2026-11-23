import json
import unittest
from unittest.mock import Mock, patch

from scripts import feed_pagination as pg
from scripts.group_feed import FeedError, extract_posts
from tests import test_group_feed as fixtures
from tests.test_group_feed import feed_data, post


def page(ids, cursor, more=True):
    value = feed_data([post(i, 10000-i, message={'text':'fixture'}) for i in ids])
    value['data']['group']['group_feed']['page_info'] = {'end_cursor':cursor,'has_next_page':more}
    return value


class PaginationTests(unittest.TestCase):
    load = fixtures.FeedRequestTests.load

    def setUp(self):
        fixtures.FeedRequestTests.setUp(self)
        self.resolver = patch('scripts.feed_pagination.resolve', return_value=('765432', {'count','cursor','id','sortingSetting'}))
        self.resolve = self.resolver.start()
        self.addCleanup(self.resolver.stop)

    def pages(self, values):
        self.session.post.side_effect = [Mock(status_code=200, text=json.dumps(value)) for value in values]

    def test_two_pages_fifty_unique_with_overlap_and_correct_cursor(self):
        self.pages([page(range(1,30),'cursor-one'),page(range(29,52),'cursor-two')])
        result = self.load(50)
        self.assertEqual(result['actual_count'],50)
        self.assertEqual(len({p['post_id'] for p in result['posts']}),50)
        self.assertEqual(result['pages_read'],2)
        sent = self.session.post.call_args.kwargs['data']
        self.assertEqual(sent['doc_id'],'765432')
        variables = json.loads(sent['variables'])
        self.assertEqual(variables['cursor'],'cursor-one')
        self.assertEqual(variables['id'],'456')
        self.assertEqual(variables['sortingSetting'],'CHRONOLOGICAL')

    def test_exhausted_group_returns_truthful_short_count(self):
        self.pages([page([1,2],'first'),page([3],None,False)])
        r=self.load(50)
        self.assertEqual(r['actual_count'],3);self.assertEqual(r['stop_reason'],'exhausted');self.assertTrue(r['complete'])

    def test_missing_query_returns_partial_not_fabricated_fifty(self):
        self.resolve.return_value=None
        self.pages([page([1,2],'first')]);r=self.load(50)
        self.assertFalse(r['complete']);self.assertEqual(r['stop_reason'],'pagination_unavailable')
        self.assertEqual(self.session.post.call_count,1)

    def test_repeated_cursor_stops_instead_of_looping(self):
        self.pages([page([1],'same'),page([1],'same')])
        with self.assertRaises(FeedError):self.load(50)
        self.assertEqual(self.session.post.call_count,2)

    def test_error_in_later_page_discards_partial_result(self):
        self.pages([page([1],'first'),{'errors':[{'code':1}]}])
        with self.assertRaises(FeedError):self.load(50)

    def test_unknown_group_in_pagination_cannot_mix_posts(self):
        wrong=page([2],'second');wrong['data']['group']['id']='999'
        self.pages([page([1],'first'),wrong])
        with self.assertRaises(FeedError):self.load(50)

    def test_max_pages_bound(self):
        self.pages([page([i],str(i)) for i in range(10)])
        r=self.load(50)
        self.assertEqual(r['pages_read'],10);self.assertEqual(r['stop_reason'],'page_limit');self.assertFalse(r['complete'])

    def test_empty_page_can_continue_with_new_cursor(self):
        self.pages([page([],'one'),page([1,2],None,False)])
        self.assertEqual(self.load(50)['actual_count'],2)

    def test_unrelated_feed_is_excluded(self):
        data=page([1],None,False)
        data['data']['recommended']=page([999],None,False)['data']['group']
        data['data']['recommended']['id']='888'
        self.assertEqual([p['post_id'] for p in extract_posts(data,'456',50)],['1'])

    def test_cancel_before_next_page_never_posts_next_query(self):
        from scripts.group_feed import load_recent_posts
        self.pages([page([1],'first')])
        checks=iter([False,True])
        with self.assertRaises(FeedError):
            load_recent_posts('456',50,self.cookies,'123',cancelled=lambda:next(checks))
        self.assertEqual(self.session.post.call_count,1)


class MetadataTests(unittest.TestCase):
    def test_current_asset_module_metadata_without_execution(self):
        text='__d("'+pg.QUERY+'.graphql",[],function(){return {operationKind:"query",name:"group_feed",args:[{kind:"LocalArgument",name:"count"},{kind:"LocalArgument",name:"cursor"},{kind:"LocalArgument",name:"id"},{kind:"LocalArgument",name:"sortingSetting"}]}});'
        text+='__d("'+pg.OPERATION+'",[],function(){e.exports="456789"});'
        doc,args=pg.metadata(text)
        self.assertEqual(doc,'456789');self.assertEqual(len(args),4)
        self.assertEqual(pg.metadata(text.replace('operationKind:"query"','operationKind:"mutation"'))[1],set())

    def test_asset_url_allowlist_no_auth_redirect_or_other_host(self):
        urls=pg.asset_urls(' '.join(['https://static.xx.fbcdn.net/rsrc.php/v4/a.js?x=1&amp;y=2','https://evil.invalid/a.js','https://static.xx.fbcdn.net:444/rsrc.php/a.js','https://user@static.xx.fbcdn.net/rsrc.php/a.js']))
        self.assertEqual(urls,['https://static.xx.fbcdn.net/rsrc.php/v4/a.js?x=1&y=2'])

    def test_variables_preserve_root_context(self):
        r=pg.variables({'feedType':'DISCUSSION','filter_topic_id':None,'renderLocation':'group'}, {'feedType','filterTopicId','referringStoryRenderLocation'},'456','cursor',25)
        self.assertEqual(r['feedType'],'DISCUSSION');self.assertEqual(r['referringStoryRenderLocation'],'group')
