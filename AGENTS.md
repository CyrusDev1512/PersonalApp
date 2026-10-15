# AGENTS.md — quy tắc dự án PersonalApp (Chi tiêu)

Quy tắc ở đây đứng trên mọi skill trong `.agents/skills/` (và các bản cầu nối ở `.claude/skills/`).

## Dự án

App quản lý chi tiêu cá nhân: mỗi khi số dư ngân hàng thay đổi, hệ thống so với các mục tiêu của tháng
(quỹ giữ + ngân sách) và chủ động cảnh báo. Một người dùng (chủ tài khoản), giao diện tiếng Việt, tiền VND.

| Thư mục | Nội dung |
|---|---|
| `backend/` | FastAPI + SQLite: nhận webhook SePay/Casso + email IMAP, đánh giá mục tiêu, dự báo, cảnh báo Telegram/FCM |
| `mobile/` | App Flutter (Material 3, Android trước): tổng quan, mục tiêu, giao dịch, cảnh báo, cài đặt; `lib/main_demo.dart` = bản demo web dữ liệu giả |
| `docs/api.md` | Hợp đồng API giữa app và backend |
| `DESIGN.md`, `.agents/design-state/` | Hệ thống thiết kế và ngữ cảnh sản phẩm (impeccable) |
| `.agents/skills/` | Nội dung thật của skill; `.claude/skills/` chỉ là cầu nối trỏ vào đây |

## Lệnh kiểm tra (giống CI)

- Backend: `cd backend && ruff check app tests scripts && pytest -q` (venv: `.venv/bin/...`).
- App: `cd mobile && flutter analyze && flutter test && dart format --set-exit-if-changed lib test`.
- APK: CI build cả bản không Firebase và bản `google-services.dummy.json`.
- Demo web: `mobile/scripts/build_web_demo.sh` (không gọi mạng ngoài lúc chạy).

## Quy tắc dữ liệu và bảo mật

- Không đọc Gmail hay hộp thư của người dùng; email mẫu chỉ lấy khi người dùng tự dán.
- Mẫu thật (email, sao kê, ảnh chụp) chỉ để ở thư mục tạm; vào repo phải ẩn danh hoá (số TK, tên, mã tham chiếu,
  số tiền/số dư giả nhưng khớp số học) và grep kiểm tra rò rỉ trước khi commit.
- Không commit secret: `.env`, `secrets/`, `google-services.json`, khoá service account.
- Không gửi ảnh chụp màn hình hay dữ liệu tài chính tới dịch vụ ngoài (API tạo ảnh, công cụ phân tích...).

## Thiết kế (impeccable)

- App Flutter là native: `impeccable` + `reference/android.md` + Material 3 quyết định cấu trúc, điều hướng, component.
  `design-taste-frontend` và `high-end-visual-design` viết cho web/landing page: chỉ dùng làm tham khảo thẩm mỹ;
  chỗ nào trái Material 3, khả năng tiếp cận hoặc `DESIGN.md` thì bỏ (vd. cấm Roboto/Material Icons, eyebrow, viền kép).
- Màu, chữ, khoảng cách lấy từ theme (`mobile/lib/theme/`), không viết màu/cỡ chữ cứng trong màn hình.
- Kiểm tra nguồn thay cho detector web của impeccable: grep `lib/` tìm `Color(0x`/`Colors.` ngoài theme, `fontSize:` cứng,
  `IconButton` thiếu `tooltip`, vùng chạm < 48dp, `ListView(` không builder với danh sách dài.
- Bằng chứng giao diện: nói rõ ảnh từ thiết bị, emulator hay Flutter web (bộ chụp của bản demo).
- Không chạy engine/hook/launcher của impeccable (`scripts/impeccable`), không tạo thư mục `.impeccable`.

## Skill

- `web-perf` có cầu nối ở dự án gốc nhưng chưa có nội dung trong repo này: chưa cài.
- `performance-testing-skill` nhắc Locust: repo này chưa có hạ tầng kiểm thử tải; không tự cài Locust/k6.
- Cầu nối `.claude/skills/*/SKILL.md` được sinh bởi `scripts/dong-bo-skill.py` ở dự án gốc (không có trong repo này);
  khi thêm/sửa skill thì sửa nội dung ở `.agents/skills/` và giữ cầu nối đồng bộ.

## Git

- Làm trên nhánh được giao; không force-push nhánh người khác; commit nhỏ theo nhóm thay đổi, CI phải xanh.
