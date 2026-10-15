import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance/api/api_client.dart';
import 'package:personal_finance/main.dart';
import 'package:personal_finance/screens/manual_tx_screen.dart';
import 'package:personal_finance/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

Map<String, dynamic> _txJson({
  int id = 55,
  int? categoryId,
  String? categoryName,
  String status = 'active',
  int? duplicateOf,
  bool manual = false,
  String bankTime = '2026-10-14T02:59:00Z',
  String description = 'RUT TIEN ATM',
  String? suggestedRule = 'rut tien atm',
  int? goalId,
  String? goalName,
  String? goalMonth,
}) => {
  'id': id,
  'account_id': 1,
  'account_name': 'VCB chính',
  'bank': 'VCB',
  'direction': 'out',
  'amount': 3500000,
  'bank_time': bankTime,
  'time_precision': 'second',
  'description': description,
  'reference_code': 'FT26287',
  'counter_account': null,
  'counter_name': null,
  'balance_after': 6500000,
  'category_id': categoryId,
  'category_name': categoryName,
  'category_icon': categoryId == null ? null : '🏠',
  'goal_id': goalId,
  'goal_name': goalName,
  'goal_month': goalMonth,
  'suggested_rule': suggestedRule,
  'categorized_by': categoryId == null ? 'none' : 'user',
  'status': status,
  'is_manual': manual,
  'affects_balance': true,
  'pair_id': null,
  'sources': ['sepay', 'email'],
  'possible_duplicate_of': duplicateOf,
};

/// Mục tiêu theo tháng cho GET /api/goals?month=…
Map<String, List<Map<String, dynamic>>> _goalsByMonth() => {
  '2026-09': [
    {
      'id': 201,
      'name': 'Tiền ăn T9',
      'type': 'budget',
      'amount': 4000000,
      'category_id': 1,
      'month': '2026-09',
      'repeat_monthly': true,
      'spent': 0,
    },
  ],
  '2026-10': (warningSummaryJson()['goals'] as List).cast<Map<String, dynamic>>(),
  '2026-11': [
    {
      'id': 300,
      'name': 'Tiền trọ',
      'type': 'reserve',
      'amount': 3000000,
      'category_id': 2,
      'month': '2026-11',
      'repeat_monthly': true,
      'spent': 3000000,
    },
  ],
};

FakeServer _server({Map<String, Object? Function(RecordedRequest req)> extra = const {}}) => FakeServer({
  'GET /api/goals': (req) => _goalsByMonth()[req.url.queryParameters['month']] ?? <Object>[],
  'GET /api/summary': (_) => warningSummaryJson(),
  'GET /api/categories': (_) => categoriesJson(),
  'GET /api/accounts': (_) => [accountJson()],
  'GET /api/transactions': (_) => {
    'items': [
      _txJson(duplicateOf: 54),
      {
        ..._txJson(id: 56, categoryId: 1, categoryName: 'Ăn uống', status: 'pending'),
        'amount': 45000,
        'description': 'GRABFOOD',
      },
    ],
    'total': 2,
  },
  'PATCH /api/transactions/55': (req) => {
    'transaction': _txJson(categoryId: 2, categoryName: 'Thuê trọ'),
    'summary': warningSummaryJson(),
  },
  'POST /api/transactions': (req) => {..._txJson(id: 77, manual: true), ...(req.json as Map<String, dynamic>)},
  'GET /api/alerts': (_) => [
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
    {
      'id': 9,
      'created_at': '2026-10-13T01:00:00Z',
      'kind': 'digest',
      'level': 'OK',
      'title': 'Bản tin sáng',
      'message': 'An toàn',
      'read': true,
      'transaction_id': null,
      'goal_id': null,
    },
  ],
  'POST /api/alerts/read-all': (_) => {'updated': 1},
  'GET /api/settings': (_) => {
    'warning_percent': 10,
    'warning_min_amount': 500000,
    'expected_income_amount': 0,
    'expected_income_day': 0,
    'notify_every_tx': true,
  },
  'PUT /api/settings': (req) => req.json,
  ...extra,
});

Future<(FakeServer, AppState)> _pump(
  WidgetTester tester, {
  // Bố cục điện thoại / máy tính bảng dọc (< 840 dp: NavigationBar); cao để không phải cuộn.
  Size size = const Size(800, 2600),
  Map<String, Object? Function(RecordedRequest req)> extra = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final server = _server(extra: extra);
  final state = AppState(
    client: ApiClient(baseUrl: 'https://finance.example.com', token: 'tok', client: server.client),
    refreshInterval: null,
  );
  addTearDown(state.dispose);
  await tester.pumpWidget(PersonalFinanceApp(state: state, refreshInterval: null));
  await tester.pumpAndSettle();
  return (server, state);
}

Future<void> _goTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Giao dịch: danh sách, huy hiệu, phân loại + nhớ luật', (tester) async {
    final (server, _) = await _pump(tester);
    await _goTab(tester, 'Giao dịch');

    expect(find.text('RUT TIEN ATM'), findsOneWidget);
    expect(find.text('−3.500.000đ'), findsOneWidget);
    expect(find.text('−45.000đ'), findsOneWidget);
    expect(find.text('Chưa phân loại'), findsWidgets);
    expect(find.text('Có thể trùng'), findsOneWidget);
    expect(find.text('Đang chờ khớp'), findsOneWidget);
    expect(find.textContaining('sepay, email'), findsWidgets);
    final amount = tester.widget<Text>(find.text('−3.500.000đ'));
    expect(amount.style?.color, Colors.red.shade700);

    await tester.tap(find.text('RUT TIEN ATM'));
    await tester.pumpAndSettle();
    expect(find.text('Tính cho tháng sau'), findsOneWidget);
    expect(find.text('Loại trừ'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '🏠 Thuê trọ'));
    await tester.pump();
    await tester.tap(find.text('Nhớ luật cho giao dịch tương tự'));
    await tester.pump();
    final pattern = find.widgetWithText(TextField, 'Cụm từ nhận diện');
    expect(pattern, findsOneWidget);
    expect(find.text('rut tien atm'), findsOneWidget);
    await tester.enterText(pattern, 'rut tien');
    await tester.tap(find.text('Lưu danh mục'));
    await tester.pumpAndSettle();

    final patch = server.where('PATCH', '/api/transactions/55').single;
    expect(patch.json, {'category_id': 2, 'remember_rule': true, 'rule_pattern': 'rut tien'});
    expect(find.text('🏠 Thuê trọ'), findsOneWidget);
  });

  testWidgets('Giao dịch: "Tính cho tháng sau" và "Loại trừ" gửi đúng body', (tester) async {
    final (server, _) = await _pump(tester);
    await _goTab(tester, 'Giao dịch');

    await tester.tap(find.text('RUT TIEN ATM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tính cho tháng sau'));
    await tester.pumpAndSettle();
    expect(server.where('PATCH', '/api/transactions/55').last.json, {'for_next_month': true});

    await tester.tap(find.text('RUT TIEN ATM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loại trừ'));
    await tester.pumpAndSettle();
    expect(server.where('PATCH', '/api/transactions/55').last.json, {'excluded': true});
  });

  testWidgets('Nhớ luật: dùng cụm từ server gợi ý; không có thì ô trống và bắt buộc nhập', (tester) async {
    final (server, _) = await _pump(
      tester,
      extra: {
        'GET /api/transactions': (_) => {
          'items': [_txJson(description: 'MBVCB.11223344.556677.NGUYEN VAN A chuyen tien', suggestedRule: null)],
          'total': 1,
        },
        'PATCH /api/transactions/55': (req) => (req.json as Map)['rule_pattern'] == 'mbvcb nguyen van'
            ? jsonResponse({'detail': 'Cụm từ không khớp mô tả giao dịch'}, 400)
            : {'transaction': _txJson(categoryId: 2, categoryName: 'Thuê trọ'), 'summary': warningSummaryJson()},
      },
    );
    await _goTab(tester, 'Giao dịch');
    await tester.tap(find.text('MBVCB.11223344.556677.NGUYEN VAN A chuyen tien'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '🏠 Thuê trọ'));
    await tester.pump();
    await tester.tap(find.text('Nhớ luật cho giao dịch tương tự'));
    await tester.pump();
    final pattern = find.widgetWithText(TextField, 'Cụm từ nhận diện');
    expect(tester.widget<TextField>(pattern).controller!.text, isEmpty);

    await tester.tap(find.text('Lưu danh mục'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập cụm từ (ít nhất 2 ký tự) để nhớ luật'), findsOneWidget);
    expect(server.where('PATCH', '/api/transactions/55'), isEmpty);

    // Server từ chối cụm từ không khớp mô tả → báo lỗi, bảng vẫn mở để sửa.
    await tester.enterText(pattern, 'mbvcb nguyen van');
    await tester.tap(find.text('Lưu danh mục'));
    await tester.pumpAndSettle();
    expect(find.text('Cụm từ không khớp mô tả giao dịch'), findsOneWidget);

    await tester.enterText(pattern, 'nguyen van a chuyen tien');
    await tester.tap(find.text('Lưu danh mục'));
    await tester.pumpAndSettle();
    expect(server.where('PATCH', '/api/transactions/55').last.json, {
      'category_id': 2,
      'remember_rule': true,
      'rule_pattern': 'nguyen van a chuyen tien',
    });
    expect(find.text('Đã phân loại và nhớ luật "nguyen van a chuyen tien"'), findsOneWidget);
  });

  testWidgets('bỏ chọn danh mục thì bỏ "Nhớ luật" và thông báo đúng điều đã gửi', (tester) async {
    final (server, _) = await _pump(
      tester,
      extra: {
        'PATCH /api/transactions/56': (req) => {
          'transaction': {..._txJson(id: 56, status: 'pending'), 'description': 'GRABFOOD'},
          'summary': warningSummaryJson(),
        },
      },
    );
    await _goTab(tester, 'Giao dịch');

    // Giao dịch chưa phân loại: chọn rồi bỏ chọn → không còn gì để lưu.
    await tester.tap(find.text('RUT TIEN ATM'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '🏠 Thuê trọ'));
    await tester.pump();
    await tester.tap(find.text('Nhớ luật cho giao dịch tương tự'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '🏠 Thuê trọ'));
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isFalse);
    expect(find.widgetWithText(TextField, 'Cụm từ nhận diện'), findsNothing);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Bỏ phân loại')).onPressed, isNull);
    await tester.tapAt(const Offset(10, 10)); // đóng bảng
    await tester.pumpAndSettle();

    // Giao dịch đã có danh mục: bỏ chọn rồi lưu → chỉ gửi category_id null.
    await tester.tap(find.text('GRABFOOD'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '🏠 Thuê trọ'));
    await tester.pump();
    await tester.tap(find.text('Nhớ luật cho giao dịch tương tự'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '🏠 Thuê trọ'));
    await tester.pump();
    await tester.tap(find.text('Bỏ phân loại'));
    await tester.pumpAndSettle();

    expect(server.where('PATCH', '/api/transactions/56').single.json, {'category_id': null});
    expect(find.text('Đã bỏ phân loại'), findsOneWidget);
    expect(find.textContaining('nhớ luật'), findsNothing);
  });

  testWidgets('Gán vào mục tiêu: dùng mục tiêu tháng của giao dịch; đã tính cho tháng sau thì hiện rõ', (tester) async {
    final (server, _) = await _pump(
      tester,
      extra: {
        'GET /api/transactions': (_) => {
          'items': [
            _txJson(id: 61, bankTime: '2026-09-20T03:00:00Z', description: 'COM TRUA T9'),
            // 23:30 ngày 30/10 giờ VN = 16:30 UTC.
            _txJson(
              id: 62,
              bankTime: '2026-10-30T16:30:00Z',
              description: 'TRA TIEN TRO T11',
              categoryId: 2,
              categoryName: 'Thuê trọ',
              goalId: 300,
              goalName: 'Tiền trọ',
              goalMonth: '2026-11',
            ),
          ],
          'total': 2,
        },
        'PATCH /api/transactions/61': (req) => {
          'transaction': _txJson(id: 61, bankTime: '2026-09-20T03:00:00Z', description: 'COM TRUA T9'),
          'summary': warningSummaryJson(),
        },
      },
    );
    await _goTab(tester, 'Giao dịch');
    expect(find.text('🎯 Tiền trọ · 11/2026'), findsOneWidget);

    // Giao dịch tháng 9: chỉ có mục tiêu tháng 9.
    await tester.tap(find.text('COM TRUA T9'));
    await tester.pumpAndSettle();
    expect(server.where('GET', '/api/goals').last.url.queryParameters['month'], '2026-09');
    expect(find.text('Mục tiêu tháng 09/2026 · mặc định tự khớp theo danh mục'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tx_goal')));
    await tester.pumpAndSettle();
    expect(find.text('Tiền trọ (Quỹ giữ · 10/2026)'), findsNothing);
    await tester.tap(find.text('Tiền ăn T9 (Ngân sách · 09/2026)').last);
    await tester.pumpAndSettle();
    expect(server.where('PATCH', '/api/transactions/61').single.json, {'goal_id': 201});

    // Đã "Tính cho tháng sau": hiện mục tiêu đang gán thay vì "Tự động", không cho bấm lại.
    await tester.tap(find.text('TRA TIEN TRO T11'));
    await tester.pumpAndSettle();
    expect(server.where('GET', '/api/goals').last.url.queryParameters['month'], '2026-10');
    expect(find.text('Tiền trọ (11/2026)'), findsWidgets);
    expect(find.text('Tự động theo danh mục'), findsNothing);
    expect(find.text('Tính cho tháng sau'), findsNothing);
    expect(find.byKey(const Key('tx_counted_later')), findsOneWidget);
    expect(find.text('Đã tính cho tháng 11/2026'), findsOneWidget);
    expect(server.where('PATCH', '/api/transactions/62'), isEmpty);
  });

  testWidgets('đổi tháng / bộ lọc lỗi thì không giữ danh sách cũ; tải lại lỗi thì báo', (tester) async {
    String? failMonth;
    var failAll = false;
    final (_, _) = await _pump(
      tester,
      extra: {
        'GET /api/transactions': (req) {
          if (failAll || req.url.queryParameters['month'] == failMonth) {
            return jsonResponse({'detail': 'boom'}, 500);
          }
          return {
            'items': [_txJson()],
            'total': 1,
          };
        },
      },
    );
    await _goTab(tester, 'Giao dịch');
    expect(find.text('RUT TIEN ATM'), findsOneWidget);

    failMonth = '2026-09';
    await tester.tap(find.byTooltip('Tháng trước'));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 09/2026'), findsOneWidget);
    expect(find.text('RUT TIEN ATM'), findsNothing);
    expect(find.text('Máy chủ gặp lỗi (500). Thử lại sau.'), findsOneWidget);

    await tester.tap(find.byTooltip('Tháng sau'));
    await tester.pumpAndSettle();
    expect(find.text('RUT TIEN ATM'), findsOneWidget);

    // Tải lại cùng tháng/bộ lọc (quay lại tab) bị lỗi: giữ danh sách nhưng có thông báo.
    failAll = true;
    await _goTab(tester, 'Tổng quan');
    await _goTab(tester, 'Giao dịch');
    expect(find.text('RUT TIEN ATM'), findsOneWidget);
    expect(find.byKey(const Key('tx_reload_error')), findsOneWidget);
    expect(find.textContaining('Không tải lại được'), findsOneWidget);

    // Đổi bộ lọc khi lỗi: không hiện các dòng của bộ lọc cũ.
    await tester.tap(find.byKey(const Key('filter_uncategorized')));
    await tester.pumpAndSettle();
    expect(find.text('RUT TIEN ATM'), findsNothing);
    expect(find.text('Máy chủ gặp lỗi (500). Thử lại sau.'), findsOneWidget);
  });

  testWidgets('chuyển tab giữ tháng, bộ lọc, chữ đang gõ và vẫn tải lại khi quay lại', (tester) async {
    final (server, _) = await _pump(tester);
    await _goTab(tester, 'Giao dịch');
    await tester.tap(find.byTooltip('Tháng trước'));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 09/2026'), findsOneWidget);
    final txLoads = server.where('GET', '/api/transactions').length;

    await _goTab(tester, 'Tổng quan');
    await _goTab(tester, 'Giao dịch');
    expect(find.text('Tháng 09/2026'), findsOneWidget);
    expect(server.where('GET', '/api/transactions').length, txLoads + 1);
    expect(server.where('GET', '/api/transactions').last.url.queryParameters['month'], '2026-09');

    // Cài đặt: chữ chưa lưu vẫn còn; danh sách tài khoản được tải lại.
    await _goTab(tester, 'Cài đặt');
    await tester.enterText(find.byKey(const Key('settings_warning_percent')), '15');
    await _goTab(tester, 'Cảnh báo');
    await _goTab(tester, 'Cài đặt');
    expect(find.widgetWithText(TextFormField, '15'), findsOneWidget);
    expect(server.where('GET', '/api/accounts'), hasLength(2));
    expect(server.where('GET', '/api/settings'), hasLength(1));

    // Cảnh báo tải lại mỗi lần quay lại.
    await _goTab(tester, 'Cảnh báo');
    expect(server.where('GET', '/api/alerts'), hasLength(2));

    // Chip "chưa phân loại" ở Tổng quan: về tháng hiện tại + bật bộ lọc, không dựng lại màn hình.
    await _goTab(tester, 'Tổng quan');
    await tester.tap(find.byKey(const Key('uncategorized_chip')));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 10/2026'), findsOneWidget);
    expect(tester.widget<FilterChip>(find.byKey(const Key('filter_uncategorized'))).selected, isTrue);
    final last = server.where('GET', '/api/transactions').last.url.queryParameters;
    expect(last['month'], '2026-10');
    expect(last['uncategorized'], 'true');
  });

  testWidgets('Sửa TK chưa xác nhận: bật "Tính vào tổng" thì xác nhận luôn', (tester) async {
    final unconfirmed = {
      ...accountJson(),
      'id': 2,
      'bank': 'MB',
      'name': 'MB lạ',
      'account_number': '999988887777',
      'last4': '7777',
      'include_in_total': false,
      'confirmed': false,
    };
    final (server, _) = await _pump(
      tester,
      extra: {
        'GET /api/accounts': (_) => [accountJson(), unconfirmed],
        'PATCH /api/accounts/2': (req) => {...unconfirmed, ...(req.json as Map<String, dynamic>)},
      },
    );
    await _goTab(tester, 'Cài đặt');
    expect(find.textContaining('không tính vào tổng'), findsOneWidget);
    await tester.tap(find.text('MB lạ · …7777'));
    await tester.pumpAndSettle();

    bool confirmed() =>
        tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Xác nhận TK mới')).value!;
    bool included() => tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Tính vào tổng số dư')).value;
    expect(confirmed(), isFalse);
    expect(included(), isFalse);

    await tester.tap(find.text('Tính vào tổng số dư'));
    await tester.pump();
    expect(included(), isTrue);
    expect(confirmed(), isTrue);

    // Bỏ xác nhận thì không tính vào tổng được.
    await tester.tap(find.text('Xác nhận TK mới'));
    await tester.pump();
    expect(confirmed(), isFalse);
    expect(included(), isFalse);

    await tester.tap(find.text('Tính vào tổng số dư'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    final body = server.where('PATCH', '/api/accounts/2').single.json as Map<String, dynamic>;
    expect(body['include_in_total'], isTrue);
    expect(body['confirmed'], isTrue);
  });

  testWidgets('Thêm giao dịch nhập tay: có ghi chú ATM và gửi POST', (tester) async {
    final (server, _) = await _pump(tester);
    await _goTab(tester, 'Giao dịch');

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Thêm giao dịch'));
    await tester.pumpAndSettle();
    expect(find.byType(ManualTxScreen), findsOneWidget);
    expect(find.textContaining('Đã phân loại khoản rút ATM thì không nhập lại'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Số tiền'), '50000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mô tả'), 'Bánh mì');
    await tester.tap(find.text('Lưu giao dịch'));
    await tester.pumpAndSettle();

    final post = server.where('POST', '/api/transactions').single.json as Map<String, dynamic>;
    expect(post['direction'], 'out');
    expect(post['amount'], 50000);
    expect(post['description'], 'Bánh mì');
    expect(post['account_id'], isNull);
    expect(post['affects_balance'], isFalse);
    expect(post['bank_time'], endsWith('Z'));
    expect(find.byType(ManualTxScreen), findsNothing);
  });

  testWidgets('Cảnh báo: lịch sử và đọc hết', (tester) async {
    final (server, _) = await _pump(tester);
    await _goTab(tester, 'Cảnh báo');

    expect(find.text('Bản tin sáng'), findsOneWidget);
    expect(find.text('⚠️ Sắp chạm mức mục tiêu'), findsOneWidget);
    await tester.tap(find.text('Đọc hết'));
    await tester.pumpAndSettle();
    expect(server.where('POST', '/api/alerts/read-all'), hasLength(1));
  });

  testWidgets('Cài đặt: tài khoản và lưu ngưỡng / lương dự kiến', (tester) async {
    final (server, _) = await _pump(tester);
    await _goTab(tester, 'Cài đặt');

    expect(find.text('https://finance.example.com'), findsOneWidget);
    expect(find.textContaining('VCB chính'), findsOneWidget);
    expect(find.text('Thêm tài khoản'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('settings_warning_percent')), '15');
    await tester.enterText(find.byKey(const Key('settings_income_amount')), '15000000');
    await tester.tap(find.byKey(const Key('settings_save')));
    await tester.pumpAndSettle();
    // Có lương mà chưa có ngày -> báo lỗi, chưa gửi.
    expect(find.text('Ngày 1–31'), findsOneWidget);
    expect(server.where('PUT', '/api/settings'), isEmpty);

    await tester.enterText(find.byKey(const Key('settings_income_day')), '5');
    await tester.tap(find.byKey(const Key('settings_save')));
    await tester.pumpAndSettle();
    expect(server.where('PUT', '/api/settings').single.json, {
      'warning_percent': 15,
      'warning_min_amount': 500000,
      'expected_income_amount': 15000000,
      'expected_income_day': 5,
      'notify_every_tx': true,
    });
  });

  testWidgets('Cài đặt: form thêm tài khoản có VCB/MB/Khác và xác nhận', (tester) async {
    final (_, _) = await _pump(tester);
    await _goTab(tester, 'Cài đặt');
    await tester.tap(find.text('Thêm tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Số tài khoản'), findsOneWidget);
    expect(find.text('Tên gợi nhớ'), findsOneWidget);
    expect(find.text('Tính vào tổng số dư'), findsOneWidget);
    expect(find.text('Số dư hiện tại'), findsOneWidget);
    await tester.tap(find.text('Vietcombank (VCB)'));
    await tester.pumpAndSettle();
    expect(find.text('MB Bank'), findsWidgets);
    expect(find.text('Khác'), findsWidgets);
  });

  testWidgets('màn hẹp 360dp không bị tràn bố cục', (tester) async {
    await _pump(tester, size: const Size(360, 740));
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Thêm mục tiêu'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pumpAndSettle();
    // pageBack() tìm tooltip "Back" tiếng Anh; app dùng tiếng Việt nên bấm BackButton trực tiếp.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    for (final tab in ['Giao dịch', 'Cảnh báo', 'Cài đặt', 'Tổng quan']) {
      await _goTab(tester, tab);
    }
    // Tổng quan: cuộn tới cuối.
    await tester.drag(find.byType(ListView).last, const Offset(0, -2000));
    await tester.pumpAndSettle();

    await _goTab(tester, 'Giao dịch');
    await tester.tap(find.text('RUT TIEN ATM'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '🏠 Thuê trọ'));
    await tester.tap(find.text('Nhớ luật cho giao dịch tương tự'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // đóng bảng
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Thêm giao dịch'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -2000));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await _goTab(tester, 'Cài đặt');
    await tester.drag(find.byType(ListView).last, const Offset(0, -3000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, 3000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Số tài khoản'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
