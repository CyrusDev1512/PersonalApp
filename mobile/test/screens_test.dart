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
}) => {
  'id': id,
  'account_id': 1,
  'account_name': 'VCB chính',
  'bank': 'VCB',
  'direction': 'out',
  'amount': 3500000,
  'bank_time': '2026-10-14T02:59:00Z',
  'time_precision': 'second',
  'description': 'RUT TIEN ATM',
  'reference_code': 'FT26287',
  'counter_account': null,
  'counter_name': null,
  'balance_after': 6500000,
  'category_id': categoryId,
  'category_name': categoryName,
  'category_icon': categoryId == null ? null : '🏠',
  'goal_id': null,
  'goal_name': null,
  'categorized_by': categoryId == null ? 'none' : 'user',
  'status': status,
  'is_manual': manual,
  'affects_balance': true,
  'pair_id': null,
  'sources': ['sepay', 'email'],
  'possible_duplicate_of': duplicateOf,
};

FakeServer _server() => FakeServer({
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
});

Future<(FakeServer, AppState)> _pump(WidgetTester tester, {Size size = const Size(1080, 2600)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final server = _server();
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
    expect(server.requests.last.json, {'for_next_month': true});

    await tester.tap(find.text('RUT TIEN ATM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loại trừ'));
    await tester.pumpAndSettle();
    expect(server.requests.last.json, {'excluded': true});
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
