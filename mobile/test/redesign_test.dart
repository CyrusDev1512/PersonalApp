// Hành vi mới của bản thiết kế lại "Bát men lam": nhóm ngày + tổng chi, bộ lọc "Chưa đọc", SnackBar thông báo
// đẩy gọn, giờ Việt Nam (ICT), công tắc Telegram lưu ngay, đọc màn hình, chữ 200% ở 360×780 không tràn.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance/api/api_client.dart';
import 'package:personal_finance/main.dart';
import 'package:personal_finance/push/push_service.dart';
import 'package:personal_finance/screens/goal_form_screen.dart';
import 'package:personal_finance/screens/settings_screen.dart';
import 'package:personal_finance/screens/tx_action_sheet.dart';
import 'package:personal_finance/state/app_state.dart';
import 'package:personal_finance/theme/typography.dart';
import 'package:personal_finance/utils/dates.dart';
import 'package:personal_finance/utils/text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// 05:00 UTC ngày 14/10/2026 = 12:00 giờ Việt Nam (Thứ Tư).
final DateTime _now = DateTime.utc(2026, 10, 14, 5);

Map<String, dynamic> _tx(
  int id,
  String bankTime, {
  String direction = 'out',
  int amount = 100000,
  String status = 'active',
  String description = 'GIAO DICH',
  int? categoryId,
  String? categoryName,
}) => {
  'id': id,
  'account_id': 1,
  'account_name': 'VCB chính',
  'bank': 'VCB',
  'direction': direction,
  'amount': amount,
  'bank_time': bankTime,
  'description': description,
  'balance_after': 6500000,
  'category_id': categoryId,
  'category_name': categoryName,
  'category_icon': null,
  'goal_id': null,
  'goal_name': null,
  'goal_month': null,
  'suggested_rule': null,
  'categorized_by': categoryId == null ? 'none' : 'user',
  'status': status,
  'is_manual': false,
  'affects_balance': true,
  'pair_id': null,
  'sources': ['sepay'],
  'possible_duplicate_of': null,
};

Map<String, dynamic> _alert(int id, String createdAt, {required bool read, String title = 'Bản tin sáng'}) => {
  'id': id,
  'created_at': createdAt,
  'kind': id == 10 ? 'tx' : 'digest',
  'level': id == 10 ? 'WARNING' : 'OK',
  'title': title,
  'message': id == 10 ? '−3.500.000đ · VCB chính\nDòng thứ hai' : 'An toàn',
  'read': read,
  'transaction_id': id == 10 ? 55 : null,
  'goal_id': null,
};

FakeServer _server({Map<String, Object? Function(RecordedRequest req)> extra = const {}}) => FakeServer({
  'GET /api/summary': (_) => {...warningSummaryJson(), 'forecast': forecastJson()},
  'GET /api/goals': (_) => <Object>[],
  'GET /api/categories': (_) => categoriesJson(),
  'GET /api/accounts': (_) => [accountJson()],
  'GET /api/transactions': (_) => {
    'items': [
      _tx(55, '2026-10-14T02:59:00Z', amount: 3500000, description: 'RUT TIEN ATM'),
      _tx(56, '2026-10-14T01:00:00Z', amount: 45000, description: 'GRABFOOD', categoryId: 1, categoryName: 'Ăn uống'),
      _tx(57, '2026-10-14T00:30:00Z', direction: 'in', amount: 1000000, description: 'NHAN TIEN'),
      // 16:30 UTC 13/10 = 23:30 ngày 13/10 giờ Việt Nam (máy ở múi UTC sẽ nhầm sang ngày khác nếu dùng giờ máy).
      _tx(58, '2026-10-13T16:30:00Z', amount: 200000, status: 'excluded', description: 'DA LOAI TRU'),
      _tx(59, '2026-10-13T10:00:00Z', amount: 120000, description: 'CAFE'),
      _tx(60, '2026-10-12T03:00:00Z', amount: 50000, status: 'pending', description: 'EMAIL CHO KHOP'),
    ],
    'total': 6,
  },
  'GET /api/transactions/55': (_) => _tx(55, '2026-10-14T02:59:00Z', amount: 3500000, description: 'RUT TIEN ATM'),
  'GET /api/alerts': (req) {
    final unread = req.url.queryParameters['unread'] == 'true';
    return [
      _alert(10, '2026-10-14T02:59:05Z', read: false, title: '⚠️ Sắp chạm mức mục tiêu'),
      if (!unread) _alert(9, '2026-10-13T01:00:00Z', read: true),
    ];
  },
  'POST /api/alerts/10/read': (_) => _alert(10, '2026-10-14T02:59:05Z', read: true, title: '⚠️ Sắp chạm mức mục tiêu'),
  'GET /api/settings': (_) => {
    'warning_percent': 10,
    'warning_min_amount': 500000,
    'expected_income_amount': 0,
    'expected_income_day': 0,
    'notify_every_tx': true,
  },
  'POST /api/devices': (_) => {
    'id': 3,
    'platform': 'android',
    'app_version': '1.0.0',
    'last_seen_at': '2026-10-14T03:00:00Z',
    'push_enabled': true,
  },
  'GET /api/devices': (_) => {'push_enabled': true, 'error': null, 'devices': <Object>[]},
  ...extra,
});

Future<(FakeServer, AppState)> _pump(
  WidgetTester tester, {
  Size size = const Size(800, 2600),
  Map<String, Object? Function(RecordedRequest req)> extra = const {},
  PushService? push,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final server = _server(extra: extra);
  final state = AppState(
    client: ApiClient(baseUrl: 'https://finance.example.com', token: 'tok', client: server.client),
    refreshInterval: null,
    clock: () => _now,
  );
  addTearDown(state.dispose);
  await tester.pumpWidget(PersonalFinanceApp(state: state, refreshInterval: null, push: push));
  await tester.pumpAndSettle();
  return (server, state);
}

Future<void> _goTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

/// Font thật (Be Vietnam Pro) cho các phép đo bề rộng chữ 200%: font thử nghiệm mặc định rộng gần gấp đôi.
Future<void> _loadAppFonts() async {
  final loader = FontLoader(appFontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    final bytes = File('assets/fonts/BeVietnamPro-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  }
  await loader.load();
}

/// Kéo danh sách cuộn [scrollable] xuống từng đoạn tới cuối, rồi lên lại đầu (dựng hết các hàng).
Future<void> _scrollThrough(WidgetTester tester, Finder scrollable) async {
  for (var i = 0; i < 12; i++) {
    await tester.drag(scrollable, const Offset(0, -500));
    await tester.pumpAndSettle();
  }
  await tester.drag(scrollable, const Offset(0, 8000));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
    await _loadAppFonts();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('giờ Việt Nam (ICT) và tiêu đề', () {
    test('giờ hiện theo ICT dù máy ở múi giờ khác', () {
      // 02:59 UTC = 09:59 ICT; 17:30 UTC 13/10 = 00:30 ngày 14/10 ICT.
      expect(formatTimeIct(DateTime.utc(2026, 10, 14, 2, 59)), '09:59');
      expect(formatTimeIct(DateTime.utc(2026, 10, 13, 17, 30)), '00:30');
      expect(dayKeyIct(DateTime.utc(2026, 10, 13, 17, 30)), '2026-10-14');
      expect(formatShortDateTimeIct(DateTime.utc(2026, 10, 13, 17, 30)), '00:30 14/10');
      expect(formatLongDateTimeIct(DateTime.utc(2026, 10, 14, 7, 32)), '14:32, Thứ Tư 14/10/2026');
    });

    test('tiêu đề nhóm ngày: Hôm nay, Hôm qua, thứ + ngày (thêm năm khi khác năm)', () {
      expect(dayHeadingIct(DateTime.utc(2026, 10, 14, 1), _now), 'Hôm nay');
      expect(dayHeadingIct(DateTime.utc(2026, 10, 13, 16, 30), _now), 'Hôm qua');
      expect(dayHeadingIct(DateTime.utc(2026, 10, 12, 3), _now), 'Thứ Hai, 12/10');
      expect(dayHeadingIct(DateTime.utc(2025, 12, 31, 3), _now), 'Thứ Tư, 31/12/2025');
      expect(monthShortLabel('2026-11', _now), 'Tháng 11');
      expect(monthShortLabel('2027-01', _now), 'Tháng 1/2027');
    });

    test('bỏ emoji đầu tiêu đề cảnh báo của máy chủ, giữ chữ và emoji giữa câu', () {
      expect(stripLeadingEmoji('⚠️ Sắp chạm mức mục tiêu'), 'Sắp chạm mức mục tiêu');
      expect(stripLeadingEmoji('✅ An toàn trở lại'), 'An toàn trở lại');
      expect(stripLeadingEmoji('🔴 Đã lấn vào tiền mục tiêu'), 'Đã lấn vào tiền mục tiêu');
      expect(stripLeadingEmoji('📊 Ngân sách sắp hết'), 'Ngân sách sắp hết');
      expect(stripLeadingEmoji('☀️ Bản tin tài chính 14/10'), 'Bản tin tài chính 14/10');
      expect(stripLeadingEmoji('❔ Chưa biết số dư'), 'Chưa biết số dư');
      expect(stripLeadingEmoji('Bản tin sáng'), 'Bản tin sáng');
      expect(stripLeadingEmoji('Ăn uống 🍜 hôm nay'), 'Ăn uống 🍜 hôm nay');
      expect(stripLeadingEmoji('⚠️'), '⚠️');
    });
  });

  testWidgets('Giao dịch: nhóm theo ngày (giờ Việt Nam) với tổng chi trong ngày', (tester) async {
    await _pump(tester);
    await _goTab(tester, 'Giao dịch');

    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Hôm qua'), findsOneWidget);
    expect(find.text('Thứ Hai, 12/10'), findsOneWidget);
    // Hôm nay: chỉ khoản chi đang tính (3.500.000 + 45.000), không tính khoản thu.
    expect(
      find.descendant(of: find.byKey(const ValueKey('day_total_2026-10-14')), matching: find.text('Đã chi 3.545.000đ')),
      findsOneWidget,
    );
    // Hôm qua: khoản đã loại trừ không tính.
    expect(
      find.descendant(of: find.byKey(const ValueKey('day_total_2026-10-13')), matching: find.text('Đã chi 120.000đ')),
      findsOneWidget,
    );
    // Ngày chỉ có khoản đang chờ khớp: không có tổng.
    expect(find.byKey(const ValueKey('day_total_2026-10-12')), findsNothing);
    // 23:30 ngày 13/10 giờ Việt Nam nằm trong nhóm "Hôm qua", giờ ICT trong dòng phụ.
    expect(find.text('VCB chính · 23:30 · SePay · Đã loại trừ'), findsOneWidget);
    final yesterday = tester.getRect(find.text('Hôm qua'));
    expect(tester.getRect(find.text('DA LOAI TRU')).top, greaterThan(yesterday.bottom));
    expect(tester.getRect(find.text('DA LOAI TRU')).bottom, lessThan(tester.getRect(find.text('Thứ Hai, 12/10')).top));
  });

  testWidgets('Cảnh báo: bộ lọc "Chưa đọc" gọi ?unread=true; bảng chi tiết mở giao dịch', (tester) async {
    final (server, _) = await _pump(tester);
    await _goTab(tester, 'Cảnh báo');

    expect(server.where('GET', '/api/alerts').last.url.queryParameters['unread'], 'false');
    expect(find.text('Sắp chạm mức mục tiêu'), findsOneWidget);
    expect(find.text('Bản tin sáng'), findsOneWidget);
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Hôm qua'), findsOneWidget);
    // Giờ ICT; chấm "chưa đọc" chỉ ở cảnh báo chưa đọc.
    expect(find.text('09:59'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.byKey(const ValueKey('alert_unread_10')), findsOneWidget);
    expect(find.byKey(const ValueKey('alert_unread_9')), findsNothing);

    await tester.tap(find.text('Chưa đọc · 2'));
    await tester.pumpAndSettle();
    expect(server.where('GET', '/api/alerts').last.url.queryParameters['unread'], 'true');
    expect(find.text('Sắp chạm mức mục tiêu'), findsOneWidget);
    expect(find.text('Bản tin sáng'), findsNothing);

    // Mở cảnh báo: đánh dấu đã đọc; giao dịch còn chưa phân loại nên nút nói đúng việc: "Phân loại giao dịch".
    await tester.tap(find.text('Sắp chạm mức mục tiêu'));
    await tester.pumpAndSettle();
    expect(server.where('POST', '/api/alerts/10/read'), hasLength(1));
    expect(find.text('09:59, Thứ Tư 14/10/2026'), findsOneWidget);
    expect(find.text('Xem giao dịch'), findsNothing);
    await tester.tap(find.text('Phân loại giao dịch'));
    await tester.pumpAndSettle();
    // Giao dịch tải sẵn khi mở bảng, dùng lại khi bấm (không tải hai lần).
    expect(server.where('GET', '/api/transactions/55'), hasLength(1));
    expect(find.byType(TxActionSheet), findsOneWidget);
  });

  testWidgets('Cảnh báo: nội dung bỏ emoji đầu dòng và lệnh bot; bản tin nhắc chưa phân loại mở Giao dịch đã lọc', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    const digest =
        '✅ An toàn — Còn 4.000.000đ được tiêu\n'
        '• 🏠 Tiền trọ (quỹ giữ): 0đ/3.000.000đ · còn cần 3.000.000đ\n'
        '📈 Dự báo: Chi như hiện tại thì cuối tháng vẫn trên mức sàn\n'
        '   🍜 Tiền ăn: theo nhịp này sẽ vượt ~200.000đ\n'
        '🏷️ 2 giao dịch chưa phân loại — gõ /uncat để phân loại.';
    final (server, _) = await _pump(
      tester,
      extra: {
        'GET /api/alerts': (_) => [
          {..._alert(9, '2026-10-14T01:00:00Z', read: true, title: '☀️ Bản tin tài chính 14/10'), 'message': digest},
        ],
      },
    );
    await _goTab(tester, 'Cảnh báo');
    expect(find.textContaining('✅'), findsNothing);
    expect(find.textContaining('An toàn — Còn 4.000.000đ được tiêu'), findsOneWidget);

    await tester.tap(find.text('Bản tin tài chính 14/10'));
    await tester.pumpAndSettle();
    final body = tester.widget<SelectableText>(find.byType(SelectableText)).data!;
    expect(body, isNot(contains('/uncat')));
    expect(body, isNot(contains('📈')));
    expect(body, isNot(contains('🏷')));
    expect(body, contains('• 🏠 Tiền trọ'), reason: 'emoji danh mục giữa câu giữ nguyên');
    expect(body, contains('   Tiền ăn: theo nhịp này'), reason: 'giữ thụt lề dòng chi tiết');
    expect(body, contains('2 giao dịch chưa phân loại.'));
    // Vùng tối sau bảng đọc "Đóng" (không phải "Scrim").
    expect(find.bySemanticsLabel('Scrim'), findsNothing);
    expect(find.bySemanticsLabel('Đóng'), findsWidgets);

    await tester.tap(find.byKey(const Key('alert_detail_action')));
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);
    expect(server.where('GET', '/api/transactions').last.url.queryParameters['uncategorized'], 'true');
    handle.dispose();
  });

  testWidgets('Cảnh báo: bộ lọc "Chưa đọc" trống thì báo bình thản', (tester) async {
    await _pump(
      tester,
      extra: {
        'GET /api/alerts': (req) =>
            req.url.queryParameters['unread'] == 'true' ? <Object>[] : [_alert(9, '2026-10-13T01:00:00Z', read: true)],
      },
    );
    await _goTab(tester, 'Cảnh báo');
    await tester.tap(find.byKey(const Key('alerts_filter_unread')));
    await tester.pumpAndSettle();
    expect(find.text('Không còn cảnh báo chưa đọc.'), findsOneWidget);
  });

  testWidgets('thông báo đẩy khi app đang mở: SnackBar gọn (tiêu đề + 1 dòng), 6 s, nằm trên FAB', (tester) async {
    final push = FakePushService();
    addTearDown(push.close);
    await _pump(tester, size: const Size(390, 844), push: push);

    push.foreground.add(
      PushMessage.fromData(
        {'alert_id': '10', 'kind': 'tx', 'level': 'WARNING', 'transaction_id': '55'},
        title: '⚠️ Sắp chạm mức mục tiêu',
        // Dòng đầu của máy chủ kết thúc bằng giờ: SnackBar bỏ giờ (không bị cắt giữa giờ).
        body: '−3.500.000đ · VCB chính · 17:38 15/10\nSố dư: 6.500.000đ\nĐược tiêu: 500.000đ\nDòng 4\nDòng 5',
      ),
    );
    await tester.pumpAndSettle();

    final snackbar = find.byKey(const Key('push_snackbar'));
    expect(snackbar, findsOneWidget);
    expect(find.descendant(of: snackbar, matching: find.text('Sắp chạm mức mục tiêu')), findsOneWidget);
    expect(find.descendant(of: snackbar, matching: find.text('−3.500.000đ · VCB chính')), findsOneWidget);
    expect(find.descendant(of: snackbar, matching: find.textContaining('Số dư:')), findsNothing);
    expect(find.descendant(of: snackbar, matching: find.textContaining('Dòng')), findsNothing);
    expect(tester.widget<SnackBar>(snackbar).duration, const Duration(seconds: 6));
    expect(find.widgetWithText(SnackBarAction, 'Xem'), findsOneWidget);
    // Điện thoại: SnackBar nổi phía trên FAB "Thêm mục tiêu", không đè lên nó.
    final fab = tester.getRect(find.widgetWithText(FloatingActionButton, 'Thêm mục tiêu'));
    expect(tester.getRect(snackbar).bottom, lessThanOrEqualTo(fab.top));
  });

  testWidgets('Cài đặt: "Báo Telegram mỗi giao dịch" lưu ngay một trường; lỗi thì trả công tắc về như cũ', (
    tester,
  ) async {
    var fail = false;
    final (server, _) = await _pump(
      tester,
      extra: {
        'PUT /api/settings': (req) => fail
            ? jsonResponse({'detail': 'Lỗi máy chủ'}, 500)
            : {
                'warning_percent': 10,
                'warning_min_amount': 500000,
                'expected_income_amount': 0,
                'expected_income_day': 0,
                ...(req.json as Map<String, dynamic>),
              },
      },
    );
    await _goTab(tester, 'Cài đặt');
    final toggle = find.byKey(const Key('settings_notify_every_tx'));
    await tester.ensureVisible(toggle);
    // "Lưu cài đặt" chỉ bật khi ô số thay đổi.
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('settings_save'))).onPressed, isNull);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(server.where('PUT', '/api/settings').single.json, {'notify_every_tx': false});
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(find.text('Đã tắt báo Telegram mỗi giao dịch'), findsOneWidget);

    fail = true;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(server.where('PUT', '/api/settings').last.json, {'notify_every_tx': true});
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(find.text('Máy chủ gặp lỗi (500). Thử lại sau.'), findsOneWidget);

    // Câu vùng đệm tính lại theo ô đang nhập (mức sàn 6.000.000đ × 15% = 900.000đ).
    await tester.enterText(find.byKey(const Key('settings_warning_percent')), '15');
    await tester.pump();
    expect(
      find.text('Đang báo khi được tiêu dưới 900.000đ (số lớn hơn giữa 15% mức sàn và 500.000đ).'),
      findsOneWidget,
    );
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('settings_save'))).onPressed, isNotNull);
  });

  testWidgets('đọc màn hình: hàng "chưa phân loại" là nút (không phải ô đánh dấu); hàng mục tiêu đọc một câu gọn', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    final row = tester.getSemantics(find.byKey(const Key('uncategorized_chip')));
    expect(row, isSemantics(isButton: true, hasTapAction: true, hasCheckedState: false));
    expect(row.getSemanticsData().label, contains('1 giao dịch chưa phân loại'));

    final goal = tester.getSemantics(find.byKey(const ValueKey('goal_row_2')));
    expect(
      goal.getSemanticsData().label,
      contains('Tiền ăn. Ngân sách, Ăn uống. Lặp lại hằng tháng. Còn được chi 3000000 đồng.'),
    );
    expect(goal.getSemanticsData().label, contains('Đã chi 2000000 đồng trên 5000000 đồng, 40 phần trăm.'));
    expect(goal.getSemanticsData().label, contains('Theo nhịp này sẽ vượt khoảng 1000000 đồng'));
    expect(goal, isSemantics(isButton: true, hasTapAction: true, hasCheckedState: false));
    handle.dispose();
  });

  group('đọc màn hình: mỗi hàng trong nhóm là một nút riêng, đúng thứ tự', () {
    testWidgets('Cài đặt: "Thêm tài khoản" là nút riêng ở cuối nhóm, không bọc các hàng tài khoản', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await _goTab(tester, 'Cài đặt');

      final add = tester.getSemantics(find.byKey(const Key('settings_add_account')));
      expect(add.getSemanticsData().label, 'Thêm tài khoản');
      expect(add, isSemantics(isButton: true, hasTapAction: true));
      final labels = <String>[];
      add.visitChildren((child) {
        labels.add(child.getSemanticsData().label);
        return true;
      });
      expect(labels.where((l) => l.contains('VCB')), isEmpty);
      final account = tester.getSemantics(find.text('VCB chính ··6789'));
      expect(account.getSemanticsData().label, contains('VCB chính ··6789'));
      // Tổ tiên chung gần nhất là nhóm; hai hàng là hai nhánh con khác nhau của nó.
      List<SemanticsNode> chain(SemanticsNode n) => [for (SemanticsNode? x = n; x != null; x = x.parent) x];
      final accountChain = chain(account);
      final addChain = chain(add);
      final group = addChain.firstWhere(accountChain.contains);
      final addRow = addChain[addChain.indexOf(group) - 1];
      final accountRow = accountChain[accountChain.indexOf(group) - 1];
      expect(addRow, isNot(same(accountRow)));
      expect(addRow.rect.height, lessThan(100), reason: 'nút chỉ bao hàng của nó, không bao cả nhóm');
      final siblings = <SemanticsNode>[];
      group.visitChildren((child) {
        siblings.add(child);
        return true;
      });
      expect(siblings.indexOf(addRow), greaterThan(siblings.indexOf(accountRow)));
      handle.dispose();
    });

    testWidgets('Tổng quan › Cần bạn xem: mỗi câu hỏi là một nút, ngay sau là các nút trả lời của nó', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        extra: {
          'GET /api/summary': (_) => {
            ...warningSummaryJson(),
            'accounts': [
              accountJson(),
              {
                'id': 2,
                'bank': 'MB',
                'name': 'MB lạ',
                'account_number': null,
                'last4': '1234',
                'include_in_total': true,
                'confirmed': false,
                'balance': null,
                'balance_as_of': null,
                'balance_derived': false,
                'manual_balance': null,
                'manual_balance_at': null,
              },
            ],
            'ingest_health': {
              'stale': true,
              'warnings': ['Chưa nhận webhook SEPAY 3 ngày'],
            },
          },
        },
      );

      String parentLabel(Finder button) => tester.getSemantics(button).parent!.getSemanticsData().label;
      expect(parentLabel(find.widgetWithText(FilledButton, 'Tính vào tổng')), contains('Phát hiện TK mới MB lạ'));
      expect(parentLabel(find.widgetWithText(OutlinedButton, 'Không tính')), contains('Phát hiện TK mới MB lạ'));
      expect(parentLabel(find.byKey(const Key('enter_balance'))), contains('Chưa biết số dư của'));
      final question = tester.getSemantics(find.textContaining('Phát hiện TK mới'));
      expect(question.getSemanticsData().label, isNot(contains('Chưa biết số dư của')));
      expect(question.getSemanticsData().label, isNot(contains('webhook')));
      final health = tester.getSemantics(find.byKey(const Key('ingest_health_note')));
      expect(health.getSemanticsData().label, contains('Chưa nhận webhook SEPAY 3 ngày'));
      expect(health.getSemanticsData().label, isNot(contains('Phát hiện')));
      handle.dispose();
    });
  });

  testWidgets(
    'chữ 200% ở 360×568 (máy 360×640 trừ thanh hệ thống): hộp xác nhận "Ngắt kết nối?" cuộn được, không cắt câu cuối',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, size: const Size(360, 568));
      await _goTab(tester, 'Cài đặt');
      final disconnect = find.widgetWithText(TextButton, 'Ngắt kết nối');
      await tester.scrollUntilVisible(
        disconnect,
        300,
        scrollable: find.descendant(of: find.byType(SettingsScreen), matching: find.byType(Scrollable)).first,
      );
      await tester.ensureVisible(disconnect);
      await tester.pumpAndSettle();
      await tester.tap(disconnect);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable, isTrue);
      final body = tester.renderObject<RenderParagraph>(find.textContaining('không bị xoá.'));
      expect(body.didExceedMaxLines, isFalse);
      expect(body.size.height, greaterThanOrEqualTo(body.getMaxIntrinsicHeight(body.size.width) - 0.5));
      expect(tester.takeException(), isNull);
    },
  );

  group('sửa sau đánh giá', () {
    testWidgets('Thêm mục tiêu: số tiền quá giới hạn báo bằng tiếng Việt; "Tiết kiệm thuần" không bị cắt ở 360 dp', (
      tester,
    ) async {
      final (server, _) = await _pump(tester, size: const Size(360, 780));
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Thêm mục tiêu'));
      await tester.pumpAndSettle();
      final category = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byKey(const ValueKey('goal_category_reserve')),
          matching: find.text('Tiết kiệm thuần'),
        ),
      );
      expect(category.didExceedMaxLines, isFalse);
      await tester.enterText(find.byKey(const Key('goal_name')), 'Mua nhà');
      await tester.enterText(find.byKey(const Key('goal_amount')), '200000000000');
      await tester.tap(find.byKey(const Key('goal_save')));
      await tester.pumpAndSettle();
      expect(find.text('Số tiền tối đa 100.000.000.000đ'), findsOneWidget);
      expect(server.where('POST', '/api/goals'), isEmpty);
    });

    testWidgets('bảng phân loại: chip đang chọn thay icon bằng dấu tích (không vẽ chồng)', (tester) async {
      await _pump(tester);
      await _goTab(tester, 'Giao dịch');
      await tester.tap(find.text('GRABFOOD'));
      await tester.pumpAndSettle();
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      final selected = chips.where((c) => c.selected).toList();
      expect(selected, hasLength(1));
      expect(selected.single.avatar, isNull);
      expect(chips.where((c) => !c.selected).every((c) => c.avatar != null), isTrue);
      expect(
        tester
            .widget<Wrap>(find.ancestor(of: find.byType(ChoiceChip).first, matching: find.byType(Wrap)).first)
            .runSpacing,
        0,
      );
    });

    testWidgets('Cảnh báo ở 200% / 360 dp: giờ xuống dưới tiêu đề, tiêu đề ngắn không bị cắt', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, size: const Size(360, 780));
      await _goTab(tester, 'Cảnh báo');
      final title = find.text('Sắp chạm mức mục tiêu');
      expect(tester.renderObject<RenderParagraph>(title).didExceedMaxLines, isFalse);
      expect(tester.getRect(find.text('09:59')).top, greaterThanOrEqualTo(tester.getRect(title).bottom));
      expect(tester.takeException(), isNull);
    });

    testWidgets('bàn phím: Tab đi hết nội dung Tổng quan rồi mới tới FAB và thanh điều hướng', (tester) async {
      await _pump(tester, size: const Size(390, 844));
      String where() {
        final context = FocusManager.instance.primaryFocus?.context;
        if (context == null) return 'none';
        if (context.findAncestorWidgetOfExactType<FloatingActionButton>() != null) return 'fab';
        if (context.findAncestorWidgetOfExactType<NavigationBar>() != null) return 'nav';
        return 'content';
      }

      final seen = <String>[];
      for (var i = 0; i < 30; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        seen.add(where());
        if (seen.where((w) => w == 'nav').length >= 4) break;
      }
      final firstFab = seen.indexOf('fab');
      expect(firstFab, greaterThan(3), reason: 'nhiều mục nội dung trước FAB: $seen');
      expect(seen.sublist(0, firstFab).every((w) => w == 'content'), isTrue, reason: '$seen');
      expect(seen.sublist(firstFab + 1, firstFab + 5), ['nav', 'nav', 'nav', 'nav'], reason: '$seen');
    });

    testWidgets('Sửa tài khoản: ngân hàng là chữ chỉ đọc (không phải ô bị khoá)', (tester) async {
      await _pump(tester);
      await _goTab(tester, 'Cài đặt');
      await tester.tap(find.text('VCB chính ··6789'));
      await tester.pumpAndSettle();
      final bank = find.byKey(const Key('account_bank_readonly'));
      expect(bank, findsOneWidget);
      expect(find.descendant(of: bank, matching: find.text('Vietcombank')), findsOneWidget);
      expect(find.ancestor(of: find.text('Vietcombank'), matching: find.byType(InputDecorator)), findsNothing);
    });
  });

  group('chữ 200% ở 360×780 không tràn bố cục', () {
    Future<void> pump200(WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, size: const Size(360, 780));
      expect(tester.takeException(), isNull);
    }

    testWidgets('Tổng quan', (tester) async {
      await pump200(tester);
      await _scrollThrough(tester, find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Giao dịch (và bảng phân loại)', (tester) async {
      await pump200(tester);
      await _goTab(tester, 'Giao dịch');
      await _scrollThrough(tester, find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('RUT TIEN ATM'));
      await tester.pumpAndSettle();
      await _scrollThrough(tester, find.byType(Scrollable).last);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Thêm mục tiêu', (tester) async {
      await pump200(tester);
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Thêm mục tiêu'));
      await tester.pumpAndSettle();
      expect(find.byType(GoalFormScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('goal_save')));
      await tester.pumpAndSettle();
      expect(find.text('Nhập tên mục tiêu'), findsOneWidget);
      final more = find.byKey(const Key('goal_more_options'));
      await tester.scrollUntilVisible(more, 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(more);
      await tester.pumpAndSettle();
      await _scrollThrough(tester, find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
    });
  });
}
