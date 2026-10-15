// Widget dùng chung của hệ thống thiết kế: MoneyText, MoneyRow, thước mức sàn, StatusHero, trạng thái trống/lỗi.
// Nạp Be Vietnam Pro thật (assets/fonts) để đo chữ như trên máy (font thử mặc định của flutter_test có mọi
// chữ số rộng bằng nhau, sẽ che mất lỗi ô chữ số).
import 'dart:io';
import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance/models/level.dart';
import 'package:personal_finance/models/summary.dart';
import 'package:personal_finance/theme/theme.dart';
import 'package:personal_finance/widgets/category_icon.dart';
import 'package:personal_finance/widgets/floor_ruler.dart';
import 'package:personal_finance/widgets/list_group.dart';
import 'package:personal_finance/widgets/money_row.dart';
import 'package:personal_finance/widgets/money_text.dart';
import 'package:personal_finance/widgets/section_header.dart';
import 'package:personal_finance/widgets/state_views.dart';
import 'package:personal_finance/widgets/status_hero.dart';

import 'test_helpers.dart';

Future<void> _loadAppFonts() async {
  final loader = FontLoader(appFontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    final bytes = File('assets/fonts/BeVietnamPro-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  }
  await loader.load();
}

/// Bọc [child] trong app có theme thật, cỡ chữ [scale], cửa sổ [size] (dp).
Widget _app(
  Widget child, {
  double scale = 1,
  Brightness brightness = Brightness.light,
  bool disableAnimations = false,
  bool supportsAnnounce = false,
}) {
  return MaterialApp(
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    themeMode: brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
    builder: (context, inner) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: disableAnimations,
        supportsAnnounce: supportsAnnounce,
      ),
      child: inner!,
    ),
    home: Scaffold(
      body: ListView(padding: const EdgeInsets.all(Gutter.compact), children: [child]),
    ),
  );
}

void _phone(WidgetTester tester, [Size size = const Size(360, 780)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// 14:32 giờ Việt Nam ngày 15/10/2026.
final _asOf = DateTime.utc(2026, 10, 15, 7, 32);
final _now = DateTime.utc(2026, 10, 15, 8);

StatusHeroData _ok({int balance = 10000000}) => StatusHeroData(
  level: Level.ok,
  free: balance - 6000000,
  balance: balance,
  floor: 6000000,
  buffer: 600000,
  daysLeft: 17,
  salaryDay: 25,
  pendingSalary: 15000000,
  balanceAsOf: _asOf,
);

StatusHeroData _warning() => StatusHeroData(
  level: Level.warning,
  free: 500000,
  balance: 6500000,
  floor: 6000000,
  buffer: 600000,
  daysLeft: 17,
  balanceAsOf: _asOf,
);

StatusHeroData _danger() => StatusHeroData(
  level: Level.danger,
  free: -350000,
  balance: 5650000,
  floor: 6000000,
  buffer: 600000,
  daysLeft: 17,
  balanceAsOf: _asOf,
);

/// Các trạng thái cần vẽ được ở mọi cỡ chữ.
final Map<String, StatusHeroData> _cases = {
  'OK': _ok(),
  'WARNING': _warning(),
  'DANGER': _danger(),
  'WARNING chờ lương (dưới mức sàn)': StatusHeroData(
    level: Level.warning,
    free: -1000000,
    balance: 5000000,
    floor: 6000000,
    buffer: 600000,
    daysLeft: 26,
    waitingIncome: true,
    salaryDay: 5,
    pendingSalary: 15000000,
    balanceAsOf: _asOf,
  ),
  'DANGER số dài, cũ, offline, ước tính, đang chuyển': StatusHeroData(
    level: Level.danger,
    free: -12500000,
    balance: 187500000,
    floor: 200000000,
    buffer: 20000000,
    daysLeft: 3,
    inTransit: 2000000,
    balanceDerived: true,
    balanceAsOf: _asOf.subtract(const Duration(days: 3)),
    offline: true,
    dataLoadedAt: _asOf,
  ),
  'OK chưa có mục tiêu, số rất lớn': StatusHeroData(
    level: Level.ok,
    free: 200000000,
    balance: 200000000,
    buffer: 500000,
    balanceAsOf: _asOf,
  ),
  'UNKNOWN chưa có TK': const StatusHeroData(level: Level.unknown),
  'UNKNOWN có TK chưa có số dư': const StatusHeroData(
    level: Level.unknown,
    missingBalanceAccount: 'Vietcombank · …1234',
    offline: true,
  ),
};

/// Hero có thể đổi dữ liệu giữa chừng (giả lập tải lại).
class _HeroHost extends StatelessWidget {
  const _HeroHost(this.data, {this.onUnknownAction});

  final ValueNotifier<StatusHeroData> data;
  final VoidCallback? onUnknownAction;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: data,
    builder: (context, value, _) => StatusHero(data: value, now: _now, onUnknownAction: onUnknownAction),
  );
}

Color _heroColor(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(find.byKey(const Key('status_hero')));
  return (box.decoration as BoxDecoration).color!;
}

String _numeralText(WidgetTester tester) {
  final texts = tester
      .widgetList<RichText>(
        find.descendant(of: find.byKey(const Key('status_hero_free')), matching: find.byType(RichText)),
      )
      .map((t) => t.text.toPlainText())
      .toList();
  return texts.last;
}

/// Ghi lại các câu báo cho trình đọc màn hình (SemanticsService.sendAnnouncement).
List<String> _recordAnnouncements(WidgetTester tester) {
  final messages = <String>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
    message,
  ) async {
    final map = message as Map<dynamic, dynamic>;
    if (map['type'] == 'announce') messages.add((map['data'] as Map<dynamic, dynamic>)['message'] as String);
    return null;
  });
  addTearDown(
    () =>
        tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null),
  );
  return messages;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('vi_VN');
    await _loadAppFonts();
  });

  group('MoneyText', () {
    test('định dạng: đủ chữ số, "." nhóm nghìn, "đ" liền sau, dấu trừ U+2212', () {
      expect(MoneyParts.of(4000000).text, '4.000.000đ');
      expect(MoneyParts.of(-350000).text, '−350.000đ');
      expect(MoneyParts.of(-350000).text.codeUnitAt(0), 0x2212);
      expect(MoneyParts.of(50000, sign: MoneySign.outgoing).text, '−50.000đ');
      expect(MoneyParts.of(2000000, sign: MoneySign.incoming).text, '+2.000.000đ');
      expect(MoneyParts.of(0, sign: MoneySign.explicit).text, '0đ');
      expect(MoneyParts.of(-1, sign: MoneySign.explicit).text, '−1đ');
      expect(MoneyParts.of(120000, estimate: true).text, '~120.000đ');
    });

    test('nhãn đọc màn hình: chữ số liền + "đồng", "âm"/"cộng"', () {
      expect(MoneyParts.of(4000000).semanticsLabel, '4000000 đồng');
      expect(MoneyParts.of(-350000).semanticsLabel, 'âm 350000 đồng');
      expect(MoneyParts.of(2000000, sign: MoneySign.incoming).semanticsLabel, 'cộng 2000000 đồng');
      expect(spokenVnd(600000), '600000 đồng');
    });

    testWidgets('một nút đọc màn hình duy nhất, chữ thuần đúng định dạng', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(const MoneyText(-350000, style: MoneyStyle.list)));
      expect(find.text('−350.000đ'), findsOneWidget);
      expect(tester.getSemantics(find.byType(MoneyText)), matchesSemantics(label: 'âm 350000 đồng'));
      semantics.dispose();
    });

    testWidgets('moneyList: chữ số trong ô cố định (cột thẳng hàng); kiểu khác tỉ lệ', (tester) async {
      await tester.pumpWidget(_app(const SizedBox()));
      final context = tester.element(find.byType(ListView));
      double w(int v, MoneyStyle s, {bool? cells}) => MoneyText.measureWidth(context, v, style: s, cells: cells);
      // Font thật đã nạp: chữ số tỉ lệ có bề rộng khác nhau.
      expect(w(8888888, MoneyStyle.body) - w(1111111, MoneyStyle.body), greaterThan(10));
      // Ô cố định: cùng số chữ số → cùng bề rộng, bất kể chữ số nào.
      final list = [1111111, 8888888, 4070090, 9999999].map((v) => w(v, MoneyStyle.list)).toList();
      for (final width in list) {
        expect(width, closeTo(list.first, 0.01));
      }
      // Ô = chữ số rộng nhất ở 700 (0,72 em × 16 sp): 7 ô + 2 dấu chấm + "đ".
      expect(list.first, greaterThan(7 * 0.72 * 16));
      // Hero đếm trong ô, đứng yên thì tỉ lệ.
      expect(w(1111111, MoneyStyle.hero, cells: true), closeTo(w(8888888, MoneyStyle.hero, cells: true), 0.01));
      expect(w(1111111, MoneyStyle.hero), lessThan(w(1111111, MoneyStyle.hero, cells: true)));
    });

    testWidgets('hai số trong cột căn phải: mép phải và bề rộng trùng nhau', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(1111111, key: Key('a'), style: MoneyStyle.list, sign: MoneySign.outgoing),
              MoneyText(8888888, key: Key('b'), style: MoneyStyle.list, sign: MoneySign.outgoing),
            ],
          ),
        ),
      );
      final a = tester.getRect(find.byKey(const Key('a')));
      final b = tester.getRect(find.byKey(const Key('b')));
      expect(a.right, b.right);
      expect(a.width, closeTo(b.width, 0.01));
    });

    testWidgets('hero không phóng chữ quá 1,3×; kiểu khác theo hệ thống', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [
              MoneyText(4000000, key: Key('hero'), style: MoneyStyle.hero),
              MoneyText(4000000, key: Key('list'), style: MoneyStyle.list),
            ],
          ),
          scale: 2,
        ),
      );
      RichText rich(String key) =>
          tester.widget<RichText>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(RichText)));
      expect(rich('hero').textScaler.scale(44), closeTo(44 * 1.3, 0.001));
      expect(rich('list').textScaler.scale(16), 32);
    });

    testWidgets('màu theo ý nghĩa: chi onSurface, thu ok.foreground, loại trừ gạch ngang', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [
              MoneyText(50000, key: Key('out'), sign: MoneySign.outgoing, tone: MoneyTone.outgoing),
              MoneyText(50000, key: Key('in'), sign: MoneySign.incoming, tone: MoneyTone.incoming),
              MoneyText(50000, key: Key('ex'), tone: MoneyTone.excluded),
            ],
          ),
        ),
      );
      // RichText.text = DefaultTextStyle bọc ngoài; con duy nhất là chữ của MoneyText.
      TextStyle style(String key) {
        final root =
            tester.widget<RichText>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(RichText))).text
                as TextSpan;
        return (root.children!.single as TextSpan).style!;
      }

      final theme = buildTheme(Brightness.light);
      expect(style('out').color, theme.colorScheme.onSurface);
      expect(style('in').color, StatusColors.light.ok.foreground);
      expect(style('ex').color, theme.colorScheme.onSurfaceVariant);
      expect(style('ex').decoration, TextDecoration.lineThrough);
      // The Red Is Earned Rule: khoản chi không đỏ.
      expect(style('out').color, isNot(theme.colorScheme.error));
    });
  });

  group('MoneyRow (chữ > 125% thì số tiền xuống dòng riêng)', () {
    Widget row({String title = 'Tiền ăn', VoidCallback? onTap}) => MoneyRow(
      leading: const LeadingDisc(icon: Icons.restaurant_outlined),
      title: Text(title, key: const Key('title')),
      meta: const Text('Vietcombank · 14:32 · SePay', key: Key('meta')),
      amount: const MoneyText(-1250000, key: Key('amount'), style: MoneyStyle.list, sign: MoneySign.outgoing),
      amountCaption: const Text('còn được chi'),
      onTap: onTap,
    );

    testWidgets('100%: số tiền cùng hàng, bên phải tiêu đề', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(row()));
      final title = tester.getRect(find.byKey(const Key('title')));
      final amount = tester.getRect(find.byKey(const Key('amount')));
      expect(amount.left, greaterThan(title.left));
      expect(amount.top, lessThan(tester.getRect(find.byKey(const Key('meta'))).bottom));
    });

    testWidgets('dòng phụ rộng hết hàng (chạy dưới cả số tiền), không bị bóp vào cột cạnh số tiền', (tester) async {
      _phone(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(
          MoneyRow(
            leading: const LeadingDisc(icon: Icons.north_east),
            title: const Text('RUT TIEN ATM VCB LE DUAN Q1', key: Key('title')),
            meta: const Text('Ăn uống · VCB chính · 19:05 · SePay', key: Key('meta')),
            amount: const MoneyText(-3500000, key: Key('amount'), style: MoneyStyle.list, sign: MoneySign.outgoing),
          ),
        ),
      );
      final title = tester.getRect(find.byKey(const Key('title')));
      final meta = tester.getRect(find.byKey(const Key('meta')));
      final amount = tester.getRect(find.byKey(const Key('amount')));
      expect(amount.top, lessThan(meta.top), reason: 'số tiền cùng dòng với tiêu đề');
      expect(meta.top, greaterThanOrEqualTo(title.bottom));
      expect(meta.left, title.left);
      expect(meta.right, greaterThan(amount.left), reason: 'dòng phụ chạy dưới cả cột số tiền');
      final metaParagraph = tester.renderObject<RenderParagraph>(find.byKey(const Key('meta')));
      expect(metaParagraph.size.height, lessThan(20), reason: 'một dòng ở 390 dp');
    });

    testWidgets('360 dp: tiêu đề dài xếp chồng (không cắt chữ), tiêu đề ngắn vẫn cạnh số tiền', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              MoneyRow(
                leading: const LeadingDisc(icon: Icons.north_east),
                title: const Text('CHUYEN TIEN CHO NGUYEN VAN NAM', key: Key('long')),
                meta: const Text('VCB chính · 20:45 · SePay', key: Key('long_meta')),
                amount: const MoneyText(-3500000, key: Key('long_amount'), style: MoneyStyle.list),
              ),
              MoneyRow(
                leading: const LeadingDisc(icon: Icons.savings_outlined),
                title: const Text('Tiền trọ', key: Key('short')),
                meta: const Text('Quỹ giữ · Thuê trọ', key: Key('short_meta')),
                amount: const MoneyText(3000000, key: Key('short_amount'), style: MoneyStyle.list),
              ),
            ],
          ),
        ),
      );
      final longTitle = tester.renderObject<RenderParagraph>(find.byKey(const Key('long')));
      expect(longTitle.didExceedMaxLines, isFalse);
      expect(
        tester.getRect(find.byKey(const Key('long_amount'))).top,
        greaterThanOrEqualTo(tester.getRect(find.byKey(const Key('long_meta'))).bottom),
      );
      expect(
        tester.getRect(find.byKey(const Key('short_amount'))).top,
        lessThan(tester.getRect(find.byKey(const Key('short_meta'))).top),
      );
      expect(tester.takeException(), isNull);
    });

    for (final scale in [1.3, 2.0]) {
      testWidgets('${(scale * 100).round()}%: số tiền dưới dòng phụ, căn phải, không tràn', (tester) async {
        _phone(tester);
        await tester.pumpWidget(
          _app(row(title: 'CHUYỂN TIỀN ĐẾN TÀI KHOẢN NGUYỄN VĂN Ễ ẪỘ TẠI NGÂN HÀNG TMCP NGOẠI THƯƠNG'), scale: scale),
        );
        final meta = tester.getRect(find.byKey(const Key('meta')));
        final amount = tester.getRect(find.byKey(const Key('amount')));
        expect(amount.top, greaterThanOrEqualTo(meta.bottom));
        // Căn phải trong cột nội dung: 360 − lề 16 − đệm hàng 16.
        expect(amount.right, closeTo(360 - Gutter.compact - AppLayout.listRowPaddingH, 0.5));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('cả hàng là một nút bấm, đọc cả tiêu đề và số tiền', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(_app(row(onTap: () => taps++)));
      final node = tester.getSemantics(find.byType(MoneyRow));
      expect(node.label, contains('Tiền ăn'));
      expect(node.label, contains('âm 1250000 đồng'));
      expect(node, isSemantics(isButton: true, hasTapAction: true));
      await tester.tap(find.byType(MoneyRow));
      expect(taps, 1);
      semantics.dispose();
    });
  });

  group('thước mức sàn', () {
    test('OK: giữ [0, sàn], được tiêu [sàn, số dư], vạch báo ở sàn + vùng đệm', () {
      final g = RulerGeometry.compute(balance: 10000000, floor: 6000000, buffer: 600000);
      expect(g.reservedEnd, closeTo(0.6, 1e-9));
      expect(g.freeStart, closeTo(0.6, 1e-9));
      expect(g.freeEnd, 1);
      expect(g.tick, closeTo(0.66, 1e-9));
      expect(g.hasMissing, isFalse);
    });

    test('WARNING: đoạn được tiêu dừng trước vạch báo (miền = sàn + vùng đệm)', () {
      final g = RulerGeometry.compute(balance: 6500000, floor: 6000000, buffer: 600000);
      expect(g.freeEnd, closeTo(6.5 / 6.6, 1e-9));
      expect(g.tick, 1);
      expect(g.freeEnd, lessThan(g.tick!));
    });

    test('DANGER: giữ [0, số dư], đoạn thiếu [số dư, sàn] chỉ viền, không có đoạn được tiêu', () {
      final g = RulerGeometry.compute(balance: 5650000, floor: 6000000, buffer: 600000);
      expect(g.reservedEnd, closeTo(5.65 / 6.6, 1e-9));
      expect(g.missingEnd, closeTo(6 / 6.6, 1e-9));
      expect(g.hasMissing, isTrue);
      expect(g.hasFree, isFalse);
    });

    test('chưa có mục tiêu: một đoạn được tiêu, không vạch báo', () {
      final g = RulerGeometry.compute(balance: 10000000, floor: 0, buffer: 500000);
      expect((g.freeStart, g.freeEnd, g.tick), (0.0, 1.0, null));
      expect(g.reservedEnd, 0);
    });

    test('nhãn đọc màn hình gộp các số', () {
      expect(
        FloorRuler.describe(balance: 10000000, floor: 6000000, free: 4000000, buffer: 600000),
        'Số dư 10000000 đồng, giữ cho mục tiêu 6000000 đồng, được tiêu 4000000 đồng, '
        'báo khi được tiêu dưới 600000 đồng',
      );
    });

    test('vẽ được ở mọi trạng thái (kể cả chuyển tiếp)', () {
      final a = RulerGeometry.compute(balance: 10000000, floor: 6000000, buffer: 600000);
      final b = RulerGeometry.compute(balance: 5650000, floor: 6000000, buffer: 600000);
      for (final t in [0.0, 0.3, 0.7, 1.0]) {
        final recorder = PictureRecorder();
        FloorRulerPainter(
          geometry: RulerGeometry.lerp(a, b, t),
          colors: LevelColors.lerp(StatusColors.light.ok, StatusColors.light.danger, t),
        ).paint(Canvas(recorder), const Size(288, Ruler.tickHeight));
        recorder.endRecording().dispose();
      }
    });

    test('chuyển OK → DANGER từng khung: không đoạn nào có bề rộng hay bán kính âm (đoạn thiếu rất hẹp)', () {
      final a = RulerGeometry.compute(balance: 10000000, floor: 6000000, buffer: 600000);
      // Giống bản demo: rút ATM rồi mua sắm, số dư xuống dưới mức sàn một chút (đoạn thiếu lớn dần từ 0).
      final b = RulerGeometry.compute(balance: 5900000, floor: 6000000, buffer: 600000);
      for (final width in [288.0, 296.0, 656.0]) {
        for (var i = 0; i <= 500; i++) {
          final canvas = _RecordingCanvas();
          FloorRulerPainter(
            geometry: RulerGeometry.lerp(a, b, i / 500),
            colors: StatusColors.light.danger,
          ).paint(canvas, Size(width, Ruler.tickHeight));
          for (final r in canvas.rrects) {
            expect(r.width, greaterThan(0), reason: 'w=$width t=${i / 500}');
            expect(r.tlRadiusX, greaterThanOrEqualTo(0), reason: 'w=$width t=${i / 500}');
            expect(r.tlRadiusX, lessThanOrEqualTo(r.width / 2 + 1e-9));
          }
        }
      }
    });
  });

  group('StatusHero: mọi trạng thái, 100/130/200% ở 360×780, không tràn', () {
    for (final entry in _cases.entries) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('${entry.key} @ ${(scale * 100).round()}%', (tester) async {
          _phone(tester);
          await tester.pumpWidget(
            _app(
              StatusHero(data: entry.value, now: _now, onUnknownAction: () {}),
              scale: scale,
            ),
          );
          expect(tester.takeException(), isNull);
          final data = entry.value;
          expect(find.text(data.displayLevel.label), findsOneWidget);
          expect(_heroColor(tester), StatusColors.light.forLevel(data.displayLevel, lightColorScheme).heroBackground);
          final hero = tester.getRect(find.byKey(const Key('status_hero')));
          expect(hero.width, 360 - 2 * Gutter.compact);
          if (data.known) {
            // Số "được tiêu" luôn nằm gọn trong hero (FittedBox co lại khi dài).
            final numeral = tester.getRect(find.byKey(const Key('status_hero_free')));
            expect(numeral.right, lessThanOrEqualTo(hero.right - HeroSpace.padding + 0.5));
            expect(find.byKey(const Key('floor_ruler')), findsOneWidget);
            expect(find.byKey(const Key('total_balance')), findsOneWidget);
          } else {
            expect(find.byKey(const Key('floor_ruler')), findsNothing);
            expect(find.byKey(const Key('status_hero_free')), findsNothing);
          }
        });
      }
    }

    testWidgets('tối: men đúng màu, chữ trong hero dùng heroForeground', (tester) async {
      _phone(tester);
      for (final data in [_ok(), _warning(), _danger(), const StatusHeroData(level: Level.unknown)]) {
        await tester.pumpWidget(
          _app(
            StatusHero(data: data, now: _now),
            brightness: Brightness.dark,
          ),
        );
        // Dữ liệu đổi trên cùng một hero thì có màn chuyển: chờ xong.
        await tester.pumpAndSettle();
        final colors = StatusColors.dark.forLevel(data.displayLevel, darkColorScheme);
        expect(_heroColor(tester), colors.heroBackground);
        final heading = tester.widget<Text>(find.text(data.displayLevel.label));
        expect(heading.style!.color, colors.heroForeground);
      }
    });
  });

  group('StatusHero: nội dung', () {
    testWidgets('OK: số, dòng ý nghĩa, chú giải, ngữ cảnh lương, giờ cập nhật (giờ VN)', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(StatusHero(data: _ok(), now: _now)));
      expect(find.text('An toàn'), findsOneWidget);
      expect(find.text('4.000.000đ'), findsOneWidget);
      expect(find.text('được tiêu thoải mái · còn 17 ngày'), findsOneWidget);
      expect(find.text('Giữ cho mục tiêu'), findsOneWidget);
      expect(find.text('6.000.000đ'), findsOneWidget);
      expect(find.text('Số dư'), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('total_balance')), matching: find.text('10.000.000đ')),
        findsOneWidget,
      );
      expect(find.text('Lương dự kiến chưa về: 15.000.000đ (ngày 25)'), findsOneWidget);
      expect(find.text('Cập nhật lúc 14:32'), findsOneWidget);
      // Không in level_reason, không có nhãn nhỏ phía trên số.
      expect(find.textContaining('Chỉ còn'), findsNothing);
    });

    testWidgets('WARNING nói vì sao số dương vẫn là cảnh báo', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(StatusHero(data: _warning(), now: _now)));
      expect(find.text('Sắp chạm mức mục tiêu'), findsOneWidget);
      expect(find.text('dưới vùng đệm 600.000đ · còn 17 ngày'), findsOneWidget);
    });

    testWidgets('DANGER: số có dấu "−350.000đ" + "đã lấn vào tiền mục tiêu"', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(StatusHero(data: _danger(), now: _now)));
      expect(find.text('Đã lấn vào tiền dành cho mục tiêu'), findsOneWidget);
      expect(find.text('−350.000đ'), findsOneWidget);
      expect(find.text('đã lấn vào tiền mục tiêu · còn 17 ngày'), findsOneWidget);
    });

    testWidgets('chờ lương, số liệu cũ, offline, ước tính, đang chuyển', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(StatusHero(data: _cases['WARNING chờ lương (dưới mức sàn)']!, now: _now)));
      expect(find.text('đang chờ lương ngày 5 · lương về sẽ đủ'), findsOneWidget);
      // Câu ý nghĩa đã nói về lương: không lặp dòng "Lương dự kiến chưa về".
      expect(find.textContaining('Lương dự kiến'), findsNothing);

      await tester.pumpWidget(
        _app(StatusHero(data: _cases['DANGER số dài, cũ, offline, ước tính, đang chuyển']!, now: _now)),
      );
      expect(find.text('Số dư chưa cập nhật 3 ngày'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.text('Đang offline · số liệu lúc 14:32'), findsOneWidget);
      expect(find.text('Số dư · ước tính'), findsOneWidget);
      expect(find.text('Đang chuyển giữa các TK: 2.000.000đ'), findsOneWidget);
    });

    testWidgets('UNKNOWN: câu hướng dẫn + một nút; bấm gọi onUnknownAction', (tester) async {
      _phone(tester);
      var taps = 0;
      await tester.pumpWidget(
        _app(
          StatusHero(
            data: const StatusHeroData(level: Level.unknown),
            now: _now,
            onUnknownAction: () => taps++,
          ),
        ),
      );
      expect(find.text('Chưa biết số dư'), findsOneWidget);
      expect(find.text('Thêm tài khoản và nhập số dư hiện tại để app tính được phần được tiêu.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('add_account')));
      expect(taps, 1);

      await tester.pumpWidget(
        _app(
          StatusHero(
            data: const StatusHeroData(level: Level.unknown, missingBalanceAccount: 'Vietcombank · …1234'),
            now: _now,
            onUnknownAction: () => taps++,
          ),
        ),
      );
      expect(find.text('Nhập số dư hiện tại của Vietcombank · …1234 để app tính được phần được tiêu.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('enter_balance')));
      expect(taps, 2);
    });

    test('fromSummary: lấy đúng số liệu từ GET /api/summary', () {
      final s = Summary.fromJson(warningSummaryJson());
      final d = StatusHeroData.fromSummary(s, offline: true);
      expect(
        (d.level, d.free, d.balance, d.floor, d.buffer, d.daysLeft),
        (Level.warning, 500000, 6500000, 6000000, 600000, 18),
      );
      expect(d.salaryDay, 5);
      expect(d.offline, isTrue);
      expect(d.known, isTrue);
      final u = StatusHeroData.fromSummary(Summary.fromJson(unknownSummaryJson()));
      expect(u.known, isFalse);
      expect(u.missingBalanceAccount, 'VCB chính ··6789');
    });

    testWidgets('trình đọc màn hình: tiêu đề là header, số đọc thành "… đồng", thước một nút', (tester) async {
      final semantics = tester.ensureSemantics();
      _phone(tester);
      await tester.pumpWidget(_app(StatusHero(data: _ok(), now: _now)));
      expect(tester.getSemantics(find.text('An toàn')), isSemantics(isHeader: true, isLiveRegion: true));
      expect(tester.getSemantics(find.byKey(const Key('status_hero_free'))), matchesSemantics(label: '4000000 đồng'));
      expect(
        tester.getSemantics(find.byKey(const Key('floor_ruler'))).label,
        startsWith('Số dư 10000000 đồng, giữ cho mục tiêu 6000000 đồng'),
      );
      semantics.dispose();
    });
  });

  group('StatusHero: chuyển động đổi trạng thái (≤ 700 ms, một lần, không ở lần vẽ đầu)', () {
    testWidgets('lần vẽ đầu: không chuyển động, không thông báo', (tester) async {
      _phone(tester);
      final said = _recordAnnouncements(tester);
      await tester.pumpWidget(_app(_HeroHost(ValueNotifier(_ok())), supportsAnnounce: true));
      expect(tester.hasRunningAnimations, isFalse);
      expect(said, isEmpty);
    });

    testWidgets('đổi mức OK → WARNING: men chuyển màu, số đếm, tiêu đề đổi, báo một lần', (tester) async {
      _phone(tester);
      final said = _recordAnnouncements(tester);
      final data = ValueNotifier(_ok());
      await tester.pumpWidget(_app(_HeroHost(data), supportsAnnounce: true));

      data.value = _warning();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = _heroColor(tester);
      expect(mid, isNot(StatusColors.light.ok.heroBackground));
      expect(mid, isNot(StatusColors.light.warning.heroBackground));
      // Tiêu đề cũ đang rời đi, tiêu đề mới đang vào.
      expect(find.text('An toàn'), findsOneWidget);
      expect(find.text('Sắp chạm mức mục tiêu'), findsOneWidget);
      // Số đang đếm (giữa hai đầu), trong ô cố định.
      final counting = _numeralText(tester);
      expect(counting, isNot('4.000.000đ'));
      expect(counting, isNot('500.000đ'));

      await tester.pump(const Duration(milliseconds: 601));
      expect(tester.hasRunningAnimations, isFalse, reason: 'tổng thời lượng ≤ 700 ms');
      expect(_heroColor(tester), StatusColors.light.warning.heroBackground);
      expect(find.text('An toàn'), findsNothing);
      expect(_numeralText(tester), '500.000đ');
      expect(said, ['Trạng thái: Sắp chạm mức mục tiêu. Được tiêu 500000 đồng.']);
    });

    testWidgets('chỉ đổi số (cùng mức): đếm lại lặng lẽ, không báo trình đọc màn hình', (tester) async {
      _phone(tester);
      final said = _recordAnnouncements(tester);
      final data = ValueNotifier(_ok());
      await tester.pumpWidget(_app(_HeroHost(data), supportsAnnounce: true));
      data.value = _ok(balance: 9900000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isTrue);
      expect(find.text('An toàn'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(_numeralText(tester), '3.900.000đ');
      expect(said, isEmpty);
    });

    testWidgets('đổi tiếp giữa chừng: bắt đầu từ thứ đang hiện, kết thúc đúng trạng thái cuối', (tester) async {
      _phone(tester);
      final said = _recordAnnouncements(tester);
      final data = ValueNotifier(_ok());
      await tester.pumpWidget(_app(_HeroHost(data), supportsAnnounce: true));
      data.value = _warning();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      data.value = _danger();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_heroColor(tester), StatusColors.light.danger.heroBackground);
      expect(_numeralText(tester), '−350.000đ');
      expect(said, hasLength(2));
      expect(said.last, 'Trạng thái: Đã lấn vào tiền dành cho mục tiêu. Được tiêu âm 350000 đồng.');
    });

    testWidgets('OK ↔ UNKNOWN: thước mờ dần, bố cục đổi, không lỗi', (tester) async {
      _phone(tester);
      final data = ValueNotifier(_ok());
      await tester.pumpWidget(_app(_HeroHost(data, onUnknownAction: () {})));
      data.value = const StatusHeroData(level: Level.unknown);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // 150 ms đầu: bố cục cũ còn đó để thước mờ đi.
      expect(find.byKey(const Key('floor_ruler')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('floor_ruler')), findsNothing);
      expect(find.byKey(const Key('add_account')), findsOneWidget);
      data.value = _ok();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('floor_ruler')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_heroColor(tester), StatusColors.light.ok.heroBackground);
    });

    testWidgets('"Xoá hiệu ứng động": chỉ đổi màu 150 ms, số và tiêu đề đổi ngay', (tester) async {
      _phone(tester);
      final data = ValueNotifier(_ok());
      await tester.pumpWidget(_app(_HeroHost(data), disableAnimations: true));
      data.value = _danger();
      await tester.pump();
      // Ngay lập tức: số cuối (chữ số tỉ lệ), chỉ còn tiêu đề mới.
      expect(_numeralText(tester), '−350.000đ');
      expect(find.text('An toàn'), findsNothing);
      expect(find.text('Đã lấn vào tiền dành cho mục tiêu'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 75));
      final mid = _heroColor(tester);
      expect(mid, isNot(StatusColors.light.danger.heroBackground));
      expect(mid, isNot(StatusColors.light.ok.heroBackground));
      await tester.pump(const Duration(milliseconds: 76));
      expect(tester.hasRunningAnimations, isFalse, reason: 'chỉ 150 ms');
      expect(_heroColor(tester), StatusColors.light.danger.heroBackground);
    });

    testWidgets('nền tảng không hỗ trợ thông báo: tiêu đề là live region, không gửi announce', (tester) async {
      final semantics = tester.ensureSemantics();
      _phone(tester);
      final said = _recordAnnouncements(tester);
      final data = ValueNotifier(_ok());
      await tester.pumpWidget(_app(_HeroHost(data)));
      final before = tester.getSemantics(find.text('An toàn'));
      data.value = _warning();
      await tester.pumpAndSettle();
      final after = tester.getSemantics(find.text('Sắp chạm mức mục tiêu'));
      expect(after, isSemantics(isLiveRegion: true, isHeader: true));
      // Cùng một nút semantics (Android chỉ đọc live region khi nhãn của nút đó đổi).
      expect(after.id, before.id);
      expect(said, isEmpty);
      semantics.dispose();
    });
  });

  group('trạng thái trống / lỗi / offline, tiêu đề phần, danh mục', () {
    testWidgets('dải offline trung tính (không đỏ), có "Thử lại"', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        _app(
          OfflineStrip(
            title: 'Đang offline, không kết nối được máy chủ',
            message: 'Đang hiện số liệu tải lúc 14:32.',
            onRetry: () => retries++,
          ),
        ),
      );
      final theme = buildTheme(Brightness.light);
      final box = tester.widget<Container>(
        find.descendant(of: find.byType(OfflineStrip), matching: find.byType(Container)).first,
      );
      expect((box.decoration! as BoxDecoration).color, theme.colorScheme.surfaceContainerHigh);
      for (final t in tester.widgetList<Text>(
        find.descendant(of: find.byType(OfflineStrip), matching: find.byType(Text)),
      )) {
        expect(t.style?.color, isNot(theme.colorScheme.error));
      }
      await tester.tap(find.text('Thử lại'));
      expect(retries, 1);
    });

    testWidgets('ErrorView và EmptyState', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 600,
            child: Column(
              children: [
                Expanded(
                  child: ErrorView(
                    title: 'Không tải được tổng quan',
                    message: 'Không kết nối được máy chủ',
                    onRetry: () => retries++,
                  ),
                ),
                const EmptyState(
                  icon: Icons.flag_outlined,
                  title: 'Chưa có mục tiêu tháng 10',
                  message: 'Đặt mục tiêu để được báo khi số dư xuống gần mức cần giữ.',
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Không tải được tổng quan'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Thử lại'));
      expect(retries, 1);
      expect(find.text('Chưa có mục tiêu tháng 10'), findsOneWidget);
    });

    testWidgets('tiêu đề phần: titleLarge, là header, trên 32 dp dưới 8 dp', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(const SectionHeader('Mục tiêu tháng 10')));
      final text = tester.widget<Text>(find.text('Mục tiêu tháng 10'));
      expect(text.style!.fontSize, 22);
      expect(text.style!.fontWeight, FontWeight.w700);
      expect(tester.getSemantics(find.text('Mục tiêu tháng 10')), isSemantics(isHeader: true));
      final padding = tester.widget<Padding>(
        find.descendant(of: find.byType(SectionHeader), matching: find.byType(Padding)).first,
      );
      expect(padding.padding, const EdgeInsets.only(top: 32, bottom: 8));
      semantics.dispose();
    });

    test('danh mục mặc định của máy chủ dùng icon Material; danh mục tự tạo giữ emoji', () {
      final food = CategoryVisual.resolve(systemKey: 'food', emoji: '🍜');
      expect(food.icon, Icons.restaurant_outlined);
      expect(food.emoji, isNull);
      expect(food.label('Ăn uống'), 'Ăn uống');
      final custom = CategoryVisual.resolve(emoji: '🎮');
      expect(custom.icon, isNull);
      expect(custom.label('Giải trí'), '🎮 Giải trí');
      expect(CategoryVisual.resolve(systemKey: null, emoji: ' ').isEmpty, isTrue);
      // Mọi system_key mà backend tạo sẵn (backend/app/seed.py) đều có icon.
      final seed = File('../backend/app/seed.py').readAsStringSync();
      final block = seed.substring(seed.indexOf('CATEGORIES = ['), seed.indexOf(']', seed.indexOf('CATEGORIES = [')));
      final keys = RegExp(r'\("(\w+)", "').allMatches(block).map((m) => m.group(1)!).toSet();
      expect(keys, isNotEmpty);
      expect(systemCategoryIcons.keys.toSet(), keys);
    });

    testWidgets('pill: "Chưa phân loại" là lời mời (primaryContainer), không phải lỗi', (tester) async {
      await tester.pumpWidget(_app(const Pill('Chưa phân loại', tone: PillTone.invitation)));
      final box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(Pill), matching: find.byType(DecoratedBox)).first,
      );
      final scheme = buildTheme(Brightness.light).colorScheme;
      expect((box.decoration as BoxDecoration).color, scheme.primaryContainer);
      expect(tester.getSize(find.byType(Pill)).height, greaterThanOrEqualTo(28));
    });
  });
}

/// Canvas ghi lại các hình bo tròn được vẽ (kiểm tra hình học của thước, không cần vẽ thật).
class _RecordingCanvas implements Canvas {
  final rrects = <RRect>[];

  @override
  void drawRRect(RRect rrect, Paint paint) => rrects.add(rrect);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
