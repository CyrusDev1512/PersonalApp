"""API end-to-end qua TestClient (DB in-memory)."""

from __future__ import annotations

import json

from sqlmodel import select

from app import clock
from app.models import Alert, Goal
from app.services.goals import ensure_month_goals


def _cat(client, key):
    return next(c["id"] for c in client.get("/api/categories").json() if c["system_key"] == key)


def test_auth_required(client):
    r = client.get("/api/summary", headers={"Authorization": "Bearer wrong"})
    assert r.status_code == 401
    r = client.get("/api/summary", headers={"Authorization": ""})
    assert r.status_code == 401
    assert client.get("/health").json()["status"] == "ok"


def test_docs_disabled(client):
    assert client.get("/docs").status_code == 404


def test_summary_unknown_without_accounts(client):
    data = client.get("/api/summary").json()
    assert data["level"] == "UNKNOWN"
    assert data["balance"] is None and data["month"] == "2026-10"
    # thay đổi đầu tiên -> nhắc nhập số dư (một lần mỗi tháng)
    client.post("/api/goals", json={"name": "Tiết kiệm", "type": "reserve", "amount": 1_000_000})
    client.post("/api/goals", json={"name": "Tiết kiệm 2", "type": "reserve", "amount": 1_000_000})
    data = client.get("/api/summary").json()
    assert [a["kind"] for a in data["latest_alerts"]].count("account") == 1


def _seed_october(client):
    acc = client.post("/api/accounts", json={"bank": "Vietcombank", "account_number": "0123456789",
                                             "name": "VCB chính", "balance": 10_000_000})
    assert acc.status_code == 201, acc.text
    assert acc.json()["bank"] == "VCB"
    rent = client.post("/api/goals", json={"name": "Tiền trọ", "type": "reserve", "amount": 3_000_000,
                                           "category_id": _cat(client, "rent")})
    food = client.post("/api/goals", json={"name": "Tiền ăn", "type": "budget", "amount": 5_000_000,
                                           "category_id": _cat(client, "food")})
    assert rent.status_code == 201 and food.status_code == 201, food.text
    spent = client.post("/api/transactions", json={"direction": "out", "amount": 2_000_000, "description": "Ăn",
                                                   "category_id": _cat(client, "food")})
    assert spent.status_code == 201
    return acc.json(), rent.json(), food.json()


def test_full_october_flow_with_sepay_webhook(client, fake_now):
    _seed_october(client)
    s = client.get("/api/summary").json()
    assert (s["floor"], s["free"], s["level"]) == (6_000_000, 4_000_000, "OK")

    payload = {
        "id": 92704, "gateway": "Vietcombank",
        "transactionDate": clock.to_ict(clock.now()).strftime("%Y-%m-%d %H:%M:%S"),
        "accountNumber": "0123456789", "code": None, "content": "RUT TIEN ATM", "transferType": "out",
        "transferAmount": 3_500_000, "accumulated": 6_500_000, "subAccount": None, "referenceCode": "FT26287001",
        "description": "",
    }
    headers = {"Authorization": "Apikey sepay-test-key-0123456789abcdef"}
    r = client.post("/webhooks/sepay", content=json.dumps(payload), headers=headers)
    assert r.status_code == 200 and r.json() == {"success": True}
    s = client.get("/api/summary").json()
    assert (s["balance"], s["floor"], s["free"], s["level"]) == (6_500_000, 6_000_000, 500_000, "WARNING")
    assert s["uncategorized_count"] == 1
    assert s["latest_alerts"][0]["level"] == "WARNING"

    # retry webhook -> không tạo giao dịch mới
    client.post("/webhooks/sepay", content=json.dumps(payload), headers=headers)
    txs = client.get("/api/transactions").json()
    assert txs["total"] == 2

    # phân loại khoản rút là tiền ăn -> mức sàn giảm, được tiêu tăng lại
    tx_id = next(t["id"] for t in txs["items"] if t["amount"] == 3_500_000)
    r = client.patch(f"/api/transactions/{tx_id}", json={"category_id": _cat(client, "food")})
    assert r.status_code == 200, r.text
    assert r.json()["transaction"]["category_name"] == "Ăn uống"
    # ăn 2tr + 3,5tr = 5,5tr > ngân sách 5tr -> phần còn cần cho tiền ăn = 0; sàn = 3tr (trọ)
    assert r.json()["summary"]["floor"] == 3_000_000
    assert r.json()["summary"]["free"] == 3_500_000


def test_webhook_auth(client):
    r = client.post("/webhooks/sepay", content="{}", headers={"Authorization": "Apikey wrong"})
    assert r.status_code == 401
    r = client.post("/webhooks/casso", content="{}")
    assert r.status_code == 404  # Casso chưa cấu hình


def test_webhook_bad_payload_still_success(client):
    headers = {"Authorization": "Apikey sepay-test-key-0123456789abcdef"}
    r = client.post("/webhooks/sepay", content="not json", headers=headers)
    assert r.status_code == 200
    events = client.get("/api/ingest-events", params={"status": "unparsed"}).json()
    assert len(events) == 1


def test_goal_validation(client):
    r = client.post("/api/goals", json={"name": "X", "type": "budget", "amount": 1000})
    assert r.status_code == 400  # ngân sách cần danh mục
    r = client.post("/api/goals", json={"name": "X", "type": "budget", "amount": 1000,
                                        "category_id": _cat(client, "income")})
    assert r.status_code == 400
    r = client.post("/api/goals", json={"name": "X", "type": "reserve", "amount": 0})
    assert r.status_code == 422
    r = client.post("/api/goals", json={"name": "Tiết kiệm", "type": "reserve", "amount": 1_000_000})
    assert r.status_code == 201


def test_goal_update_and_delete_semantics(client, session, fake_now):
    _seed_october(client)
    goals = client.get("/api/goals").json()
    food = next(g for g in goals if g["name"] == "Tiền ăn")
    r = client.patch(f"/api/goals/{food['id']}", json={"amount": 6_000_000})
    assert r.json()["amount"] == 6_000_000 and r.json()["spent"] == 2_000_000

    # "Chỉ xoá tháng này": tháng sau vẫn được clone
    r = client.delete(f"/api/goals/{food['id']}")
    assert r.status_code == 204
    assert all(g["id"] != food["id"] for g in client.get("/api/goals").json())
    created = ensure_month_goals(session, "2026-11")
    assert created == 2
    nov = session.exec(select(Goal).where(Goal.month == "2026-11")).all()
    assert {g.name for g in nov} == {"Tiền trọ", "Tiền ăn"}
    assert next(g for g in nov if g.name == "Tiền ăn").amount == 6_000_000

    # "Xoá và dừng lặp": tháng 12 không còn
    rent_nov = next(g for g in nov if g.name == "Tiền trọ")
    client.delete(f"/api/goals/{rent_nov.id}", params={"stop_series": "true"})
    session.expire_all()  # session của test đang giữ bản cũ; API dùng session riêng
    ensure_month_goals(session, "2026-12")
    dec = session.exec(select(Goal).where(Goal.month == "2026-12")).all()
    assert {g.name for g in dec} == {"Tiền ăn"}
    # gọi lại không tạo trùng
    assert ensure_month_goals(session, "2026-12") == 0


def test_lazy_rollover_on_new_month(client, fake_now):
    _seed_october(client)
    fake_now.value = fake_now.value.replace(month=11, day=2)
    s = client.get("/api/summary").json()
    assert s["month"] == "2026-11"
    assert {g["name"] for g in s["goals"]} == {"Tiền trọ", "Tiền ăn"}
    assert all(g["spent"] == 0 for g in s["goals"])


def test_pay_next_month_rent_early(client, fake_now):
    _seed_october(client)
    rent_cat = _cat(client, "rent")
    # trả trọ tháng 10
    t1 = client.post("/api/transactions", json={"direction": "out", "amount": 3_000_000, "category_id": rent_cat,
                                                "description": "tien tro T10"}).json()
    # 30/10 trả trọ tháng 11 -> "Tính cho tháng sau"
    t2 = client.post("/api/transactions", json={"direction": "out", "amount": 3_000_000, "category_id": rent_cat,
                                                "description": "tien tro T11"}).json()
    r = client.patch(f"/api/transactions/{t2['id']}", json={"for_next_month": True})
    assert r.status_code == 200, r.text
    assert r.json()["transaction"]["goal_name"].endswith("(2026-11)")
    assert t1["goal_id"] is None
    fake_now.value = fake_now.value.replace(month=11, day=1, hour=1)
    s = client.get("/api/summary").json()
    rent = next(g for g in s["goals"] if g["name"] == "Tiền trọ")
    assert rent["remaining"] == 0
    assert len([g for g in s["goals"] if g["name"] == "Tiền trọ"]) == 1


def test_account_crud_and_balance(client):
    r = client.post("/api/accounts", json={"bank": "MB", "account_number": "9876 5432 10", "name": "MB",
                                           "balance": 1_000_000})
    acc = r.json()
    assert acc["account_number"] == "9876543210" and acc["balance"] == 1_000_000
    r = client.post("/api/accounts", json={"bank": "MB", "account_number": "9876543210", "name": "dup"})
    assert r.status_code == 400
    r = client.patch(f"/api/accounts/{acc['id']}", json={"balance": 2_500_000})
    assert r.json()["balance"] == 2_500_000
    assert client.delete(f"/api/accounts/{acc['id']}").status_code == 204


def test_settings_roundtrip(client):
    r = client.put("/api/settings", json={"warning_percent": 20, "expected_income_amount": 15_000_000,
                                          "expected_income_day": 5})
    assert r.json()["warning_percent"] == 20
    assert client.get("/api/settings").json()["expected_income_day"] == 5


def test_alerts_read(client, session):
    client.post("/api/goals", json={"name": "Tiết kiệm", "type": "reserve", "amount": 1_000_000})
    alerts = client.get("/api/alerts", params={"unread": True}).json()
    assert alerts
    r = client.post(f"/api/alerts/{alerts[0]['id']}/read")
    assert r.json()["read"] is True
    r = client.post("/api/alerts/read-all")
    assert "updated" in r.json()
    assert session.exec(select(Alert).where(Alert.read == False)).first() is None  # noqa: E712


def test_manual_transaction_delete_only_manual(client):
    t = client.post("/api/transactions", json={"direction": "out", "amount": 50_000, "description": "bánh mì"})
    assert t.status_code == 201
    assert client.delete(f"/api/transactions/{t.json()['id']}").status_code == 204


def test_remember_rule(client):
    _seed_october(client)
    t = client.post("/api/transactions", json={"direction": "out", "amount": 70_000, "description": "Quan co Ba"})
    r = client.patch(f"/api/transactions/{t.json()['id']}", json={"category_id": _cat(client, "food"),
                                                                   "remember_rule": True, "rule_pattern": "Quán cô Ba"})
    assert r.status_code == 200
    rules = client.get(f"/api/categories/{_cat(client, 'food')}/rules").json()
    assert any(x["pattern"] == "quan co ba" and x["origin"] == "user" for x in rules)


def test_body_limit(client):
    r = client.post("/webhooks/sepay", content="x" * 70_000,
                    headers={"Authorization": "Apikey sepay-test-key-0123456789abcdef"})
    assert r.status_code == 413
