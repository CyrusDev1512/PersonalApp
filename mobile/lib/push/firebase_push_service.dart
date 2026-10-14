import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_service.dart';

/// [PushService] dùng Firebase Cloud Messaging.
///
/// Bản build không có `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) thì
/// `Firebase.initializeApp()` báo lỗi: bắt lại, [available] = `false`, push tắt và app vẫn chạy.
/// `FirebaseMessaging` chỉ được dùng sau khi khởi tạo thành công.
///
/// Không cần handler nền: khi app ở nền/đã tắt, hệ điều hành tự hiện thông báo (payload `notification`)
/// trên khay hệ thống; bấm vào thì [onOpened] phát ra.
class FirebasePushService implements PushService {
  FirebasePushService();

  bool _available = false;
  Future<bool>? _init;
  bool _initialMessageTaken = false;

  @override
  bool get available => _available;

  @override
  Future<bool> init() => _init ??= _initialize();

  Future<bool> _initialize() async {
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (e) {
      // Thiếu cấu hình Firebase trong bản build (hoặc nền tảng không hỗ trợ).
      debugPrint('Thông báo đẩy tắt: chưa khởi tạo được Firebase ($e)');
      _available = false;
    }
    return _available;
  }

  @override
  Future<PushPermission> requestPermission() async {
    if (!_available) return PushPermission.denied;
    final settings = await FirebaseMessaging.instance.requestPermission();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized => PushPermission.granted,
      AuthorizationStatus.provisional => PushPermission.provisional,
      AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      AuthorizationStatus.denied => PushPermission.denied,
      AuthorizationStatus.deniedPermanently => PushPermission.denied,
    };
  }

  @override
  Future<String?> getToken() async {
    if (!_available) return null;
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Stream<String> get onTokenRefresh => _available ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  @override
  Stream<PushMessage> get onForeground => _available ? FirebaseMessaging.onMessage.map(_convert) : const Stream.empty();

  @override
  Stream<PushMessage> get onOpened => _available ? _opened() : const Stream.empty();

  /// Thông báo đã mở app từ trạng thái tắt hẳn (chỉ phát một lần), rồi các lần bấm khi app ở nền.
  Stream<PushMessage> _opened() async* {
    if (!_initialMessageTaken) {
      _initialMessageTaken = true;
      RemoteMessage? initial;
      try {
        initial = await FirebaseMessaging.instance.getInitialMessage();
      } catch (e) {
        debugPrint('Không đọc được thông báo mở app: $e');
      }
      if (initial != null) yield _convert(initial);
    }
    yield* FirebaseMessaging.onMessageOpenedApp.map(_convert);
  }

  @override
  Future<void> deleteToken() async {
    if (!_available) return;
    await FirebaseMessaging.instance.deleteToken();
  }

  static PushMessage _convert(RemoteMessage m) =>
      PushMessage.fromData(m.data, title: m.notification?.title, body: m.notification?.body);
}
