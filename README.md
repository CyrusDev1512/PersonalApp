# Chi tiêu — quản lý chi tiêu cá nhân + cảnh báo theo mục tiêu

Mỗi khi số dư tài khoản ngân hàng thay đổi, hệ thống tự nhận biết và **chủ động cảnh báo** khi số dư xuống gần
mức cần giữ cho các mục tiêu tài chính bạn đặt ra (vd. tháng 10: giữ 3 triệu tiền trọ, 5 triệu tiền ăn).

- **Backend** (`backend/`): Python FastAPI + SQLite. Nhận biến động qua **webhook SePay / Casso** và **email biến động số dư
  (IMAP)**, khử trùng lặp giữa các nguồn, tính mức sàn và gửi cảnh báo qua **Telegram**.
- **App** (`mobile/`): Flutter (Android/iOS). Dashboard trạng thái, nút **"Thêm mục tiêu"**, phân loại giao dịch, lịch sử
  cảnh báo, cài đặt tài khoản.
- Hợp đồng API: [`docs/api.md`](docs/api.md).

```
Ngân hàng (VCB, MB) ──► SePay / Casso ──webhook──► ┐
          └──────────► Email biến động ──IMAP────► ├─► Backend ──► Telegram (cảnh báo tức thì)
                                                    │      ▲
                                    App Flutter ◄───┘──────┘ REST API (dashboard, mục tiêu, phân loại)
```

## Cách cảnh báo hoạt động

Mỗi mục tiêu thuộc một trong hai loại:

| Loại | Ví dụ | Ý nghĩa |
|---|---|---|
| **Quỹ giữ** (`reserve`) | Tiền trọ 3.000.000đ | Tiền phải giữ nguyên trong tài khoản; khi trả trọ (giao dịch danh mục *Thuê trọ*) thì phần cần giữ giảm tương ứng. |
| **Ngân sách chi tiêu** (`budget`) | Tiền ăn 5.000.000đ | Tiền dành cho một danh mục, trừ dần mỗi lần chi *Ăn uống*. Có cảnh báo khi đã dùng 80% và 100%. |

- **Mức sàn** = tổng phần *còn cần* của các mục tiêu trong tháng.
- **Được tiêu thoải mái** = tổng số dư (các TK được tính) − mức sàn.
- **Vùng đệm** = max(10% mức sàn, 500.000đ) — chỉnh được trong app.

| Trạng thái | Điều kiện |
|---|---|
| ✅ An toàn | được tiêu ≥ vùng đệm |
| ⚠️ Sắp chạm mức mục tiêu | 0 ≤ được tiêu < vùng đệm |
| 🔴 Đã lấn vào tiền mục tiêu | được tiêu < 0 |

Ví dụ ngày 14/10: số dư 10tr, trọ 3tr (chưa trả), ăn 5tr đã chi 2tr → mức sàn 6tr, được tiêu 4tr ✅.
Rút ATM 3,5tr → số dư 6,5tr → chỉ còn 500k trên mức sàn → **⚠️ cảnh báo ngay qua Telegram**.

Chống làm phiền: chỉ báo khi trạng thái xấu đi (có ngưỡng trễ để không báo đi báo lại khi số dư dao động), mỗi giao dịch chỉ
một tin; bấm nút phân loại thì tin cũ được sửa tại chỗ. Bản tin tổng hợp gửi lúc 08:00 mỗi sáng.

**Dự báo cuối tháng**: dựa trên tốc độ chi *ngoài mục tiêu* 14 ngày gần nhất (khoản chi lớn bất thường được giới hạn
để không làm méo dự báo, đầu tháng thì trộn với số liệu tháng trước) và nhịp chi của từng ngân sách, app ước tính
"được tiêu" cuối tháng, ngày có thể chạm mức sàn và mức nên chi mỗi ngày — ví dụ *"Chi như hiện tại thì khoảng ngày
25/10 sẽ chạm mức sàn — gợi ý chi ngoài mục tiêu tối đa ~120.000đ/ngày"*. Khi dự kiến chạm mức sàn trong vòng 7 ngày,
hệ thống chủ động cảnh báo sớm (một lần, báo lại nếu ngày chạm sàn sớm hơn đáng kể).

Một số tình huống được xử lý sẵn:
- **Chuyển tiền giữa VCB ↔ MB** của chính bạn được ghép cặp, không bị tính là chi tiêu.
- **Trả trọ tháng sau từ sớm** (vd. 30/10): bấm "📅 Tính cho tháng sau" để khoản đó tính cho mục tiêu tháng 11.
- **Lương dự kiến** (tuỳ chọn): đầu tháng chưa có lương thì chỉ báo "đang thiếu, chờ lương", không báo đỏ mỗi ngày.
- Mục tiêu bật "Lặp lại hằng tháng" sẽ tự tạo cho tháng mới vào 00:05 ngày 1.

## 1. Chạy backend

> **Máy Windows (Docker Desktop + ngrok miễn phí)**: làm theo [docs/cai-dat-windows.md](docs/cai-dat-windows.md).
> Nháy đúp `scripts\windows\setup.cmd` là script tự tạo `.env`, sinh khoá, khởi động server và lấy Chat ID Telegram.

### Bằng Docker (khuyên dùng)

```bash
cp .env.example .env
python3 -c "import secrets; print(secrets.token_urlsafe(32))"   # dán vào APP_TOKEN trong .env
docker compose up -d --build
curl http://127.0.0.1:8000/health
```

Dữ liệu SQLite nằm trong volume `app-data` (`/data/app.db`). Mặc định cổng 8000 chỉ mở cho chính máy chủ; muốn điện
thoại trong cùng mạng Wi-Fi kết nối thì thêm `BIND_ADDR=0.0.0.0` vào `.env`.

### Chạy trực tiếp (dev)

```bash
cd backend
python3 -m venv .venv && .venv/bin/pip install -r requirements-dev.txt
cp ../.env.example .env   # điền APP_TOKEN, ...
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1
.venv/bin/pytest          # chạy test
```

> Luôn chạy **1 worker**: các job nền và khoá ghi nằm trong một tiến trình.

## 2. Public HTTPS cho webhook (Cloudflare Tunnel)

SePay/Casso cần gọi được tới server qua HTTPS. Không có tên miền riêng: dùng tên miền miễn phí của **ngrok**
(`NGROK_AUTHTOKEN`, `NGROK_DOMAIN` trong `.env`, rồi `docker compose --profile ngrok up -d`), xem
[docs/cai-dat-windows.md](docs/cai-dat-windows.md). Hoặc dùng Cloudflare Tunnel (cần tên miền trên Cloudflare):
1. Vào Cloudflare Zero Trust → *Networks → Tunnels* → tạo tunnel, chép **token** vào `CLOUDFLARE_TUNNEL_TOKEN` trong `.env`.
2. Thêm *Public Hostname*, ví dụ `finance.tenmien.com` → service `http://app:8000`.
3. `docker compose --profile tunnel up -d`.

Chỉ cần public `/webhooks/*`, `/api/*` và `/health`. Mọi `/api/*` đều đòi `APP_TOKEN`; trang `/docs` tắt trừ khi `DEBUG=true`.
Chạy trên VPS cũng được: đặt reverse proxy (Caddy/nginx) có HTTPS trước cổng 8000.

## 3. Telegram bot

1. Nhắn [@BotFather](https://t.me/BotFather) → `/newbot` → chép token vào `TELEGRAM_BOT_TOKEN`.
2. Để trống `TELEGRAM_CHAT_ID`, khởi động server, nhắn `/start` cho bot → bot trả về chat id của bạn.
3. Điền `TELEGRAM_CHAT_ID` rồi `docker compose up -d`. Bot chỉ trả lời đúng chat id này.

Lệnh: `/status`, `/goals`, `/uncat`. Dưới mỗi tin biến động có nút chọn danh mục, "↔️ Chuyển nội bộ", "📅 Tính cho tháng sau".

## 4. Nguồn biến động số dư

### SePay (webhook)
1. Đăng ký tại sepay.vn, liên kết tài khoản VCB / MB.
2. *Tích hợp WebHooks* → URL `https://finance.tenmien.com/webhooks/sepay`, kiểu chứng thực **API Key**, đặt một khoá ngẫu
   nhiên → chép vào `SEPAY_API_KEY`. (Hỗ trợ cả chữ ký HMAC: `SEPAY_HMAC_SECRET`.)
3. Bật nhận cả **tiền ra** lẫn tiền vào (tuỳ gói và ngân hàng).

### Casso (webhook v2)
1. Đăng ký tại casso.vn, liên kết tài khoản.
2. Thêm Webhook v2 với URL `https://finance.tenmien.com/webhooks/casso`, chép **khoá bảo mật** vào `CASSO_SECURE_KEY`.
3. **Tắt** tuỳ chọn chỉ nhận tiền vào (`income_only`), nếu không sẽ không biết các khoản chi.

Có thể bật cả hai: giao dịch trùng giữa các nguồn được tự động gộp. Webhook "test" của Casso (TK `88888888`) bị bỏ qua.

### Email biến động số dư (nguồn phụ)
1. Bật thông báo biến động số dư qua email trong app ngân hàng (nếu ngân hàng hỗ trợ).
2. Gmail: bật xác minh 2 bước → tạo **Mật khẩu ứng dụng** → điền `IMAP_USER`, `IMAP_PASSWORD`.
3. Server đọc email mỗi 2 phút (không đánh dấu đã đọc). Chỉ nhận email từ domain trong `EMAIL_BANK_DOMAINS` và qua kiểm tra
   DKIM/DMARC. Lần chạy đầu nhập im lặng các email từ đầu tháng.

> Bộ đọc email là **bản chung** (chưa thử trên email thật của VCB/MB). Email không đọc được sẽ nằm trong
> `GET /api/ingest-events?status=unparsed` để chỉnh parser (`backend/app/ingest/parsers/`).

## 5. App Flutter

```bash
cd mobile
flutter pub get
flutter run                 # chạy trên máy ảo / điện thoại cắm cáp
flutter build apk --release # file APK: build/app/outputs/flutter-apk/app-release.apk
```

Hoặc chạy workflow **CI** trên GitHub (*Actions → CI → Run workflow*) để tải APK ở mục *Artifacts*.

Lần đầu mở app: nhập **địa chỉ server** (vd. `https://finance.tenmien.com`) và **APP_TOKEN** → vào *Cài đặt → Tài khoản*
thêm TK VCB/MB và **số dư hiện tại** → bấm **"Thêm mục tiêu"** trên màn hình Tổng quan.

## 6. Thông báo đẩy vào app (Firebase, tuỳ chọn)

Telegram đã đẩy cảnh báo về điện thoại; nếu muốn cảnh báo hiện thẳng thành thông báo của app "Chi tiêu":

1. Vào [Firebase console](https://console.firebase.google.com) → tạo project (miễn phí).
2. *Add app → Android*, package name: `com.personalapp.personal_finance`. Tải **`google-services.json`** và đặt vào
   `mobile/android/app/google-services.json` (file này đã được `.gitignore`, không commit), rồi build lại APK.
   Không có file này app vẫn chạy bình thường, chỉ tắt thông báo đẩy.
3. Kiểm tra *Project settings → Cloud Messaging*: **Firebase Cloud Messaging API (V1)** đang bật.
4. Tạo khoá cho server: *Project settings → Service accounts → Generate new private key* (hoặc tạo service account riêng
   trong Google Cloud chỉ với quyền *Firebase Cloud Messaging API Admin*). Lưu thành `secrets/fcm.json` cạnh
   `docker-compose.yml`, cho user trong container đọc được: `chmod 644 secrets/fcm.json`.
5. Trong `.env`: `FCM_SERVICE_ACCOUNT_FILE=/run/secrets/fcm.json` → `docker compose up -d`.
6. Mở app → *Cài đặt → Thông báo đẩy* → cho phép thông báo → bấm **Gửi thử**.

Lưu ý:
- Chỉ các cảnh báo quan trọng (loại có chuông trên Telegram) mới được đẩy; Telegram vẫn chạy song song.
- Một số máy Xiaomi/Oppo/Vivo chặn thông báo khi app chạy nền: bật *Tự khởi động* và tắt *Tối ưu pin* cho app.
- Nội dung thông báo đi qua máy chủ của Google (FCM).
- iOS cần tài khoản Apple Developer, khoá APNs (.p8) tải lên Firebase và `GoogleService-Info.plist` — chưa làm sẵn.

## 7. Thử nhanh không cần ngân hàng

```bash
cd backend
export BASE_URL=http://127.0.0.1:8000 APP_TOKEN=... SEPAY_API_KEY=...
.venv/bin/python scripts/demo_seed.py                                   # TK 10tr, trọ 3tr, ăn 5tr (đã chi 2tr) → OK
.venv/bin/python scripts/send_test_webhook.py --amount 3500000 --balance 6500000   # → ⚠️ WARNING
.venv/bin/python scripts/send_test_webhook.py --provider casso --direction in \
    --amount 15000000 --balance 21500000 --content "CTY ABC tra luong"   # → ✅ an toàn trở lại (cần CASSO_SECURE_KEY)
```

### Dùng thử bản demo trên trình duyệt

Bản demo chạy **chính app Flutter** (cùng màn hình, cùng cách tính mức sàn / được tiêu / cảnh báo) với một máy chủ
giả nằm ngay trong app:

- **Dữ liệu giả**: TK VCB + MB tổng 10.000.000đ, quỹ giữ "Tiền trọ" 3.000.000đ, ngân sách "Tiền ăn" 5.000.000đ (đã chi
  2.000.000đ) và vài giao dịch mẫu theo ngày hiện tại.
- **Không cần máy chủ**: không cần địa chỉ server hay APP_TOKEN, không gửi dữ liệu đi đâu (CanvasKit và font nằm sẵn
  cạnh `index.html`).
- **Không lưu lại**: tải lại trang là về dữ liệu ban đầu.

Bấm **Giả lập biến động số dư** ở thanh trên cùng: "Rút ATM 3.500.000đ" → ⚠️ *Sắp chạm mức mục tiêu* (kèm thông báo đẩy
giả trong app), "Nhận lương 15.000.000đ" → ✅ *An toàn trở lại*; **Đặt lại dữ liệu demo** để về trạng thái ban đầu.

```bash
mobile/scripts/build_web_demo.sh   # cần Flutter 3.47, python3 + fonttools, font Noto Color Emoji và DejaVu Sans
python3 -m http.server --directory mobile/build/web 8080   # mở http://localhost:8080
```

`mobile/build/web_artifact/` là bản để đăng lên web tĩnh (chỉ đường dẫn tương đối, không service worker). Trình duyệt
cần hỗ trợ WebAssembly (Chrome, Edge, Firefox, Safari bản mới).

Bản demo dùng entrypoint riêng `mobile/lib/main_demo.dart`, nên **APK không thay đổi**. **App thật vẫn cần máy chủ**
(mục 1) để có số dư, giao dịch và cảnh báo thật.

## 8. Sao lưu

```bash
docker compose exec app python -c "import sqlite3; s=sqlite3.connect('/data/app.db'); d=sqlite3.connect('/data/backup.db'); s.backup(d)"
docker compose cp app:/data/backup.db ./backup-$(date +%F).db
```

## Giới hạn hiện tại
- Parser email là bản chung, có thể cần chỉnh theo mẫu email thật của ngân hàng.
- Chi tiết webhook SePay được viết theo tài liệu công khai nhưng chưa thử với tài khoản thật; chữ ký Casso v2 đã kiểm
  bằng bộ mẫu chính thức của Casso.
- Token của app lưu bằng `shared_preferences` (nên nâng cấp lên `flutter_secure_storage`).
