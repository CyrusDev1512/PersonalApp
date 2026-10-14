import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../push/push_service.dart';
import 'app_state.dart';

/// Phiên bản app gửi kèm khi đăng ký thiết bị (giữ khớp `version` trong pubspec.yaml).
const String kAppVersion = '1.0.0';

/// Trạng thái thông báo đẩy để hiện ở Cài đặt.
enum PushStatus {
  /// Chưa kết nối máy chủ / chưa kiểm tra.
  idle('idle'),

  /// Đang khởi tạo, xin quyền, đăng ký token.
  checking('checking'),

  /// Bản build không có cấu hình Firebase (`google-services.json`).
  notAvailableInBuild('not_available_in_build'),

  /// Người dùng không cho phép hiện thông báo.
  permissionDenied('permission_denied'),

  /// Máy chủ chưa cấu hình Firebase (`push_enabled=false`).
  serverNotConfigured('server_not_configured'),
  enabled('enabled'),
  error('error');

  const PushStatus(this.code);

  final String code;

  String get label => switch (this) {
    PushStatus.idle => 'Chưa kiểm tra',
    PushStatus.checking => 'Đang kiểm tra…',
    PushStatus.notAvailableInBuild => 'Ứng dụng chưa cấu hình Firebase',
    PushStatus.permissionDenied => 'Chưa được cấp quyền thông báo',
    PushStatus.serverNotConfigured => 'Máy chủ chưa cấu hình Firebase',
    PushStatus.enabled => 'Đang bật',
    PushStatus.error => 'Lỗi',
  };
}

String _defaultPlatform() => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

/// Đăng ký / huỷ đăng ký thiết bị nhận thông báo đẩy theo kết nối máy chủ của [AppState].
///
/// - Sau khi kết nối máy chủ thành công (tải được tổng quan): khởi tạo push → xin quyền
///   (Android 13+) → lấy token → `POST /api/devices`.
/// - Token đổi → đăng ký lại.
/// - Ngắt kết nối → `DELETE /api/devices/{token}` rồi xoá token trên máy;
///   đổi máy chủ → huỷ ở máy chủ cũ, đăng ký ở máy chủ mới.
///
/// Các thao tác chạy tuần tự (hàng đợi) để không lẫn thứ tự đăng ký / huỷ.
class PushController extends ChangeNotifier {
  PushController({required this.service, String? platform, this.appVersion = kAppVersion})
    : platform = platform ?? _defaultPlatform();

  final PushService service;

  /// `android` | `ios`.
  final String platform;
  final String appVersion;

  PushStatus _status = PushStatus.idle;
  String? _errorMessage;
  String? _serverError;
  String? _token;
  ApiClient? _client;
  AppState? _state;
  Future<bool>? _init;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  final StreamController<PushMessage> _foreground = StreamController<PushMessage>.broadcast();
  final StreamController<PushMessage> _opened = StreamController<PushMessage>.broadcast();
  Future<void> _queue = Future.value();
  bool _disposed = false;

  PushStatus get status => _status;

  /// Chi tiết lỗi khi [status] = [PushStatus.error].
  String? get errorMessage => _errorMessage;

  /// Lỗi cấu hình Firebase phía máy chủ (`GET /api/devices` → `error`).
  String? get serverError => _serverError;

  /// Token đang được đăng ký ở máy chủ (null nếu chưa).
  String? get registeredToken => _token;

  /// Gửi thử được không (đã đăng ký và máy chủ bật push).
  bool get canSendTest => _status == PushStatus.enabled && _client != null;

  /// Thông báo đến khi app đang mở.
  Stream<PushMessage> get foregroundMessages => _foreground.stream;

  /// Người dùng bấm vào thông báo.
  Stream<PushMessage> get openedMessages => _opened.stream;

  /// Hoàn tất khi mọi thao tác đang chờ đã xong (dùng trong test).
  Future<void> get settled => _queue;

  /// Theo dõi kết nối máy chủ của [state].
  void attach(AppState state) {
    _state?.removeListener(_sync);
    _state = state;
    state.addListener(_sync);
    _sync();
  }

  void _sync() {
    final state = _state;
    if (state == null || _disposed) return;
    final current = state.client;
    final attached = _client;
    if (attached != null && !identical(attached, current)) {
      // Ngắt kết nối hoặc đổi máy chủ.
      _client = null;
      final loggedOut = current == null;
      _enqueue(() => _unregister(attached, deleteLocalToken: loggedOut));
    }
    final confirmed = state.confirmedClient;
    if (confirmed != null && _client == null) {
      _client = confirmed;
      _enqueue(() => _register(confirmed));
    }
  }

  /// Thử đăng ký lại (nút "Thử lại" ở Cài đặt, vd. sau khi bật quyền thông báo).
  Future<void> retry() {
    final client = _client;
    if (client != null) _enqueue(() => _register(client));
    return _queue;
  }

  /// POST /api/devices/test.
  Future<TestPushResult> sendTest() async {
    final client = _client ?? _state?.client;
    if (client == null) throw const ApiException(null, 'Chưa kết nối máy chủ.');
    return client.sendTestPush();
  }

  /// Đọc lại trạng thái push của máy chủ (GET /api/devices). Lỗi thì bỏ qua.
  Future<void> refreshServerStatus() async {
    final client = _client;
    if (client == null || _token == null) return;
    try {
      final list = await client.listDevices();
      if (!identical(client, _client)) return;
      _serverError = list.error;
      if (!list.pushEnabled && _status == PushStatus.enabled) {
        _status = PushStatus.serverNotConfigured;
      } else if (list.pushEnabled && _status == PushStatus.serverNotConfigured) {
        _status = PushStatus.enabled;
      }
      _notify();
    } on ApiException {
      // Giữ trạng thái cũ.
    }
  }

  // ------------------------------------------------------------- nội bộ

  void _enqueue(Future<void> Function() op) {
    _queue = _queue.then((_) async {
      if (_disposed) return;
      try {
        await op();
      } catch (e) {
        debugPrint('PushController: $e');
      }
    });
  }

  Future<bool> _ensureInit() => _init ??= _initialize();

  Future<bool> _initialize() async {
    bool ok;
    try {
      ok = await service.init() && service.available;
    } catch (e) {
      debugPrint('Không khởi tạo được thông báo đẩy: $e');
      ok = false;
    }
    if (ok && !_disposed) {
      _subscriptions
        ..add(service.onForeground.listen(_forward(_foreground), onError: _logError))
        ..add(service.onOpened.listen(_forward(_opened), onError: _logError))
        ..add(service.onTokenRefresh.listen(_onTokenRefresh, onError: _logError));
    }
    return ok;
  }

  void Function(PushMessage) _forward(StreamController<PushMessage> target) => (message) {
    if (!target.isClosed) target.add(message);
  };

  static void _logError(Object e) => debugPrint('Thông báo đẩy: $e');

  Future<void> _register(ApiClient client) async {
    if (!identical(_client, client)) return;
    _setStatus(PushStatus.checking);
    if (!await _ensureInit()) {
      if (identical(_client, client)) _setStatus(PushStatus.notAvailableInBuild);
      return;
    }
    try {
      final permission = await service.requestPermission();
      if (!identical(_client, client)) return;
      if (!permission.allowed) {
        _setStatus(PushStatus.permissionDenied);
        return;
      }
      final token = await service.getToken();
      if (!identical(_client, client)) return;
      if (token == null || token.isEmpty) {
        _setError('Không lấy được token thông báo đẩy từ Firebase.');
        return;
      }
      await _sendToken(client, token);
    } on ApiException catch (e) {
      if (identical(_client, client)) _setError(e.message);
    } catch (e) {
      if (identical(_client, client)) _setError('Không bật được thông báo đẩy: $e');
    }
  }

  Future<void> _sendToken(ApiClient client, String token) async {
    final registration = await client.registerDevice(token: token, platform: platform, appVersion: appVersion);
    // Đã có trên máy chủ: phải huỷ khi ngắt kết nối (kể cả khi vừa đổi máy chủ trong lúc chờ).
    _token = token;
    if (!identical(_client, client)) return;
    bool enabled;
    String? serverError;
    if (registration.pushEnabled == true) {
      enabled = true;
    } else {
      // Máy chủ chưa bật push (hoặc không nói rõ): hỏi GET /api/devices để biết lý do.
      try {
        final list = await client.listDevices();
        enabled = list.pushEnabled;
        serverError = list.error;
      } on ApiException {
        enabled = registration.pushEnabled ?? true;
      }
      if (!identical(_client, client)) return;
    }
    _serverError = serverError;
    _errorMessage = null;
    _setStatus(enabled ? PushStatus.enabled : PushStatus.serverNotConfigured);
  }

  void _onTokenRefresh(String token) {
    _enqueue(() async {
      final client = _client;
      if (client == null || token.isEmpty || token == _token) return;
      if (_status == PushStatus.permissionDenied || _status == PushStatus.notAvailableInBuild) return;
      try {
        await _sendToken(client, token);
      } on ApiException catch (e) {
        if (identical(_client, client)) _setError(e.message);
      }
    });
  }

  Future<void> _unregister(ApiClient client, {required bool deleteLocalToken}) async {
    final token = _token;
    _token = null;
    if (token != null) {
      try {
        await client.unregisterDevice(token);
      } catch (e) {
        debugPrint('Không huỷ được đăng ký thiết bị: $e');
      }
    }
    if (deleteLocalToken && service.available) {
      try {
        await service.deleteToken();
      } catch (e) {
        debugPrint('Không xoá được token thông báo đẩy: $e');
      }
    }
    if (_client == null) {
      _errorMessage = null;
      _serverError = null;
      _setStatus(PushStatus.idle);
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _setStatus(PushStatus.error);
  }

  void _setStatus(PushStatus status) {
    _status = status;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _state?.removeListener(_sync);
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    unawaited(_foreground.close());
    unawaited(_opened.close());
    super.dispose();
  }
}
