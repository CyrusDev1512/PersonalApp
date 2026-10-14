"""Thông báo đẩy FCM: JWT service account, cache token, outbox push, xử lý lỗi, API thiết bị."""

from __future__ import annotations

import asyncio
import json
from urllib.parse import parse_qs

import httpx
import jwt
import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from sqlmodel import select

from app.db import kv_get
from app.models import Alert, Device, PushDelivery
from app.notify import push_outbox
from app.notify.fcm import SCOPE, FcmClient, ServiceAccount

TOKEN_URI = "https://oauth2.googleapis.com/token"


@pytest.fixture(scope="module")
def rsa_key():
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pem = key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                            serialization.NoEncryption()).decode()
    return key, pem


@pytest.fixture
def sa(rsa_key):
    return ServiceAccount.from_dict({"client_email": "push@demo-proj.iam.gserviceaccount.com",
                                     "private_key": rsa_key[1], "private_key_id": "kid123",
                                     "project_id": "demo-proj", "token_uri": TOKEN_URI})


class FakeGoogle:
    def __init__(self, rsa_key, fcm_responses=None):
        self.public_key = rsa_key[0].public_key()
        self.token_requests = 0
        self.sends: list[dict] = []
        self.fcm_responses = list(fcm_responses or [])

    def handler(self, request: httpx.Request) -> httpx.Response:
        if str(request.url) == TOKEN_URI:
            form = parse_qs(request.content.decode())
            assert form["grant_type"] == ["urn:ietf:params:oauth:grant-type:jwt-bearer"]
            claims = jwt.decode(form["assertion"][0], self.public_key, algorithms=["RS256"], audience=TOKEN_URI)
            assert claims["iss"] == "push@demo-proj.iam.gserviceaccount.com" and claims["scope"] == SCOPE
            assert jwt.get_unverified_header(form["assertion"][0])["kid"] == "kid123"
            self.token_requests += 1
            return httpx.Response(200, json={"access_token": f"tok{self.token_requests}", "expires_in": 3600})
        if request.url.host == "fcm.googleapis.com":
            assert request.url.path == "/v1/projects/demo-proj/messages:send"
            self.sends.append({"auth": request.headers["authorization"], **json.loads(request.content)})
            if self.fcm_responses:
                return self.fcm_responses.pop(0)
            return httpx.Response(200, json={"name": "projects/demo-proj/messages/1"})
        raise AssertionError(f"không được gọi ra ngoài: {request.url}")

    def client(self, sa) -> FcmClient:
        return FcmClient(sa, client=httpx.AsyncClient(transport=httpx.MockTransport(self.handler)))


def test_jwt_and_token_cache_and_401_refresh(sa, rsa_key):
    g = FakeGoogle(rsa_key, [httpx.Response(401, json={"error": {"code": 401}})])
    fcm = g.client(sa)
    asyncio.run(fcm.send({"token": "abc"}))  # 401 -> làm mới token rồi gửi lại thành công
    asyncio.run(fcm.send({"token": "abc"}))
    assert g.token_requests == 2
    assert [s["auth"] for s in g.sends] == ["Bearer tok1", "Bearer tok2", "Bearer tok2"]


def _alert(session, **kw):
    a = Alert(kind=kw.pop("kind", "tx"), level="WARNING", title="⚠️ Sắp chạm mức mục tiêu", message="Chỉ còn 500k",
              transaction_id=kw.pop("transaction_id", 55), month="2026-10", **kw)
    session.add(a)
    session.commit()
    return a


def _device(session, token="fcm-token-0123456789"):
    d = Device(token=token, platform="android")
    session.add(d)
    session.commit()
    return d


def test_fan_out_skips_history_and_quiet_alerts(session, fake_now):
    _alert(session)  # có từ trước khi bật push
    push_outbox.fan_out(session)  # lần đầu: chỉ ghi con trỏ
    session.commit()
    assert session.exec(select(PushDelivery)).all() == []
    _device(session)
    loud = _alert(session)
    _alert(session, loud=False)
    _alert(session, read=True)
    _alert(session, deliver_telegram=False)  # cảnh báo chỉ lưu trong app
    push_outbox.fan_out(session)
    session.commit()
    rows = session.exec(select(PushDelivery)).all()
    assert [r.alert_id for r in rows] == [loud.id]
    assert kv_get(session, push_outbox.CURSOR_KEY) >= loud.id


def _prime(session):
    push_outbox.fan_out(session)
    session.commit()


def test_send_payload_and_retry_after_503(session, fake_now, sa, rsa_key):
    _prime(session)
    _device(session)
    a = _alert(session)
    g = FakeGoogle(rsa_key, [httpx.Response(503, json={"error": {"code": 503, "status": "UNAVAILABLE"}})])
    fcm = g.client(sa)
    assert asyncio.run(push_outbox.drain_push_once(fcm)) == 0
    d = session.exec(select(PushDelivery)).one()
    session.refresh(d)
    assert d.status == "pending" and d.attempts == 1 and d.next_attempt_at is not None
    assert asyncio.run(push_outbox.drain_push_once(fcm)) == 0  # chưa tới giờ thử lại
    fake_now.advance(seconds=30)
    assert asyncio.run(push_outbox.drain_push_once(fcm)) == 1
    session.refresh(d)
    assert d.status == "sent"
    msg = g.sends[-1]["message"]
    assert msg["notification"]["title"].startswith("⚠️")
    assert msg["data"] == {"alert_id": str(a.id), "kind": "tx", "level": "WARNING", "transaction_id": "55",
                           "goal_id": "", "month": "2026-10"}
    assert msg["android"]["notification"]["channel_id"] == "alerts"
    assert all(isinstance(v, str) for v in msg["data"].values())
    assert asyncio.run(push_outbox.drain_push_once(fcm)) == 0
    assert len(g.sends) == 2


def test_unregistered_token_deletes_device(session, fake_now, sa, rsa_key):
    _prime(session)
    dev_id = _device(session).id
    _alert(session)
    _alert(session)
    err = {"error": {"code": 404, "status": "NOT_FOUND", "message": "Requested entity was not found.",
                     "details": [{"@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError",
                                  "errorCode": "UNREGISTERED"}]}}
    g = FakeGoogle(rsa_key, [httpx.Response(404, json=err)])
    asyncio.run(push_outbox.drain_push_once(g.client(sa)))
    session.expire_all()  # outbox dùng session riêng
    assert session.get(Device, dev_id) is None
    assert {r.status for r in session.exec(select(PushDelivery)).all()} == {"dropped"}
    assert len(g.sends) == 1


def test_retry_after_header_is_honoured(session, fake_now, sa, rsa_key):
    _prime(session)
    _device(session)
    _alert(session)
    g = FakeGoogle(rsa_key, [httpx.Response(429, headers={"Retry-After": "120"}, json={"error": {"code": 429}})])
    asyncio.run(push_outbox.drain_push_once(g.client(sa)))
    d = session.exec(select(PushDelivery)).one()
    session.refresh(d)
    assert (d.next_attempt_at - fake_now.value).total_seconds() == 120


def test_bad_request_marks_failed_without_retry(session, fake_now, sa, rsa_key):
    _prime(session)
    _device(session)
    _alert(session)
    g = FakeGoogle(rsa_key, [httpx.Response(400, json={"error": {"code": 400, "status": "INVALID_ARGUMENT"}})])
    asyncio.run(push_outbox.drain_push_once(g.client(sa)))
    d = session.exec(select(PushDelivery)).one()
    session.refresh(d)
    assert d.status == "failed"


def test_device_api_without_push_configured(client):
    token = "fcm:APA91b-token/with+chars=="
    r = client.post("/api/devices", json={"token": token, "platform": "android", "app_version": "1.0.0"})
    assert r.status_code == 201 and r.json()["push_enabled"] is False and "token" not in r.json()
    r = client.post("/api/devices", json={"token": token, "platform": "android"})
    assert r.status_code == 200
    data = client.get("/api/devices").json()
    assert data["push_enabled"] is False and len(data["devices"]) == 1 and "token" not in data["devices"][0]
    assert client.post("/api/devices/test").json() == {"queued": True, "push_enabled": False}
    from urllib.parse import quote

    assert client.delete(f"/api/devices/{quote(token, safe='')}").status_code == 204
    assert client.get("/api/devices").json()["devices"] == []
    assert client.delete("/api/devices/khong-ton-tai-123").status_code == 204


def test_device_cap(client):
    for i in range(12):
        client.post("/api/devices", json={"token": f"token-number-{i:03d}", "platform": "android"})
    assert len(client.get("/api/devices").json()["devices"]) == 10


def test_get_transaction_and_alert_by_id(client):
    t = client.post("/api/transactions", json={"direction": "out", "amount": 50_000, "description": "bánh mì"}).json()
    assert client.get(f"/api/transactions/{t['id']}").json()["id"] == t["id"]
    assert client.get("/api/transactions/99999").status_code == 404
    client.post("/api/devices/test")
    alerts = client.get("/api/alerts").json()
    assert client.get(f"/api/alerts/{alerts[0]['id']}").json()["kind"] == "push_test"


def test_service_account_errors(tmp_path):
    from app.config import Settings
    from app.notify.fcm import FcmConfigError

    bad = tmp_path / "sa.json"
    bad.write_text("{not json")
    with pytest.raises(FcmConfigError):
        ServiceAccount.load(Settings(app_token="x" * 32, fcm_service_account_file=str(bad)))
    with pytest.raises(FcmConfigError):
        ServiceAccount.load(Settings(app_token="x" * 32, fcm_service_account_json='{"project_id": "p"}'))
