"""Giả lập webhook SePay hoặc Casso gửi tới server (để thử cảnh báo).

Ví dụ:
  BASE_URL=http://127.0.0.1:8000 SEPAY_API_KEY=... \
      python scripts/send_test_webhook.py --amount 3500000 --balance 6500000
  BASE_URL=... CASSO_SECURE_KEY=... \
      python scripts/send_test_webhook.py --provider casso --direction in --amount 15000000
"""

from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import os
import random
import sys
import time
from datetime import datetime
from zoneinfo import ZoneInfo

import httpx


def _sort(obj):
    if isinstance(obj, dict):
        return {k: _sort(obj[k]) for k in sorted(obj)}
    if isinstance(obj, list):
        return [_sort(x) for x in obj]
    return obj


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--provider", choices=["sepay", "casso"], default="sepay")
    p.add_argument("--direction", choices=["in", "out"], default="out")
    p.add_argument("--amount", type=int, default=3_500_000)
    p.add_argument("--balance", type=int, default=0, help="số dư sau giao dịch (0 = không báo)")
    p.add_argument("--content", default="RUT TIEN ATM")
    p.add_argument("--account", default=os.environ.get("DEMO_ACCOUNT", "0123456789"))
    p.add_argument("--bank", default="Vietcombank")
    p.add_argument("--id", type=int, default=None)
    args = p.parse_args()

    base = os.environ.get("BASE_URL", "http://127.0.0.1:8000").rstrip("/")
    now_vn = datetime.now(ZoneInfo("Asia/Ho_Chi_Minh")).strftime("%Y-%m-%d %H:%M:%S")
    tx_id = args.id or random.randint(10_000_000, 99_999_999)

    if args.provider == "sepay":
        key = os.environ.get("SEPAY_API_KEY", "")
        if not key:
            print("Cần SEPAY_API_KEY", file=sys.stderr)
            return 2
        body = {
            "id": tx_id, "gateway": args.bank, "transactionDate": now_vn, "accountNumber": args.account,
            "code": None, "content": args.content, "transferType": args.direction, "transferAmount": args.amount,
            "accumulated": args.balance, "subAccount": None, "referenceCode": f"TEST{tx_id}", "description": "",
        }
        raw = json.dumps(body, ensure_ascii=False).encode()
        headers = {"Authorization": f"Apikey {key}", "Content-Type": "application/json"}
        url = f"{base}/webhooks/sepay"
    else:
        key = os.environ.get("CASSO_SECURE_KEY", "")
        if not key:
            print("Cần CASSO_SECURE_KEY", file=sys.stderr)
            return 2
        body = {"error": 0, "data": {
            "id": tx_id, "reference": f"TEST{tx_id}", "description": args.content,
            "amount": args.amount if args.direction == "in" else -args.amount, "runningBalance": args.balance,
            "transactionDateTime": now_vn, "accountNumber": args.account, "bankName": args.bank,
            "bankAbbreviation": args.bank, "virtualAccountNumber": "", "virtualAccountName": "",
            "counterAccountName": "", "counterAccountNumber": "", "counterAccountBankId": "",
            "counterAccountBankName": "",
        }}
        raw = json.dumps(body, ensure_ascii=False).encode()
        t = str(int(time.time() * 1000))
        msg = f"{t}." + json.dumps(_sort(body), separators=(",", ":"), ensure_ascii=False)
        sig = hmac.new(key.encode(), msg.encode(), hashlib.sha512).hexdigest()
        headers = {"X-Casso-Signature": f"t={t},v1={sig}", "Content-Type": "application/json"}
        url = f"{base}/webhooks/casso"

    r = httpx.post(url, content=raw, headers=headers, timeout=15)
    print(r.status_code, r.text)
    return 0 if r.status_code == 200 else 1


if __name__ == "__main__":
    raise SystemExit(main())
