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

  testWidgets('WARNING: status hero (tiêu đề, số được tiêu, ý nghĩa, chú giải), cần xem, mục tiêu, tài khoản', (
    tester,
  ) async {
    final server = _server();
    await _pumpApp(tester, _stateFor(server, now: DateTime.utc(2026, 10, 14, 3)));

    expect(find.byType(HomeShell), findsOneWidget);
    // Hero: tiêu đề trạng thái, số "được tiêu" lớn, dòng ý nghĩa thay cho lý do của máy chủ.
    expect(find.text('Sắp chạm mức mục tiêu'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('status_hero_free')), matching: find.text('500.000đ')), findsOne);
    expect(find.text('dưới vùng đệm 600.000đ · còn 18 ngày'), findsOneWidget);
    expect(find.text('Chỉ còn 500.000đ trên mức sàn 6.000.000đ'), findsNothing);
    expect(find.byKey(const Key('floor_ruler')), findsOneWidget);
    // Chú giải: mức sàn và tổng số dư (không còn số dư là số lớn nhất).
    expect(find.text('Giữ cho mục tiêu'), findsOneWidget);
    expect(find.text('6.000.000đ'), findsOneWidget);
    expect(find.text('Số dư'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('total_balance')), matching: find.text('6.500.000đ')), findsOne);
    // Giờ cập nhật theo giờ Việt Nam (02:59Z = 09:59 ICT).
    expect(find.text('Cập nhật lúc 09:59'), findsOneWidget);
    expect(find.textContaining('Số dư chưa cập nhật'), findsNothing);
    expect(find.text('Số dư · ước tính'), findsNothing);

    // Cần bạn xem: hàng chưa phân loại.
    expect(find.text('Cần bạn xem'), findsOneWidget);
    expect(find.text('1 giao dịch chưa phân loại'), findsOneWidget);

    // Mục tiêu: hàng trong một nhóm, thanh 6 dp, chú thích tiến độ.
    expect(find.text('Mục tiêu tháng 10'), findsOneWidget);
    expect(find.text('Tiền trọ'), findsOneWidget);
    expect(find.textContaining('Quỹ giữ · 🏠 Thuê trọ'), findsOneWidget);
    expect(find.textContaining('Ngân sách · 🍜 Ăn uống'), findsOneWidget);
    expect(find.text('Đã chi 2.000.000đ / 5.000.000đ · 40%'), findsOneWidget);
    expect(find.byKey(const ValueKey('goal_progress_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('goal_progress_2')), findsOneWidget);

    // Tài khoản (gọn, cùng hàng với Cài đặt). Không còn "Cảnh báo gần đây".
    expect(find.text('VCB chính ··6789'), findsOneWidget);
    expect(find.text('⚠️ Sắp chạm mức mục tiêu'), findsNothing);

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

    expect(find.text('Số dư chưa cập nhật 3 ngày'), findsOneWidget);
    expect(find.text('Số dư · ước tính'), findsOneWidget);
    expect(find.text('Vietcombank · cập nhật 09:59 14/10 · ước tính'), findsOneWidget);
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
    // Loại mục tiêu trước, nhãn ngắn; tháng là "Tháng 10" / "Tháng 11".
    expect(find.text('Loại mục tiêu'), findsOneWidget);
    expect(find.text('Quỹ giữ'), findsOneWidget);
    expect(find.text('Ngân sách'), findsOneWidget);
    expect(find.text('Tháng 10'), findsOneWidget);
    expect(find.text('Tháng 11'), findsOneWidget);

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

    await tester.tap(find.text('Ngân sách'));
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
    expect(find.text('Nhập số dư hiện tại của VCB chính ··6789 để app tính được phần được tiêu.'), findsOneWidget);
    expect(find.text('Chưa có mục tiêu tháng 10'), findsOneWidget);
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
    // 02:59 UTC = 09:59 giờ Việt Nam: giờ hiện theo ICT, không theo múi giờ của máy.
    final state = _stateFor(server, now: DateTime.utc(2026, 10, 14, 2, 59));
    await _pumpApp(tester, state);
    expect(find.byKey(const Key('offline_banner')), findsNothing);

    fail = true;
    await state.load();
    await tester.pumpAndSettle();

    // Dải trung tính (không đỏ) + dòng offline trong hero.
    expect(find.byKey(const Key('offline_banner')), findsOneWidget);
    expect(find.text('Đang offline, không kết nối được máy chủ'), findsOneWidget);
    expect(find.text('Đang hiện số liệu tải lúc 09:59 14/10.'), findsOneWidget);
    expect(find.text('Đang offline · số liệu lúc 09:59'), findsOneWidget);
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

  testWidgets('nguồn dữ liệu: hiện nguyên văn cảnh báo của server, không còn câu "48 giờ" cố định', (tester) async {
    const warnings = [
      'Đọc email ngân hàng đang lỗi từ 08:00 14/10.',
      'Chưa nhận webhook SePay nào trong 48 giờ qua.',
      '3 email chưa đọc được nội dung.',
    ];
    final server = _server(
      summary: () => {
        ...warningSummaryJson(),
        'ingest_health': {
          'stale': true,
          'warnings': warnings,
          'error_events': 0,
          'unparsed_events': 3,
          'sources': <String, Object>{},
        },
      },
    );
    await _pumpApp(tester, _stateFor(server));

    final note = find.descendant(of: find.byKey(const Key('ingest_health_note')), matching: find.byType(Text));
    expect(tester.widget<Text>(note).data, warnings.join('\n'));
  });

  testWidgets('nguồn dữ liệu: server cũ (stale, chưa có warnings) không báo sai "48 giờ"', (tester) async {
    final server = _server(
      summary: () => {
        ...warningSummaryJson(),
        'ingest_health': {'stale': true, 'error_events': 0, 'unparsed_events': 2},
      },
    );
    await _pumpApp(tester, _stateFor(server));

    final note = find.descendant(of: find.byKey(const Key('ingest_health_note')), matching: find.byType(Text));
    final text = tester.widget<Text>(note).data!;
    expect(text, contains('Nguồn dữ liệu ngân hàng đang gặp sự cố'));
    expect(text, contains('2 email chưa đọc được nội dung.'));
    expect(text, isNot(contains('48 giờ')));
  });

  testWidgets('mục tiêu tháng sau: tạo được, hiện trên Tổng quan và chạm để sửa', (tester) async {
    final nextGoals = <Map<String, dynamic>>[];
    final server = _server();
    server.routes['GET /api/goals'] = (req) =>
        req.url.queryParameters['month'] == '2026-11' ? nextGoals : warningSummaryJson()['goals'];
    server.routes['POST /api/goals'] = (req) {
      final goal = {
        ...(req.json as Map<String, dynamic>),
        'id': 300,
        'category_name': 'Thuê trọ',
        'category_icon': '🏠',
        'spent': 0,
        'auto_match': true,
      };
      nextGoals.add(goal);
      return jsonResponse(goal, 201);
    };
    await _pumpApp(tester, _stateFor(server));

    expect(server.where('GET', '/api/goals').last.url.queryParameters['month'], '2026-11');
    expect(find.textContaining('mục tiêu đã tạo trước'), findsNothing);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Thêm mục tiêu'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('goal_name')), 'Tiền trọ');
    await tester.enterText(find.byKey(const Key('goal_amount')), '3500000');
    await tester.tap(find.byKey(const ValueKey('goal_category_reserve')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🏠 Thuê trọ').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('goal_series_hint')), findsNothing);
    await tester.tap(find.text('Tháng 11'));
    await tester.pumpAndSettle();
    // Tháng này đã có "Tiền trọ" lặp lại cùng danh mục → báo sẽ cập nhật chuỗi đó.
    expect(find.byKey(const Key('goal_series_hint')), findsOneWidget);

    await tester.tap(find.byKey(const Key('goal_save')));
    await tester.pumpAndSettle();
    expect((server.where('POST', '/api/goals').single.json as Map)['month'], '2026-11');
    expect(find.text('Đã tạo mục tiêu cho tháng 11'), findsOneWidget);

    // Một hàng thu gọn "Tháng 11 · 1 mục tiêu đã tạo trước"; chạm để mở danh sách.
    final section = find.byKey(const Key('next_month_goals'));
    await tester.ensureVisible(section);
    expect(find.descendant(of: section, matching: find.text('3.500.000đ')), findsNothing);
    await tester.tap(find.text('Tháng 11 · 1 mục tiêu đã tạo trước'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: section, matching: find.text('3.500.000đ')), findsOneWidget);

    await tester.tap(find.descendant(of: section, matching: find.text('Tiền trọ')));
    await tester.pumpAndSettle();
    expect(find.text('Sửa mục tiêu'), findsOneWidget);
    expect(find.text('Tháng 11/2026'), findsOneWidget);
    expect(find.text('3.500.000'), findsOneWidget);
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
          // 01:30 UTC = 08:30 giờ Việt Nam.
          'loaded_at': DateTime.utc(2026, 10, 14, 1, 30).toIso8601String(),
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
      expect(find.text('Đang hiện số liệu tải lúc 08:30 14/10.'), findsOneWidget);
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
      // Bước token lỗi: lỗi nằm dưới bước đó.
      expect(
        tester.getRect(find.byKey(const Key('connect_error'))).top,
        greaterThan(tester.getRect(find.text('Token hợp lệ (/api/summary)')).bottom),
      );

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
      // Lỗi nằm ngay dưới bước bị lỗi (/health), phía trên bước token chưa chạy.
      final error = tester.getRect(find.byKey(const Key('connect_error')));
      expect(error.top, greaterThan(tester.getRect(find.text('Máy chủ phản hồi (/health)')).bottom));
      expect(error.bottom, lessThan(tester.getRect(find.text('Token hợp lệ (/api/summary)')).top));
    });
  });
}
