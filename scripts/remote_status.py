"""Conservative classification; no raw response or tokens escape this module."""
from urllib.parse import urlparse

EVIDENCE = {'unspecified', 'verification_redirect', 'ambiguous_checkpoint_marker',
            'ambiguous_verification_redirect', 'login_redirect_or_401', 'http_rate_limit',
            'ambiguous_restriction_marker', 'http_forbidden', 'unexpected_redirect',
            'http_error', 'graphql_verification_message', 'graphql_restriction_message',
            'graphql_session_message', 'unclassified_graphql_error',
            'graphql_target_permission_message', 'local_or_parser_exception'}


class RemoteStop(ValueError):
    def __init__(self, category, evidence='unspecified', http_status=None):
        self.category = category
        self.evidence = evidence
        self.http_status = http_status
        super().__init__(category)


def diagnostic(exc, stage):
    """Allowlisted metadata only: never persist response text, URLs or tokens."""
    category = exc.category if isinstance(exc, RemoteStop) else 'unrecognized_response'
    scope = ('session' if category in {'verification_required', 'session_expired', 'restricted'}
             else 'request' if category == 'permission_denied' else 'unknown')
    evidence = exc.evidence if isinstance(exc, RemoteStop) else 'local_or_parser_exception'
    if evidence not in EVIDENCE:
        evidence = 'unspecified'
    if evidence == 'graphql_target_permission_message':
        scope = 'request'
    result = {'scope': scope, 'stage': stage if stage in {'read', 'sync', 'preflight', 'comment', 'recheck'} else 'unknown',
              'evidence': evidence}
    if isinstance(exc, RemoteStop) and type(exc.http_status) is int:
        result['http_status'] = exc.http_status
    return result


def check_response(response):
    status = response.status_code
    location = response.headers.get('Location', '')
    redirect = urlparse(location)
    path = redirect.path.lower()
    body = response.text.lower()
    if '/checkpoint' in path or '/challenge' in path:
        trusted = not redirect.netloc or redirect.hostname in {'facebook.com', 'www.facebook.com', 'm.facebook.com', 'web.facebook.com'}
        direct = any(path == prefix or path.startswith(prefix + '/') for prefix in ('/checkpoint', '/challenge'))
        if trusted and direct and 300 <= status < 400:
            raise RemoteStop('verification_required', 'verification_redirect', status)
        raise RemoteStop('unrecognized_response', 'ambiguous_verification_redirect', status)
    if 'checkpoint_url' in body:
        # A bootstrap configuration may contain checkpoint_url:null, or a post
        # may quote this text. Preserve the stop, but do not assert verification.
        raise RemoteStop('unrecognized_response', 'ambiguous_checkpoint_marker', status)
    if '/login' in path or status == 401:
        raise RemoteStop('session_expired', 'login_redirect_or_401', status)
    if status == 429:
        raise RemoteStop('restricted', 'http_rate_limit', status)
    if 'temporarily blocked' in body or 'you’re temporarily blocked' in body:
        raise RemoteStop('unrecognized_response', 'ambiguous_restriction_marker', status)
    if status == 403:
        raise RemoteStop('permission_denied', 'http_forbidden', status)
    if 300 <= status < 400:
        raise RemoteStop('unrecognized_response', 'unexpected_redirect', status)
    if status != 200:
        raise RemoteStop('remote_error', 'http_error', status)


def check_graphql(data):
    errors = data.get('errors') or []
    if not errors:
        return
    # Unknown codes are deliberately not translated into 'safe to retry'.
    # Inspect actual error messages, not arbitrary data/path/debug fields that
    # could merely mention an authentication keyword. Every error still stops.
    entries = errors if isinstance(errors, list) else [errors]
    text = ' '.join(e['message'] for e in entries if isinstance(e, dict) and isinstance(e.get('message'), str)).lower()
    if 'checkpoint' in text or 'confirm your identity' in text:
        raise RemoteStop('verification_required', 'graphql_verification_message')
    if 'temporarily blocked' in text or 'rate limit' in text:
        raise RemoteStop('restricted', 'graphql_restriction_message')
    if 'session has expired' in text or 'not logged in' in text:
        raise RemoteStop('session_expired', 'graphql_session_message')
    if any(s in text for s in ('cannot comment on this post', 'permission to comment on this post', 'post is no longer available')):
        # Diagnostic scope only. Unknown mutation outcomes still stop and keep
        # the existing durable hold; this does not authorize the next comment.
        raise RemoteStop('unrecognized_response', 'graphql_target_permission_message')
    raise RemoteStop('unrecognized_response', 'unclassified_graphql_error')
