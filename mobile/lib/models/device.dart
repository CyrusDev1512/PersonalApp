import 'json_utils.dart';

/// Kết quả POST /api/devices (server không bao giờ trả lại token).
class DeviceRegistration {
  const DeviceRegistration({this.id, this.platform, this.appVersion, this.lastSeenAt, this.pushEnabled});

  final int? id;
  final String? platform;
  final String? appVersion;
  final DateTime? lastSeenAt;

  /// `false` khi máy chủ chưa cấu hình Firebase; `null` nếu server không trả trường này.
  final bool? pushEnabled;

  factory DeviceRegistration.fromJson(JsonMap json) => DeviceRegistration(
    id: asIntOrNull(json['id']),
    platform: asStringOrNull(json['platform']),
    appVersion: asStringOrNull(json['app_version']),
    lastSeenAt: asDateTime(json['last_seen_at']),
    pushEnabled: json['push_enabled'] == null ? null : asBool(json['push_enabled']),
  );
}

/// Một thiết bị đã đăng ký nhận thông báo đẩy.
class DeviceInfo {
  const DeviceInfo({required this.id, this.platform, this.appVersion, this.createdAt, this.lastSeenAt, this.lastError});

  final int id;
  final String? platform;
  final String? appVersion;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;
  final String? lastError;

  factory DeviceInfo.fromJson(JsonMap json) => DeviceInfo(
    id: asInt(json['id']),
    platform: asStringOrNull(json['platform']),
    appVersion: asStringOrNull(json['app_version']),
    createdAt: asDateTime(json['created_at']),
    lastSeenAt: asDateTime(json['last_seen_at']),
    lastError: asStringOrNull(json['last_error']),
  );
}

/// Kết quả GET /api/devices.
class DeviceList {
  const DeviceList({required this.pushEnabled, this.error, this.devices = const []});

  /// `false` khi máy chủ chưa cấu hình Firebase.
  final bool pushEnabled;

  /// Mô tả lỗi cấu hình Firebase của máy chủ (nếu có).
  final String? error;
  final List<DeviceInfo> devices;

  factory DeviceList.fromJson(JsonMap json) {
    final error = asStringOrNull(json['error'])?.trim();
    return DeviceList(
      pushEnabled: asBool(json['push_enabled']),
      error: error == null || error.isEmpty ? null : error,
      devices: asList(json['devices'], DeviceInfo.fromJson),
    );
  }
}

/// Kết quả POST /api/devices/test.
class TestPushResult {
  const TestPushResult({required this.queued, required this.pushEnabled});

  final bool queued;
  final bool pushEnabled;

  factory TestPushResult.fromJson(JsonMap json) =>
      TestPushResult(queued: asBool(json['queued']), pushEnabled: asBool(json['push_enabled'], true));
}
