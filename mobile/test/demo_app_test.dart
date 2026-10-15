import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance/api/api_client.dart';
import 'package:personal_finance/demo/demo_app.dart';
import 'package:personal_finance/demo/demo_backend.dart';
import 'package:personal_finance/screens/connect_screen.dart';

/// Màn hình điện thoại 390×844.
void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<DemoBackend> _pumpDemo(WidgetTester tester) async {
  _usePhoneScreen(tester);
  final backend = DemoBackend(
    clock: () => DateTime.utc(2026, 10, 15, 7),
    latency: Duration.zero,
    pushDelay: Duration.zero,
  );
  addTearDown(backend.dispose);
  await tester.pumpWidget(DemoApp(backend: backend, refreshInterval: null));
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
  });

  testWidgets('bản dùng thử: thanh demo, bảng giả lập, "Rút ATM" -> WARNING + SnackBar thông báo đẩy', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpDemo(tester);

    expect(find.bySemanticsLabel('Bản dùng thử · dữ liệu giả'), findsOneWidget);
    expect(find.text('Giả lập biến động số dư'), findsOneWidget);
    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.text('An toàn'), findsOneWidget);
    expect(find.text('4.000.000đ'), findsWidgets);

    await tester.tap(find.byKey(const Key('demo_simulate')));
    await tester.pumpAndSettle();
    for (final title in [
      'Rút ATM 3.500.000đ',
      'Nhận lương 15.000.000đ',
      'Chuyển tiền trọ 3.000.000đ',
      'Mua sắm 600.000đ',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('Đặt lại dữ liệu demo'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('Đặt lại dữ liệu demo'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rút ATM 3.500.000đ'), -200, scrollable: find.byType(Scrollable).last);

    await tester.tap(find.text('Rút ATM 3.500.000đ'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('push_snackbar')), findsOneWidget);
    expect(find.textContaining('⚠️ Sắp chạm mức mục tiêu\n−3.500.000đ · VCB chính'), findsOneWidget);
    expect(find.text('Sắp chạm mức mục tiêu'), findsOneWidget);
    expect(find.text('500.000đ'), findsWidgets);
    semantics.dispose();
  });

  testWidgets('"Ngắt kết nối" không cụt đường: nút "Kết nối lại bản dùng thử"', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpDemo(tester);
    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ngắt kết nối'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ngắt kết nối'));
    await tester.pumpAndSettle();

    expect(find.byType(ConnectScreen), findsOneWidget);
    expect(find.text('Bản dùng thử\nđã ngắt kết nối'), findsOneWidget);
    // Màn 390 px: chữ nút ngắn để nhãn bên trái không bị cắt, nhưng trình đọc màn hình vẫn nghe đủ câu.
    expect(find.descendant(of: find.byKey(const Key('demo_reconnect')), matching: find.text('Kết nối lại')), findsOne);
    expect(find.bySemanticsLabel('Kết nối lại bản dùng thử'), findsOneWidget);
    await tester.tap(find.byKey(const Key('demo_reconnect')));
    await tester.pumpAndSettle();
    expect(find.byType(ConnectScreen), findsNothing);
    expect(find.text('Giả lập biến động số dư'), findsOneWidget);
    expect(find.text('An toàn'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('tự nhập biến động (tự phân loại theo luật) rồi đặt lại dữ liệu demo', (tester) async {
    final backend = await _pumpDemo(tester);
    await tester.tap(find.byKey(const Key('demo_simulate')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('demo_amount')), '120000');
    await tester.enterText(find.byKey(const Key('demo_content')), 'GRABFOOD COM TAM');
    await tester.scrollUntilVisible(
      find.byKey(const Key('demo_custom_submit')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('demo_custom_submit')));
    await tester.pumpAndSettle();

    final client = ApiClient(baseUrl: demoBaseUrl, token: demoToken, client: backend);
    final latest = (await client.listTransactions(limit: 1)).items.single;
    expect((latest.amount, latest.categoryName, latest.description), (120000, 'Ăn uống', 'GRABFOOD COM TAM'));
    // Không có cảnh báo quan trọng: không có thông báo đẩy, chỉ có SnackBar giải thích (lời trung tính).
    expect(find.textContaining('không tạo cảnh báo quan trọng nên không có thông báo đẩy'), findsOneWidget);

    await tester.tap(find.byKey(const Key('demo_simulate')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('demo_reset')), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(const Key('demo_reset')));
    await tester.pumpAndSettle();
    expect(find.text('Đã đặt lại dữ liệu demo'), findsOneWidget);
    expect((await client.listTransactions(limit: 1)).items.single.description, isNot('GRABFOOD COM TAM'));
  });

  testWidgets('màn hình rộng (1280×800): app hiện thành cột cỡ điện thoại ở giữa, kể cả thanh demo', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final backend = DemoBackend(
      clock: () => DateTime.utc(2026, 10, 15, 7),
      latency: Duration.zero,
      pushDelay: Duration.zero,
    );
    addTearDown(backend.dispose);
    await tester.pumpWidget(DemoApp(backend: backend, refreshInterval: null));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(NavigationBar)).width, 440);
    expect(tester.getCenter(find.byType(NavigationBar)).dx, 640);
    final banner = tester.getRect(find.byKey(const Key('demo_simulate')));
    expect(banner.right, lessThanOrEqualTo(640 + 220));
    expect(find.text('An toàn'), findsOneWidget);
  });
}
