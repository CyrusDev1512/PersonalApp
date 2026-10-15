import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance/api/api_client.dart';
import 'package:personal_finance/main.dart';
import 'package:personal_finance/models/models.dart';
import 'package:personal_finance/state/app_state.dart';
import 'package:personal_finance/theme/status_colors.dart';
import 'package:personal_finance/widgets/forecast_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

Future<void> _pumpCard(WidgetTester tester, Forecast? forecast, {String month = '2026-10'}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ForecastCard(forecast: forecast, month: month),
        ),
      ),
    ),
  );
}

Color? _headlineColor(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('forecast_headline'))).style?.color;

/// Số dòng chữ trên màn hình có chứa [needle] (để bắt nội dung bị lặp).
int _linesContaining(WidgetTester tester, String needle) => tester
    .widgetList<Text>(find.byType(Text))
    .where((t) => (t.data ?? t.textSpan?.toPlainText() ?? '').contains(needle))
    .length;

/// `forecast_dict()` thật của backend (độ tin cậy thấp, một ngân sách vượt nhịp).
const _realBackendForecast = <String, dynamic>{
  'status': 'ok',
  'confidence': 'low',
  'reason': null,
  'observed_days': 5,
  'window_days': 5,
  'daily_spend': 514286,
  'capped_amount': 0,
  'capped_count': 0,
  'projected_free_end': -10661751,
  'projected_budget_overrun': 4790322,
  'income_pending': 0,
  'floor_hit_date': '2026-10-17',
  'days_until_floor_hit': 12,
  'recovers_on': null,
  'safe_daily_spend': 100358,
  'headline': 'Chi như hiện tại thì khoảng ngày 17/10 sẽ chạm mức sàn',
  'details': [
    'Tốc độ chi ngoài mục tiêu: ~514.286đ/ngày (ước tính theo tháng trước)',
    'Gợi ý: chi ngoài mục tiêu tối đa ~100.358đ/ngày để giữ trên mức sàn',
    '🍜 Tiền ăn uống hằng ngày của cả gia đình: với tốc độ này sẽ dùng 260% ngân sách — nên chi tối đa ~55.555đ/ngày',
    'Ước tính sơ bộ: mới có 5 ngày dữ liệu',
  ],
  'budgets': [
    {
      'goal_id': 2,
      'name': 'Tiền ăn uống hằng ngày của cả gia đình',
      'category_icon': '🍜',
      'spent': 1500000,
      'amount': 3000000,
      'daily_rate': 241935,
      'projected_spent': 7790323,
      'projected_pct': 259.7,
      'status': 'over_pace',
      'suggested_daily': 55555,
    },
  ],
};

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
      expect(f.details, hasLength(4));
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
    testWidgets('chạm mức sàn trong ≤ 7 ngày: tiêu đề hổ phách + icon xu hướng giảm (không đỏ)', (tester) async {
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
      // The Red Is Earned Rule: dự báo chưa phải tiền mục tiêu đang bị dùng, nên không đỏ (đỏ chỉ ở hero DANGER).
      // "Trong 7 ngày" được nói bằng icon trending_down.
      expect(_headlineColor(tester), StatusColors.light.warning.foreground);
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('chạm mức sàn trong tháng: tiêu đề hổ phách + đúng các dòng chi tiết của server, không lặp', (
      tester,
    ) async {
      final json = forecastJson();
      await _pumpCard(tester, Forecast.fromJson(json));
      expect(_headlineColor(tester), StatusColors.light.warning.foreground);
      expect(find.text('Chi như hiện tại thì khoảng ngày 25/10 sẽ chạm mức sàn'), findsOneWidget);
      // Gợi ý chi/ngày thành câu "Nên chi tối đa ~120.000đ mỗi ngày"; dòng "Gợi ý: …" cùng số của máy chủ
      // không lặp lại. Các dòng chi tiết khác giữ nguyên văn.
      expect(find.text('Nên chi tối đa ~120.000đ mỗi ngày'), findsOneWidget);
      for (final line in json['details'] as List<String>) {
        expect(find.text(line), line.contains('~120.000đ') ? findsNothing : findsOneWidget);
      }
      expect(_linesContaining(tester, '120.000đ'), 1);
      expect(_linesContaining(tester, 'Tiền ăn'), 1);
      expect(_linesContaining(tester, '133.333đ'), 1);
      expect(find.textContaining('Cà phê'), findsNothing);
      // Số được tiêu cuối tháng thành câu (âm = thiếu cho mục tiêu).
      expect(find.text('Cuối tháng dự kiến thiếu ~350.000đ cho mục tiêu'), findsOneWidget);
      expect(find.textContaining('Ước tính sơ bộ'), findsNothing);
    });

    testWidgets('dữ liệu thật của backend: mỗi ý chỉ hiện một lần', (tester) async {
      tester.view.physicalSize = const Size(360, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await _pumpCard(tester, Forecast.fromJson(_realBackendForecast));
      expect(tester.takeException(), isNull);
      for (final line in _realBackendForecast['details'] as List<String>) {
        expect(find.text(line), line.contains('~100.358đ') ? findsNothing : findsOneWidget);
      }
      expect(_linesContaining(tester, '100.358đ'), 1);
      expect(_linesContaining(tester, 'Tiền ăn uống'), 1);
      expect(_linesContaining(tester, 'Ước tính sơ bộ'), 1);
      expect(find.text('Cuối tháng dự kiến thiếu ~10.661.751đ cho mục tiêu'), findsOneWidget);
    });

    testWidgets('không chạm mức sàn: màu thường; ít dữ liệu thì có dòng "Ước tính sơ bộ" của server', (tester) async {
      await _pumpCard(
        tester,
        Forecast.fromJson({
          ...forecastJson(
            floorHitDate: null,
            daysUntilFloorHit: null,
            confidence: 'low',
            observedDays: 4,
            headline: 'Chi như hiện tại, cuối tháng còn khoảng 800.000đ được tiêu',
          ),
          'projected_free_end': 800000,
        }),
      );
      final color = _headlineColor(tester);
      expect(color, isNot(StatusColors.light.danger.foreground));
      expect(color, isNot(StatusColors.light.warning.foreground));
      expect(find.text('Chi như hiện tại, cuối tháng còn khoảng 800.000đ được tiêu'), findsOneWidget);
      expect(find.text('Ước tính sơ bộ: mới có 4 ngày dữ liệu'), findsOneWidget);
      expect(_linesContaining(tester, 'Ước tính sơ bộ'), 1);
      // Tiêu đề đã nói số được tiêu cuối tháng.
      expect(find.byKey(const Key('forecast_free_end')), findsNothing);
      expect(_linesContaining(tester, '800.000đ'), 1);
    });

    testWidgets('server không gửi headline: tiêu đề dự phòng + được tiêu cuối tháng', (tester) async {
      await _pumpCard(
        tester,
        Forecast.fromJson({
          ...forecastJson(floorHitDate: null, daysUntilFloorHit: null, headline: null),
          'projected_free_end': 800000,
        }),
      );
      expect(find.text('Chi như hiện tại thì cuối tháng vẫn trên mức sàn'), findsOneWidget);
      expect(find.text('Cuối tháng dự kiến còn ~800.000đ được tiêu'), findsOneWidget);
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
      expect(find.byKey(const Key('forecast_free_end')), findsNothing);
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

    testWidgets('khối dự báo nằm dưới status hero, trước mục tiêu tháng', (tester) async {
      await pumpDashboard(tester, forecastJson());
      final card = find.byKey(const Key('forecast_card'));
      expect(card, findsOneWidget);
      expect(find.text('Dự báo cuối tháng'), findsOneWidget);
      final hero = tester.getRect(find.byKey(const Key('status_hero')));
      final rect = tester.getRect(card);
      final goals = tester.getRect(find.text('Mục tiêu tháng 10'));
      expect(rect.top, greaterThan(hero.bottom));
      expect(rect.bottom, lessThan(goals.top));
      expect(find.text('Nên chi tối đa ~120.000đ mỗi ngày'), findsOneWidget);
    });

    testWidgets('không có forecast (tháng cũ) thì không có thẻ', (tester) async {
      await pumpDashboard(tester, null);
      expect(find.byKey(const Key('status_hero')), findsOneWidget);
      expect(find.byKey(const Key('forecast_card')), findsNothing);
    });
  });
}
