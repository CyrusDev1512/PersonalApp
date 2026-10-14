import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance/api/api_client.dart';
import 'package:personal_finance/models/models.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
  });

  ApiClient clientFor(FakeServer server, {String baseUrl = 'https://finance.example.com/'}) =>
      ApiClient(baseUrl: baseUrl, token: 'tok-123', client: server.client);

  group('xác thực', () {
    test('gửi header Authorization: Bearer <token> cho /api/*', () async {
      final server = FakeServer({'GET /api/summary': (_) => warningSummaryJson()});
      await clientFor(server).getSummary(month: '2026-10');

      final req = server.requests.single;
      expect(req.headers['Authorization'], 'Bearer tok-123');
      expect(req.url.toString(), 'https://finance.example.com/api/summary?month=2026-10');
    });

    test('/health không gửi token', () async {
      final server = FakeServer({
        'GET /health': (_) => {'status': 'ok', 'time': '2026-10-14T03:00:00Z', 'version': '0.1.0'},
      });
      final health = await clientFor(server).health();
      expect(health['status'], 'ok');
      expect(server.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('401 -> ApiException "Sai token"', () async {
      final server = FakeServer({
        'GET /api/summary': (_) => jsonResponse({'detail': 'Unauthorized'}, 401),
      });
      await expectLater(
        clientFor(server).getSummary(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)
              .having((e) => e.message, 'message', contains('Sai token')),
        ),
      );
    });
  });

  group('parse Summary theo docs/api.md', () {
    test('các trường chính, GoalView, Account, Alert', () async {
      final server = FakeServer({'GET /api/summary': (_) => warningSummaryJson()});
      final s = await clientFor(server).getSummary();

      expect(s.month, '2026-10');
      expect(s.level, Level.warning);
      expect(s.levelReason, 'Chỉ còn 500.000đ trên mức sàn 6.000.000đ');
      expect(s.balance, 6500000);
      expect(s.balanceKnown, isTrue);
      expect(s.floor, 6000000);
      expect(s.free, 500000);
      expect(s.buffer, 600000);
      expect(s.waitingIncome, isFalse);
      expect(s.expectedIncome?.amount, 15000000);
      expect(s.expectedIncome?.day, 5);
      expect(s.daysLeft, 18);
      expect(s.uncategorizedCount, 1);
      expect(s.unreadAlerts, 2);
      expect(s.ingestHealth.stale, isFalse);
      expect(s.ingestHealth.sources['email']?['enabled'], isTrue);

      // Thời gian UTC "Z" -> giờ máy (.toLocal()) nhưng cùng thời điểm.
      expect(s.balanceAsOf, isNotNull);
      expect(s.balanceAsOf!.isUtc, isFalse);
      expect(s.balanceAsOf!.toUtc(), DateTime.utc(2026, 10, 14, 2, 59));

      final acc = s.accounts.single;
      expect(acc.bank, 'VCB');
      expect(acc.last4, '6789');
      expect(acc.includeInTotal, isTrue);
      expect(acc.balanceDerived, isFalse);
      expect(acc.manualBalance, 10000000);
      expect(acc.manualBalanceAt!.toUtc(), DateTime.utc(2026, 10, 13, 17));

      expect(s.goals, hasLength(2));
      final rent = s.goals.first;
      expect(rent.name, 'Tiền trọ');
      expect(rent.isReserve, isTrue);
      expect(rent.typeLabel, 'Quỹ giữ');
      expect(rent.amount, 3000000);
      expect(rent.remaining, 3000000);
      expect(rent.categoryIcon, '🏠');
      expect(rent.autoMatch, isTrue);
      final food = s.goals[1];
      expect(food.isBudget, isTrue);
      expect(food.typeLabel, 'Ngân sách');
      expect(food.spent, 2000000);
      expect(food.usagePct, 40.0);
      expect(food.progress, closeTo(0.4, 1e-9));

      final alert = s.latestAlerts.single;
      expect(alert.id, 10);
      expect(alert.kind, 'tx');
      expect(alert.level, Level.warning);
      expect(alert.read, isFalse);
      expect(alert.transactionId, 55);
      expect(alert.goalId, isNull);
    });

    test('UNKNOWN: balance/free/balance_as_of null, expected_income null', () async {
      final server = FakeServer({'GET /api/summary': (_) => unknownSummaryJson()});
      final s = await clientFor(server).getSummary();
      expect(s.level, Level.unknown);
      expect(s.balance, isNull);
      expect(s.free, isNull);
      expect(s.balanceAsOf, isNull);
      expect(s.expectedIncome, isNull);
      expect(s.accountsMissingBalance.single.id, 1);
    });

    test('chịu được số thực thay số nguyên và thiếu trường', () {
      final s = Summary.fromJson({
        'month': '2026-10',
        'level': 'OK',
        'balance': 10000000.0,
        'floor': 6000000.0,
        'free': '4000000',
        'goals': [
          {'id': 3.0, 'name': 'X', 'type': 'budget', 'amount': 1000.0, 'spent': 1500, 'usage_pct': 150},
        ],
        'accounts': null,
      });
      expect(s.balance, 10000000);
      expect(s.balanceKnown, isTrue);
      expect(s.floor, 6000000);
      expect(s.free, 4000000);
      expect(s.accounts, isEmpty);
      expect(s.latestAlerts, isEmpty);
      expect(s.goals.single.id, 3);
      expect(s.goals.single.usagePct, 150.0);
      expect(s.goals.single.overspent, isTrue);
      expect(s.goals.single.progress, 1.0);
      expect(s.goals.single.remaining, 0);
    });
  });

  group('các endpoint khác', () {
    test('PATCH giao dịch gửi body và trả transaction + summary', () async {
      final server = FakeServer({
        'PATCH /api/transactions/55': (req) => {
          'transaction': {
            'id': 55,
            'direction': 'out',
            'amount': 3500000,
            'bank_time': '2026-10-14T02:59:00Z',
            'description': 'RUT TIEN ATM',
            'category_id': 2,
            'category_name': 'Thuê trọ',
            'status': 'active',
            'sources': ['sepay', 'email'],
            'possible_duplicate_of': null,
          },
          'summary': warningSummaryJson(),
        },
      });
      final result = await clientFor(server)
          .patchTransaction(55, {'category_id': 2, 'remember_rule': true, 'rule_pattern': 'rut tien atm'});
      expect(server.requests.single.json, {'category_id': 2, 'remember_rule': true, 'rule_pattern': 'rut tien atm'});
      expect(server.requests.single.headers['Content-Type'], startsWith('application/json'));
      expect(result.transaction.categoryName, 'Thuê trọ');
      expect(result.transaction.sources, ['sepay', 'email']);
      expect(result.transaction.isUncategorized, isFalse);
      expect(result.summary?.level, Level.warning);
    });

    test('danh sách giao dịch: query đúng tên tham số', () async {
      final server = FakeServer({
        'GET /api/transactions': (_) => {
          'items': [
            {'id': 1, 'direction': 'out', 'amount': 50000, 'status': 'pending', 'possible_duplicate_of': 7},
          ],
          'total': 120,
        },
      });
      final page = await clientFor(server).listTransactions(month: '2026-10', uncategorized: true, offset: 50);
      final q = server.requests.single.url.queryParameters;
      expect(q, {'month': '2026-10', 'uncategorized': 'true', 'limit': '50', 'offset': '50'});
      expect(page.total, 120);
      expect(page.items.single.isPending, isTrue);
      expect(page.items.single.isPossibleDuplicate, isTrue);
    });

    test('tạo mục tiêu, xoá với stop_series, cài đặt', () async {
      final server = FakeServer({
        'POST /api/goals': (req) => jsonResponse({...?(req.json as Map<String, dynamic>?), 'id': 9, 'spent': 0}, 201),
        'DELETE /api/goals/9': (_) => http.Response('', 204),
        'PUT /api/settings': (req) => req.json,
        'POST /api/alerts/read-all': (_) => {'updated': 3},
      });
      final api = clientFor(server);
      final goal = await api.createGoal(
        const GoalInput(name: 'Tiền ăn', type: GoalType.budget, amount: 5000000, categoryId: 1, month: '2026-10'),
      );
      expect(server.requests.last.json, {
        'name': 'Tiền ăn',
        'type': 'budget',
        'amount': 5000000,
        'category_id': 1,
        'month': '2026-10',
        'repeat_monthly': true,
        'opening_spent': 0,
      });
      expect(goal.id, 9);

      await api.deleteGoal(9, stopSeries: true);
      expect(server.requests.last.url.queryParameters['stop_series'], 'true');

      final saved = await api.updateSettings(
        const AppSettings(warningPercent: 15, expectedIncomeAmount: 15000000, expectedIncomeDay: 5),
      );
      expect(saved.warningPercent, 15);
      expect(saved.usesExpectedIncome, isTrue);

      expect(await api.markAllAlertsRead(), 3);
    });

    test('lỗi validate 422 của FastAPI -> thông báo dễ đọc', () async {
      final server = FakeServer({
        'POST /api/goals': (_) => jsonResponse({
          'detail': [
            {
              'loc': ['body', 'amount'],
              'msg': 'Input should be greater than 0',
              'type': 'greater_than',
            },
          ],
        }, 422),
      });
      await expectLater(
        clientFor(server).createGoal(const GoalInput(name: 'x', type: 'reserve', amount: 1)),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', 'amount: Input should be greater than 0'),
        ),
      );
    });

    test('lỗi 400 với detail chuỗi tiếng Việt (UTF-8 không ghi charset)', () async {
      final server = FakeServer({
        'DELETE /api/transactions/5': (_) => jsonResponse({'detail': 'Chỉ xoá được giao dịch nhập tay'}, 400),
      });
      await expectLater(
        clientFor(server).deleteTransaction(5),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Chỉ xoá được giao dịch nhập tay')),
      );
    });
  });

  group('lỗi mạng', () {
    test('ClientException -> ApiException isNetwork', () async {
      final api = ApiClient(
        baseUrl: 'http://192.168.1.10:8000',
        token: 't',
        client: MockClient((_) async => throw http.ClientException('Connection refused')),
      );
      await expectLater(
        api.getSummary(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isNetwork, 'isNetwork', isTrue)
              .having((e) => e.statusCode, 'statusCode', isNull)
              .having((e) => e.message, 'message', ApiMessages.network),
        ),
      );
    });

    test('quá thời gian -> ApiException timeout', () async {
      final never = Completer<http.Response>();
      final api = ApiClient(
        baseUrl: 'https://finance.example.com',
        token: 't',
        client: MockClient((_) => never.future),
        timeout: const Duration(milliseconds: 50),
      );
      await expectLater(
        api.getSummary(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isNetwork, 'isNetwork', isTrue)
              .having((e) => e.message, 'message', ApiMessages.timeout),
        ),
      );
    });

    test('mặc định timeout 15 giây', () {
      final api = ApiClient(
        baseUrl: 'https://a.example',
        token: 't',
        client: MockClient((_) async => jsonResponse({})),
      );
      expect(api.timeout, const Duration(seconds: 15));
    });

    test('URL không hợp lệ bị từ chối, URL hợp lệ được chuẩn hoá', () {
      for (final bad in ['', 'finance.example.com', 'ftp://x.com', 'http://', 'https://x.com/?a=1']) {
        expect(() => ApiClient.normalizeBaseUrl(bad), throwsA(isA<ApiException>()), reason: bad);
      }
      expect(ApiClient.normalizeBaseUrl(' https://finance.example.com/ '), 'https://finance.example.com');
      expect(ApiClient.normalizeBaseUrl('http://192.168.1.10:8000'), 'http://192.168.1.10:8000');
      expect(ApiClient.isInsecureUrl('http://192.168.1.10:8000'), isTrue);
      expect(ApiClient.isInsecureUrl('https://finance.example.com'), isFalse);
    });

    test('baseUrl có đường dẫn con', () async {
      final server = FakeServer({'GET /finance/api/goals': (_) => <Object>[]});
      final api = clientFor(server, baseUrl: 'https://example.com/finance/');
      expect(await api.listGoals(month: '2026-10'), isEmpty);
      expect(server.requests.single.url.toString(), 'https://example.com/finance/api/goals?month=2026-10');
    });
  });
}
