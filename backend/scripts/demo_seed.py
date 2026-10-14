"""Dựng kịch bản demo tháng hiện tại qua API: TK VCB 10tr, mục tiêu trọ 3tr + ăn 5tr, đã chi ăn 2tr.

Dùng:  BASE_URL=http://127.0.0.1:8000 APP_TOKEN=... python scripts/demo_seed.py
"""

from __future__ import annotations

import os
import sys

import httpx

BASE_URL = os.environ.get("BASE_URL", "http://127.0.0.1:8000").rstrip("/")
TOKEN = os.environ.get("APP_TOKEN", "")
ACCOUNT = os.environ.get("DEMO_ACCOUNT", "0123456789")


def main() -> int:
    if not TOKEN:
        print("Cần biến môi trường APP_TOKEN", file=sys.stderr)
        return 2
    c = httpx.Client(base_url=BASE_URL, headers={"Authorization": f"Bearer {TOKEN}"}, timeout=15)
    cats = {x["system_key"]: x["id"] for x in c.get("/api/categories").raise_for_status().json()}

    accounts = c.get("/api/accounts").raise_for_status().json()
    acc = next((a for a in accounts if a["account_number"] == ACCOUNT), None)
    if acc is None:
        acc = c.post("/api/accounts", json={"bank": "VCB", "account_number": ACCOUNT, "name": "VCB chính",
                                            "include_in_total": True}).raise_for_status().json()

    goals = {g["name"] for g in c.get("/api/goals").raise_for_status().json()}
    if "Tiền trọ" not in goals:
        c.post("/api/goals", json={"name": "Tiền trọ", "type": "reserve", "amount": 3_000_000,
                                   "category_id": cats["rent"]}).raise_for_status()
    if "Tiền ăn" not in goals:
        c.post("/api/goals", json={"name": "Tiền ăn", "type": "budget", "amount": 5_000_000,
                                   "category_id": cats["food"]}).raise_for_status()
        # 2tr tiền ăn đã chi từ trước (nhập tay, không ảnh hưởng số dư ngân hàng)
        c.post("/api/transactions", json={"direction": "out", "amount": 2_000_000, "category_id": cats["food"],
                                          "description": "Tiền ăn đầu tháng (demo)"}).raise_for_status()
    # Đặt số dư hiện tại SAU khi đã có các khoản chi trước đó
    c.patch(f"/api/accounts/{acc['id']}", json={"balance": 10_000_000}).raise_for_status()

    s = c.get("/api/summary").raise_for_status().json()
    print(f"level={s['level']} balance={s['balance']} floor={s['floor']} free={s['free']}")
    print(s["level_reason"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
