"""Discover only the joined-groups read query in this page's public assets."""
from concurrent.futures import ThreadPoolExecutor
from functools import lru_cache
import re
import requests
from scripts.feed_pagination import asset_urls, module, MAX_BYTES

QUERY = 'GroupsCometAllJoinedGroupsSectionPaginationQuery'
ARGS = {'count', 'cursor', 'ordering', 'scale'}

def metadata(text):
    query = module(text, QUERY + '.graphql')
    args = set(re.findall(r'kind:"LocalArgument",name:"([A-Za-z0-9_]+)"', query))
    valid = (args == ARGS and 'operationKind:"query"' in query
             and 'alias:"all_joined_groups"' in query and 'name:"tab_groups_list"' in query
             and 'name:"viewer_join_state"' in query)
    operation = module(text, QUERY + '_facebookRelayOperation')
    ids = set(re.findall(r'\.exports\s*=\s*"([0-9]{1,40})"', operation))
    return next(iter(ids)) if len(ids) == 1 else None, valid

@lru_cache(maxsize=64)
def asset_metadata(url):
    try:
        with requests.get(url, timeout=(5, 15), allow_redirects=False, stream=True) as r:
            if r.status_code != 200: return None, False
            chunks, size = [], 0
            for chunk in r.iter_content(65536):
                size += len(chunk)
                if size > MAX_BYTES: return None, False
                chunks.append(chunk)
            return metadata(b''.join(chunks).decode('utf-8', errors='replace'))
    except requests.RequestException:
        return None, False

def resolve(html, cancelled=lambda: False):
    doc, valid = metadata(html)
    ids = {doc} if doc else set()
    urls = asset_urls(html)
    for start in range(0, len(urls), 4):
        if cancelled(): return None
        with ThreadPoolExecutor(max_workers=4) as pool:
            for candidate, verified in pool.map(asset_metadata, urls[start:start+4]):
                if candidate: ids.add(candidate)
                valid = valid or verified
        if len(ids) > 1: return None
        if ids and valid: return next(iter(ids))
    return next(iter(ids)) if len(ids) == 1 and valid else None
