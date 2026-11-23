import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch

import requests

from scripts.group_feed import FeedError, bootstrap, extract_posts, load_recent_posts, parse_group


def page_html(actor='123', sorting='CHRONOLOGICAL'):
    metadata = {'queryName': 'CometGroupDiscussionRootSuccessQuery', 'queryID': '987654',
                'actorID': actor, 'variables': {'groupID': '456', 'sortingSetting': sorting,
                'regular_stories_count': 1, 'regular_stories_stream_initial_count': 1,
                'hoistStoriesCount': 0}}
    return ('<script type="application/json">' + json.dumps({'route': metadata}) + '</script>'
            '<script>["DTSGInitData",[],{"token":"synthetic-only"}]</script>')


def post(post_id, stamp, **extra):
    return dict(__typename='Story', post_id=str(post_id), creation_time=stamp,
                feedback={'can_viewer_comment': True}, **extra)


def feed_data(nodes):
    return {'data': {'group': {'id': '456', 'group_feed': {'edges': [{'node': node} for node in nodes]}}}}


class FeedParserTests(unittest.TestCase):
    def test_group_and_post_link_resolve_to_group(self):
        for raw in ('456', 'https://www.facebook.com/groups/example/',
                    'https://www.facebook.com/groups/example/permalink/789/?locale=vi_VN'):
            self.assertTrue(parse_group(raw)['url'].startswith('https://www.facebook.com/groups/'))

    def test_untrusted_or_unsupported_group_urls_rejected(self):
        for raw in ('https://facebook.com.evil/groups/1/', 'http://facebook.com/groups/1/',
                    'https://user:secret@facebook.com/groups/1/', 'https://facebook.com:8000/groups/1/',
                    'https://facebook.com/groups/../', 'https://facebook.com/profile/posts/123', None):
            with self.subTest(raw=raw), self.assertRaises(FeedError):
                parse_group(raw)

    def test_bootstrap_uses_dynamic_query_and_preserves_sorting(self):
        group_id, doc, variables, _ = bootstrap(page_html(), '123', 20)
        self.assertEqual((group_id, doc), ('456', '987654'))
        self.assertEqual(variables['sortingSetting'], 'CHRONOLOGICAL')
        self.assertEqual(variables['regular_stories_count'], 25)
        self.assertEqual(variables['hoistStoriesCount'], 0)

    def test_wrong_actor_and_nonchronological_feed_rejected(self):
        for html in (page_html(actor='999'), page_html(sorting='RECENT_ACTIVITY'), '<html>login</html>'):
            with self.assertRaises(FeedError):
                bootstrap(html, '123', 10)

    def test_only_feed_edges_not_attached_or_related_posts(self):
        node = post(789, 20, attached_story=post(999, 99))
        data = feed_data([node, {'__typename': 'GroupHeader'}, post(790, 30), post(789, 20)])
        data['related_story'] = post(888, 999)
        posts = extract_posts(data, '456', 10)
        self.assertEqual([item['post_id'] for item in posts], ['790', '789'])
        self.assertEqual(posts[0]['target']['group'], '456')

    def test_missing_id_date_and_unknown_response_do_not_create_targets(self):
        data = feed_data([post('pfbidExample', 100), post(1, None)])
        with self.assertRaises(FeedError):
            extract_posts(data, '456', 20)
        for data in ({'errors': [{}]}, {'_stream_incomplete': True}):
            with self.assertRaises(FeedError):
                extract_posts(data, '456', 20)

    def test_post_that_disallows_comments_is_marked(self):
        node = post(789, 20)
        node['feedback']['can_viewer_comment'] = False
        self.assertFalse(extract_posts(feed_data([node]), '456', 10)[0]['can_comment'])


class FeedRequestTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.cookies = Path(self.temp.name)/'cookies.json'
        self.cookies.write_text(json.dumps([{'name':'c_user','value':'123'}, {'name':'xs','value':'synthetic-only'}]))
        self.session = requests.Session()
        self.session.get = Mock(return_value=Mock(status_code=200, text=page_html()))
        self.session.post = Mock(return_value=Mock(status_code=200, text=json.dumps(feed_data([post(789, 100)]))))
        self.create = patch('scripts.group_feed.create_session', return_value=self.session)
        self.create.start()
        self.addCleanup(self.create.stop)
        self.network = patch('requests.sessions.Session.request', side_effect=AssertionError('No network in unit tests'))
        self.network.start()
        self.addCleanup(self.network.stop)

    def load(self, count=10):
        return load_recent_posts('https://www.facebook.com/groups/example/', count, self.cookies, '123')

    def test_read_uses_only_captured_query_and_no_comment_mutation(self):
        result = self.load()
        self.assertEqual(result['actual_count'], 1)
        sent = self.session.post.call_args.kwargs
        self.assertFalse(sent['allow_redirects'])
        self.assertEqual(sent['data']['doc_id'], '987654')
        self.assertEqual(sent['data']['fb_api_req_friendly_name'], 'CometGroupDiscussionRootSuccessQuery')
        self.assertEqual(json.loads(sent['data']['variables'])['sortingSetting'], 'CHRONOLOGICAL')
        self.assertTrue(all(cookie.domain == '.facebook.com' for cookie in self.session.cookies))

    def test_counts_other_than_integer_10_or_20_rejected(self):
        for count in (1, 21, '10', 10.0, True):
            with self.subTest(count=count), self.assertRaises(FeedError):
                self.load(count)
        self.session.get.assert_not_called()

    def test_login_or_external_redirect_stops_before_query(self):
        for target in ('https://evil.invalid/', 'https://www.facebook.com/login/', '/checkpoint/'):
            self.session.get.return_value = Mock(status_code=302, headers={'Location': target})
            with self.assertRaises(FeedError):
                self.load()
        self.session.post.assert_not_called()

    def test_network_error_and_invalid_payload_are_safe(self):
        self.session.get.side_effect = requests.Timeout('do not expose upstream details')
        with self.assertRaises(FeedError) as ctx:
            self.load()
        self.assertNotIn('upstream', str(ctx.exception))
        self.session.get.side_effect = None
        self.session.post.return_value.text = '<html>login</html>'
        with self.assertRaises(FeedError):
            self.load()
