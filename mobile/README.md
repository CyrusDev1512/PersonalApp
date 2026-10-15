# Chi tiêu — app Flutter

App điện thoại (Android/iOS) cho backend trong `../backend`: xem tổng số dư, mức sàn, phần "được tiêu thoải mái",
trạng thái cảnh báo; thêm/sửa mục tiêu (Quỹ giữ / Ngân sách chi tiêu); phân loại giao dịch; xem lịch sử cảnh báo;
quản lý tài khoản và ngưỡng cảnh báo. Hợp đồng API: `../docs/api.md`.

## Chạy

```bash
flutter pub get
flutter run            # cần thiết bị/emulator
flutter analyze
flutter test
flutter build apk --release   # cần Android SDK
scripts/build_web_demo.sh     # bản demo chạy trên trình duyệt, không cần máy chủ (xem README gốc, mục 7)
```

Lần đầu mở app sẽ hiện màn **Kết nối máy chủ**: nhập URL backend (nên là `https://…` qua Cloudflare Tunnel) và
`APP_TOKEN`. App gọi `GET /health` rồi `GET /api/summary` để kiểm tra trước khi lưu.

- `http://` chỉ nên dùng trong mạng LAN khi dev (Android đã bật `usesCleartextTraffic`, iOS bật
  `NSAllowsLocalNetworking`); app sẽ cảnh báo token được gửi không mã hoá.
- URL/token và bản tổng quan gần nhất được lưu bằng `shared_preferences` (sau này có thể chuyển sang
  `flutter_secure_storage`).
- Tổng quan tự tải lại mỗi 30 giây khi app đang mở.

## Cấu trúc

- `lib/api/api_client.dart` — client REST, `ApiException` với thông báo tiếng Việt (401, lỗi mạng, quá 15 giây).
- `lib/models/` — model + `fromJson` viết tay (chịu được null, số thực thay số nguyên; thời gian `.toLocal()`).
- `lib/state/` — `AppState` (ChangeNotifier: client, summary, loading/error, tự làm mới) và `ConnectionStore`.
- `lib/screens/` — Tổng quan, form mục tiêu, Giao dịch (+ bảng phân loại, nhập tay), Cảnh báo, Cài đặt, Kết nối.
- `lib/widgets/` — `StatusBanner`, `GoalCard`, hộp thoại tài khoản/số dư, các widget chung.
- `lib/utils/` — định dạng tiền VND (`6.500.000đ`, định dạng khi gõ) và tháng theo giờ Việt Nam.
- `lib/demo/` + `lib/main_demo.dart` — bản demo trên trình duyệt: máy chủ giả trong app (`DemoBackend`, dữ liệu giả,
  port gọn logic của backend), thông báo đẩy giả và thanh "Giả lập biến động số dư". Không dùng trong APK.
