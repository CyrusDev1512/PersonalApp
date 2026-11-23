"""Resolve the feed pagination query from the current page's public JS assets.

Never execute downloaded JavaScript or send session cookies to asset servers.
"""
from concurrent.futures import ThreadPoolExecutor
from functools import lru_cache
from html import unescape
import re
from urllib.parse import urlparse

import requests

QUERY = 'GroupsCometFeedRegularStoriesPaginationQuery'
OPERATION = QUERY + '_facebookRelayOperation'
MAX_BYTES = 8 * 1024 * 1024


def asset_urls(html):
    urls = []
    for raw in re.findall(r'https://[^"<>\s]+\.js(?:\?[^"<>\s]*)?', html):
        url = unescape(raw)
        try:
            parsed = urlparse(url)
            valid = (parsed.scheme == 'https' and parsed.hostname == 'static.xx.fbcdn.net'
                     and parsed.port in (None, 443) and not parsed.username and not parsed.password
                     and parsed.path.startswith('/rsrc.php/'))
        except ValueError:
            valid = False
        if valid and url not in urls:
            urls.append(url)
    return urls[:24]


def module(text, name):
    match = re.search(r'__d\("' + re.escape(name) + r'"\s*,', text)
    if not match:
        return ''
    end = text.find('__d(', match.end())
    return text[match.start():end if end >= 0 else len(text)]


def metadata(text):
    query = module(text, QUERY + '.graphql')
    args = set(re.findall(r'kind:"LocalArgument",name:"([A-Za-z0-9_]+)"', query))
    # Only this read query, never an arbitrary operation mentioned in an asset.
    if ('operationKind:"query"' not in query or 'name:"group_feed"' not in query
            or not {'count', 'cursor', 'id', 'sortingSetting'} <= args):
        args = set()
    operation = module(text, OPERATION)
    ids = set(re.findall(r'\.exports\s*=\s*"([0-9]{1,40})"', operation))
    return (next(iter(ids)) if len(ids) == 1 else None), args


@lru_cache(maxsize=64)
def asset_metadata(url):
    try:
        with requests.get(url, timeout=(5, 15), allow_redirects=False, stream=True) as response:
            if response.status_code != 200:
                return None, set()
            chunks, size = [], 0
            for chunk in response.iter_content(65536):
                size += len(chunk)
                if size > MAX_BYTES:
                    return None, set()
                chunks.append(chunk)
            return metadata(b''.join(chunks).decode('utf-8', errors='replace'))
    except requests.RequestException:
        return None, set()


def resolve(html):
    doc, arguments = metadata(html)
    ids = {doc} if doc else set()
    urls = asset_urls(html)
    for start in range(0, len(urls), 4):
        with ThreadPoolExecutor(max_workers=4) as pool:
            for candidate, args in pool.map(asset_metadata, urls[start:start+4]):
                if candidate:
                    ids.add(candidate)
                if args:
                    arguments = args
        if len(ids) > 1:
            return None
        if ids and arguments:
            return next(iter(ids)), arguments
    return None


def variables(root, args, group_id, cursor, count):
    result = {name: root.get(name) for name in args}
    result.update(id=group_id, cursor=cursor, count=count, stream_initial_count=count,
                  sortingSetting='CHRONOLOGICAL')
    if 'filterTopicId' in args:
        result['filterTopicId'] = root.get('filter_topic_id')
    if 'referringStoryRenderLocation' in args:
        result['referringStoryRenderLocation'] = root.get('renderLocation')
    return result
