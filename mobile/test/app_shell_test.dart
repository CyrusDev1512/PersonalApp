// Khung chính thích ứng: NavigationBar trên điện thoại, NavigationRail từ 840 dp, cột nội dung tối đa 720 dp.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance/api/api_client.dart';
import 'package:personal_finance/main.dart';
import 'package:personal_finance/screens/dashboard_screen.dart';
import 'package:personal_finance/models/tx.dart';
import 'package:personal_finance/screens/goal_form_screen.dart';
import 'package:personal_finance/screens/tx_action_sheet.dart';
import 'package:personal_finance/state/app_state.dart';
import 'package:personal_finance/theme/tokens.dart';

import 'test_helpers.dart';

FakeServer _server({bool fail = false}) => FakeServer({
  'GET /api/summary': (_) => fail ? http.Response('{"detail":"Lỗi máy chủ"}', 500) : warningSummaryJson(),
  'GET /api/categories': (_) => categoriesJson(),
  'GET /api/transactions': (_) => {'items': <Object>[], 'total': 0},
  'GET /api/alerts': (_) => <Object>[],
  'GET /api/settings': (_) => {
    'warning_percent': 10,
    'warning_min_amount': 500000,
    'expected_income_amount': 0,
    'expected_income_day': 0,
    'notify_every_tx': true,
  },
});

Future<void> _pump(WidgetTester tester, Size size, {bool fail = false}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final server = _server(fail: fail);
  final state = AppState(
    client: ApiClient(baseUrl: 'https://finance.example.com', token: 'tok', client: server.client),
    refreshInterval: null,
  );
  addTearDown(state.dispose);
  await tester.pumpWidget(PersonalFinanceApp(state: state, refreshInterval: null));
  await tester.pumpAndSettle();
}

Finder get _addGoalFab => find.widgetWithText(FloatingActionButton, 'Thêm mục tiêu');

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
  });

  testWidgets('điện thoại 390×844: NavigationBar, FAB "Thêm mục tiêu" trên Tổng quan, chừa 96 dp cuối danh sách', (
    tester,
  ) async {
    await _pump(tester, const Size(390, 844));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(_addGoalFab, findsOneWidget);
    expect(find.byKey(const Key('rail_add_goal')), findsNothing);
    // FAB không che hàng cuối: danh sách chừa khoảng trống bằng chiều cao FAB + lề.
    final list = tester.widget<ListView>(
      find.descendant(of: find.byType(DashboardScreen), matching: find.byType(ListView)).first,
    );
    expect((list.padding! as EdgeInsets).bottom, AppLayout.fabClearance);
    // Thanh điều hướng: nhãn labelSmall 12 sp / 600.
    final label = tester.widget<Text>(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('Tổng quan')),
    );
    final style = DefaultTextStyle.of(tester.element(find.byWidget(label))).style.merge(label.style);
    expect(style.fontSize, 12);
    expect(style.fontWeight, FontWeight.w600);
  });

  testWidgets('máy tính 1280×800: NavigationRail + FAB ở đầu rail (chỉ ở Tổng quan), thân màn tối đa 720 dp ở giữa', (
    tester,
  ) async {
    await _pump(tester, const Size(1280, 800));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    // Một FAB duy nhất (ở rail), Tổng quan không hiện thêm.
    expect(_addGoalFab, findsOneWidget);
    expect(find.descendant(of: find.byType(NavigationRail), matching: _addGoalFab), findsOneWidget);
    final dashboardScaffold = find.descendant(of: find.byType(DashboardScreen), matching: find.byType(Scaffold));
    expect(tester.widget<Scaffold>(dashboardScaffold).floatingActionButton, isNull);
    final rail = tester.getRect(find.byType(NavigationRail));
    // App bar rộng hết phần bên phải rail (màu khi cuộn dưới thanh phủ hết bề ngang, không thành một "tấm" giữa
    // màn); thân màn là cột 720 dp ở giữa; tiêu đề thẳng mép trái của nội dung (mép cột + lề 32).
    final appBar = tester.getRect(find.descendant(of: find.byType(DashboardScreen), matching: find.byType(AppBar)));
    expect(appBar.left, rail.right);
    expect(appBar.right, 1280);
    final column = tester.getRect(
      find.descendant(of: find.byType(DashboardScreen), matching: find.byType(RefreshIndicator)).first,
    );
    expect(column.width, AppLayout.contentMaxWidth);
    expect(column.center.dx, moreOrLessEquals((rail.right + 1280) / 2, epsilon: 0.5));
    final title = tester.getRect(find.descendant(of: find.byType(AppBar), matching: find.text('Tổng quan')));
    expect(title.left, moreOrLessEquals(column.left + Gutter.expanded, epsilon: 0.5));

    // Đổi tab bằng rail. Ở tab khác, FAB "Thêm mục tiêu" của rail ẩn (giữ chỗ): Giao dịch chỉ có "Nhập tay".
    await tester.tap(find.descendant(of: find.byType(NavigationRail), matching: find.text('Giao dịch')));
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex, 1);
    expect(find.byKey(const Key('rail_add_goal')).hitTestable(), findsNothing);
    expect(find.byType(FloatingActionButton).hitTestable(), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Nhập tay').hitTestable(), findsOneWidget);
    // FAB của tab nằm trong cột nội dung (mép phải cột − 16), không trôi ra mép cửa sổ.
    final txColumn = (rail.right + 1280) / 2 + AppLayout.contentMaxWidth / 2;
    final txFab = tester.getRect(find.widgetWithText(FloatingActionButton, 'Nhập tay'));
    expect(txFab.right, moreOrLessEquals(txColumn - 16, epsilon: 0.5));

    // Về Tổng quan: FAB ở rail mở form mục tiêu, form cũng nằm trong cột 720 dp.
    await tester.tap(find.descendant(of: find.byType(NavigationRail), matching: find.text('Tổng quan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rail_add_goal')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalFormScreen), findsOneWidget);
    expect(tester.getRect(find.byType(GoalFormScreen)).width, AppLayout.contentMaxWidth);
  });

  testWidgets('điện thoại xoay ngang (844×390): giữ NavigationBar, không dùng rail (rail không cuộn được)', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, const Size(844, 390));
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
    final settings = tester.getRect(find.descendant(of: find.byType(NavigationBar), matching: find.text('Cài đặt')));
    expect(settings.bottom, lessThanOrEqualTo(390));
  });

  testWidgets('Back của hệ thống ở tab khác Tổng quan: về Tổng quan trước, chưa thoát app', (tester) async {
    await _pump(tester, const Size(390, 844));
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Cài đặt')));
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 3);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue, reason: 'Back được app xử lý (không thoát)');
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);

    // Ở Tổng quan, Back để hệ thống xử lý như thường (thoát app).
    final atStart = await tester.binding.handlePopRoute();
    expect(atStart, isFalse);
  });

  testWidgets('Tổng quan trên điện thoại: FAB thu gọn khi cuộn xuống (vẫn đọc "Thêm mục tiêu"), mở lại khi cuộn lên', (
    tester,
  ) async {
    await _pump(tester, const Size(390, 640));
    final fab = find.byKey(const Key('dashboard_add_goal'));
    expect(tester.widget<FloatingActionButton>(fab).isExtended, isTrue);
    final list = find.descendant(of: find.byType(DashboardScreen), matching: find.byType(Scrollable)).first;
    await tester.drag(list, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.widget<FloatingActionButton>(fab).isExtended, isFalse);
    expect(tester.getSize(fab), const Size(56, 56));
    expect(tester.widget<FloatingActionButton>(fab).tooltip, 'Thêm mục tiêu');
    await tester.drag(list, const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(tester.widget<FloatingActionButton>(fab).isExtended, isTrue);
  });

  testWidgets('huy hiệu Cảnh báo đọc "N cảnh báo chưa đọc" (không đọc con số trơn trước tên tab)', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const Size(390, 844));
    final tab = tester.getSemantics(find.descendant(of: find.byType(NavigationBar), matching: find.text('Cảnh báo')));
    final data = tab.getSemanticsData();
    final spoken = '${data.label} ${data.value}';
    expect(spoken, contains('2 cảnh báo chưa đọc'));
    expect(data.label.trimLeft().startsWith('2'), isFalse);
    handle.dispose();
  });

  testWidgets('1280×800: bảng trượt (cả bảng giao dịch) không kéo giãn quá 640 dp', (tester) async {
    await _pump(tester, const Size(1280, 800));
    double sheetWidth() =>
        tester.getRect(find.descendant(of: find.byType(BottomSheet), matching: find.byType(Material)).first).width;
    final context = tester.element(find.byType(DashboardScreen));
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const SizedBox(height: 120, child: Center(child: Text('Bảng thử'))),
    );
    await tester.pumpAndSettle();
    expect(sheetWidth(), AppLayout.sheetMaxWidth);
    Navigator.of(context).pop();
    await tester.pumpAndSettle();

    final client = ApiClient(baseUrl: 'https://finance.example.com', token: 'tok', client: _server().client);
    showTxActionSheet(
      context,
      client: client,
      tx: const Tx(id: 55, direction: 'out', amount: 50000, description: 'GRABFOOD'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TxActionSheet), findsOneWidget);
    expect(sheetWidth(), AppLayout.sheetMaxWidth);
  });

  testWidgets('1280×800, lỗi tải và chưa có dữ liệu: ẩn FAB (không vô hiệu hoá), "Thử lại" là hành động', (
    tester,
  ) async {
    await _pump(tester, const Size(1280, 800), fail: true);
    expect(find.byKey(const Key('rail_add_goal')), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Thử lại'), findsOneWidget);
  });

  testWidgets('thanh hệ thống trong suốt, icon theo theme (cả màn không có app bar)', (tester) async {
    await _pump(tester, const Size(390, 844));
    final regions = tester.widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    );
    final root = regions.first.value;
    expect(root.statusBarColor, const Color(0x00000000));
    expect(root.systemNavigationBarColor, const Color(0x00000000));
    expect(root.statusBarIconBrightness, Brightness.dark);
  });
}
