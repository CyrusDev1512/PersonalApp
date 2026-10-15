import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../utils/currency.dart';

/// Lỗi khi gọi API, kèm thông báo tiếng Việt hiển thị được ngay.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message, {this.isNetwork = false});

  /// Mã HTTP; `null` khi lỗi mạng / quá thời gian / URL sai.
  final int? statusCode;
  final String message;

  /// `true` = không tới được máy chủ (mất mạng, sai địa chỉ, quá 15 giây).
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Thông báo chuẩn cho các lỗi thường gặp.
abstract final class ApiMessages {
  static const unauthorized = 'Sai token (401). Kiểm tra lại APP_TOKEN của máy chủ trong Cài đặt.';
  static const network = 'Không kết nối được máy chủ. Kiểm tra mạng, địa chỉ máy chủ và máy chủ có đang chạy không.';
  static const timeout = 'Máy chủ không phản hồi sau 15 giây. Thử lại sau.';
  static const invalidUrl =
      'Địa chỉ máy chủ không hợp lệ. Ví dụ: https://finance.example.com hoặc http://192.168.1.10:8000';
  static const badResponse = 'Máy chủ trả dữ liệu không hợp lệ.';
}

/// Client REST cho backend (hợp đồng trong docs/api.md).
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.token,
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = normalizeBaseUrl(baseUrl),
       _http = client ?? http.Client();

  /// URL gốc đã chuẩn hoá (không có "/" ở cuối).
  final String baseUrl;
  final String token;
  final Duration timeout;
  final http.Client _http;

  /// Chuẩn hoá & kiểm tra URL máy chủ; sai định dạng -> [ApiException] (statusCode `null`).
  static String normalizeBaseUrl(String input) {
    var s = input.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    final uri = Uri.tryParse(s);
    if (s.isEmpty ||
        uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const ApiException(null, ApiMessages.invalidUrl);
    }
    return s;
  }

  /// `true` khi URL dùng http:// (token gửi đi không được mã hoá).
  static bool isInsecureUrl(String input) => input.trim().toLowerCase().startsWith('http://');

  void close() => _http.close();

  // ---------------------------------------------------------------- lõi HTTP

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool auth = true,
  }) async {
    final uri = _uri(path, query);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (auth) 'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
    };
    final encoded = body == null ? null : jsonEncode(body);

    http.Response resp;
    try {
      final Future<http.Response> future = switch (method) {
        'GET' => _http.get(uri, headers: headers),
        'POST' => _http.post(uri, headers: headers, body: encoded),
        'PUT' => _http.put(uri, headers: headers, body: encoded),
        'PATCH' => _http.patch(uri, headers: headers, body: encoded),
        'DELETE' => _http.delete(uri, headers: headers, body: encoded),
        _ => throw ArgumentError.value(method, 'method'),
      };
      resp = await future.timeout(timeout);
    } on TimeoutException {
      throw const ApiException(null, ApiMessages.timeout, isNetwork: true);
    } on ApiException {
      rethrow;
    } on ArgumentError {
      rethrow;
    } catch (_) {
      // http.ClientException, SocketException, HandshakeException…
      throw const ApiException(null, ApiMessages.network, isNetwork: true);
    }

    // FastAPI không ghi charset → luôn giải mã UTF-8 thủ công (tiếng Việt).
    final text = utf8.decode(resp.bodyBytes, allowMalformed: true);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (text.trim().isEmpty) return null;
      try {
        return jsonDecode(text);
      } on FormatException {
        throw ApiException(resp.statusCode, ApiMessages.badResponse);
      }
    }
    throw _errorFor(resp.statusCode, text);
  }

  static ApiException _errorFor(int status, String text) {
    if (status == 401) return const ApiException(401, ApiMessages.unauthorized);
    final detail = _detailMessage(text);
    final message = switch (status) {
      403 => 'Không có quyền truy cập (403).',
      404 => detail ?? 'Không tìm thấy trên máy chủ (404). Kiểm tra lại địa chỉ máy chủ.',
      400 || 409 || 422 => detail ?? 'Dữ liệu không hợp lệ ($status).',
      413 => 'Dữ liệu gửi lên quá lớn (413).',
      >= 500 => 'Máy chủ gặp lỗi ($status). Thử lại sau.',
      _ => detail ?? 'Lỗi không xác định từ máy chủ ($status).',
    };
    return ApiException(status, message);
  }

  /// Tên tiếng Việt của các trường trong lỗi validate (docs/api.md).
  static const Map<String, String> _fieldLabels = {
    'amount': 'Số tiền',
    'name': 'Tên',
    'opening_spent': 'Số đã chi trước khi dùng app',
    'balance': 'Số dư',
    'description': 'Nội dung',
    'rule_pattern': 'Cụm từ nhận diện',
    'pattern': 'Cụm từ nhận diện',
    'bank': 'Ngân hàng',
    'account_number': 'Số tài khoản',
    'warning_percent': 'Phần trăm mức sàn',
    'warning_min_amount': 'Vùng đệm tối thiểu',
    'expected_income_amount': 'Số tiền lương',
    'expected_income_day': 'Ngày nhận lương',
    'month': 'Tháng',
    'category_id': 'Danh mục',
    'goal_id': 'Mục tiêu',
    'token': 'Token',
  };

  /// Trường tiền (giới hạn ghi theo kiểu "100.000.000.000đ").
  static const Set<String> _moneyFields = {
    'amount',
    'opening_spent',
    'balance',
    'warning_min_amount',
    'expected_income_amount',
  };

  /// Một lỗi validate của FastAPI/pydantic (`type`, `loc`, `ctx`) thành câu tiếng Việt; không đưa câu tiếng Anh
  /// của máy chủ ra giao diện.
  static String _validationMessage(Map<dynamic, dynamic> item) {
    final loc = item['loc'];
    final key = loc is List && loc.isNotEmpty ? loc.last.toString() : '';
    final field = _fieldLabels[key] ?? (key.isEmpty || key == 'body' ? 'Dữ liệu' : key);
    final ctx = item['ctx'] is Map ? item['ctx'] as Map : const {};
    String? value(String k) {
      final v = ctx[k];
      if (v == null) return null;
      if (v is num && v != 0 && _moneyFields.contains(key)) return '${formatGrouped(v.toInt())}đ';
      return '$v';
    }

    final message = switch (item['type']) {
      'greater_than' => value('gt') == null ? null : '$field phải lớn hơn ${value('gt')}',
      'greater_than_equal' => value('ge') == null ? null : '$field phải từ ${value('ge')} trở lên',
      'less_than' => value('lt') == null ? null : '$field phải nhỏ hơn ${value('lt')}',
      'less_than_equal' => value('le') == null ? null : '$field tối đa ${value('le')}',
      'string_too_long' => value('max_length') == null ? null : '$field tối đa ${value('max_length')} ký tự',
      'string_too_short' => value('min_length') == null ? null : '$field cần ít nhất ${value('min_length')} ký tự',
      'missing' => 'Thiếu $field',
      _ => null,
    };
    return message ?? '$field không hợp lệ';
  }

  /// Lấy `detail` của FastAPI: chuỗi, hoặc danh sách lỗi validate.
  static String? _detailMessage(String text) {
    if (text.trim().isEmpty) return null;
    try {
      final data = jsonDecode(text);
      if (data is! Map) return null;
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail;
      if (detail is List) {
        final parts = <String>[
          for (final item in detail)
            if (item is Map) _validationMessage(item),
        ];
        if (parts.isNotEmpty) return parts.toSet().join('; ');
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  JsonMap _map(Object? data) {
    if (data is Map) return asMap(data);
    throw const ApiException(null, ApiMessages.badResponse);
  }

  List<T> _list<T>(Object? data, T Function(JsonMap) parse) {
    if (data is List) return asList(data, parse);
    throw const ApiException(null, ApiMessages.badResponse);
  }

  // ------------------------------------------------------------------ health

  /// GET /health (không cần token).
  Future<JsonMap> health() async => _map(await _request('GET', '/health', auth: false));

  // ----------------------------------------------------------------- summary

  /// JSON thô của GET /api/summary (app lưu lại để xem khi offline).
  Future<JsonMap> getSummaryJson({String? month}) async =>
      _map(await _request('GET', '/api/summary', query: {'month': ?month}));

  Future<Summary> getSummary({String? month}) async => Summary.fromJson(await getSummaryJson(month: month));

  // ------------------------------------------------------------------- goals

  Future<List<GoalView>> listGoals({String? month}) async =>
      _list(await _request('GET', '/api/goals', query: {'month': ?month}), GoalView.fromJson);

  Future<GoalView> createGoal(GoalInput input) async =>
      GoalView.fromJson(_map(await _request('POST', '/api/goals', body: input.toJson())));

  /// PATCH với tập con trường bất kỳ (gửi `null` để xoá giá trị, vd. `category_id`).
  Future<GoalView> updateGoal(int id, JsonMap changes) async =>
      GoalView.fromJson(_map(await _request('PATCH', '/api/goals/$id', body: changes)));

  /// [stopSeries] = true: "Xoá và dừng lặp lại"; false: "Chỉ xoá tháng này".
  Future<void> deleteGoal(int id, {bool stopSeries = false}) async {
    await _request('DELETE', '/api/goals/$id', query: {'stop_series': '$stopSeries'});
  }

  // -------------------------------------------------------------- categories

  Future<List<Category>> listCategories() async {
    final list = _list(await _request('GET', '/api/categories'), Category.fromJson);
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<Category> createCategory({required String name, String kind = 'expense', String? icon}) async =>
      Category.fromJson(
        _map(await _request('POST', '/api/categories', body: {'name': name, 'kind': kind, 'icon': ?icon})),
      );

  // ------------------------------------------------------------ transactions

  Future<TxPage> listTransactions({String? month, bool uncategorized = false, int limit = 50, int offset = 0}) async =>
      TxPage.fromJson(
        _map(
          await _request(
            'GET',
            '/api/transactions',
            query: {'month': ?month, 'uncategorized': '$uncategorized', 'limit': '$limit', 'offset': '$offset'},
          ),
        ),
      );

  /// GET /api/transactions/{id} (mở giao dịch khi bấm thông báo đẩy).
  Future<Tx> getTransaction(int id) async => Tx.fromJson(_map(await _request('GET', '/api/transactions/$id')));

  /// Body là tập con của: `category_id`, `goal_id`, `for_next_month`, `excluded`,
  /// `remember_rule`, `rule_pattern`. Trả giao dịch mới kèm tổng quan đã tính lại.
  Future<TxPatchResult> patchTransaction(int id, JsonMap changes) async =>
      TxPatchResult.fromJson(_map(await _request('PATCH', '/api/transactions/$id', body: changes)));

  /// Nhập tay (chi tiền mặt, chi trước khi dùng app…).
  Future<Tx> createTransaction({
    required String direction,
    required int amount,
    String description = '',
    int? categoryId,
    DateTime? bankTime,
    int? accountId,
    bool affectsBalance = false,
  }) async => Tx.fromJson(
    _map(
      await _request(
        'POST',
        '/api/transactions',
        body: {
          'direction': direction,
          'amount': amount,
          'description': description,
          'category_id': categoryId,
          if (bankTime != null) 'bank_time': bankTime.toUtc().toIso8601String(),
          'account_id': accountId,
          'affects_balance': affectsBalance,
        },
      ),
    ),
  );

  /// Chỉ xoá được giao dịch nhập tay.
  Future<void> deleteTransaction(int id) async {
    await _request('DELETE', '/api/transactions/$id');
  }

  // ---------------------------------------------------------------- accounts

  Future<List<Account>> listAccounts() async => _list(await _request('GET', '/api/accounts'), Account.fromJson);

  Future<Account> createAccount({
    required String bank,
    required String name,
    String? accountNumber,
    bool includeInTotal = true,
    int? balance,
  }) async => Account.fromJson(
    _map(
      await _request(
        'POST',
        '/api/accounts',
        body: {
          'bank': bank,
          'name': name,
          if (accountNumber != null && accountNumber.isNotEmpty) 'account_number': accountNumber,
          'include_in_total': includeInTotal,
          'balance': ?balance,
        },
      ),
    ),
  );

  /// Tập con của `name`, `account_number`, `include_in_total`, `confirmed`, `balance`.
  Future<Account> updateAccount(int id, JsonMap changes) async =>
      Account.fromJson(_map(await _request('PATCH', '/api/accounts/$id', body: changes)));

  /// Đặt số dư hiện tại làm mốc.
  Future<Account> setAccountBalance(int id, int balance) => updateAccount(id, {'balance': balance});

  Future<void> deleteAccount(int id) async {
    await _request('DELETE', '/api/accounts/$id');
  }

  // ------------------------------------------------------------------ alerts

  Future<List<Alert>> listAlerts({bool unread = false, int limit = 50}) async =>
      _list(await _request('GET', '/api/alerts', query: {'unread': '$unread', 'limit': '$limit'}), Alert.fromJson);

  /// GET /api/alerts/{id} (mở cảnh báo khi bấm thông báo đẩy).
  Future<Alert> getAlert(int id) async => Alert.fromJson(_map(await _request('GET', '/api/alerts/$id')));

  Future<Alert> markAlertRead(int id) async => Alert.fromJson(_map(await _request('POST', '/api/alerts/$id/read')));

  /// Trả số cảnh báo được đánh dấu.
  Future<int> markAllAlertsRead() async {
    final data = await _request('POST', '/api/alerts/read-all');
    return data is Map ? asInt(data['updated']) : 0;
  }

  // ------------------------------------------------------------ thông báo đẩy

  /// POST /api/devices: đăng ký (hoặc cập nhật) token FCM của máy này.
  Future<DeviceRegistration> registerDevice({
    required String token,
    required String platform,
    required String appVersion,
  }) async => DeviceRegistration.fromJson(
    _map(
      await _request('POST', '/api/devices', body: {'token': token, 'platform': platform, 'app_version': appVersion}),
    ),
  );

  /// DELETE /api/devices/{token} (idempotent; token được URL-encode trong path).
  Future<void> unregisterDevice(String token) async {
    await _request('DELETE', '/api/devices/${Uri.encodeComponent(token)}');
  }

  Future<DeviceList> listDevices() async => DeviceList.fromJson(_map(await _request('GET', '/api/devices')));

  /// POST /api/devices/test: gửi một thông báo thử tới mọi thiết bị.
  Future<TestPushResult> sendTestPush() async {
    final data = await _request('POST', '/api/devices/test');
    return TestPushResult.fromJson(data is Map ? asMap(data) : const {});
  }

  // ---------------------------------------------------------------- settings

  Future<AppSettings> getSettings() async => AppSettings.fromJson(_map(await _request('GET', '/api/settings')));

  Future<AppSettings> updateSettings(AppSettings settings) async =>
      AppSettings.fromJson(_map(await _request('PUT', '/api/settings', body: settings.toJson())));

  /// PUT /api/settings với một tập con các trường (vd. `{"notify_every_tx": false}`), docs/api.md › Cài đặt.
  Future<AppSettings> updateSettingsFields(JsonMap changes) async =>
      AppSettings.fromJson(_map(await _request('PUT', '/api/settings', body: changes)));
}
