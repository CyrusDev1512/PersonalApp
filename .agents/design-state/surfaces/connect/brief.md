# Kết nối máy chủ (connect / first run): shape brief

Target: `mobile/lib/screens/connect_screen.dart` (first run via `RootGate`, and `/connect` from Cài đặt with
`popOnSuccess`). Visitor mode: **operate** (setup). Inherits DESIGN.md.

## Job and audience

The owner, who self-hosts the backend, pairs the phone with it once: server URL (normally `https://…` through
Cloudflare Tunnel, `http://` only on a trusted LAN) and `APP_TOKEN` from the server's `.env`. Later they may change
server or token from Cài đặt. They are technical; the copy can name `/health`, `APP_TOKEN` and `.env` precisely.

## The one primary action

**"Kiểm tra & kết nối"** (`connect_submit`): full-width filled button under the fields; also triggered by the keyboard
action on the token field. Busy state keeps the label and shows the step checklist.

## Information order

1. **First run:** no app bar. A header block with the wordmark "Chi tiêu" in `displaySmall` 700 (`primary`) and one
   line in `bodyLarge`: "Theo dõi số dư Vietcombank, MB và giữ tiền cho mục tiêu tháng này." **From Cài đặt:** small app
   bar "Kết nối máy chủ" with Back, fields prefilled.
2. One instruction sentence: "Nhập địa chỉ máy chủ và APP_TOKEN (trong file .env của máy chủ)."
3. "Địa chỉ máy chủ (URL)" (`connect_url`, `dns_outlined`, placeholder "https://finance.example.com", helper "Nên dùng
   https:// qua Cloudflare Tunnel").
4. Inline note when the URL is `http://` (no tinted box): `lock_open` in `warning.foreground` + `bodySmall`
   "Địa chỉ http:// không mã hoá: token sẽ được gửi dạng rõ qua mạng. Chỉ dùng trong mạng LAN tin cậy."
5. "Token (APP_TOKEN)" (`connect_token`, `key_outlined`, show/hide icon button with tooltips "Hiện token" / "Ẩn token").
6. Primary button.
7. **Step checklist** (appears on submit): "Máy chủ phản hồi (/health)" and "Token hợp lệ (/api/summary)", each with a
   state icon: pending `radio_button_unchecked` (`onSurfaceVariant`), running 18 dp progress, done `check_circle`
   (`ok.foreground`), failed `error` (`error`).
8. Error message under the checklist: `error` icon + `bodyMedium` text naming the problem and the fix.

## States and ranges

| State | What shows |
|---|---|
| Idle | Fields + button. |
| Invalid URL / empty token | Inline field errors: "Nhập địa chỉ máy chủ", the parser's message, "Nhập token". |
| Checking `/health` | Step 1 running; fields disabled. |
| Checking token | Step 1 done, step 2 running. |
| 401 | Step 2 failed: "Sai token: máy chủ từ chối (401). Kiểm tra lại APP_TOKEN trong file .env của máy chủ." |
| 404 on `/health` | Step 1 failed: "Địa chỉ này không phải máy chủ Chi tiêu (không có /health). Kiểm tra lại URL." |
| Network / timeout | Step 1 failed with `ApiMessages.network` ("Không kết nối được máy chủ. Kiểm tra mạng, địa chỉ máy chủ và máy chủ có đang chạy không.") or `ApiMessages.timeout` ("Máy chủ không phản hồi sau 15 giây. Thử lại sau."). |
| Success (first run) | Both steps done; `RootGate` swaps to the home shell (no extra confirmation screen). |
| Success (from Cài đặt) | Pop back; snackbar "Đã kết nối máy chủ". |

## Remove / merge compared with today

- First-run `AppBar` → wordmark header (the first screen of the product should say what it is).
- The amber bordered box for `http://` → inline note with a warning icon (no coloured container, no border).
- The `errorContainer` error box and the single progress text line (`_step`) → the two-step checklist plus one inline
  error line; the cause is shown at the step where it failed.
- Hard-coded `Colors.amber.*` → `StatusColors.warning`.

## Constraints and open decisions

- Keep `Key`s `connect_url`, `connect_token`, `connect_submit`; keep the `/health` → `/api/summary` order and messages.
- Token stays obscured by default; never log or prefill it into the URL field.
- **Open (inferred):** a "Dán" (paste) suffix button on the token field for long tokens.
