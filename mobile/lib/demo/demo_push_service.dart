import 'dart:async';

import '../push/push_service.dart';
import 'demo_backend.dart';

/// [PushService] của bản dùng thử: luôn "có Firebase", quyền thông báo luôn được cấp, và mỗi cảnh báo quan trọng
/// mà [DemoBackend] đẩy tới thiết bị đã đăng ký được phát ra như thông báo đến khi app đang mở
/// (để luồng SnackBar "Xem" của PushNavigator hiện ra như trên điện thoại).
class DemoPushService implements PushService {
  DemoPushService(this.backend);

  final DemoBackend backend;

  bool _available = false;
  int _generation = 1;
  final StreamController<String> _tokenRefresh = StreamController<String>.broadcast();

  @override
  Future<bool> init() async => _available = true;

  @override
  bool get available => _available;

  @override
  Future<PushPermission> requestPermission() async => PushPermission.granted;

  @override
  Future<String?> getToken() async => 'demo-web-token-$_generation';

  @override
  Stream<String> get onTokenRefresh => _tokenRefresh.stream;

  @override
  Stream<PushMessage> get onForeground =>
      backend.pushes.map((p) => PushMessage.fromData(p.data, title: p.title, body: p.body));

  @override
  Stream<PushMessage> get onOpened => const Stream.empty();

  /// Như FCM: sau khi xoá, lần [getToken] sau trả token mới.
  @override
  Future<void> deleteToken() async => _generation++;

  Future<void> dispose() => _tokenRefresh.close();
}
