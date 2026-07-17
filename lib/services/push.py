"""
push.py — Firebase Cloud Messaging (HTTP v1) sender for the HCP HRMS app.

Config (Flask app.config OR environment variables):
    FCM_PROJECT_ID            - Firebase project id (e.g. 'hcp-hrms')
    FCM_SERVICE_ACCOUNT_FILE  - absolute path to the service account JSON

If either is missing, all send functions become safe no-ops (log + return).
Push failure must NEVER break a core operation, so nothing here raises to callers.

Requires: google-auth, requests  (pip install google-auth requests)
"""
import os
import logging

_log = logging.getLogger(__name__)

_SCOPES = ['https://www.googleapis.com/auth/firebase.messaging']


def _cfg(key):
    try:
        from flask import current_app
        v = current_app.config.get(key)
        if v:
            return v
    except Exception:
        pass
    return os.environ.get(key)


def _access_token(sa_file):
    from google.oauth2 import service_account
    from google.auth.transport.requests import Request
    creds = service_account.Credentials.from_service_account_file(sa_file, scopes=_SCOPES)
    creds.refresh(Request())
    return creds.token


def _send_one(project_id, token_str, title, body, data, access_token):
    import requests
    url = 'https://fcm.googleapis.com/v1/projects/%s/messages:send' % project_id
    message = {
        'message': {
            'token': token_str,
            'notification': {'title': title, 'body': body},
            'android': {'priority': 'high', 'notification': {'sound': 'default'}},
        }
    }
    if data:
        message['message']['data'] = {str(k): str(v) for k, v in data.items()}
    return requests.post(
        url,
        headers={'Authorization': 'Bearer %s' % access_token, 'Content-Type': 'application/json'},
        json=message, timeout=10)


def send_push_to_tokens(tokens, title, body, data=None):
    """Send to raw token strings. Returns list of dead tokens (to be cleaned up)."""
    project_id = _cfg('FCM_PROJECT_ID')
    sa_file = _cfg('FCM_SERVICE_ACCOUNT_FILE')
    if not project_id or not sa_file or not os.path.exists(sa_file):
        _log.info('FCM not configured; skipping push (%d token(s)).', len(tokens or []))
        return []
    tokens = [t for t in (tokens or []) if t]
    if not tokens:
        return []
    try:
        at = _access_token(sa_file)
    except Exception as e:
        _log.warning('FCM auth failed: %s', e)
        return []
    dead = []
    for tk in tokens:
        try:
            r = _send_one(project_id, tk, title, body, data, at)
            if r.status_code in (403, 404) or (r.status_code == 400 and 'UNREGISTERED' in (r.text or '')):
                dead.append(tk)
            elif r.status_code >= 400:
                _log.warning('FCM send %s: %s', r.status_code, (r.text or '')[:200])
        except Exception as e:
            _log.warning('FCM send error: %s', e)
    return dead


def send_push_to_users(user_ids, title, body, data=None):
    """Look up device tokens for the given user ids and push. Cleans up dead tokens."""
    try:
        from models import db
        from models.device_token import DeviceToken
    except Exception:
        return
    uids = [u for u in (user_ids or []) if u]
    if not uids:
        return
    try:
        rows = DeviceToken.query.filter(DeviceToken.user_id.in_(uids)).all()
    except Exception as e:
        _log.warning('device token lookup failed: %s', e)
        return
    if not rows:
        return
    dead = send_push_to_tokens([r.token for r in rows], title, body, data) or []
    if dead:
        try:
            for r in rows:
                if r.token in dead:
                    db.session.delete(r)
            db.session.commit()
        except Exception:
            db.session.rollback()
