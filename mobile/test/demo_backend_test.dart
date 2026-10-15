import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:personal_finance/api/api_client.dart';
import 'package:personal_finance/demo/demo_backend.dart';
import 'package:personal_finance/models/models.dart';

/// 15/10/2026 14:00 giờ VN.
final DateTime _now = DateTime.utc(2026, 10, 15, 7);

class _Demo {
  _Demo({DateTime? now}) : clock = now ?? _now {
    backend = DemoBackend(clock: () => clock, latency: Duration.zero, pushDelay: Duration.zero);
    client = ApiClient(baseUrl: 'https://demo.local', token: 'demo', client: backend);
  }

  DateTime clock;
  late final DemoBackend backend;
  late final ApiClient client;

  int get vcb => backend.bankAccounts.firstWhere((a) => a.bank == 'VCB').id;

  Future<DemoSimulation> atm() => backend.simulateBankTx(
    accountId: vcb,
    direction: 'out',
    amount: 3500000,
    description: 'RUT TIEN ATM VCB LE DUAN',
  );

  Future<DemoSimulation> salary() => backend.simulateBankTx(
    accountId: vcb,
    direction: 'in',
    amount: 15000000,
    description: 'CONG TY TNHH ABC TRA LUONG',
  );

  /// Như app: PushController đăng ký thiết bị rồi mới nhận được thông báo đẩy.
  Future<void> registerDevice() =>
      client.registerDevice(token: 'demo-web-token-1', platform: 'android', appVersion: '1.0.0');

  void advance(Duration d) => clock = clock.add(d);
}

void main() {
  late _Demo demo;

  setUp(() => demo = _Demo());
  tearDown(() => demo.backend.dispose());

  test('trạng thái đầu: OK, được tiêu 4.000.000đ trên mức sàn 6.000.000đ', () async {
    final s = await demo.client.getSummary();
    expect(s.month, '2026-10');
    expect(s.level, Level.ok);
    expect(s.balance, 10000000);
    expect(s.floor, 6000000);
    expect(s.free, 4000000);
    expect(s.buffer, 600000);
    expect(s.levelReason, 'Còn 4.000.000đ có thể tiêu thoải mái');
    expect(s.daysLeft, 17);
    expect(s.accounts.map((a) => a.name), ['VCB chính', 'MB phụ']);
    expect(s.accounts.every((a) => a.includeInTotal && a.balanceKnown), isTrue);

    final rent = s.goals.firstWhere((g) => g.name == 'Tiền trọ');
    expect(rent.isReserve, isTrue);
    expect((rent.amount, rent.spent, rent.remaining), (3000000, 0, 3000000));
    final food = s.goals.firstWhere((g) => g.name == 'Tiền ăn');
    expect(food.isBudget, isTrue);
    expect((food.amount, food.spent, food.usagePct), (5000000, 2000000, 40.0));
    expect(food.categoryIcon, '🍜');

    expect(s.uncategorizedCount, 2);
    expect(s.unreadAlerts, 0);
    expect(s.latestAlerts, isNotEmpty);
    expect(s.expectedIncome?.amount, 15000000);
    expect(s.expectedIncome?.pending, 15000000);
    expect(s.ingestHealth.hasProblems, isFalse);

    final fc = s.forecast!;
    expect(fc.isOk, isTrue);
    expect(fc.observedDays, 14);
    expect(fc.floorHitDate, isNull);
    expect(fc.headline, startsWith('Chi như hiện tại, cuối tháng còn khoảng'));
    expect(fc.details.first, startsWith('Tốc độ chi ngoài mục tiêu: ~'));
    expect(fc.budgets.single.name, 'Tiền ăn');

    final alerts = await demo.client.listAlerts();
    expect(alerts.length, 3);
    expect(alerts.map((a) => a.kind).toSet(), {'push_test', 'tx', 'digest'});
  });

  test('"Rút ATM 3.500.000đ": WARNING, được tiêu 500.000đ, cảnh báo đổi mức kèm dự báo, có đẩy', () async {
    await demo.client.getSummary();
    await demo.registerDevice();
    final pushes = <DemoPush>[];
    final sub = demo.backend.pushes.listen(pushes.add);
    addTearDown(sub.cancel);

    final r = await demo.atm();
    expect(r.level, 'WARNING');
    expect(r.free, 500000);
    expect(r.pushed, isTrue);
    expect(r.alertTitles, ['⚠️ Sắp chạm mức mục tiêu']);

    final s = await demo.client.getSummary();
    expect(s.level, Level.warning);
    expect(s.free, 500000);
    expect(s.levelReason, 'Chỉ còn 500.000đ trên mức sàn 6.000.000đ');
    expect(s.unreadAlerts, 1);
    expect(s.uncategorizedCount, 3);
    expect(s.forecast!.floorHitDate, DateTime(2026, 10, 18));
    expect(s.forecast!.recoversOn, DateTime(2026, 10, 25));
    expect(s.forecast!.cappedCount, 1);

    final alert = s.latestAlerts.first;
    expect(alert.kind, 'tx');
    expect(alert.level, Level.warning);
    expect(alert.transactionId, r.transactionId);
    expect(alert.message, contains('−3.500.000đ · VCB chính · 14:00 15/10'));
    expect(alert.message, contains('Danh mục: (chưa phân loại)'));
    expect(alert.message, contains('Số dư: 6.500.000đ'));
    expect(alert.message, contains('Mức sàn: 6.000.000đ · Được tiêu: 500.000đ'));
    expect(alert.message, contains('⚠️ Sắp chạm mức mục tiêu: Chỉ còn 500.000đ trên mức sàn 6.000.000đ'));
    expect(alert.message, contains('📉 Dự báo: Chi như hiện tại thì khoảng ngày 18/10 sẽ chạm mức sàn'));

    final tx = await demo.client.getTransaction(r.transactionId);
    expect(tx.balanceAfter, 5920000);
    expect(tx.isUncategorized, isTrue);
    expect(tx.sources, ['sepay']);
    expect(tx.suggestedRule, 'le duan');

    await pumpEventQueue();
    expect(pushes, hasLength(1));
    expect(pushes.single.title, '⚠️ Sắp chạm mức mục tiêu');
    expect(pushes.single.data['alert_id'], '${alert.id}');
    expect(pushes.single.data['transaction_id'], '${r.transactionId}');
    expect(pushes.single.data['level'], 'WARNING');
    expect(pushes.single.data['month'], '2026-10');
  });

  test('không có thiết bị đăng ký thì không có thông báo đẩy', () async {
    final r = await demo.atm();
    expect(r.level, 'WARNING');
    expect(r.pushed, isFalse);
  });

  test('"Nhận lương 15.000.000đ" sau khi rút ATM: an toàn trở lại (OK), hết chờ lương', () async {
    await demo.atm();
    demo.advance(const Duration(minutes: 30));
    final r = await demo.salary();
    expect(r.level, 'OK');
    expect(r.alertTitles, ['✅ An toàn trở lại']);
    final s = await demo.client.getSummary();
    expect(s.level, Level.ok);
    expect(s.free, 15500000);
    expect(s.expectedIncome?.pending, 0);
    final tx = await demo.client.getTransaction(r.transactionId);
    expect(tx.categoryName, 'Thu nhập');
    expect(tx.categorizedBy, 'rule');
  });

  test('chuyển tiền trọ tự phân loại, trừ vào quỹ giữ: được tiêu không đổi, cảnh báo im lặng', () async {
    final r = await demo.backend.simulateBankTx(
      accountId: demo.vcb,
      direction: 'out',
      amount: 3000000,
      description: 'CHUYEN TIEN TRO CHO CO HOA',
    );
    expect(r.level, 'OK');
    expect(r.free, 4000000);
    expect(r.pushed, isFalse);
    expect(r.alertTitles, ['💸 Chi 3.000.000đ']);
    final s = await demo.client.getSummary();
    expect(s.floor, 3000000);
    expect(s.goals.firstWhere((g) => g.name == 'Tiền trọ').spent, 3000000);
    expect(s.unreadAlerts, 0);
  });

  test('ngân sách ăn uống vượt 80% thì có cảnh báo ngân sách', () async {
    await demo.registerDevice();
    final r = await demo.backend.simulateBankTx(
      accountId: demo.vcb,
      direction: 'out',
      amount: 2100000,
      description: 'NHA HANG TIEC SINH NHAT',
    );
    expect(r.alertTitles, ['📊 Ngân sách sắp hết']);
    expect(r.pushed, isTrue);
    final alert = (await demo.client.listAlerts()).first;
    expect(alert.message, contains('🍜 Tiền ăn đã dùng 82% (4.100.000đ/5.000.000đ) — còn 900.000đ cho 17 ngày'));
  });

  test('thêm mục tiêu làm giảm "được tiêu"; sửa, xoá mục tiêu', () async {
    final goal = await demo.client.createGoal(
      const GoalInput(name: 'Quỹ dự phòng', type: GoalType.reserve, amount: 1000000),
    );
    expect(goal.month, '2026-10');
    expect(goal.remaining, 1000000);
    expect(goal.autoMatch, isTrue);
    expect((await demo.client.getSummary()).free, 3000000);

    final updated = await demo.client.updateGoal(goal.id, {'amount': 1500000});
    expect(updated.amount, 1500000);
    expect((await demo.client.getSummary()).free, 2500000);

    await demo.client.deleteGoal(goal.id);
    final s = await demo.client.getSummary();
    expect(s.free, 4000000);
    expect(s.goals.map((g) => g.name), isNot(contains('Quỹ dự phòng')));

    await expectLater(
      demo.client.createGoal(const GoalInput(name: 'Sai', type: GoalType.budget, amount: 1000)),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Ngân sách chi tiêu cần chọn danh mục')),
    );
  });

  test('mục tiêu tháng sau: tạo trước rồi xem bằng ?month=', () async {
    final categories = await demo.client.listCategories();
    final rent = categories.firstWhere((c) => c.systemKey == 'rent');
    expect(await demo.client.listGoals(month: '2026-11'), isEmpty);
    final next = await demo.client.createGoal(
      GoalInput(name: 'Tiền trọ', type: GoalType.reserve, amount: 3200000, categoryId: rent.id, month: '2026-11'),
    );
    final current = (await demo.client.listGoals()).firstWhere((g) => g.name == 'Tiền trọ');
    expect(next.seriesId, current.seriesId);
    expect((await demo.client.listGoals(month: '2026-11')).single.amount, 3200000);
  });

  test('phân loại giao dịch: tính lại tổng quan, nhớ luật, tính cho tháng sau', () async {
    final page = await demo.client.listTransactions(uncategorized: true);
    expect(page.total, 2);
    final coffee = page.items.firstWhere((t) => t.description.contains('CA PHE'));
    expect(coffee.suggestedRule, 'ca phe muoi');
    final food = (await demo.client.listCategories()).firstWhere((c) => c.systemKey == 'food');

    final result = await demo.client.patchTransaction(coffee.id, {
      'category_id': food.id,
      'remember_rule': true,
      'rule_pattern': coffee.suggestedRule,
    });
    expect(result.transaction.categoryName, 'Ăn uống');
    expect(result.transaction.categorizedBy, 'user');
    final s = result.summary!;
    expect(s.uncategorizedCount, 1);
    expect(s.goals.firstWhere((g) => g.name == 'Tiền ăn').spent, 2045000);
    expect(s.free, 4045000);

    // Luật vừa nhớ được dùng cho biến động sau.
    final r = await demo.backend.simulateBankTx(
      accountId: demo.vcb,
      direction: 'out',
      amount: 39000,
      description: 'CA PHE MUOI QUAN 3',
    );
    expect((await demo.client.getTransaction(r.transactionId)).categoryName, 'Ăn uống');

    final rentTx = await demo.backend.simulateBankTx(
      accountId: demo.vcb,
      direction: 'out',
      amount: 3000000,
      description: 'CHUYEN TIEN TRO CHO CO HOA',
    );
    final moved = await demo.client.patchTransaction(rentTx.transactionId, {'for_next_month': true});
    expect(moved.transaction.goalMonth, '2026-11');
    expect(moved.transaction.countedForLaterMonth, isTrue);
    expect(moved.summary!.goals.firstWhere((g) => g.name == 'Tiền trọ').spent, 0);
    expect((await demo.client.listGoals(month: '2026-11')).single.spent, 3000000);

    final excluded = await demo.client.patchTransaction(r.transactionId, {'excluded': true});
    expect(excluded.transaction.isExcluded, isTrue);

    await expectLater(
      demo.client.patchTransaction(coffee.id, {'category_id': 999}),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 400)),
    );
  });

  test('đặt lại dữ liệu demo (giữ thiết bị, không đẩy lại cảnh báo cũ)', () async {
    await demo.registerDevice();
    final pushes = <DemoPush>[];
    final sub = demo.backend.pushes.listen(pushes.add);
    addTearDown(sub.cancel);
    await demo.atm();
    await demo.client.createGoal(const GoalInput(name: 'Quỹ', type: GoalType.reserve, amount: 1000000));
    expect((await demo.client.getSummary()).level, Level.warning);
    demo.backend.reset();
    final s = await demo.client.getSummary();
    expect(s.level, Level.ok);
    expect(s.free, 4000000);
    expect(s.goals, hasLength(2));
    expect((await demo.client.listAlerts()).length, 3);
    expect((await demo.client.listDevices()).devices, hasLength(1));
    await pumpEventQueue();
    expect(pushes.map((p) => p.title), ['⚠️ Sắp chạm mức mục tiêu']);
  });

  test('mọi endpoint app gọi trả JSON đọc được bằng model thật', () async {
    expect((await demo.client.health())['status'], 'ok');

    final categories = await demo.client.listCategories();
    expect(categories.map((c) => c.systemKey).take(3), ['food', 'rent', 'transport']);
    final created = await demo.client.createCategory(name: 'Học phí', icon: '🎓');
    expect((created.name, created.isExpense, created.icon), ('Học phí', true, '🎓'));
    await expectLater(
      demo.client.createCategory(name: 'Học phí'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Danh mục đã tồn tại')),
    );

    final all = await demo.client.listTransactions();
    expect(all.total, greaterThanOrEqualTo(20));
    expect(all.items.first.bankTime!.isAfter(all.items.last.bankTime!), isTrue);
    final paged = await demo.client.listTransactions(limit: 5, offset: 5);
    expect(paged.items.map((t) => t.id), all.items.skip(5).take(5).map((t) => t.id));
    final cash = all.items.firstWhere((t) => t.isManual);
    expect(cash.title, 'Bún chả vỉa hè');
    expect(cash.affectsBalance, isFalse);
    final october = await demo.client.listTransactions(month: '2026-09');
    expect(october.items, isEmpty);

    final manual = await demo.client.createTransaction(direction: 'out', amount: 50000, description: 'Bánh mì');
    expect(manual.isManual, isTrue);
    await demo.client.deleteTransaction(manual.id);
    await expectLater(
      demo.client.deleteTransaction(all.items.firstWhere((t) => !t.isManual).id),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 400)),
    );
    await expectLater(
      demo.client.getTransaction(99999),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Không tìm thấy giao dịch')),
    );

    final accounts = await demo.client.listAccounts();
    expect(accounts.map((a) => a.bankLabel), ['Vietcombank', 'MB Bank']);
    final acc = await demo.client.createAccount(
      bank: 'OTHER',
      name: 'Ví phụ',
      accountNumber: '123 456 7890',
      balance: 200000,
    );
    expect((acc.bank, acc.last4, acc.balance), ('OTHER', '7890', 200000));
    expect((await demo.client.getSummary()).free, 4200000);
    final updated = await demo.client.setAccountBalance(acc.id, 300000);
    expect(updated.balance, 300000);
    final excluded = await demo.client.updateAccount(acc.id, {'include_in_total': false});
    expect(excluded.includeInTotal, isFalse);
    await demo.client.deleteAccount(acc.id);
    expect(await demo.client.listAccounts(), hasLength(2));

    final settings = await demo.client.getSettings();
    expect(settings.usesExpectedIncome, isTrue);
    final saved = await demo.client.updateSettings(settings.copyWith(warningMinAmount: 5000000));
    expect(saved.warningMinAmount, 5000000);
    expect((await demo.client.getSummary()).level, Level.warning);

    final reg = await demo.client.registerDevice(token: 'demo-web-token-1', platform: 'android', appVersion: '1.0.0');
    expect(reg.pushEnabled, isTrue);
    final devices = await demo.client.listDevices();
    expect(devices.pushEnabled, isTrue);
    expect(devices.devices, hasLength(1));
    final pushed = demo.backend.pushes.first;
    final test = await demo.client.sendTestPush();
    expect(test.queued, isTrue);
    expect((await pushed).title, '🔔 Thử thông báo');
    await demo.client.unregisterDevice('demo-web-token-1');
    expect((await demo.client.listDevices()).devices, isEmpty);

    final alerts = await demo.client.listAlerts(limit: 100);
    final one = await demo.client.getAlert(alerts.first.id);
    expect(one.id, alerts.first.id);
    final read = await demo.client.markAlertRead(one.id);
    expect(read.read, isTrue);
    expect(await demo.client.markAllAlertsRead(), greaterThanOrEqualTo(1));
    expect(await demo.client.listAlerts(unread: true), isEmpty);
  });

  test('cần token; đường dẫn lạ trả 404', () async {
    final noToken = ApiClient(baseUrl: 'https://demo.local', token: '', client: demo.backend);
    await expectLater(noToken.getSummary(), throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', true)));
    await expectLater(
      demo.client.getSummary(month: '2026-13'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'month phải có dạng YYYY-MM')),
    );
  });

  test('dữ liệu mẫu theo thời điểm: đầu tháng (có cả tháng trước) và sau ngày lương', () async {
    final early = _Demo(now: DateTime.utc(2026, 11, 2, 3));
    addTearDown(early.backend.dispose);
    final s1 = await early.client.getSummary();
    expect(s1.month, '2026-11');
    expect(s1.level, Level.ok);
    expect(s1.free, 4000000);
    expect(s1.goals.firstWhere((g) => g.name == 'Tiền ăn').spent, 2000000);
    expect(s1.forecast!.isOk, isTrue);
    expect(s1.forecast!.isLowConfidence, isTrue);
    expect((await early.client.listTransactions(month: '2026-10')).total, greaterThan(0));

    final late = _Demo(now: DateTime.utc(2026, 10, 29, 5));
    addTearDown(late.backend.dispose);
    final s2 = await late.client.getSummary();
    expect(s2.free, 4000000);
    expect(s2.expectedIncome?.pending, 0);
    final salary = (await late.client.listTransactions()).items.where((t) => t.categoryName == 'Thu nhập');
    expect(salary.single.amount, 15000000);
  });

  test('độ trễ mô phỏng mặc định ~150 ms', () {
    final backend = DemoBackend();
    addTearDown(backend.dispose);
    expect(backend.latency, const Duration(milliseconds: 150));
    unawaited(Future<void>.value());
  });

  group('ở mọi thời điểm (giờ VN): trạng thái đầu giống nhau, "Rút ATM" luôn báo to + đẩy, lương báo an toàn', () {
    final clocks = <String, DateTime>{
      'ngày 1 lúc 00:00:30': DateTime.utc(2026, 10, 31, 17, 0, 30),
      'ngày 1 lúc 00:10': DateTime.utc(2026, 10, 31, 17, 10),
      'ngày 1 lúc 09:00': DateTime.utc(2026, 11, 1, 2),
      'ngày 3 lúc 00:30': DateTime.utc(2026, 10, 2, 17, 30),
      'ngày 5 lúc 00:30': DateTime.utc(2026, 10, 4, 17, 30),
      'ngày 5 lúc 08:00': DateTime.utc(2026, 10, 5, 1),
      'ngày 15 lúc 14:00': DateTime.utc(2026, 10, 15, 7),
      'ngày 26 lúc 00:10 (vừa nhận lương)': DateTime.utc(2026, 10, 25, 17, 10),
      'ngày 31 lúc 23:50': DateTime.utc(2026, 10, 31, 16, 50),
      '01/03 lúc 00:05 (sau tháng 2 ngắn)': DateTime.utc(2027, 2, 28, 17, 5),
    };
    for (final MapEntry(key: label, value: at) in clocks.entries) {
      test(label, () async {
        final demo = _Demo(now: at);
        addTearDown(demo.backend.dispose);
        final month =
            '${at.add(const Duration(hours: 7)).year}-'
            '${at.add(const Duration(hours: 7)).month.toString().padLeft(2, '0')}';

        final s = await demo.client.getSummary();
        expect(s.month, month);
        expect(s.level, Level.ok);
        expect((s.balance, s.floor, s.free, s.buffer), (10000000, 6000000, 4000000, 600000));
        expect(s.levelReason, 'Còn 4.000.000đ có thể tiêu thoải mái');
        expect(s.goals.firstWhere((g) => g.name == 'Tiền ăn').spent, 2000000);
        expect(s.uncategorizedCount, 2);
        final txs = await demo.client.listTransactions(limit: 500);
        expect(txs.items.every((t) => !t.bankTime!.isAfter(at)), isTrue, reason: 'không có giao dịch ở tương lai');

        await demo.registerDevice();
        final pushes = <DemoPush>[];
        final sub = demo.backend.pushes.listen(pushes.add);
        addTearDown(sub.cancel);

        final atm = await demo.atm();
        expect((atm.level, atm.free, atm.important, atm.pushed), ('WARNING', 500000, true, true));
        expect(atm.alertTitles, ['⚠️ Sắp chạm mức mục tiêu']);
        final after = await demo.client.getSummary();
        expect(after.levelReason, 'Chỉ còn 500.000đ trên mức sàn 6.000.000đ');
        expect(after.unreadAlerts, 1);
        expect(after.latestAlerts.first.title, '⚠️ Sắp chạm mức mục tiêu');
        expect(after.latestAlerts.first.read, isFalse);
        await pumpEventQueue();
        expect(pushes.map((p) => p.title), ['⚠️ Sắp chạm mức mục tiêu']);

        demo.advance(const Duration(minutes: 5));
        final salary = await demo.salary();
        expect((salary.level, salary.pushed), ('OK', true));
        expect(salary.alertTitles, ['✅ An toàn trở lại']);
        await pumpEventQueue();
        expect(pushes.map((p) => p.title), ['⚠️ Sắp chạm mức mục tiêu', '✅ An toàn trở lại']);
      });
    }
  });

  group('JSON giống hệt backend (serialize.py, routes.py)', () {
    Future<(int, Object?)> raw(String method, String path, [Object? body]) async {
      final request = http.Request(method, Uri.parse('https://demo.local$path'))
        ..headers['Authorization'] = 'Bearer demo';
      if (body != null) {
        request
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode(body);
      }
      final response = await http.Response.fromStream(await demo.backend.send(request));
      final text = utf8.decode(response.bodyBytes);
      return (response.statusCode, text.isEmpty ? null : jsonDecode(text));
    }

    Set<String> keys(Object? json) => (json! as Map<String, dynamic>).keys.toSet();

    const accountKeys = {
      'id', 'bank', 'name', 'account_number', 'last4', 'include_in_total', 'confirmed', 'balance', //
      'balance_as_of', 'balance_derived', 'manual_balance', 'manual_balance_at',
    };
    const goalKeys = {
      'id', 'series_id', 'name', 'type', 'amount', 'category_id', 'category_name', 'category_icon', 'month', //
      'repeat_monthly', 'opening_spent', 'spent', 'remaining', 'usage_pct', 'auto_match',
    };
    const alertKeys = {'id', 'created_at', 'kind', 'level', 'title', 'message', 'read', 'transaction_id', 'goal_id'};
    const txKeys = {
      'id', 'account_id', 'account_name', 'bank', 'direction', 'amount', 'bank_time', 'time_precision', //
      'description', 'reference_code', 'counter_account', 'counter_name', 'balance_after', 'category_id',
      'category_name', 'category_icon', 'goal_id', 'goal_name', 'goal_month', 'categorized_by', 'suggested_rule',
      'status', 'is_manual', 'affects_balance', 'pair_id', 'sources', 'possible_duplicate_of',
    };
    const evaluationKeys = {
      'month', 'level', 'level_reason', 'balance', 'balance_known', 'in_transit', 'floor', 'free', 'buffer', //
      'waiting_income', 'days_left', 'goals',
    };
    const summaryKeys = {
      ...evaluationKeys, 'generated_at', 'balance_as_of', 'expected_income', 'accounts', 'uncategorized_count', //
      'unread_alerts', 'latest_alerts', 'ingest_health', 'forecast',
    };
    const forecastKeys = {
      'status', 'confidence', 'reason', 'observed_days', 'window_days', 'daily_spend', 'capped_amount', //
      'capped_count', 'projected_free_end', 'projected_budget_overrun', 'income_pending', 'floor_hit_date',
      'days_until_floor_hit', 'recovers_on', 'safe_daily_spend', 'headline', 'details', 'budgets',
    };
    const budgetPaceKeys = {
      'goal_id', 'name', 'category_icon', 'spent', 'amount', 'daily_rate', 'projected_spent', 'projected_pct', //
      'status', 'suggested_daily',
    };

    test('bộ khoá của từng loại đối tượng', () async {
      final (_, summary) = await raw('GET', '/api/summary');
      expect(keys(summary), summaryKeys);
      final s = summary! as Map<String, dynamic>;
      expect(keys(s['expected_income']), {'amount', 'day', 'pending'});
      expect(keys(s['ingest_health']), {'stale', 'warnings', 'error_events', 'unparsed_events', 'sources'});
      expect(keys(s['forecast']), forecastKeys);
      expect(keys((s['forecast'] as Map)['budgets'][0]), budgetPaceKeys);
      expect(keys((s['accounts'] as List).first), accountKeys);
      expect(keys((s['goals'] as List).first), goalKeys);
      expect(keys((s['latest_alerts'] as List).first), alertKeys);

      final (_, txPage) = await raw('GET', '/api/transactions');
      expect(keys(txPage), {'items', 'total'});
      final tx = ((txPage! as Map)['items'] as List).first as Map<String, dynamic>;
      expect(keys(tx), txKeys);
      final (_, oneTx) = await raw('GET', '/api/transactions/${tx['id']}');
      expect(keys(oneTx), txKeys);
      final (patchStatus, patched) = await raw('PATCH', '/api/transactions/${tx['id']}', {'excluded': false});
      expect(patchStatus, 200);
      expect(keys(patched), {'transaction', 'summary'});
      expect(keys((patched! as Map)['summary']), summaryKeys);

      final (_, goals) = await raw('GET', '/api/goals');
      expect(keys((goals! as List).first), goalKeys);
      final (_, accounts) = await raw('GET', '/api/accounts');
      expect(keys((accounts! as List).first), accountKeys);
      final (_, alerts) = await raw('GET', '/api/alerts');
      expect(keys((alerts! as List).first), alertKeys);
      final (_, categories) = await raw('GET', '/api/categories');
      expect(keys((categories! as List).first), {'id', 'name', 'kind', 'icon', 'sort_order', 'system_key'});
      final (_, rules) = await raw('GET', '/api/categories/1/rules');
      expect(keys((rules! as List).first), {'id', 'category_id', 'pattern', 'direction', 'priority', 'origin'});
      final (_, settings) = await raw('GET', '/api/settings');
      expect(keys(settings), {
        'warning_percent', 'warning_min_amount', 'expected_income_amount', 'expected_income_day', 'notify_every_tx', //
      });
      final (regStatus, reg) = await raw('POST', '/api/devices', {'token': 'demo-web-token-1', 'platform': 'android'});
      expect(regStatus, 201);
      expect(keys(reg), {'id', 'platform', 'app_version', 'last_seen_at', 'push_enabled'});
      expect((await raw('POST', '/api/devices', {'token': 'demo-web-token-1'})).$1, 200);
      final (_, devices) = await raw('GET', '/api/devices');
      expect(keys(devices), {'push_enabled', 'error', 'devices'});
      expect(keys(((devices! as Map)['devices'] as List).first), {
        'id',
        'platform',
        'app_version',
        'created_at',
        'last_seen_at',
        'last_error',
      });
      final (testStatus, testPush) = await raw('POST', '/api/devices/test');
      expect(testStatus, 202);
      expect(keys(testPush), {'queued', 'push_enabled'});
      expect(keys((await raw('POST', '/api/alerts/read-all')).$2), {'updated'});
      final (healthStatus, health) = await raw('GET', '/health');
      expect(healthStatus, 200);
      expect(keys(health), {'status', 'time', 'version'});
    });

    test('lỗi trả đúng chuỗi tiếng Việt của routes.py (404 theo đối tượng, 400), đường dẫn lạ "Not Found"', () async {
      Future<Object?> detail(String method, String path) async => ((await raw(method, path)).$2! as Map)['detail'];
      Future<void> notFound(String method, String path, String detail, [Object? body]) async {
        final (status, json) = await raw(method, path, body);
        expect(status, 404, reason: '$method $path');
        expect(json, {'detail': detail}, reason: '$method $path');
      }

      await notFound('GET', '/api/transactions/99999', 'Không tìm thấy giao dịch');
      await notFound('GET', '/api/alerts/99999', 'Không tìm thấy cảnh báo');
      await notFound('POST', '/api/alerts/99999/read', 'Không tìm thấy cảnh báo');
      await notFound('PATCH', '/api/goals/99999', 'Không tìm thấy mục tiêu', {'amount': 1});
      await notFound('DELETE', '/api/goals/99999', 'Không tìm thấy mục tiêu');
      await notFound('PATCH', '/api/accounts/99999', 'Không tìm thấy tài khoản', {'name': 'x'});
      await notFound('GET', '/api/khong-co', 'Not Found');

      final bankTx = (await demo.client.listTransactions()).items.firstWhere((t) => !t.isManual);
      expect(
        await detail('DELETE', '/api/transactions/${bankTx.id}'),
        'Chỉ xoá được giao dịch nhập tay — giao dịch ngân hàng hãy dùng "Loại trừ"',
      );
      expect(
        await detail('DELETE', '/api/accounts/${bankTx.accountId}'),
        'Tài khoản đã có giao dịch — hãy tắt "Tính vào tổng" thay vì xoá',
      );
      // ApiClient hiện nguyên văn `detail` cho người dùng.
      await expectLater(
        demo.client.getAlert(99999),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Không tìm thấy cảnh báo')),
      );
    });

    test('lỗi 400 giữa chừng không để lại thay đổi nào (như rollback của backend)', () async {
      Future<Object?> get(String path) async => (await raw('GET', path)).$2;
      void expect400((int, Object?) response, String detail) {
        expect(response.$1, 400);
        expect(response.$2, {'detail': detail});
      }

      final accounts = (await get('/api/accounts'))! as List;
      final (vcb, mb) = (accounts[0] as Map, accounts[1] as Map);
      final txsBefore = await get('/api/transactions?limit=500');
      final foodRules =
          '/api/categories/${(await demo.client.listCategories()).firstWhere((c) => c.name == 'Ăn uống').id}/rules';
      final rulesBefore = await get(foodRules);

      // Đổi tên + số tài khoản trùng: 400 và tên cũ vẫn giữ nguyên.
      expect400(
        await raw('PATCH', '/api/accounts/${mb['id']}', {
          'name': 'MB đổi tên',
          'account_number': vcb['account_number'],
        }),
        'Số tài khoản đã tồn tại',
      );
      expect(await get('/api/accounts'), accounts);

      // Loại trừ + phân loại + nhớ luật rồi mới gặp mục tiêu không tồn tại: không đổi giao dịch, số dư hay luật.
      final items = ((txsBefore! as Map)['items'] as List).cast<Map<String, dynamic>>();
      final food = items.firstWhere((t) => t['category_name'] == 'Ăn uống' && t['is_manual'] == false);
      final foodId = food['category_id'];
      expect400(
        await raw('PATCH', '/api/transactions/${food['id']}', {
          'excluded': true,
          'category_id': foodId,
          'remember_rule': true,
          'rule_pattern': 'mon an moi',
          'goal_id': 99999,
        }),
        'Mục tiêu không tồn tại',
      );
      // Lỗi ở bước cuối (tính cho tháng sau khi chưa thuộc mục tiêu nào).
      final uncategorized = items.firstWhere((t) => t['category_id'] == null && t['direction'] == 'out');
      expect400(
        await raw('PATCH', '/api/transactions/${uncategorized['id']}', {'excluded': true, 'for_next_month': true}),
        'Giao dịch chưa thuộc mục tiêu nào — hãy chọn danh mục trước',
      );

      expect(await get('/api/transactions?limit=500'), txsBefore);
      expect(await get('/api/accounts'), accounts);
      expect(await get(foodRules), rulesBefore);
    });
  });

  test('bản tin sáng chỉ có khi đã qua 08:00 hôm nay (không ghi ngày hôm qua với số liệu hôm nay)', () async {
    for (final (at, expected) in [
      (DateTime.utc(2026, 10, 31, 17, 10), null), // 01/11 lúc 00:10
      (DateTime.utc(2026, 10, 4, 17, 30), null), // 05/10 lúc 00:30
      (DateTime.utc(2026, 10, 5, 1), '☀️ Bản tin tài chính 05/10'), // 05/10 lúc 08:00
      (DateTime.utc(2026, 10, 15, 7), '☀️ Bản tin tài chính 15/10'),
    ]) {
      final d = _Demo(now: at);
      addTearDown(d.backend.dispose);
      final digests = (await d.client.listAlerts()).where((a) => a.kind == 'digest').toList();
      expect(digests.map((a) => a.title).firstOrNull, expected, reason: '$at');
      expect(digests.every((a) => !a.createdAt!.isAfter(at)), isTrue, reason: '$at');
    }
  });
}
