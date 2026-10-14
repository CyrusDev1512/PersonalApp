import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance/api/api_client.dart';
import 'package:personal_finance/main.dart';
import 'package:personal_finance/models/models.dart';
import 'package:personal_finance/state/app_state.dart';
import 'package:personal_finance/widgets/forecast_card.dart';
import 'package:personal_finance/widgets/status_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

Future<void> _pumpCard(WidgetTester tester, Forecast? forecast, {String month = '2026-10'}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: ForecastCard(forecast: forecast, month: month)),
      ),
    ),
  );
}

Color? _headlineColor(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('forecast_headline'))).style?.color;

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
  });

  group('parse Forecast theo docs/api.md', () {
    test('đủ trường, ngày "YYYY-MM-DD" là ngày địa phương', () {
      final f = Forecast.fromJson(forecastJson());
      expect(f.isOk, isTrue);
      expect(f.confidence, 'normal');
      expect(f.isLowConfidence, isFalse);
      expect(f.observedDays, 14);
      expect(f.windowDays, 14);
      expect(f.dailySpend, 180000);
      expect(f.cappedAmount, 4000000);
      expect(f.cappedCount, 1);
      expect(f.projectedFreeEnd, -350000);
      expect(f.projectedBudgetOverrun, 1000000);
      expect(f.floorHitDate, DateTime(2026, 10, 25));
      expect(f.floorHitDate!.isUtc, isFalse);
      expect(f.daysUntilFloorHit, 11);
      expect(f.recoversOn, isNull);
      expect(f.safeDailySpend, 120000);
      expect(f.headline, 'Chi như hiện tại thì khoảng ngày 25/10 sẽ chạm mức sàn');
      expect(f.details, hasLength(2));
      expect(f.budgets, hasLength(2));
      final food = f.budgets.first;
      expect(food.goalId, 2);
      expect(food.label, '🍜 Tiền ăn');
      expect(food.projectedPct, 120.0);
      expect(food.isOverPace, isTrue);
      expect(food.suggestedDaily, 133333);
      expect(f.budgetsNeedingAttention.map((b) => b.name), ['Tiền ăn']);
    });

    test('dễ tính: thiếu trường, số dạng chuỗi/thực, ngày sai', () {
      final f = Forecast.fromJson({
        'status': 'ok',
        'daily_spend': '180000',
        'safe_daily_spend': 120000.6,
        'floor_hit_date': '2026-02-31',
        'recovers_on': '2026-11-05',
        'details': ['', 'Một dòng', null],
        'budgets': [
          {'name': 'Tiền ăn', 'projected_pct': '130.4', 'status': 'exceeded'},
          'rác',
        ],
      });
      expect(f.dailySpend, 180000);
      expect(f.safeDailySpend, 120001);
      expect(f.floorHitDate, isNull);
      expect(f.recoversOn, DateTime(2026, 11, 5));
      expect(f.details, ['Một dòng']);
      expect(f.budgets.single.isExceeded, isTrue);
      expect(f.budgets.single.projectedPct, closeTo(130.4, 0.001));
      expect(f.confidence, 'normal');
      expect(f.headline, isNull);

      expect(Forecast.fromJson({}).isUnavailable, isTrue);
    });

    test('Summary.forecast: có, null (tháng cũ), không phải object', () {
      expect(Summary.fromJson({...warningSummaryJson(), 'forecast': forecastJson()}).forecast?.isOk, isTrue);
      expect(Summary.fromJson({...warningSummaryJson(), 'forecast': null}).forecast, isNull);
      expect(Summary.fromJson(warningSummaryJson()).forecast, isNull);
      expect(Summary.fromJson({...warningSummaryJson(), 'forecast': 'ok'}).forecast, isNull);
      final s = Summary.fromJson({...warningSummaryJson(), 'forecast': forecastJson()});
      expect(s.copyWith(unreadAlerts: 0).forecast, same(s.forecast));
    });

    test('mức độ: đỏ ≤ 7 ngày, hổ phách trong tháng, còn lại thường', () {
      Forecast f(String? date, int? days) =>
          Forecast.fromJson(forecastJson(floorHitDate: date, daysUntilFloorHit: days));
      expect(f('2026-10-19', 5).severity(month: '2026-10'), ForecastSeverity.danger);
      expect(f('2026-10-21', 7).severity(month: '2026-10'), ForecastSeverity.danger);
      expect(f('2026-10-14', 0).severity(month: '2026-10'), ForecastSeverity.danger);
      expect(f('2026-10-25', 11).severity(month: '2026-10'), ForecastSeverity.warning);
      expect(f('2026-11-02', null).severity(month: '2026-10'), ForecastSeverity.neutral);
      expect(f(null, null).severity(month: '2026-10'), ForecastSeverity.neutral);
      expect(
        Forecast.fromJson(forecastJson(status: 'insufficient_data', daysUntilFloorHit: 2)).severity(),
        ForecastSeverity.neutral,
      );
    });
  });

  group('ForecastCard', () {
    testWidgets('chạm mức sàn trong ≤ 7 ngày: tiêu đề đỏ', (tester) async {
      await _pumpCard(
        tester,
        Forecast.fromJson(
          forecastJson(
            floorHitDate: '2026-10-19',
            daysUntilFloorHit: 5,
            headline: 'Chi như hiện tại thì khoảng ngày 19/10 sẽ chạm mức sàn',
          ),
        ),
      );
      expect(find.byKey(const Key('forecast_card')), findsOneWidget);
      expect(find.text('Chi như hiện tại thì khoảng ngày 19/10 sẽ chạm mức sàn'), findsOneWidget);
      expect(_headlineColor(tester), Colors.red.shade700);
    });

    testWidgets('chạm mức sàn trong tháng: tiêu đề hổ phách + chi tiết, gợi ý, ngân sách vượt nhịp', (tester) async {
      await _pumpCard(tester, Forecast.fromJson(forecastJson()));
      expect(_headlineColor(tester), Colors.amber.shade800);
      expect(find.text('Chi như hiện tại thì khoảng ngày 25/10 sẽ chạm mức sàn'), findsOneWidget);
      expect(find.text('Tốc độ chi ngoài mục tiêu: ~180.000đ/ngày (14 ngày gần nhất)'), findsOneWidget);
      expect(find.text('Nên chi tối đa ~120.000đ/ngày'), findsOneWidget);
      expect(find.text('Được tiêu cuối tháng (dự kiến): -350.000đ'), findsOneWidget);
      // Chỉ ngân sách over_pace/exceeded.
      expect(find.text('Ngân sách vượt nhịp'), findsOneWidget);
      expect(
        find.textContaining('🍜 Tiền ăn: dự kiến 120% · gợi ý ~133.333đ/ngày', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('Cà phê', findRichText: true), findsNothing);
      expect(find.textContaining('Ước tính sơ bộ'), findsNothing);
    });

    testWidgets('không chạm mức sàn: màu thường; ít dữ liệu thì ghi "Ước tính sơ bộ"', (tester) async {
      await _pumpCard(
        tester,
        Forecast.fromJson({
          ...forecastJson(
            floorHitDate: null,
            daysUntilFloorHit: null,
            confidence: 'low',
            observedDays: 4,
            headline: 'Chi như hiện tại thì cuối tháng vẫn trên mức sàn',
          ),
          'budgets': <Object>[],
          'projected_free_end': 800000,
        }),
      );
      final color = _headlineColor(tester);
      expect(color, isNot(Colors.red.shade700));
      expect(color, isNot(Colors.amber.shade800));
      expect(find.text('Chi như hiện tại thì cuối tháng vẫn trên mức sàn'), findsOneWidget);
      expect(find.text('Ước tính sơ bộ (mới có 4 ngày dữ liệu)'), findsOneWidget);
      expect(find.text('Ngân sách vượt nhịp'), findsNothing);
      expect(find.text('Được tiêu cuối tháng (dự kiến): 800.000đ'), findsOneWidget);
    });

    testWidgets('chưa đủ dữ liệu: chỉ hiện câu chữ mờ', (tester) async {
      await _pumpCard(
        tester,
        Forecast.fromJson({
          'status': 'insufficient_data',
          'reason': 'Mới có 1 ngày dữ liệu',
          'headline': 'Chưa đủ dữ liệu để dự báo (cần ~3 ngày)',
        }),
      );
      expect(find.byKey(const Key('forecast_card')), findsOneWidget);
      expect(find.text('Chưa đủ dữ liệu để dự báo (cần ~3 ngày)'), findsOneWidget);
      expect(find.text('Mới có 1 ngày dữ liệu'), findsOneWidget);
      expect(find.textContaining('Nên chi tối đa'), findsNothing);
      final muted = Theme.of(tester.element(find.byKey(const Key('forecast_headline')))).colorScheme.onSurfaceVariant;
      expect(_headlineColor(tester), muted);
    });

    testWidgets('ẩn khi không có dự báo hoặc chưa biết số dư', (tester) async {
      await _pumpCard(tester, null);
      expect(find.byKey(const Key('forecast_card')), findsNothing);
      await _pumpCard(tester, Forecast.fromJson({'status': 'unavailable', 'headline': 'Chưa biết số dư'}));
      expect(find.byKey(const Key('forecast_card')), findsNothing);
      expect(ForecastCard.shouldShow(null), isFalse);
    });
  });

  group('Tổng quan', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<FakeServer> pumpDashboard(WidgetTester tester, Object? forecast) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final server = FakeServer({
        'GET /api/summary': (_) => {...warningSummaryJson(), 'forecast': forecast},
        'GET /api/goals': (_) => <Object>[],
      });
      final state = AppState(
        client: ApiClient(baseUrl: 'https://finance.example.com', token: 'tok', client: server.client),
        refreshInterval: null,
      );
      addTearDown(state.dispose);
      await tester.pumpWidget(PersonalFinanceApp(state: state, refreshInterval: null));
      await tester.pumpAndSettle();
      return server;
    }

    testWidgets('thẻ dự báo nằm ngay dưới banner trạng thái', (tester) async {
      await pumpDashboard(tester, forecastJson());
      final card = find.byKey(const Key('forecast_card'));
      expect(card, findsOneWidget);
      final banner = tester.getRect(find.byType(StatusBanner));
      final rect = tester.getRect(card);
      expect(rect.top, greaterThan(banner.bottom));
      expect(rect.top - banner.bottom, lessThan(20));
      expect(find.text('Nên chi tối đa ~120.000đ/ngày'), findsOneWidget);
    });

    testWidgets('không có forecast (tháng cũ) thì không có thẻ', (tester) async {
      await pumpDashboard(tester, null);
      expect(find.byType(StatusBanner), findsOneWidget);
      expect(find.byKey(const Key('forecast_card')), findsNothing);
    });
  });
}
