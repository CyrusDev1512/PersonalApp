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

  testWidgets('máy tính 1280×800: NavigationRail + FAB ở đầu rail, cột nội dung tối đa 720 dp ở giữa', (tester) async {
    await _pump(tester, const Size(1280, 800));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    // Một FAB duy nhất (ở rail), Tổng quan không hiện thêm.
    expect(_addGoalFab, findsOneWidget);
    expect(find.descendant(of: find.byType(NavigationRail), matching: _addGoalFab), findsOneWidget);
    expect(
      tester
          .widget<Scaffold>(find.descendant(of: find.byType(DashboardScreen), matching: find.byType(Scaffold)))
          .floatingActionButton,
      isNull,
    );
    final rail = tester.getRect(find.byType(NavigationRail));
    final page = tester.getRect(find.descendant(of: find.byType(DashboardScreen), matching: find.byType(Scaffold)));
    expect(page.width, AppLayout.contentMaxWidth);
    expect(page.center.dx, moreOrLessEquals((rail.right + 1280) / 2, epsilon: 0.5));

    // Đổi tab bằng rail.
    await tester.tap(find.descendant(of: find.byType(NavigationRail), matching: find.text('Giao dịch')));
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex, 1);

    // FAB ở rail mở form mục tiêu, form cũng nằm trong cột 720 dp.
    await tester.tap(find.byKey(const Key('rail_add_goal')));
    await tester.pumpAndSettle();
    expect(find.byType(GoalFormScreen), findsOneWidget);
    expect(tester.getRect(find.byType(GoalFormScreen)).width, AppLayout.contentMaxWidth);
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
