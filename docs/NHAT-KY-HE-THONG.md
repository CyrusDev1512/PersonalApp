# Nhật ký hệ thống — Chi tiêu (PersonalApp)

Cập nhật: 15/10/2026. Nhánh `claude/cool-darwin-edy2qo`, PR [CyrusDev1512/PersonalApp#1](https://github.com/CyrusDev1512/PersonalApp/pull/1).

## 1. Mục tiêu cuối cùng

Một hệ thống quản lý chi tiêu cho **một người** (chủ tài khoản), giao diện tiếng Việt, tiền VND:

- **Mỗi khi số dư tài khoản Vietcombank / MB Bank thay đổi**, hệ thống biết ngay.
- So số dư với **các mục tiêu tài chính đặt trước cho từng tháng**: quỹ giữ (vd. 3.000.000đ tiền trọ) và ngân sách (vd. 5.000.000đ tiền ăn).
- **Chủ động cảnh báo** khi số dư xuống gần mức cần giữ cho các mục tiêu, trước khi lỡ tiêu vào tiền đã dành; dự báo cuối tháng
  để cảnh báo sớm theo tốc độ chi.
- App có nút **"Thêm mục tiêu"**, xem trạng thái, phân loại giao dịch, lịch sử cảnh báo.

**Đích đến cụ thể (khi nào coi là xong):**

1. Server chạy bằng Docker trên **máy Windows của chủ**, mở ra Internet qua **ngrok** (tên miền miễn phí cố định).
2. **SePay** gửi biến động VCB + MB về server (webhook); **email ngân hàng qua Gmail (IMAP)** làm nguồn dự phòng.
3. Cảnh báo qua **Telegram** + thông báo đẩy trong app (Firebase, tuỳ chọn) + màn hình trong app.
4. **App Android** (Flutter) với giao diện mới "Bát men lam", kết nối server bằng địa chỉ ngrok + `APP_TOKEN`, chạy với dữ liệu thật.
5. Bản demo trên trình duyệt (dữ liệu giả) để thử giao diện mà không cần server.

## 2. Kiến trúc

```
 Vietcombank / MB Bank
        │ biến động số dư
        ├──────────────► SePay ──(webhook HTTPS, API key)──┐
        └──► email thông báo ──► Gmail ──(IMAP, DKIM/DMARC)─┤
                                                           ▼
 ┌──────────────────────── Máy Windows của chủ (Docker) ─────────────────────────┐
 │  ngrok (tên miền cố định) ──► Backend FastAPI + SQLite                         │
 │     ingest/  nhận & chuẩn hoá giao dịch, khử trùng nguồn, ghép chuyển nội bộ  │
 │     engine/  mức sàn, được tiêu, mức cảnh báo, dự báo cuối tháng, phân loại   │
 │     notify/  outbox Telegram (sửa tin tại chỗ) + outbox đẩy FCM               │
 │     jobs     mỗi phút (tick), 08:00 bản tin sáng, sang tháng (rollover)       │
 │     api/     REST /api/* (Bearer APP_TOKEN), /webhooks/sepay, /webhooks/casso │
 └────────────────────────────────────────────────────────────────────────────────┘
        │ Telegram Bot API          │ FCM HTTP v1           ▲ REST qua ngrok
        ▼                           ▼                        │
   Tin nhắn Telegram         Thông báo trên điện thoại ── App Android (Flutter)
```

### Backend (`backend/`, Python 3.13, FastAPI, SQLModel/SQLite)

| Thư mục | Vai trò |
|---|---|
| `app/api/` | REST cho app (29 route): tổng quan, mục tiêu, giao dịch, tài khoản, cảnh báo, thiết bị, cài đặt; webhook SePay/Casso; giới hạn kích thước body |
| `app/ingest/` | Adapter SePay (API key/HMAC), Casso v2 (HMAC-SHA512), email IMAP (TLS có xác thực, DKIM/DMARC, parser VCB/MB + parser chung), khử trùng giữa các nguồn, ghép chuyển khoản nội bộ VCB↔MB |
| `app/engine/` | `evaluator` (mức sàn, được tiêu, mức), `alerts` (chống spam: trễ, lặp tối thiểu 2 giờ, leo thang), `forecast` (dự báo cuối tháng), `categorize`, `messages` (nội dung tiếng Việt) |
| `app/services/` | Số dư (neo tự sửa), tổng quan, dự báo, thao tác giao dịch, mục tiêu, sức khoẻ hệ thống |
| `app/notify/` | Outbox Telegram + bot long-polling, outbox đẩy FCM (JWT service account, không dùng firebase-admin) |
| `app/jobs.py` | Tick định kỳ, bản tin 08:00, chuyển tháng cho mục tiêu lặp lại |
| `app/db.py` | SQLite + `auto_migrate` (tự thêm cột mới cho DB đã triển khai) |

Bảng dữ liệu: `Account`, `Category`, `CategoryRule`, `Goal`, `Transaction`, `TransactionSource`, `IngestEvent`, `Alert`,
`AlertState`, `KV`, `Device`, `PushDelivery`.

Logic cốt lõi:

- **Mức sàn** = Σ phần còn cần của từng mục tiêu; **được tiêu** = số dư (các TK được tính) − mức sàn;
  **đệm** = max(10% mức sàn, 500.000đ).
- Mức: **OK** · **WARNING** (được tiêu < đệm) · **DANGER** (được tiêu < 0) · **UNKNOWN** (chưa biết số dư); ngân sách báo ở 80% / 100%.
- **Dự báo**: tốc độ chi ngoài mục tiêu 14 ngày gần nhất (giới hạn khoản lớn bất thường), mô phỏng từng ngày tới cuối tháng
  có tính lương dự kiến → ngày chạm mức sàn, mức chi an toàn mỗi ngày; cảnh báo khi chạm sàn trong ≤ 7 ngày và thiếu ≥ 200k.

### App (`mobile/`, Flutter 3.47, Material 3)

| Thư mục | Vai trò |
|---|---|
| `lib/api/` | `ApiClient` gọi REST (Bearer token) |
| `lib/state/` | `AppState` (kết nối, tổng quan, làm mới 30 giây, bản lưu offline), `PushController` (đăng ký thiết bị) |
| `lib/screens/` | Tổng quan, Thêm/Sửa mục tiêu, Giao dịch (+ bảng phân loại, nhập tay), Cảnh báo, Cài đặt, Kết nối máy chủ |
| `lib/theme/`, `lib/widgets/` | Hệ thống thiết kế "Bát men lam" (đang làm lại), các thành phần dùng chung |
| `lib/push/` | Firebase Cloud Messaging (tắt êm khi chưa có `google-services.json`) |
| `lib/demo/`, `lib/main_demo.dart` | Bản demo web: backend giả trong app, kiểm chứng khớp logic backend thật |

### Hạ tầng và quy trình

- `Dockerfile`, `docker-compose.yml` (đang thêm profile ngrok), `.env.example`.
- CI GitHub Actions: backend (ruff + pytest), mobile (analyze + test), build APK hai biến thể (có/không Firebase).
- Bộ skill trong `.agents/skills/` (impeccable, test-driven-development, verification-before-completion, design-taste-frontend,
  high-end-visual-design, performance-testing-skill), cầu nối ở `.claude/skills/`, quy tắc dự án ở `AGENTS.md`.
- Thiết kế: `DESIGN.md` + `.agents/design-state/` (PRODUCT.md, design.json, brief và critique từng màn hình).

## 3. Những gì đã làm

| Đợt | Thời gian | Nội dung | Commit tiêu biểu |
|---|---|---|---|
| 1 | 14/10 sáng | Backend (engine mục tiêu, ingest SePay/Casso/email, REST, Telegram), app Flutter, CI | `411cb36`, `4bbe204`, `dee850f` |
| 1 | 14/10 | Review đối kháng nhiều agent: 35 lỗi xác minh độc lập, sửa hết kèm test (TLS IMAP, body chunked, chèn giao dịch giả qua nội dung CK, cảnh báo sai khi chuyển nội bộ…) | `d15de79` … `63c38f4` |
| 2 | 14/10 chiều | Tự migrate SQLite; dự báo cuối tháng; thông báo đẩy FCM (backend + app + Android); CI build APK có/không Firebase | `7f61d8a` … `f698879` |
| 2 | 14/10 | Review vòng 2: 12 lỗi (mức chi an toàn tính lương trước ngày nhận, báo trùng khi sang tháng, khoá FCM hỏng im lặng…), sửa hết; PR chuyển **Ready for review** | `839b900`, `2e8890e` |
| 3 | 15/10 | Cài bộ skill vào repo + `AGENTS.md` | `81891f1` |
| 3 | 15/10 | Bản demo web (backend giả, đối chiếu khớp backend thật ở 5 mốc ngày), đăng tại https://claude.ai/artifact/HoRKnsxRrhdJ6Bix2SRuaZ (giao diện cũ) | `c4f7525`, `10ba63c` |
| 3 | 15/10 | Hệ thống thiết kế "Bát men lam" theo impeccable: lam coban trên nền trắng ánh xanh, Be Vietnam Pro, ô trạng thái + thước mức sàn; 252 cặp tương phản đạt chuẩn | `0336485` |
| 3 | 15/10 | Impeccable chấm giao diện cũ: 22–29/40 điểm, 15 lỗi lớn (critique-before từng màn hình) | commit lưu tạm |
| 3 | 15/10 | **Đang làm**: thiết kế lại toàn bộ màn hình; bộ cài Windows (Docker + ngrok + SePay + Gmail) | commit lưu tạm |

Kiểm tra ở commit ổn định gần nhất (`10ba63c`): backend 657 test, app 130 test, analyze sạch, CI xanh cả 4 job.

## 4. Trạng thái hiện tại

- **Commit lưu tạm** (theo yêu cầu "commit tất cả"): chứa phần thiết kế lại **đang làm dở** — `flutter analyze` còn 5 lỗi
  (widget cũ đang được thay bằng widget mới), nên CI của commit này dự kiến **đỏ**; commit kế tiếp của đợt thiết kế lại sẽ sửa.
- Bản demo trên trình duyệt chạy được (đã xác nhận WebAssembly được phép); sẽ cập nhật cùng link khi giao diện mới xong.
- Chưa triển khai server thật nên app chưa có dữ liệu tài khoản thật.

## 5. Việc còn lại

| # | Việc | Ai làm |
|---|---|---|
| 1 | Hoàn tất thiết kế lại (màn hình, kiểm tra impeccable trước/sau, a11y, chữ to), CI xanh, cập nhật link demo | Claude |
| 2 | Hoàn tất bộ cài Windows: `docker-compose` profile ngrok, script PowerShell (cài đặt, trạng thái, gửi thử, cập nhật), hướng dẫn `docs/cai-dat-windows.md` | Claude |
| 3 | Cài Docker Desktop; tạo tài khoản ngrok (authtoken + tên miền miễn phí); tạo bot Telegram; đăng ký SePay và liên kết VCB + MB; (dự phòng) Gmail riêng + mật khẩu ứng dụng + đăng ký email biến động | **Chủ** |
| 4 | Chạy script cài đặt, dán URL + API key vào webhook SePay, gửi giao dịch thử, nhận tin Telegram | Chủ (theo hướng dẫn) |
| 5 | Cài APK giao diện mới, kết nối bằng URL ngrok + `APP_TOKEN` | Chủ |
| 6 | Parser email chính xác cho VCB/MB (cần chủ dán email mẫu; hiện dùng parser chung) | Claude, khi có mẫu |
| 7 | Skill `web-perf` (gói gửi lên thiếu nội dung) | Chủ gửi thêm |
| 8 | Duyệt và merge PR #1 | Chủ |

## 6. Quyết định đã chốt

- Nguồn số dư: SePay (+ Casso hỗ trợ sẵn) và email IMAP dự phòng; ngân hàng VCB + MB.
- Logic "quỹ giữ + ngân sách"; cảnh báo Telegram + trong app + đẩy FCM (tuỳ chọn).
- Triển khai: Docker trên máy Windows của chủ, ngrok tên miền miễn phí; chỉ app Android (không làm bản web dữ liệu thật).
- Thiết kế: "Điềm tĩnh, tin cậy" + "Hiện đại, đậm nét" → "Bát men lam"; Material 3; không dùng màu động Material You;
  khi vượt sàn hiện số âm kèm "đã lấn vào tiền mục tiêu".
- Không đọc Gmail của chủ qua connector; mẫu thật phải ẩn danh trước khi vào repo.

## 7. Cách chạy và kiểm tra

```bash
# Backend
cd backend && ruff check app tests scripts && pytest -q
# App
cd mobile && flutter analyze && flutter test && dart format --set-exit-if-changed lib test
# Bản demo web (dữ liệu giả)
mobile/scripts/build_web_demo.sh
# Server (sau khi có bộ cài Windows: scripts/windows/setup.ps1)
docker compose up -d
```

Quy tắc dữ liệu, bảo mật và thiết kế: xem `AGENTS.md`. Hợp đồng API: `docs/api.md`. Hướng dẫn cài đặt chung: `README.md`.
