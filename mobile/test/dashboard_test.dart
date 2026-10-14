import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance/api/api_client.dart';
import 'package:personal_finance/main.dart';
import 'package:personal_finance/screens/connect_screen.dart';
import 'package:personal_finance/screens/goal_form_screen.dart';
import 'package:personal_finance/screens/home_shell.dart';
import 'package:personal_finance/state/app_state.dart';
import 'package:personal_finance/state/connection_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// Màn hình cao để ListView dựng đủ nội dung.
void _useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

FakeServer _server({Map<String, dynamic> Function()? summary}) {
  return FakeServer({
    'GET /health': (_) => {'status': 'ok', 'time': '2026-10-14T03:00:00Z', 'version': '0.1.0'},
    'GET /api/summary': (_) => (summary ?? warningSummaryJson)(),
    'GET /api/categories': (_) => categoriesJson(),
    'POST /api/goals': (req) => jsonResponse({
      ...(req.json as Map<String, dynamic>),
      'id': 99,
      'spent': 0,
      'remaining': (req.json as Map<String, dynamic>)['amount'],
      'usage_pct': 0,
      'auto_match': true,
    }, 201),
    'DELETE /api/goals/1': (_) => http.Response('', 204),
    'PATCH /api/accounts/1': (req) => accountJson(balance: (req.json as Map<String, dynamic>)['balance'] as int),
    'GET /api/transactions': (_) => {'items': <Object>[], 'total': 0},
  });
}

AppState _stateFor(FakeServer server, {DateTime? now}) {
  final state = AppState(
    client: ApiClient(baseUrl: 'https://finance.example.com', token: 'tok', client: server.client),
    refreshInterval: null,
    clock: now == null ? null : () => now,
  );
  addTearDown(state.dispose);
  return state;
}

Future<void> _pumpApp(WidgetTester tester, AppState state) async {
  _useTallScreen(tester);
  await tester.pumpWidget(PersonalFinanceApp(state: state, refreshInterval: null));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('WARNING: banner cam với chữ và lý do, số dư / mức sàn / được tiêu', (tester) async {
    final server = _server();
    await _pumpApp(tester, _stateFor(server, now: DateTime.utc(2026, 10, 14, 3)));

    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.text('Sắp chạm mức mục tiêu'), findsOneWidget);
    expect(find.text('Chỉ còn 500.000đ trên mức sàn 6.000.000đ'), findsOneWidget);
    expect(find.text('6.500.000đ'), findsOneWidget);
    expect(find.text('Mức sàn'), findsOneWidget);
    expect(find.text('6.000.000đ'), findsOneWidget);
    expect(find.text('Được tiêu thoải mái'), findsOneWidget);
    expect(find.text('500.000đ'), findsOneWidget);
    expect(find.textContaining('cập nhật lúc'), findsOneWidget);
    expect(find.textContaining('đã hơn 48 giờ'), findsNothing);
    expect(find.text('ước tính'), findsNothing);

    // Thẻ mục tiêu.
    expect(find.text('Tiền trọ'), findsOneWidget);
    expect(find.text('Quỹ giữ'), findsOneWidget);
    expect(find.text('Ngân sách'), findsOneWidget);
    expect(find.text('Đã chi 2.000.000đ / 5.000.000đ'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));

    // Chip chưa phân loại + cảnh báo gần nhất.
    expect(find.text('1 giao dịch chưa phân loại'), findsOneWidget);
    expect(find.text('⚠️ Sắp chạm mức mục tiêu'), findsOneWidget);

    // Gọi API đúng header.
    expect(server.where('GET', '/api/summary').first.headers['Authorization'], 'Bearer tok');
  });

  testWidgets('số dư cũ hơn 48 giờ và ước tính', (tester) async {
    final server = _server(
      summary: () => {
        ...warningSummaryJson(),
        'accounts': [accountJson(derived: true)],
      },
    );
    await _pumpApp(tester, _stateFor(server, now: DateTime.utc(2026, 10, 17, 3)));

    expect(find.textContaining('đã hơn 48 giờ'), findsOneWidget);
    expect(find.text('ước tính'), findsOneWidget);
  });

  testWidgets('FAB "Thêm mục tiêu" mở form và tạo mục tiêu', (tester) async {
    final server = _server();
    await _pumpApp(tester, _stateFor(server));

    final fab = find.widgetWithText(FloatingActionButton, 'Thêm mục tiêu');
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.byType(GoalFormScreen), findsOneWidget);
    expect(find.text('Tên mục tiêu'), findsOneWidget);
    expect(find.text('Quỹ giữ'), findsOneWidget);
    expect(find.text('Ngân sách chi tiêu'), findsOneWidget);
    expect(find.text('Tháng này (10/2026)'), findsOneWidget);
    expect(find.text('Tháng sau (11/2026)'), findsOneWidget);

    // Lưu khi trống -> thông báo lỗi.
    await tester.tap(find.byKey(const Key('goal_save')));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên mục tiêu'), findsOneWidget);
    expect(find.text('Nhập số tiền'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('goal_name')), 'Quỹ khẩn cấp');
    await tester.enterText(find.byKey(const Key('goal_amount')), '3000000');
    await tester.pump();
    // Định dạng VND khi gõ.
    expect(find.text('3.000.000'), findsOneWidget);

    await tester.tap(find.byKey(const Key('goal_save')));
    await tester.pumpAndSettle();

    final post = server.where('POST', '/api/goals').single;
    expect(post.json, {
      'name': 'Quỹ khẩn cấp',
      'type': 'reserve',
      'amount': 3000000,
      'category_id': null,
      'month': '2026-10',
      'repeat_monthly': true,
      'opening_spent': 0,
    });
    // Quay lại tổng quan và tải lại summary.
    expect(find.byType(GoalFormScreen), findsNothing);
    expect(server.where('GET', '/api/summary').length, greaterThanOrEqualTo(2));
  });

  testWidgets('Ngân sách chi tiêu bắt buộc chọn danh mục', (tester) async {
    final server = _server();
    await _pumpApp(tester, _stateFor(server));
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Thêm mục tiêu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ngân sách chi tiêu'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('goal_name')), 'Tiền ăn');
    await tester.enterText(find.byKey(const Key('goal_amount')), '5000000');
    await tester.tap(find.byKey(const Key('goal_save')));
    await tester.pumpAndSettle();

    expect(find.text('Ngân sách chi tiêu cần chọn danh mục'), findsOneWidget);
    expect(server.where('POST', '/api/goals'), isEmpty);
  });

  testWidgets('sửa mục tiêu: xoá có 2 lựa chọn', (tester) async {
    final server = _server();
    await _pumpApp(tester, _stateFor(server));

    await tester.tap(find.text('Tiền trọ'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa mục tiêu'), findsOneWidget);

    await tester.tap(find.byTooltip('Xoá mục tiêu'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉ xoá tháng này'), findsOneWidget);
    expect(find.text('Xoá và dừng lặp lại'), findsOneWidget);

    await tester.tap(find.text('Xoá và dừng lặp lại'));
    await tester.pumpAndSettle();
    final del = server.where('DELETE', '/api/goals/1').single;
    expect(del.url.queryParameters['stop_series'], 'true');
    expect(find.byType(GoalFormScreen), findsNothing);
  });

  testWidgets('UNKNOWN hiện nút "Nhập số dư" và gửi số dư', (tester) async {
    final server = _server(summary: unknownSummaryJson);
    await _pumpApp(tester, _stateFor(server));

    expect(find.text('Chưa biết số dư'), findsWidgets);
    expect(find.text('Chưa có mục tiêu'), findsOneWidget);
    final button = find.widgetWithText(FilledButton, 'Nhập số dư');
    expect(button, findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Số dư hiện tại'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '10000000');
    await tester.pump();
    expect(find.text('10.000.000'), findsOneWidget);
    await tester.tap(find.text('Lưu số dư'));
    await tester.pumpAndSettle();

    final patch = server.where('PATCH', '/api/accounts/1').single;
    expect(patch.json, {'balance': 10000000});
  });

  testWidgets('mất mạng: banner offline kèm giờ tải thành công gần nhất', (tester) async {
    var fail = false;
    final server = FakeServer({
      'GET /api/summary': (_) {
        if (fail) throw http.ClientException('Network is unreachable');
        return warningSummaryJson();
      },
    });
    final state = _stateFor(server, now: DateTime(2026, 10, 14, 9, 59));
    await _pumpApp(tester, state);
    expect(find.byKey(const Key('offline_banner')), findsNothing);

    fail = true;
    await state.load();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offline_banner')), findsOneWidget);
    expect(find.textContaining('Đang offline'), findsOneWidget);
    expect(find.textContaining('09:59 14/10'), findsOneWidget);
    // Dữ liệu cũ vẫn hiện.
    expect(find.text('Sắp chạm mức mục tiêu'), findsOneWidget);
  });

  testWidgets('chip chưa phân loại mở tab Giao dịch đã lọc', (tester) async {
    final server = _server();
    await _pumpApp(tester, _stateFor(server));

    await tester.tap(find.byKey(const Key('uncategorized_chip')));
    await tester.pumpAndSettle();

    final req = server.where('GET', '/api/transactions').last;
    expect(req.url.queryParameters['uncategorized'], 'true');
    expect(req.url.queryParameters['month'], '2026-10');
    final chip = tester.widget<FilterChip>(find.byKey(const Key('filter_uncategorized')));
    expect(chip.selected, isTrue);
  });

  group('lần đầu chạy', () {
    testWidgets('chưa có URL/token -> màn "Kết nối máy chủ"', (tester) async {
      SharedPreferences.setMockInitialValues({});
      _useTallScreen(tester);
      await tester.pumpWidget(const PersonalFinanceApp(refreshInterval: null));
      await tester.pumpAndSettle();

      expect(find.byType(ConnectScreen), findsOneWidget);
      expect(find.text('Kết nối máy chủ'), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
    });

    testWidgets('mở app khi offline: hiện bản tổng quan đã lưu + banner offline', (tester) async {
      SharedPreferences.setMockInitialValues({
        ConnectionStore.keyBaseUrl: 'https://finance.example.com',
        ConnectionStore.keyToken: 'tok',
        ConnectionStore.keySummaryCache: jsonEncode({
          'base_url': 'https://finance.example.com',
          'loaded_at': DateTime(2026, 10, 14, 8, 30).toUtc().toIso8601String(),
          'summary': warningSummaryJson(),
        }),
      });
      final server = FakeServer({'GET /api/summary': (_) => throw http.ClientException('Network is unreachable')});
      _useTallScreen(tester);
      await tester.pumpWidget(
        PersonalFinanceApp(
          refreshInterval: null,
          clientFactory: (url, token) => ApiClient(baseUrl: url, token: token, client: server.client),
        ),
      );
      await tester.pumpAndSettle();

      expect(server.where('GET', '/api/summary'), isNotEmpty);
      expect(find.text('Sắp chạm mức mục tiêu'), findsOneWidget);
      expect(find.byKey(const Key('offline_banner')), findsOneWidget);
      expect(find.textContaining('08:30 14/10'), findsOneWidget);
    });

    testWidgets('tải thành công thì lưu bản tổng quan cho lần offline sau', (tester) async {
      SharedPreferences.setMockInitialValues({
        ConnectionStore.keyBaseUrl: 'https://finance.example.com',
        ConnectionStore.keyToken: 'tok',
      });
      final server = _server();
      _useTallScreen(tester);
      await tester.pumpWidget(
        PersonalFinanceApp(
          refreshInterval: null,
          clientFactory: (url, token) => ApiClient(baseUrl: url, token: token, client: server.client),
        ),
      );
      await tester.pumpAndSettle();

      final cached = await const ConnectionStore().loadSummary('https://finance.example.com');
      expect(cached, isNotNull);
      expect(cached!.json['level'], 'WARNING');
      expect(await const ConnectionStore().loadSummary('https://other.example.com'), isNull);
    });

    testWidgets('đã lưu URL/token -> vào thẳng tổng quan', (tester) async {
      SharedPreferences.setMockInitialValues({
        ConnectionStore.keyBaseUrl: 'https://finance.example.com',
        ConnectionStore.keyToken: 'tok',
      });
      final server = _server();
      _useTallScreen(tester);
      await tester.pumpWidget(
        PersonalFinanceApp(
          refreshInterval: null,
          clientFactory: (url, token) => ApiClient(baseUrl: url, token: token, client: server.client),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConnectScreen), findsNothing);
      expect(find.text('Sắp chạm mức mục tiêu'), findsOneWidget);
    });

    testWidgets('kết nối: cảnh báo http://, lỗi 401, thành công thì lưu và vào tổng quan', (tester) async {
      var token = 'sai';
      final server = FakeServer({
        'GET /health': (_) => {'status': 'ok'},
        'GET /api/summary': (req) => req.headers['Authorization'] == 'Bearer dung'
            ? warningSummaryJson()
            : jsonResponse({'detail': 'Unauthorized'}, 401),
      });
      _useTallScreen(tester);
      await tester.pumpWidget(
        PersonalFinanceApp(
          refreshInterval: null,
          clientFactory: (url, t) => ApiClient(baseUrl: url, token: t, client: server.client),
        ),
      );
      await tester.pumpAndSettle();

      // URL sai định dạng.
      await tester.enterText(find.byKey(const Key('connect_url')), 'finance.example.com');
      await tester.enterText(find.byKey(const Key('connect_token')), token);
      await tester.tap(find.byKey(const Key('connect_submit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Địa chỉ máy chủ không hợp lệ'), findsOneWidget);
      expect(server.requests, isEmpty);

      // http:// -> cảnh báo token không mã hoá.
      await tester.enterText(find.byKey(const Key('connect_url')), 'http://192.168.1.10:8000');
      await tester.pump();
      expect(find.textContaining('không mã hoá'), findsOneWidget);

      // Sai token.
      await tester.tap(find.byKey(const Key('connect_submit')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sai token'), findsOneWidget);
      expect(find.byType(ConnectScreen), findsOneWidget);

      // Đúng token.
      token = 'dung';
      await tester.enterText(find.byKey(const Key('connect_token')), token);
      await tester.tap(find.byKey(const Key('connect_submit')));
      await tester.pumpAndSettle();

      expect(find.byType(ConnectScreen), findsNothing);
      expect(find.text('Sắp chạm mức mục tiêu'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ConnectionStore.keyBaseUrl), 'http://192.168.1.10:8000');
      expect(prefs.getString(ConnectionStore.keyToken), 'dung');
      expect(server.where('GET', '/health').first.headers.containsKey('Authorization'), isFalse);
    });

    testWidgets('không tới được máy chủ -> thông báo lỗi mạng', (tester) async {
      final server = FakeServer({'GET /health': (_) => throw http.ClientException('Connection refused')});
      _useTallScreen(tester);
      await tester.pumpWidget(
        PersonalFinanceApp(
          refreshInterval: null,
          clientFactory: (url, t) => ApiClient(baseUrl: url, token: t, client: server.client),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('connect_url')), 'https://finance.example.com');
      await tester.enterText(find.byKey(const Key('connect_token')), 'tok');
      await tester.tap(find.byKey(const Key('connect_submit')));
      await tester.pumpAndSettle();
      expect(find.text(ApiMessages.network), findsOneWidget);
    });
  });
}
