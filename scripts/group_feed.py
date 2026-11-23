"""Read a group's chronological feed using the authenticated page's own query.

No browser automation, hard-coded document IDs, or comment mutations here.
"""
from html.parser import HTMLParser
import json
import re
from urllib.parse import urlparse, urljoin

import requests

from scripts.comment_probe import read_personal_cookies
from scripts.fb_session import create_session, _graphql_form, parse_graphql_response
from scripts.remote_status import check_response, check_graphql, RemoteStop
from scripts import feed_pagination


class FeedError(ValueError):
    pass


def parse_group(raw):
    if not isinstance(raw, str) or not 1 <= len(raw) <= 2048:
        raise FeedError('Nhập link nhóm hoặc ID nhóm.')
    raw = raw.strip()
    if re.fullmatch(r'[0-9]{1,30}', raw):
        slug = raw
    else:
        try:
            u = urlparse(raw)
            valid = (u.scheme == 'https' and u.hostname in
                     {'facebook.com', 'www.facebook.com', 'm.facebook.com', 'web.facebook.com'}
                     and not u.username and not u.password and u.port in (None, 443))
        except ValueError:
            valid = False
        if not valid:
            raise FeedError('Cần link HTTPS facebook.com/groups/... hoặc ID nhóm dạng số.')
        match = re.fullmatch(r'/groups/([A-Za-z0-9._-]{1,100})(?:/(?:(?:posts|permalink)/[A-Za-z0-9]+/?)?)?', u.path)
        if not match or match[1] in {'.', '..'}:
            raise FeedError('Cần link nhóm facebook.com/groups/...; có thể dán link một bài trong nhóm.')
        slug = match[1]
    return {'slug': slug, 'url': f'https://www.facebook.com/groups/{slug}/'}


class JsonScripts(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.parts = []
        self.documents = []

    def handle_starttag(self, tag, attrs):
        if tag == 'script':
            self.active = dict(attrs).get('type') == 'application/json'
            self.parts = []

    def handle_data(self, data):
        if self.active:
            self.parts.append(data)

    def handle_endtag(self, tag):
        if tag == 'script' and self.active:
            try:
                self.documents.append(json.loads(''.join(self.parts)))
            except ValueError:
                pass
            self.active = False


def walk(value):
    yield value
    if isinstance(value, dict):
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def bootstrap(html, actor, limit):
    parser = JsonScripts()
    parser.feed(html)
    candidates = [value for doc in parser.documents for value in walk(doc)
                  if isinstance(value, dict) and value.get('queryName') == 'CometGroupDiscussionRootSuccessQuery'
                  and isinstance(value.get('variables'), dict)]
    if not candidates:
        raise FeedError('Không đọc được nhóm. Kiểm tra phiên đăng nhập và quyền xem nhóm trên Facebook.')
    group_ids = {str(value['variables'].get('groupID', '')) for value in candidates}
    if len(group_ids) != 1 or not re.fullmatch(r'[0-9]{1,30}', next(iter(group_ids))):
        raise FeedError('Không xác định chắc chắn nhóm; chưa lấy danh sách bài.')
    q = candidates[0]
    if str(q.get('actorID', '')) != actor:
        raise FeedError('Danh tính Facebook không khớp phiên đã chọn. Hãy lưu lại phiên cá nhân.')
    if not re.fullmatch(r'[0-9]{1,40}', str(q.get('queryID', ''))):
        raise FeedError('Facebook thay đổi định dạng đọc nhóm; chưa lấy danh sách bài.')
    variables = dict(q['variables'])
    if variables.get('sortingSetting') != 'CHRONOLOGICAL':
        raise FeedError('Facebook chưa trả chế độ bài mới nhất. Chưa dùng danh sách này để gửi.')
    for name in ('regular_stories_count', 'regular_stories_stream_initial_count'):
        if type(variables.get(name)) is not int:
            raise FeedError('Facebook thay đổi cấu trúc danh sách bài; cần cập nhật bộ đọc.')
        # Non-post feed units (e.g. group headers) can consume an edge slot.
        variables[name] = limit + 5
    tokens = {}
    patterns = {'fb_dtsg': r'"DTSGInitData",\[\],\{"token":"([^"]+)"',
                'lsd': r'"LSD",\[\],\{"token":"([^"]+)"',
                '__rev': r'"client_revision":(\d+)', '__hsi': r'"hsi":"(\d+)"',
                '__spin_t': r'"__spin_t":(\d+)', '__spin_b': r'"__spin_b":"([^"]+)"'}
    for name, pattern in patterns.items():
        match = re.search(pattern, html)
        if match:
            tokens[name] = match[1]
    if not tokens.get('fb_dtsg'):
        raise FeedError('Phiên không còn dùng được. Đăng nhập Facebook rồi lấy lại phiên.')
    return next(iter(group_ids)), str(q['queryID']), variables, tokens


def group_feeds(data, group_id):
    return [node['group_feed'] for node in walk(data) if isinstance(node, dict)
            and str(node.get('id')) == group_id and isinstance(node.get('group_feed'), dict)]


def extract_posts(data, group_id, limit, *, allow_empty=False):
    if data.get('errors') or data.get('_stream_incomplete'):
        raise FeedError('Facebook chưa trả danh sách đầy đủ hoặc đã từ chối yêu cầu đọc nhóm.')
    feeds = group_feeds(data, group_id)
    posts = {}
    for feed in feeds:
        for edge in feed.get('edges', []):
            node = edge.get('node') if isinstance(edge, dict) else None
            if not isinstance(node, dict) or node.get('__typename') != 'Story':
                continue
            post_id, stamp = node.get('post_id'), node.get('creation_time')
            if not isinstance(post_id, str) or not re.fullmatch(r'[0-9]{1,30}', post_id):
                continue
            if type(stamp) not in (int, float) or not 0 < stamp < 100_000_000_000:
                continue
            feedback = node.get('feedback') or {}
            if not isinstance(feedback, dict):
                feedback = {}
            sections = node.get('comet_sections')
            content = sections.get('content') if isinstance(sections, dict) else None
            story = content.get('story') if isinstance(content, dict) else None
            story = story if isinstance(story, dict) else {}
            message = story.get('message') or node.get('message') or {}
            text = message.get('text', '') if isinstance(message, dict) else ''
            posts[post_id] = {'post_id': post_id, 'created_at': stamp,
                              'excerpt': text[:180] if isinstance(text, str) else '',
                              'can_comment': feedback.get('can_viewer_comment') is not False,
                              'target': {'post_id': post_id, 'group': group_id,
                                         'url': f'https://www.facebook.com/groups/{group_id}/posts/{post_id}/'}}
    if not posts and not allow_empty:
        raise FeedError('Không lấy được bài có ID và ngày đăng rõ ràng; chưa tạo danh sách gửi.')
    return sorted(posts.values(), key=lambda post: post['created_at'], reverse=True)[:limit]


def next_cursor(data, group_id):
    feeds = group_feeds(data, group_id)
    if len(feeds) != 1:
        raise FeedError('Không xác định chắc chắn trang tiếp theo của nhóm.')
    info = feeds[0].get('page_info')
    if not isinstance(info, dict) or type(info.get('has_next_page')) is not bool:
        return None, 'unknown'
    if not info['has_next_page']:
        return None, 'exhausted'
    cursor = info.get('end_cursor')
    if not isinstance(cursor, str) or not 1 <= len(cursor) <= 20000:
        raise FeedError('Facebook trả trang tiếp theo thiếu mốc phân trang; đã dừng đọc.')
    return cursor, 'more'


def group_name(html, data, group_id):
    parser = JsonScripts()
    parser.feed(html)
    names = {node['name'].strip() for doc in [data, *parser.documents] for node in walk(doc)
             if isinstance(node, dict) and node.get('__typename') == 'Group'
             and str(node.get('id')) == group_id and isinstance(node.get('name'), str)
             and 0 < len(node['name'].strip()) <= 300}
    return next(iter(names)) if len(names) == 1 else None


def load_recent_posts(raw_group, limit, cookie_path, actor, *, strict=False, cancelled=None):
    if type(limit) is not int or limit not in (10, 20, 50):
        raise FeedError('Chọn 10, 20 hoặc 50 bài.')
    group = parse_group(raw_group)
    cookies = read_personal_cookies(cookie_path, actor)
    session = create_session(cookies)
    session.cookies.clear()
    for key, value in cookies.items():
        session.cookies.set(key, value, domain='.facebook.com', path='/', secure=True)
    try:
        url = group['url'] + '?sorting_setting=CHRONOLOGICAL'
        for _ in range(4):
            response = session.get(url, timeout=25, allow_redirects=False)
            if response.status_code not in (301, 302, 303, 307, 308):
                if strict:
                    check_response(response)
                break
            target = urljoin(url, response.headers.get('Location', ''))
            parsed = urlparse(target)
            if (parsed.scheme != 'https' or parsed.hostname not in {'www.facebook.com', 'facebook.com'}
                    or parsed.username or parsed.password or parsed.port not in (None, 443)
                    or not parsed.path.startswith('/groups/')):
                if strict:
                    check_response(response)
                raise FeedError('Facebook yêu cầu đăng nhập hoặc xác minh. Hãy xử lý trên Facebook rồi lưu lại phiên.')
            url = target
        if response.status_code != 200:
            raise FeedError('Facebook từ chối hoặc chưa tải được nhóm. Chưa gửi bình luận nào.')
        group_id, doc_id, variables, tokens = bootstrap(response.text, actor, limit)
        def query(query_id, name, values):
            if cancelled and cancelled():
                raise FeedError('Đã dừng đọc theo yêu cầu.')
            form = _graphql_form(tokens, actor, query_id, name, values)
            result = session.post('https://www.facebook.com/api/graphql/', data=form, timeout=45,
                              allow_redirects=False, headers={'Content-Type': 'application/x-www-form-urlencoded',
                              'Origin': 'https://www.facebook.com', 'Referer': group['url'],
                              'X-FB-Friendly-Name': name})
            if strict:
                check_response(result)
            if result.status_code != 200:
                raise FeedError('Facebook từ chối đọc bài mới nhất. Kiểm tra phiên hoặc quyền truy cập nhóm.')
            try:
                data = parse_graphql_response(result.text)
            except (ValueError, TypeError):
                raise FeedError('Phản hồi danh sách bài không hợp lệ; chưa tạo danh sách gửi.') from None
            if strict:
                check_graphql(data)
            return data
        data = query(doc_id, 'CometGroupDiscussionRootSuccessQuery', variables)
        name = group_name(response.text, data, group_id)
        posts = {p['post_id']:p for p in extract_posts(data, group_id, limit, allow_empty=True)}
        pages, cursors, stop_reason = 1, set(), 'limit'
        pagination = None
        while len(posts) < limit:
            cursor, status = next_cursor(data, group_id)
            if not cursor:
                stop_reason = status
                break
            if cursor in cursors:
                raise FeedError('Facebook lặp lại mốc phân trang; đã dừng để tránh lấy bài trùng.')
            if pages >= 10:
                stop_reason = 'page_limit'
                break
            if cancelled and cancelled():
                raise FeedError('Đã dừng đọc theo yêu cầu.')
            pagination = pagination or feed_pagination.resolve(response.text)
            if not pagination:
                stop_reason = 'pagination_unavailable'
                break
            cursors.add(cursor)
            page_id, args = pagination
            data = query(page_id, feed_pagination.QUERY,
                         feed_pagination.variables(variables, args, group_id, cursor, min(30, limit-len(posts)+5)))
            pages += 1
            for post in extract_posts(data, group_id, limit, allow_empty=True):
                posts.setdefault(post['post_id'], post)
        selected = sorted(posts.values(), key=lambda post: post['created_at'], reverse=True)[:limit]
        return {'group': dict(group, id=group_id, name=name), 'posts': selected, 'requested_count': limit,
                'actual_count': len(selected), 'sorting': 'CHRONOLOGICAL', 'pages_read':pages,
                'stop_reason':stop_reason, 'complete':len(selected)>=limit or stop_reason=='exhausted'}
    except requests.RequestException:
        raise FeedError('Không tải được danh sách bài. Kiểm tra kết nối rồi thử lại; chưa gửi bình luận.') from None
    finally:
        session.close()
