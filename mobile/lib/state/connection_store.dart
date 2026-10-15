import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// URL máy chủ + token đã lưu.
class ConnectionInfo {
  const ConnectionInfo({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;
}

/// Tổng quan tải thành công gần nhất (để hiện khi offline).
class CachedSummary {
  const CachedSummary({required this.loadedAt, required this.json});

  final DateTime loadedAt;
  final Map<String, dynamic> json;
}

/// Lưu thông tin kết nối (và bản tổng quan gần nhất) trong shared_preferences.
/// (Sau này có thể chuyển token sang flutter_secure_storage.)
class ConnectionStore {
  const ConnectionStore();

  static const keyBaseUrl = 'server_url';
  static const keyToken = 'app_token';
  static const keySummaryCache = 'summary_cache';

  Future<ConnectionInfo?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(keyBaseUrl)?.trim() ?? '';
    final token = prefs.getString(keyToken)?.trim() ?? '';
    if (url.isEmpty || token.isEmpty) return null;
    return ConnectionInfo(baseUrl: url, token: token);
  }

  Future<void> save(ConnectionInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyBaseUrl, info.baseUrl);
    await prefs.setString(keyToken, info.token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyBaseUrl);
    await prefs.remove(keyToken);
    await prefs.remove(keySummaryCache);
  }

  /// Đọc bản tổng quan đã lưu của đúng máy chủ [baseUrl]; hỏng / khác máy chủ -> `null`.
  Future<CachedSummary?> loadSummary(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keySummaryCache);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map || data['base_url'] != baseUrl) return null;
      final loadedAt = DateTime.tryParse('${data['loaded_at']}');
      final json = data['summary'];
      if (loadedAt == null || json is! Map<String, dynamic>) return null;
      return CachedSummary(loadedAt: loadedAt.toLocal(), json: json);
    } on FormatException {
      return null;
    }
  }

  Future<void> saveSummary(String baseUrl, DateTime loadedAt, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      keySummaryCache,
      jsonEncode({'base_url': baseUrl, 'loaded_at': loadedAt.toUtc().toIso8601String(), 'summary': json}),
    );
  }
}
