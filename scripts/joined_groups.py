"""Read joined groups until Facebook explicitly returns the final page."""
import re
from scripts.group_feed import JsonScripts, walk, FeedError
from scripts.comment_probe import read_personal_cookies
from scripts.fb_session import create_session, _graphql_form, parse_graphql_response
from scripts.remote_status import check_response, check_graphql
from scripts import joined_pagination

MAX_PAGES = 500


def connection_result(documents):
    nodes = [n for doc in documents for n in walk(doc) if isinstance(n, dict)]
    viewers = [n['viewer'] for n in nodes if isinstance(n.get('viewer'), dict)
               and isinstance(n['viewer'].get('all_joined_groups'), dict)]
    connections = [v['all_joined_groups'].get('tab_groups_list') for v in viewers]
    if len(connections) != 1 or not isinstance(connections[0], dict):
        raise FeedError('Cấu trúc nhóm đã tham gia thay đổi. Giữ danh sách cũ.')
    conn = connections[0]
    info = conn.get('page_info') or {}
    if type(info.get('has_next_page')) is not bool or not isinstance(conn.get('edges'), list):
        raise FeedError('Chưa xác minh được trạng thái phân trang.')
    cursor = info.get('end_cursor')
    if info['has_next_page'] and (not isinstance(cursor, str) or not cursor or len(cursor) > 16384):
        raise FeedError('Thiếu dữ liệu phân trang; chưa cập nhật danh sách.')
    groups = {}
    for edge in conn['edges']:
        n = edge.get('node') if isinstance(edge, dict) else None
        if not isinstance(n, dict) or n.get('__typename') != 'Group' or n.get('viewer_join_state') != 'MEMBER':
            raise FeedError('Danh sách chứa mục chưa xác minh tư cách thành viên.')
        gid, name = n.get('id'), n.get('name')
        if not isinstance(gid, str) or not re.fullmatch(r'\d{1,30}', gid) or not isinstance(name, str):
            raise FeedError('Thông tin nhóm không hợp lệ.')
        groups[gid] = {'url': f'https://www.facebook.com/groups/{gid}/', 'name': name[:300]}
    return {'groups': list(groups.values()), 'complete': not info['has_next_page'],
            'cursor': cursor if info['has_next_page'] else None,
            'status': 'partial' if info['has_next_page'] else 'completed'}


def bootstrap(html, actor):
    parser = JsonScripts(); parser.feed(html)
    queries = [n for doc in parser.documents for n in walk(doc) if isinstance(n, dict)
               and n.get('queryName') == 'GroupsCometJoinsRootQuery']
    if len(queries) != 1 or str(queries[0].get('actorID')) != actor:
        raise FeedError('Chưa xác minh được danh tính và nguồn danh sách nhóm.')
    return connection_result(parser.documents), queries[0].get('variables') or {}


def parse_joined(html, actor):
    return bootstrap(html, actor)[0]


def tokens_from(html):
    patterns = {'fb_dtsg': r'"DTSGInitData",\[\],\{"token":"([^"]+)"',
                'lsd': r'"LSD",\[\],\{"token":"([^"]+)"',
                '__rev': r'"client_revision":(\d+)', '__hsi': r'"hsi":"(\d+)"',
                '__spin_t': r'"__spin_t":(\d+)', '__spin_b': r'"__spin_b":"([^"]+)"'}
    values = {}
    for key, pattern in patterns.items():
        match = re.search(pattern, html)
        if match: values[key] = match[1]
    if not values.get('fb_dtsg'):
        raise FeedError('Thiếu dữ liệu xác thực để đọc trang nhóm tiếp theo.')
    return values


def load_joined(cookies, actor, *, cancelled=None, progress=None):
    cancelled = cancelled or (lambda: False)
    progress = progress or (lambda **_: None)
    def check_cancel():
        if cancelled(): raise FeedError('Đã dừng đồng bộ theo yêu cầu.')
    values = read_personal_cookies(cookies, actor)
    session = create_session({})
    for k, v in values.items():
        session.cookies.set(k, v, domain='.facebook.com', path='/', secure=True)
    try:
        check_cancel()
        r = session.get('https://www.facebook.com/groups/joins/', timeout=25, allow_redirects=False)
        check_response(r)
        page, variables = bootstrap(r.text, actor)
        groups = {g['url']: g for g in page['groups']}
        pages, cursors, reason = 1, set(), 'exhausted'
        progress(completed=len(groups), pages_read=pages, phase='reading')
        if not page['complete']:
            check_cancel()
            progress(completed=len(groups), pages_read=pages, phase='resolving')
            doc = joined_pagination.resolve(r.text, cancelled)
            check_cancel()
            if not doc:
                return dict(groups=list(groups.values()), complete=False, status='partial',
                            pages_read=pages, stop_reason='pagination_unavailable')
            tokens = tokens_from(r.text)
            if not isinstance(variables.get('ordering'), list) or not variables['ordering']:
                raise FeedError('Chưa xác minh được cách sắp xếp danh sách nhóm.')
            while not page['complete']:
                check_cancel()
                cursor = page['cursor']
                if cursor in cursors:
                    reason = 'repeated_cursor'; break
                if pages >= MAX_PAGES:
                    reason = 'page_limit'; break
                cursors.add(cursor)
                form = _graphql_form(tokens, actor, doc, joined_pagination.QUERY,
                                     dict(count=20, cursor=cursor, ordering=variables['ordering'],
                                          scale=variables.get('scale', 1)))
                response = session.post('https://www.facebook.com/api/graphql/', data=form,
                    timeout=35, allow_redirects=False, headers={'Content-Type':'application/x-www-form-urlencoded',
                    'Origin':'https://www.facebook.com', 'Referer':'https://www.facebook.com/groups/joins/',
                    'X-FB-Friendly-Name':joined_pagination.QUERY})
                check_response(response)
                try: data = parse_graphql_response(response.text)
                except (ValueError, TypeError): raise FeedError('Không đọc được phản hồi phân trang nhóm.') from None
                check_graphql(data)
                if data.get('_stream_incomplete'):
                    raise FeedError('Trang nhóm chưa được trả đầy đủ; không đánh dấu hoàn tất.')
                page = connection_result([data])
                for group in page['groups']: groups[group['url']] = group
                pages += 1
                progress(completed=len(groups), pages_read=pages, phase='reading')
        check_cancel()
        return dict(groups=list(groups.values()), complete=page['complete'],
                    status='completed' if page['complete'] else 'partial', pages_read=pages,
                    stop_reason=reason)
    finally:
        session.close()
