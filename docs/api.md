# API backend (hợp đồng giữa app Flutter và server)

- Base URL: ví dụ `https://finance.example.com` (qua Cloudflare Tunnel) hoặc `http://192.168.1.10:8000` khi dev.
- Mọi endpoint `/api/*` cần header `Authorization: Bearer <APP_TOKEN>`. Sai/thiếu token → `401 {"detail": "Unauthorized"}`.
- JSON UTF-8. Tiền là **số nguyên VND**. Thời gian là chuỗi ISO-8601 **UTC có hậu tố `Z`**, ví dụ `"2026-10-14T02:59:00Z"`.
- Tháng là chuỗi `"YYYY-MM"` theo giờ Việt Nam.
- Lỗi validate: `400` hoặc `422` với `{"detail": "..."}` (chuỗi) hoặc danh sách lỗi kiểu FastAPI.

## Mức cảnh báo (`level`)

| Giá trị   | Ý nghĩa hiển thị                         | Màu gợi ý |
|-----------|------------------------------------------|-----------|
| `OK`      | An toàn                                  | xanh lá   |
| `WARNING` | Sắp chạm mức mục tiêu                    | cam       |
| `DANGER`  | Đã lấn vào tiền dành cho mục tiêu        | đỏ        |
| `UNKNOWN` | Chưa biết số dư (cần nhập số dư ban đầu) | xám       |

## GET /health  (không cần token)
```json
{"status": "ok", "time": "2026-10-14T03:00:00Z", "version": "0.1.0"}
```

## GET /api/summary?month=YYYY-MM  (mặc định tháng hiện tại)
```json
{
  "month": "2026-10",
  "generated_at": "2026-10-14T03:00:00Z",
  "level": "WARNING",
  "level_reason": "Chỉ còn 500.000đ trên mức sàn 6.000.000đ",
  "balance": 6500000,
  "balance_known": true,
  "balance_as_of": "2026-10-14T02:59:00Z",
  "in_transit": 0,
  "floor": 6000000,
  "free": 500000,
  "buffer": 600000,
  "waiting_income": false,
  "expected_income": {"amount": 15000000, "day": 5, "pending": 0},
  "days_left": 18,
  "accounts": [Account],
  "goals": [GoalView],
  "uncategorized_count": 1,
  "unread_alerts": 2,
  "latest_alerts": [Alert],
  "ingest_health": {
    "stale": false,
    "warnings": [],
    "error_events": 0,
    "unparsed_events": 0,
    "sources": {
      "sepay": {"last_event_at": "2026-10-14T02:59:00Z"},
      "casso": {"last_event_at": null},
      "email": {"enabled": true, "last_success_at": "2026-10-14T02:58:00Z", "last_error": null}
    }
  }
}
```
- `balance`, `free`, `balance_as_of` có thể là `null` khi `balance_known=false` (khi đó `level="UNKNOWN"`).
- `expected_income` là `null` nếu chưa cài lương dự kiến. `waiting_income=true` nghĩa là đang thiếu nhưng sẽ đủ khi nhận lương.
- `latest_alerts`: tối đa 5 cảnh báo mới nhất.
- `ingest_health.warnings`: các câu cảnh báo tiếng Việt đã soạn sẵn để hiển thị (đọc email lỗi, 48 giờ không có webhook,
  biến động không đọc được...). `stale` = có ít nhất một cảnh báo.
- `in_transit`: tiền đang chờ ghép chuyển nội bộ (dương = tiền ra được cộng lại tạm, âm = tiền vào bị trừ ra tạm).

### Account
```json
{"id": 1, "bank": "VCB", "name": "VCB chính", "account_number": "0123456789", "last4": "6789",
 "include_in_total": true, "confirmed": true, "balance": 6500000, "balance_as_of": "2026-10-14T02:59:00Z",
 "balance_derived": false, "manual_balance": 10000000, "manual_balance_at": "2026-10-13T17:00:00Z"}
```
`bank` ∈ `VCB`, `MB`, `OTHER` (có thể có mã khác). `confirmed=false` là TK lạ do webhook/email tự phát hiện, cần người dùng xác nhận.
`balance_derived=true` nghĩa là số dư được ước tính (cộng/trừ từ mốc), nên hiển thị chữ "ước tính".

### GoalView
```json
{"id": 1, "series_id": "9f1c...", "name": "Tiền trọ", "type": "reserve", "amount": 3000000,
 "category_id": 2, "category_name": "Thuê trọ", "category_icon": "🏠", "month": "2026-10",
 "repeat_monthly": true, "opening_spent": 0, "spent": 0, "remaining": 3000000, "usage_pct": 0.0,
 "auto_match": true}
```
- `type`: `reserve` = **Quỹ giữ** (tiền phải giữ lại, vd. tiền trọ); `budget` = **Ngân sách chi tiêu** (vd. tiền ăn, trừ dần).
- `usage_pct` = spent / amount × 100 (số thực, có thể > 100).
- `auto_match=false`: đã có mục tiêu khác cùng danh mục trong tháng → mục tiêu này chỉ tính giao dịch được gán trực tiếp.

### Alert
```json
{"id": 10, "created_at": "2026-10-14T02:59:05Z", "kind": "tx", "level": "WARNING",
 "title": "⚠️ Sắp chạm mức mục tiêu", "message": "−3.500.000đ · VCB ...", "read": false,
 "transaction_id": 55, "goal_id": null}
```
`kind` ∈ `tx` (biến động), `floor`, `safe`, `budget`, `digest`, `account`, `health`, `info`.

## Mục tiêu
- `GET /api/goals?month=YYYY-MM` → `[GoalView]` (không gồm mục tiêu đã xoá).
- `POST /api/goals` body:
  ```json
  {"name": "Tiền ăn", "type": "budget", "amount": 5000000, "category_id": 1, "month": "2026-10",
   "repeat_monthly": true, "opening_spent": 0}
  ```
  `month` mặc định tháng hiện tại; `category_id` có thể `null` (chỉ cho `reserve` = tiết kiệm thuần). → `201 GoalView`.
  Tạo cho tháng tương lai mà tháng trước đó đã có mục tiêu lặp cùng danh mục + loại → server sửa bản của tháng đó
  trong chuỗi (không tạo trùng).
- `PATCH /api/goals/{id}` body: bất kỳ tập con các trường trên (trừ `month`) → `GoalView`. Thay đổi được áp luôn cho
  các tháng sau của cùng chuỗi đã được tạo trước.
- `DELETE /api/goals/{id}?stop_series=false` → `204`. `stop_series=true` = "Xoá và dừng lặp lại"; `false` = "Chỉ xoá tháng này".

## Danh mục
- `GET /api/categories` → `[{"id": 1, "name": "Ăn uống", "kind": "expense", "icon": "🍜", "sort_order": 10, "system_key": "food"}]`
  (`kind` ∈ `expense`, `income`, `transfer`; chỉ `expense` được chọn cho mục tiêu).
- `POST /api/categories` `{"name": "Học phí", "kind": "expense", "icon": "🎓"}` → `201 Category`.
- `GET /api/categories/{id}/rules` → `[{"id": 3, "category_id": 1, "pattern": "com tam", "direction": "out", "priority": 50, "origin": "seed"}]`
- `POST /api/categories/{id}/rules` `{"pattern": "quan co ba", "direction": "out"}` → `201 Rule`; `DELETE /api/rules/{id}` → `204`.

## Giao dịch
- `GET /api/transactions?month=YYYY-MM&uncategorized=false&limit=50&offset=0` → `{"items": [Tx], "total": 120}` (mới nhất trước).
- Tx:
  ```json
  {"id": 55, "account_id": 1, "account_name": "VCB chính", "bank": "VCB", "direction": "out", "amount": 3500000,
   "bank_time": "2026-10-14T02:59:00Z", "time_precision": "second", "description": "RUT TIEN ATM",
   "reference_code": "FT26287...", "counter_account": null, "counter_name": null, "balance_after": 6500000,
   "category_id": null, "category_name": null, "category_icon": null, "goal_id": null, "goal_name": null,
   "goal_month": null, "categorized_by": "none", "suggested_rule": "atm", "status": "active", "is_manual": false,
   "affects_balance": true, "pair_id": null, "sources": ["sepay", "email"], "possible_duplicate_of": null}
  ```
  `status` ∈ `active`, `pending` (email đang chờ webhook khớp), `excluded` (đã loại trừ: không tính vào chi tiêu/mục tiêu;
  số dư ngân hàng báo kèm nó vẫn được dùng). `goal_month` = tháng của mục tiêu được gán qua `goal_id`.
  `suggested_rule` = cụm từ gợi ý cho "nhớ luật" (chắc chắn khớp lại chính giao dịch này), `null` nếu không có.
- `PATCH /api/transactions/{id}` body (tập con):
  `{"category_id": 1, "goal_id": null, "for_next_month": false, "excluded": false, "remember_rule": true, "rule_pattern": "quan co ba"}`
  → `{"transaction": Tx, "summary": Summary}`. `category_id: null` = bỏ phân loại; đổi sang danh mục khác thì bỏ luôn
  `goal_id` của mục tiêu thuộc danh mục cũ. `for_next_month: true` = tính cho mục tiêu cùng loại của tháng sau (vd. trả
  trọ tháng 11 vào 30/10); gọi lại khi đã ở tháng sau thì không đổi gì.
- `POST /api/transactions` (nhập tay, vd. chi tiền mặt hoặc chi trước khi dùng app):
  `{"direction": "out", "amount": 50000, "description": "Bánh mì", "category_id": 1, "bank_time": "2026-10-14T01:00:00Z",
   "account_id": null, "affects_balance": false}` → `201 Tx`.
- `DELETE /api/transactions/{id}` → `204` (chỉ giao dịch nhập tay; còn lại `400`).

## Tài khoản
- `GET /api/accounts` → `[Account]`
- `POST /api/accounts` `{"bank": "VCB", "account_number": "0123456789", "name": "VCB chính", "include_in_total": true, "balance": 10000000}` → `201 Account`
- `PATCH /api/accounts/{id}` `{"name": "...", "include_in_total": true, "confirmed": true, "balance": 10000000}` → `Account`
  (`balance` = đặt số dư hiện tại làm mốc; bật `include_in_total` cũng đồng thời xác nhận TK).
- `DELETE /api/accounts/{id}` → `204` (chỉ khi chưa có giao dịch; còn lại `400`).

## Cảnh báo
- `GET /api/alerts?unread=false&limit=50` → `[Alert]` (mới nhất trước)
- `POST /api/alerts/{id}/read` → `Alert`; `POST /api/alerts/read-all` → `{"updated": 3}`

## Cài đặt
- `GET /api/settings` →
  `{"warning_percent": 10, "warning_min_amount": 500000, "expected_income_amount": 0, "expected_income_day": 0, "notify_every_tx": true}`
  (`expected_income_amount=0` nghĩa là không dùng lương dự kiến).
- `PUT /api/settings` (tập con các trường trên) → settings mới.

## Webhook (do SePay / Casso gọi, không dùng trong app)
- `POST /webhooks/sepay` — header `Authorization: Apikey <SEPAY_API_KEY>` hoặc chữ ký HMAC `X-SePay-Signature`.
- `POST /webhooks/casso` — header `X-Casso-Signature: t=<ms>,v1=<hex>`.
- Thành công luôn trả `200 {"success": true}`; sai xác thực `401`; chưa cấu hình `404`.
