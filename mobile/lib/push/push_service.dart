import 'dart:async';

/// Quyền hiển thị thông báo của hệ điều hành.
enum PushPermission {
  granted,

  /// iOS: được phép hiển thị lặng lẽ (vẫn coi là bật).
  provisional,
  denied,
  notDetermined;

  bool get allowed => this == PushPermission.granted || this == PushPermission.provisional;
}

/// Một thông báo đẩy (FCM) đã chuyển sang dạng app dùng.
///
/// `data` theo docs/api.md: mọi giá trị là chuỗi, rỗng nếu không có —
/// `alert_id`, `kind`, `level`, `transaction_id`, `goal_id`, `month`.
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  /// Từ `notification{title, body}` + `data` của FCM; giá trị `data` được đổi sang chuỗi.
  factory PushMessage.fromData(Map<String, dynamic> data, {String? title, String? body}) => PushMessage(
    title: _nonBlank(title),
    body: _nonBlank(body),
    data: {
      for (final e in data.entries)
        if (e.value != null) e.key: e.value.toString(),
    },
  );

  final String? title;
  final String? body;
  final Map<String, String> data;

  String? _field(String key) => _nonBlank(data[key]);

  String? get alertId => _field('alert_id');
  String? get kind => _field('kind');
  String? get level => _field('level');
  String? get transactionId => _field('transaction_id');
  String? get goalId => _field('goal_id');
  String? get month => _field('month');

  int? get alertIdValue => int.tryParse(alertId ?? '');
  int? get transactionIdValue => int.tryParse(transactionId ?? '');

  @override
  String toString() => 'PushMessage(title: $title, data: $data)';
}

String? _nonBlank(String? v) {
  final s = v?.trim();
  return s == null || s.isEmpty ? null : s;
}

/// Lớp trừu tượng trên Firebase Cloud Messaging để app chạy (và test) được khi không có Firebase.
abstract class PushService {
  /// Khởi tạo; `false` = bản build không có cấu hình Firebase (push tắt, app vẫn chạy bình thường).
  Future<bool> init();

  /// `true` sau khi [init] thành công.
  bool get available;

  /// Xin quyền hiển thị thông báo (Android 13+ / iOS).
  Future<PushPermission> requestPermission();

  /// Token FCM của máy này; `null` nếu không lấy được.
  Future<String?> getToken();

  /// Token mới khi FCM đổi token.
  Stream<String> get onTokenRefresh;

  /// Thông báo đến khi app đang mở (hệ điều hành không tự hiện).
  Stream<PushMessage> get onForeground;

  /// Người dùng bấm vào thông báo (gồm cả thông báo đã mở app từ trạng thái tắt hẳn).
  Stream<PushMessage> get onOpened;

  /// Huỷ token hiện tại trên máy (khi ngắt kết nối).
  Future<void> deleteToken();
}

/// Không có push (mặc định, bản build không có Firebase, và trong test).
class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<bool> init() async => false;

  @override
  bool get available => false;

  @override
  Future<PushPermission> requestPermission() async => PushPermission.denied;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<PushMessage> get onForeground => const Stream.empty();

  @override
  Stream<PushMessage> get onOpened => const Stream.empty();

  @override
  Future<void> deleteToken() async {}
}
