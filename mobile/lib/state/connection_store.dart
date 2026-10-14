import 'package:shared_preferences/shared_preferences.dart';

/// URL máy chủ + token đã lưu.
class ConnectionInfo {
  const ConnectionInfo({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;
}

/// Lưu thông tin kết nối trong shared_preferences.
/// (Sau này có thể chuyển token sang flutter_secure_storage.)
class ConnectionStore {
  const ConnectionStore();

  static const keyBaseUrl = 'server_url';
  static const keyToken = 'app_token';

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
  }
}
