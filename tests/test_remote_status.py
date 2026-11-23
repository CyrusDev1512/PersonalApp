import json
import unittest
from unittest.mock import Mock

from scripts.remote_status import RemoteStop, check_graphql, check_response, diagnostic


class RemoteClassificationTests(unittest.TestCase):
    def response_error(self, status=200, body='', location=''):
        with self.assertRaises(RemoteStop) as caught:
            check_response(Mock(status_code=status, text=body, headers={'Location': location}))
        return caught.exception

    def test_checkpoint_config_null_does_not_prove_verification(self):
        exc = self.response_error(body='{"checkpoint_url":null}')
        self.assertEqual(exc.category, 'unrecognized_response')
        self.assertEqual(diagnostic(exc, 'read')['evidence'], 'ambiguous_checkpoint_marker')

    def test_quoted_restriction_text_does_not_prove_account_block(self):
        exc = self.response_error(body='<p>My post says temporarily blocked.</p>')
        self.assertEqual(exc.category, 'unrecognized_response')
        self.assertEqual(diagnostic(exc, 'read')['scope'], 'unknown')

    def test_checkpoint_redirect_is_a_session_signal(self):
        exc = self.response_error(302, location='/checkpoint/123?private=DO_NOT_LOG')
        self.assertEqual(exc.category, 'verification_required')
        details = diagnostic(exc, 'read')
        self.assertEqual(details, {'scope':'session', 'stage':'read', 'evidence':'verification_redirect', 'http_status':302})
        self.assertNotIn('DO_NOT_LOG', json.dumps(details))

    def test_unrelated_redirect_does_not_prove_verification(self):
        for url in ('https://example.test/checkpoint/', '/help/checkpoint-text', '/checkpoint_info'):
            self.assertEqual(self.response_error(302, location=url).category, 'unrecognized_response')

    def test_403_is_request_scope_not_account_restriction(self):
        exc = self.response_error(403)
        self.assertEqual(exc.category, 'permission_denied')
        self.assertEqual(diagnostic(exc, 'comment')['scope'], 'request')

    def test_429_remains_restricted(self):
        self.assertEqual(self.response_error(429).category, 'restricted')

    def test_debug_keyword_does_not_prove_verification(self):
        with self.assertRaises(RemoteStop) as caught:
            check_graphql({'errors':[{'message':'Unexpected error', 'debug':{'checkpoint_url':None}}]})
        self.assertEqual(caught.exception.category, 'unrecognized_response')

    def test_actual_graphql_identity_message_remains_session_signal(self):
        with self.assertRaises(RemoteStop) as caught:
            check_graphql({'errors':[{'message':'Please confirm your identity'}]})
        self.assertEqual(caught.exception.category, 'verification_required')

    def test_target_permission_message_has_request_scope_but_still_stops(self):
        with self.assertRaises(RemoteStop) as caught:
            check_graphql({'errors':[{'message':'You cannot comment on this post'}]})
        self.assertEqual(caught.exception.category, 'unrecognized_response')
        self.assertEqual(diagnostic(caught.exception, 'comment')['scope'], 'request')

    def test_malformed_error_shape_stops_without_inventing_category(self):
        for errors in ('PRIVATE_RESPONSE', [123], [{'message':{'checkpoint':'PRIVATE_RESPONSE'}}]):
            with self.assertRaises(RemoteStop) as caught:
                check_graphql({'errors':errors})
            self.assertEqual(caught.exception.category, 'unrecognized_response')
            self.assertNotIn('PRIVATE_RESPONSE', json.dumps(diagnostic(caught.exception, 'comment')))

    def test_diagnostics_never_store_exception_text_or_arbitrary_metadata(self):
        for exc in (ValueError('xs=PRIVATE_RESPONSE'), RemoteStop('unrecognized_response', 'xs=PRIVATE_RESPONSE')):
            self.assertNotIn('PRIVATE_RESPONSE', json.dumps(diagnostic(exc, 'PRIVATE_RESPONSE')))
