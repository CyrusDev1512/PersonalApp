import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personal_finance/push/push_service.dart';

/// Ví dụ Summary đúng như docs/api.md (mức WARNING).
Map<String, dynamic> warningSummaryJson() => {
  'month': '2026-10',
  'generated_at': '2026-10-14T03:00:00Z',
  'level': 'WARNING',
  'level_reason': 'Chỉ còn 500.000đ trên mức sàn 6.000.000đ',
  'balance': 6500000,
  'balance_known': true,
  'balance_as_of': '2026-10-14T02:59:00Z',
  'in_transit': 0,
  'floor': 6000000,
  'free': 500000,
  'buffer': 600000,
  'waiting_income': false,
  'expected_income': {'amount': 15000000, 'day': 5, 'pending': 0},
  'days_left': 18,
  'accounts': [accountJson()],
  'goals': [
    {
      'id': 1,
      'series_id': '9f1c',
      'name': 'Tiền trọ',
      'type': 'reserve',
      'amount': 3000000,
      'category_id': 2,
      'category_name': 'Thuê trọ',
      'category_icon': '🏠',
      'month': '2026-10',
      'repeat_monthly': true,
      'opening_spent': 0,
      'spent': 0,
      'remaining': 3000000,
      'usage_pct': 0.0,
      'auto_match': true,
    },
    {
      'id': 2,
      'series_id': 'a7b2',
      'name': 'Tiền ăn',
      'type': 'budget',
      'amount': 5000000,
      'category_id': 1,
      'category_name': 'Ăn uống',
      'category_icon': '🍜',
      'month': '2026-10',
      'repeat_monthly': true,
      'opening_spent': 0,
      'spent': 2000000,
      'remaining': 3000000,
      'usage_pct': 40.0,
      'auto_match': true,
    },
  ],
  'uncategorized_count': 1,
  'unread_alerts': 2,
  'latest_alerts': [
    {
      'id': 10,
      'created_at': '2026-10-14T02:59:05Z',
      'kind': 'tx',
      'level': 'WARNING',
      'title': '⚠️ Sắp chạm mức mục tiêu',
      'message': '−3.500.000đ · VCB ...',
      'read': false,
      'transaction_id': 55,
      'goal_id': null,
    },
  ],
  'ingest_health': {
    'stale': false,
    'error_events': 0,
    'unparsed_events': 0,
    'sources': {
      'sepay': {'last_event_at': '2026-10-14T02:59:00Z'},
      'casso': {'last_event_at': null},
      'email': {'enabled': true, 'last_success_at': '2026-10-14T02:58:00Z', 'last_error': null},
    },
  },
};

Map<String, dynamic> accountJson({int? balance = 6500000, bool derived = false}) => {
  'id': 1,
  'bank': 'VCB',
  'name': 'VCB chính',
  'account_number': '0123456789',
  'last4': '6789',
  'include_in_total': true,
  'confirmed': true,
  'balance': balance,
  'balance_as_of': balance == null ? null : '2026-10-14T02:59:00Z',
  'balance_derived': derived,
  'manual_balance': balance == null ? null : 10000000,
  'manual_balance_at': balance == null ? null : '2026-10-13T17:00:00Z',
};

/// Summary khi chưa biết số dư (UNKNOWN), không có mục tiêu.
Map<String, dynamic> unknownSummaryJson() => {
  ...warningSummaryJson(),
  'level': 'UNKNOWN',
  'level_reason': 'Chưa biết số dư TK VCB chính',
  'balance': null,
  'balance_known': false,
  'balance_as_of': null,
  'free': null,
  'floor': 0,
  'expected_income': null,
  'accounts': [accountJson(balance: null)],
  'goals': <Object>[],
  'uncategorized_count': 0,
  'unread_alerts': 0,
  'latest_alerts': <Object>[],
};

List<Map<String, dynamic>> categoriesJson() => [
  {'id': 1, 'name': 'Ăn uống', 'kind': 'expense', 'icon': '🍜', 'sort_order': 10, 'system_key': 'food'},
  {'id': 2, 'name': 'Thuê trọ', 'kind': 'expense', 'icon': '🏠', 'sort_order': 20, 'system_key': 'rent'},
  {'id': 6, 'name': 'Thu nhập', 'kind': 'income', 'icon': '💰', 'sort_order': 60, 'system_key': 'income'},
  {'id': 8, 'name': 'Chuyển nội bộ', 'kind': 'transfer', 'icon': '↔️', 'sort_order': 80, 'system_key': 'transfer'},
];

/// Phản hồi JSON UTF-8, giống FastAPI (không ghi charset).
http.Response jsonResponse(Object? body, [int status = 200]) => http.Response.bytes(
  body == null ? <int>[] : utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

/// Một request đã ghi lại.
class RecordedRequest {
  RecordedRequest(this.method, this.url, this.headers, this.body);

  final String method;
  final Uri url;
  final Map<String, String> headers;
  final String body;

  dynamic get json => body.isEmpty ? null : jsonDecode(body);
}

/// Máy chủ giả: định tuyến theo "METHOD /path" và ghi lại mọi request.
class FakeServer {
  FakeServer(this.routes);

  /// "GET /api/summary" -> handler. Handler trả `http.Response` hoặc JSON.
  final Map<String, Object? Function(RecordedRequest req)> routes;
  final List<RecordedRequest> requests = [];

  late final MockClient client = MockClient((request) async {
    final rec = RecordedRequest(request.method, request.url, request.headers, request.body);
    requests.add(rec);
    final handler = routes['${request.method} ${request.url.path}'];
    if (handler == null) return jsonResponse({'detail': 'Not Found'}, 404);
    final result = handler(rec);
    if (result is http.Response) return result;
    return jsonResponse(result);
  });

  Iterable<RecordedRequest> where(String method, String path) =>
      requests.where((r) => r.method == method && r.url.path == path);
}

/// Dự báo như ví dụ trong docs/api.md (chạm mức sàn ngày 25/10, còn 11 ngày); `details` đúng như
/// `backend/app/engine/forecast.py::_details` soạn cho các số này (kể cả dòng ngân sách / "Ước tính sơ bộ").
Map<String, dynamic> forecastJson({
  String status = 'ok',
  String confidence = 'normal',
  String? floorHitDate = '2026-10-25',
  int? daysUntilFloorHit = 11,
  String? headline = 'Chi như hiện tại thì khoảng ngày 25/10 sẽ chạm mức sàn',
  int observedDays = 14,
}) => {
  'status': status,
  'confidence': confidence,
  'reason': null,
  'observed_days': observedDays,
  'window_days': observedDays < 14 ? observedDays : 14,
  'daily_spend': 180000,
  'capped_amount': 4000000,
  'capped_count': 1,
  'projected_free_end': -350000,
  'projected_budget_overrun': 1000000,
  'income_pending': 0,
  'floor_hit_date': floorHitDate,
  'days_until_floor_hit': daysUntilFloorHit,
  'recovers_on': null,
  'safe_daily_spend': 120000,
  'headline': headline,
  'details': [
    'Tốc độ chi ngoài mục tiêu: ~180.000đ/ngày (${observedDays < 14 ? observedDays : 14} ngày gần nhất)',
    'Không tính phần vượt của 1 khoản chi lớn (4.000.000đ)',
    'Gợi ý: chi ngoài mục tiêu tối đa ~120.000đ/ngày để giữ trên mức sàn',
    '🍜 Tiền ăn: với tốc độ này sẽ dùng 120% ngân sách — nên chi tối đa ~133.333đ/ngày',
    if (confidence == 'low') 'Ước tính sơ bộ: mới có $observedDays ngày dữ liệu',
  ],
  'budgets': [
    {
      'goal_id': 2,
      'name': 'Tiền ăn',
      'category_icon': '🍜',
      'spent': 2600000,
      'amount': 5000000,
      'daily_rate': 200000,
      'projected_spent': 6000000,
      'projected_pct': 120.0,
      'status': 'over_pace',
      'suggested_daily': 133333,
    },
    {
      'goal_id': 3,
      'name': 'Cà phê',
      'category_icon': '☕',
      'spent': 300000,
      'amount': 1000000,
      'daily_rate': 20000,
      'projected_spent': 650000,
      'projected_pct': 65.0,
      'status': 'on_track',
      'suggested_daily': 40000,
    },
  ],
};

/// [PushService] giả: điều khiển được token, quyền và các luồng thông báo trong test.
class FakePushService implements PushService {
  FakePushService({this.token = 'fcm:token-1', this.permission = PushPermission.granted, this.initOk = true});

  String? token;
  PushPermission permission;
  bool initOk;

  /// Gọi khi [deleteToken] chạy (để kiểm tra thứ tự so với request DELETE).
  void Function()? onDeleteToken;

  /// Token Firebase cấp sau [deleteToken] (FCM tạo token mới ở lần [getToken] sau); `null` = không có.
  String? tokenAfterDelete;

  int initCalls = 0;
  int permissionCalls = 0;
  int deleteTokenCalls = 0;
  bool _available = false;

  final StreamController<String> tokenRefresh = StreamController<String>.broadcast();
  final StreamController<PushMessage> foreground = StreamController<PushMessage>.broadcast();
  final StreamController<PushMessage> opened = StreamController<PushMessage>.broadcast();

  @override
  bool get available => _available;

  @override
  Future<bool> init() async {
    initCalls++;
    _available = initOk;
    return initOk;
  }

  @override
  Future<PushPermission> requestPermission() async {
    permissionCalls++;
    return permission;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => tokenRefresh.stream;

  @override
  Stream<PushMessage> get onForeground => foreground.stream;

  @override
  Stream<PushMessage> get onOpened => opened.stream;

  @override
  Future<void> deleteToken() async {
    onDeleteToken?.call();
    deleteTokenCalls++;
    token = tokenAfterDelete;
  }

  Future<void> close() async {
    await tokenRefresh.close();
    await foreground.close();
    await opened.close();
  }
}
