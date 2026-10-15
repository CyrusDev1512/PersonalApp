import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'demo_engine.dart';
import 'demo_text.dart';

/// Một thông báo đẩy mà máy chủ giả "gửi" tới thiết bị đã đăng ký (giống payload FCM của backend).
class DemoPush {
  const DemoPush({required this.title, required this.body, required this.data});

  final String title;
  final String body;

  /// `alert_id`, `kind`, `level`, `transaction_id`, `goal_id`, `month` — mọi giá trị là chuỗi.
  final Map<String, String> data;
}

/// Kết quả "Giả lập biến động số dư".
class DemoSimulation {
  const DemoSimulation({
    required this.transactionId,
    required this.alertTitles,
    required this.important,
    required this.pushed,
    required this.level,
    required this.free,
  });

  final int transactionId;

  /// Tiêu đề các cảnh báo vừa tạo (kể cả cảnh báo im lặng).
  final List<String> alertTitles;

  /// Có cảnh báo quan trọng (loại được gửi thông báo đẩy, `push_outbox.should_push`) vừa được tạo không.
  final bool important;

  /// Có cảnh báo quan trọng được đẩy tới thiết bị không (cần [important] và một thiết bị đã đăng ký).
  final bool pushed;

  /// Mức sau giao dịch (OK | WARNING | DANGER | UNKNOWN).
  final String level;

  /// "Được tiêu thoải mái" sau giao dịch.
  final int? free;
}

/// Tài khoản ngân hàng chọn được khi giả lập.
typedef DemoAccountChoice = ({int id, String name, String bank});

/// Máy chủ giả có trạng thái, chạy ngay trong app (bản dùng thử trên trình duyệt, không cần server).
///
/// Là một [http.BaseClient] nên cắm thẳng vào `ApiClient(client: DemoBackend())`: mọi endpoint app gọi
/// (docs/api.md) được trả JSON đúng hình dạng của backend thật, và ngữ nghĩa được port gọn từ
/// `backend/app` (mức sàn, được tiêu, vùng đệm, mức cảnh báo, cảnh báo ngân sách 80/100%, cảnh báo đổi mức,
/// tin từng giao dịch, dự báo cuối tháng). Dữ liệu mẫu được tạo theo thời điểm hiện tại.
class DemoBackend extends http.BaseClient {
  DemoBackend({
    DateTime Function()? clock,
    this.latency = const Duration(milliseconds: 150),
    this.pushDelay = const Duration(milliseconds: 400),
  }) : _clock = clock ?? DateTime.now {
    _seed();
  }

  /// Độ trễ mô phỏng của mỗi request.
  final Duration latency;

  /// Độ trễ mô phỏng của thông báo đẩy (FCM) sau khi cảnh báo được tạo.
  final Duration pushDelay;

  final DateTime Function() _clock;

  DateTime now() => _clock().toUtc();

  final StreamController<DemoPush> _pushes = StreamController<DemoPush>.broadcast();
  final Set<Timer> _timers = {};
  bool _closed = false;

  /// Đang tạo dữ liệu mẫu: cảnh báo cũ không được đẩy lại tới thiết bị.
  bool _seeding = false;

  /// Thông báo đẩy tới các thiết bị đã đăng ký (POST /api/devices).
  Stream<DemoPush> get pushes => _pushes.stream;

  // ------------------------------------------------------------------ dữ liệu

  final List<_Category> _categories = [];
  final List<DemoRule> _rules = [];
  final List<_Account> _accounts = [];
  final List<_Goal> _goals = [];
  final List<_Tx> _txs = [];
  final List<_Alert> _alerts = [];
  final List<_Device> _devices = [];
  _Settings _settings = _Settings();
  final Map<String, FloorState> _floorStates = {};
  final Map<String, bool> _budgetArmed = {};
  final Map<String, ForecastState> _forecastStates = {};
  final Set<String> _unknownNotified = {};
  DateTime? _sepayLastEvent;
  final Map<String, int> _ids = {};
  final math.Random _random = math.Random(2026);

  int _nextId(String table) => _ids[table] = (_ids[table] ?? 0) + 1;

  String _uuid() => List.generate(32, (_) => _random.nextInt(16).toRadixString(16)).join();

  /// Tài khoản ngân hàng (không gồm ví tiền mặt) để chọn khi giả lập.
  List<DemoAccountChoice> get bankAccounts => [
    for (final a in _accounts)
      if (a.bank != 'CASH') (id: a.id, name: a.name, bank: a.bank),
  ];

  /// Đặt lại toàn bộ dữ liệu mẫu (giữ thiết bị đã đăng ký nhận thông báo đẩy).
  void reset() => _seed();

  void dispose() {
    _closed = true;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    unawaited(_pushes.close());
  }

  // ------------------------------------------------------------------ HTTP

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (_closed) throw http.ClientException('Máy chủ demo đã đóng', request.url);
    _Resp resp;
    try {
      resp = _route(request.method, request.url, request.headers, bytes);
    } on _HttpError catch (e) {
      resp = _Resp(e.status, {'detail': e.detail});
    }
    final body = resp.body == null ? <int>[] : utf8.encode(jsonEncode(resp.body));
    return http.StreamedResponse(
      Stream.value(body),
      resp.status,
      contentLength: body.length,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }

  _Resp _route(String method, Uri url, Map<String, String> headers, List<int> bytes) {
    final segs = url.pathSegments.where((s) => s.isNotEmpty).toList();
    final q = url.queryParameters;
    if (segs.length == 1 && segs[0] == 'health') {
      if (method != 'GET') throw const _HttpError(405, 'Method Not Allowed');
      return _Resp(200, {'status': 'ok', 'time': isoZ(now()), 'version': '0.1.0'});
    }
    if (segs.isEmpty || segs[0] != 'api') throw const _HttpError(404, 'Not Found');
    final auth = headers['authorization'] ?? headers['Authorization'] ?? '';
    if (!auth.startsWith('Bearer ') || auth.substring(7).trim().isEmpty) {
      throw const _HttpError(401, 'Unauthorized');
    }
    final p = segs.sublist(1);
    final route = '$method ${p.isEmpty ? '' : p.first}';
    _Json body() => _decodeBody(bytes);

    switch (p.length) {
      case 1:
        switch (route) {
          case 'GET summary':
            return _Resp(200, _summaryPayload(_monthParam(q['month'])));
          case 'GET goals':
            return _Resp(200, [for (final g in _evaluation(_monthParam(q['month'])).goals) g.toJson()]);
          case 'POST goals':
            return _createGoal(body());
          case 'GET categories':
            return _Resp(200, [for (final c in _sortedCategories()) c.toJson()]);
          case 'POST categories':
            return _createCategory(body());
          case 'GET transactions':
            return _listTransactions(q);
          case 'POST transactions':
            return _createTransaction(body());
          case 'GET accounts':
            return _Resp(200, [for (final a in _bankAccountRows()) a.toJson()]);
          case 'POST accounts':
            return _createAccount(body());
          case 'GET alerts':
            return _listAlerts(q);
          case 'POST devices':
            return _registerDevice(body());
          case 'GET devices':
            return _Resp(200, {
              'push_enabled': true,
              'error': null,
              'devices': [for (final d in _devices) d.toJson()],
            });
          case 'GET settings':
            return _Resp(200, _settings.toJson());
          case 'PUT settings':
            return _updateSettings(body());
        }
      case 2:
        final id = int.tryParse(p[1]);
        if (route == 'POST alerts' && p[1] == 'read-all') {
          final rows = _alerts.where((a) => !a.read).toList();
          for (final a in rows) {
            a.read = true;
          }
          return _Resp(200, {'updated': rows.length});
        }
        if (route == 'POST devices' && p[1] == 'test') return _testPush();
        if (route == 'DELETE devices') {
          _devices.removeWhere((d) => d.token == p[1]);
          return const _Resp(204, null);
        }
        if (id == null) {
          if (method == 'GET' || method == 'PATCH' || method == 'DELETE') _validationPath(p[1]);
          throw const _HttpError(404, 'Not Found');
        }
        switch (route) {
          case 'PATCH goals':
            return _updateGoal(id, body());
          case 'DELETE goals':
            return _deleteGoal(id, _boolParam(q, 'stop_series', false));
          case 'GET transactions':
            return _Resp(200, _txDict(_txOr404(id)));
          case 'PATCH transactions':
            return _updateTransaction(id, body());
          case 'DELETE transactions':
            return _deleteTransaction(id);
          case 'PATCH accounts':
            return _updateAccount(id, body());
          case 'DELETE accounts':
            return _deleteAccount(id);
          case 'GET alerts':
            return _Resp(200, _alertOr404(id).toJson());
          case 'DELETE rules':
            final before = _rules.length;
            _rules.removeWhere((r) => r.id == id);
            if (_rules.length == before) throw const _HttpError(404, 'Không tìm thấy luật');
            return const _Resp(204, null);
        }
      case 3:
        final id = int.tryParse(p[1]);
        if (id != null && route == 'POST alerts' && p[2] == 'read') {
          final a = _alertOr404(id)..read = true;
          return _Resp(200, a.toJson());
        }
        if (id != null && p[2] == 'rules' && p[0] == 'categories') {
          if (method == 'GET') {
            return _Resp(200, [for (final r in _rules.where((r) => r.categoryId == id)) _ruleJson(r)]);
          }
          if (method == 'POST') return _createRule(id, body());
        }
    }
    if (p.length >= 2 && p[0] == 'devices' && method == 'DELETE') {
      final token = p.sublist(1).join('/');
      _devices.removeWhere((d) => d.token == token);
      return const _Resp(204, null);
    }
    throw const _HttpError(404, 'Not Found');
  }

  // ------------------------------------------------------------------ kiểm tra đầu vào

  /// Lỗi 422 đúng dạng pydantic (`type`, `loc`, `msg`, `input`, `ctx`) như backend thật.
  static Never _invalid(
    String field,
    String msg, {
    String loc = 'body',
    Object? input,
    String type = 'value_error',
    Map<String, Object?>? ctx,
  }) => throw _HttpError(422, [
    {
      'type': type,
      'loc': [loc, field],
      'msg': msg,
      'input': input,
      'ctx': ?ctx,
    },
  ]);

  static void _validationPath(String raw) =>
      _invalid('id', 'Input should be a valid integer, unable to parse string as an integer', loc: 'path', input: raw);

  static _Json _decodeBody(List<int> bytes) {
    if (bytes.isEmpty) return {};
    try {
      final data = jsonDecode(utf8.decode(bytes));
      if (data is Map<String, dynamic>) return data;
    } on FormatException {
      // rơi xuống lỗi bên dưới
    }
    throw const _HttpError(422, [
      {
        'type': 'json_invalid',
        'loc': ['body'],
        'msg': 'JSON decode error',
      },
    ]);
  }

  static String? _str(_Json b, String key, {int? min, int? max, bool required = false}) {
    final v = b[key];
    if (v == null) {
      if (required) _invalid(key, 'Field required', type: 'missing');
      return null;
    }
    if (v is! String) _invalid(key, 'Input should be a valid string', input: v);
    final len = v.runes.length;
    if (min != null && len < min) {
      _invalid(
        key,
        'String should have at least $min character',
        input: v,
        type: 'string_too_short',
        ctx: {'min_length': min},
      );
    }
    if (max != null && len > max) {
      _invalid(
        key,
        'String should have at most $max characters',
        input: v,
        type: 'string_too_long',
        ctx: {'max_length': max},
      );
    }
    return v;
  }

  static int? _int(_Json b, String key, {int? gt, int? ge, int? le, bool required = false}) {
    final v = b[key];
    if (v == null) {
      if (required) _invalid(key, 'Field required', type: 'missing');
      return null;
    }
    final int n;
    if (v is int) {
      n = v;
    } else if (v is double && v == v.roundToDouble()) {
      n = v.toInt();
    } else {
      _invalid(key, 'Input should be a valid integer', input: v);
    }
    if (gt != null && n <= gt) {
      _invalid(key, 'Input should be greater than $gt', input: v, type: 'greater_than', ctx: {'gt': gt});
    }
    if (ge != null && n < ge) {
      _invalid(
        key,
        'Input should be greater than or equal to $ge',
        input: v,
        type: 'greater_than_equal',
        ctx: {'ge': ge},
      );
    }
    if (le != null && n > le) {
      _invalid(key, 'Input should be less than or equal to $le', input: v, type: 'less_than_equal', ctx: {'le': le});
    }
    return n;
  }

  static bool? _bool(_Json b, String key) {
    final v = b[key];
    if (v == null) return null;
    if (v is bool) return v;
    _invalid(key, 'Input should be a valid boolean', input: v);
  }

  static String? _choice(_Json b, String key, List<String> allowed) {
    final v = _str(b, key);
    if (v != null && !allowed.contains(v)) {
      _invalid(key, 'Input should be ${allowed.map((a) => "'$a'").join(' or ')}', input: v);
    }
    return v;
  }

  static bool _boolParam(Map<String, String> q, String key, bool fallback) {
    final v = q[key]?.trim().toLowerCase();
    if (v == null) return fallback;
    if (const ['true', '1', 'yes', 'on', 't', 'y'].contains(v)) return true;
    if (const ['false', '0', 'no', 'off', 'f', 'n'].contains(v)) return false;
    _invalid(key, 'Input should be a valid boolean, unable to interpret input', loc: 'query', input: v);
  }

  static int _intParam(Map<String, String> q, String key, int fallback, {int? ge, int? le}) {
    final raw = q[key];
    if (raw == null) return fallback;
    final n = int.tryParse(raw.trim());
    if (n == null) {
      _invalid(key, 'Input should be a valid integer, unable to parse string as an integer', loc: 'query', input: raw);
    }
    if (ge != null && n < ge) _invalid(key, 'Input should be greater than or equal to $ge', loc: 'query', input: raw);
    if (le != null && n > le) _invalid(key, 'Input should be less than or equal to $le', loc: 'query', input: raw);
    return n;
  }

  String _monthParam(String? month) {
    if (month == null) return monthOf(now());
    if (!isValidMonth(month)) throw const _HttpError(400, 'month phải có dạng YYYY-MM');
    return month;
  }

  // ------------------------------------------------------------------ truy vấn nội bộ

  _Category? _category(int? id) => id == null ? null : _categories.where((c) => c.id == id).firstOrNull;
  _Category? _categoryByKey(String key) => _categories.where((c) => c.systemKey == key).firstOrNull;
  _Account? _account(int? id) => id == null ? null : _accounts.where((a) => a.id == id).firstOrNull;
  _Goal? _goal(int? id) => id == null ? null : _goals.where((g) => g.id == id).firstOrNull;
  _Tx? _tx(int? id) => id == null ? null : _txs.where((t) => t.id == id).firstOrNull;

  _Tx _txOr404(int id) => _tx(id) ?? (throw const _HttpError(404, 'Không tìm thấy giao dịch'));
  _Alert _alertOr404(int id) =>
      _alerts.where((a) => a.id == id).firstOrNull ?? (throw const _HttpError(404, 'Không tìm thấy cảnh báo'));

  List<_Category> _sortedCategories() => [..._categories]
    ..sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      return c != 0 ? c : a.id.compareTo(b.id);
    });

  List<_Account> _bankAccountRows() => _accounts.where((a) => a.bank != 'CASH').toList();

  List<_Account> _includedAccounts() => _accounts.where((a) => a.includeInTotal && a.confirmed).toList();

  bool _isInternal(_Tx tx) => _category(tx.categoryId)?.kind == 'transfer';

  List<_Goal> _goalsForMonth(String month) =>
      _goals.where((g) => g.month == month && !g.archived).toList()..sort((a, b) => a.id.compareTo(b.id));

  _Goal _clone(_Goal src, String month) {
    final g = _Goal(
      id: _nextId('goal'),
      seriesId: src.seriesId,
      name: src.name,
      type: src.type,
      amount: src.amount,
      categoryId: src.categoryId,
      month: month,
      repeatMonthly: src.repeatMonthly,
      createdAt: now(),
    );
    _goals.add(g);
    return g;
  }

  _Goal? _latestBefore(String seriesId, String month) {
    final rows = _goals.where((g) => g.seriesId == seriesId && g.month.compareTo(month) < 0).toList()
      ..sort((a, b) => b.month.compareTo(a.month));
    return rows.firstOrNull;
  }

  _Goal? _exists(String seriesId, String month) =>
      _goals.where((g) => g.seriesId == seriesId && g.month == month).firstOrNull;

  /// `ensure_month_goals`: clone các mục tiêu lặp hằng tháng sang [month].
  void _ensureMonthGoals(String month) {
    final seriesIds = {
      for (final g in _goals)
        if (g.month.compareTo(month) < 0) g.seriesId,
    };
    final sources = <_Goal>[];
    for (final sid in seriesIds) {
      if (_exists(sid, month) != null) continue;
      final src = _latestBefore(sid, month);
      if (src != null && src.repeatMonthly) sources.add(src);
    }
    sources.sort((a, b) => a.id.compareTo(b.id));
    for (final src in sources) {
      _clone(src, month);
    }
  }

  /// `ensure_goal`: lấy (hoặc tạo trước) mục tiêu của chuỗi trong [month].
  _Goal? _ensureGoal(String seriesId, String month) {
    final existing = _exists(seriesId, month);
    if (existing != null) {
      if (existing.archived) {
        existing
          ..archived = false
          ..updatedAt = now();
      }
      return existing;
    }
    final src = _latestBefore(seriesId, month);
    return src == null ? null : _clone(src, month);
  }

  int _seriesRank(String seriesId) =>
      _goals.where((g) => g.seriesId == seriesId).map((g) => g.id).reduce((a, b) => math.min(a, b));

  /// `auto_goal_for`: mục tiêu tự khớp của danh mục trong tháng (chuỗi tạo sớm nhất).
  _Goal? _autoGoalFor(int categoryId, String month) {
    final cands = _goalsForMonth(month).where((g) => g.categoryId == categoryId).toList();
    if (cands.isEmpty) return null;
    cands.sort((a, b) {
      final c = _seriesRank(a.seriesId).compareTo(_seriesRank(b.seriesId));
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    return cands.first;
  }

  TxIn _txIn(_Tx t) => TxIn(
    id: t.id,
    direction: t.direction,
    amount: t.amount,
    bankTime: t.bankTime,
    categoryId: t.categoryId,
    goalId: t.goalId,
  );

  /// `month_inputs`: mục tiêu của tháng + giao dịch active liên quan.
  (List<GoalIn>, List<_Tx>) _monthInputs(String month) {
    final goals = _goalsForMonth(month);
    final goalIns = [
      for (final g in goals)
        GoalIn(
          id: g.id,
          name: g.name,
          type: g.type,
          amount: g.amount,
          month: g.month,
          categoryId: g.categoryId,
          categoryName: _category(g.categoryId)?.name,
          categoryIcon: _category(g.categoryId)?.icon,
          seriesId: g.seriesId,
          repeatMonthly: g.repeatMonthly,
          openingSpent: g.openingSpent,
          rank: _seriesRank(g.seriesId),
        ),
    ];
    final (start, end) = monthBoundsUtc(month);
    final goalIds = {for (final g in goals) g.id};
    final txs = _txs
        .where(
          (t) =>
              t.status == 'active' &&
              ((!t.bankTime.isBefore(start) && t.bankTime.isBefore(end)) || goalIds.contains(t.goalId)),
        )
        .toList();
    return (goalIns, txs);
  }

  /// `build_evaluation`.
  Evaluation _evaluation(String? month, {DateTime? at}) {
    final t = at ?? now();
    final cur = monthOf(t);
    month ??= cur;
    if (month == cur) _ensureMonthGoals(month);
    final (goalIns, txs) = _monthInputs(month);
    final accounts = _includedAccounts();
    int? balance;
    if (accounts.isNotEmpty && accounts.every((a) => a.balance != null)) {
      balance = accounts.fold<int>(0, (s, a) => s + a.balance!);
    }
    final included = {for (final a in accounts) a.id};
    final incomeIds = {
      for (final c in _categories)
        if (c.systemKey == 'income') c.id,
    };
    final (start, end) = monthBoundsUtc(month);
    final incomeReceived = txs
        .where(
          (x) =>
              x.direction == 'in' &&
              incomeIds.contains(x.categoryId) &&
              included.contains(x.accountId) &&
              !x.bankTime.isBefore(start) &&
              x.bankTime.isBefore(end),
        )
        .fold<int>(0, (s, x) => s + x.amount);
    return evaluate(
      month: month,
      goals: goalIns,
      txs: [for (final x in txs) _txIn(x)],
      balance: balance,
      settings: _settings.evalSettings,
      today: ictDate(t),
      incomeReceived: incomeReceived,
    );
  }

  int _uncategorizedCount(String month) {
    final (start, end) = monthBoundsUtc(month);
    final included = {for (final a in _includedAccounts()) a.id};
    return _txs
        .where((t) => _isUncategorized(t, included) && !t.bankTime.isBefore(start) && t.bankTime.isBefore(end))
        .length;
  }

  bool _isUncategorized(_Tx t, Set<int> included) =>
      t.status == 'active' &&
      t.direction == 'out' &&
      t.categoryId == null &&
      t.goalId == null &&
      t.pairId == null &&
      included.contains(t.accountId);

  // ------------------------------------------------------------------ dự báo (services/forecast.py)

  bool _countsAsSpending(_Tx t, Set<int> included, Set<int> transferIds, DateTime at) =>
      t.direction == 'out' &&
      t.status == 'active' &&
      included.contains(t.accountId) &&
      t.affectsBalance &&
      t.pairId == null &&
      !transferIds.contains(t.categoryId) &&
      !t.bankTime.isAfter(at);

  List<OutflowIn> _outflows(String month, Set<int> included, DateTime at) {
    final transferIds = {
      for (final c in _categories)
        if (c.kind == 'transfer') c.id,
    };
    final (goalIns, txs) = _monthInputs(month);
    final attribution = attributeGoals(goalIns, [for (final t in txs) _txIn(t)]);
    final (start, end) = monthBoundsUtc(month);
    return [
      for (final t in txs)
        if (!t.bankTime.isBefore(start) && t.bankTime.isBefore(end) && _countsAsSpending(t, included, transferIds, at))
          OutflowIn(id: t.id, amount: t.amount, day: ictDate(t.bankTime), goalId: attribution[t.id]),
    ];
  }

  List<OutflowIn> _refunds(String month, Set<int> included, DateTime at) {
    final refundIds = {
      for (final c in _categories)
        if (c.systemKey == 'refund') c.id,
    };
    final (start, end) = monthBoundsUtc(month);
    return [
      for (final t in _txs)
        if (t.direction == 'in' &&
            t.status == 'active' &&
            refundIds.contains(t.categoryId) &&
            included.contains(t.accountId) &&
            !t.bankTime.isBefore(start) &&
            t.bankTime.isBefore(end) &&
            t.goalId == null &&
            t.affectsBalance &&
            !t.bankTime.isAfter(at))
          OutflowIn(id: t.id, amount: t.amount, day: ictDate(t.bankTime)),
    ];
  }

  DateTime _dataSince(List<_Account> accounts, DateTime today) {
    final candidates = [for (final a in accounts) ictDate(a.createdAt)];
    final ids = {for (final a in accounts) a.id};
    final times = [
      for (final t in _txs)
        if (ids.contains(t.accountId)) t.bankTime,
    ];
    if (times.isNotEmpty) candidates.add(ictDate(times.reduce((a, b) => a.isBefore(b) ? a : b)));
    if (candidates.isEmpty) return today;
    return candidates.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  int? _baselineRate(String month, Set<int> included, DateTime dataSince, DateTime at) {
    final prev = prevMonth(month);
    final (y, m) = parseYm(prev);
    final prevStart = DateTime.utc(y, m, 1);
    final prevEnd = DateTime.utc(y, m, daysInMonth(prev));
    final from = dataSince.isAfter(prevStart) ? dataSince : prevStart;
    final days = prevEnd.difference(from).inDays + 1;
    if (days < 7) return null;
    final amounts = [
      for (final o in _outflows(prev, included, at))
        if (o.goalId == null) o.amount,
    ];
    final (counted, _, _) = cappedTotal(amounts);
    return pyRound(counted / days);
  }

  Forecast? _buildForecast(Evaluation ev, DateTime at) {
    if (ev.month != monthOf(at)) return null;
    final today = ictDate(at);
    final accounts = _includedAccounts();
    final included = {for (final a in accounts) a.id};
    final since = _dataSince(accounts, today);
    return forecast(
      ev: ev,
      outflows: _outflows(ev.month, included, at),
      today: today,
      dataSince: since,
      incomeDay: _settings.expectedIncomeDay,
      baselineRate: _baselineRate(ev.month, included, since, at),
      refunds: _refunds(ev.month, included, at),
    );
  }

  // ------------------------------------------------------------------ JSON

  Map<String, Object?> _summaryPayload(String month) {
    final at = now();
    final ev = _evaluation(month, at: at);
    final accounts = _bankAccountRows();
    final unread = _alerts.where((a) => !a.read).toList()..sort((a, b) => b.id.compareTo(a.id));
    var latest = unread.take(5).toList();
    if (latest.isEmpty) {
      latest = (_alerts.where((a) => a.kind != 'tx').toList()..sort((a, b) => b.id.compareTo(a.id))).take(5).toList();
    }
    final asOf = [
      for (final a in accounts)
        if (a.includeInTotal && a.balanceAsOf != null) a.balanceAsOf!,
    ];
    final balanceAsOf = asOf.isEmpty ? null : asOf.reduce((a, b) => a.isAfter(b) ? a : b);
    return {
      ...ev.toJson(),
      'generated_at': isoZ(at),
      'balance_as_of': ev.balanceKnown ? isoZ(balanceAsOf) : null,
      'expected_income': _settings.expectedIncomeAmount > 0
          ? {
              'amount': _settings.expectedIncomeAmount,
              'day': _settings.expectedIncomeDay,
              'pending': ev.expectedPending,
            }
          : null,
      'accounts': [for (final a in accounts) a.toJson()],
      'uncategorized_count': _uncategorizedCount(ev.month),
      'unread_alerts': unread.length,
      'latest_alerts': [for (final a in latest) a.toJson()],
      'ingest_health': _ingestHealth(at),
      'forecast': _buildForecast(ev, at)?.toJson(),
    };
  }

  Map<String, Object?> _ingestHealth(DateTime at) {
    final last = _sepayLastEvent;
    final warnings = [
      if (last == null || last.isBefore(at.subtract(const Duration(hours: 48))))
        '🔌 Chưa nhận webhook SEPAY trong 48 giờ qua — kiểm tra kết nối.',
    ];
    return {
      'stale': warnings.isNotEmpty,
      'warnings': warnings,
      'error_events': 0,
      'unparsed_events': 0,
      'sources': {
        'sepay': {'enabled': true, 'last_event_at': isoZ(last)},
        'casso': {'enabled': false, 'last_event_at': null},
        'email': {'enabled': false, 'last_success_at': null, 'last_error': null},
      },
    };
  }

  int? _possibleDuplicateOf(_Tx t) {
    if (t.isManual || t.pairId != null) return null;
    for (final o in _txs) {
      if (o.id != t.id &&
          o.accountId == t.accountId &&
          o.amount == t.amount &&
          o.direction == t.direction &&
          o.status != 'excluded' &&
          o.bankTime.difference(t.bankTime).inSeconds.abs() <= 3600) {
        return o.id;
      }
    }
    return null;
  }

  Map<String, Object?> _txDict(_Tx t) {
    final acc = _account(t.accountId);
    final cat = _category(t.categoryId);
    final goal = _goal(t.goalId);
    return {
      'id': t.id,
      'account_id': t.accountId,
      'account_name': acc?.name,
      'bank': acc?.bank,
      'direction': t.direction,
      'amount': t.amount,
      'bank_time': isoZ(t.bankTime),
      'time_precision': 'second',
      'description': t.description,
      'reference_code': t.referenceCode,
      'counter_account': t.counterAccount,
      'counter_name': t.counterName,
      'balance_after': t.balanceAfter,
      'category_id': t.categoryId,
      'category_name': cat?.name,
      'category_icon': cat?.icon,
      'goal_id': t.goalId,
      'goal_name': goal == null ? null : '${goal.name} (${goal.month})',
      'goal_month': goal?.month,
      'categorized_by': t.categorizedBy,
      'suggested_rule': suggestRule(t.description),
      'status': t.status,
      'is_manual': t.isManual,
      'affects_balance': t.affectsBalance,
      'pair_id': t.pairId,
      'sources': ([...t.sources.toSet()]..sort()),
      'possible_duplicate_of': _possibleDuplicateOf(t),
    };
  }

  static Map<String, Object?> _ruleJson(DemoRule r) => {
    'id': r.id,
    'category_id': r.categoryId,
    'pattern': r.pattern,
    'direction': r.direction,
    'priority': r.priority,
    'origin': r.origin,
  };

  // ------------------------------------------------------------------ số dư (services/balance.py)

  void _recomputeBalance(_Account account) {
    final rows = _txs
        .where((t) => t.accountId == account.id && (t.status == 'active' || t.status == 'excluded') && t.affectsBalance)
        .toList();
    final active = rows.where((t) => t.status == 'active').toList();
    int cmp((DateTime, int) a, (DateTime, int) b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : a.$2.compareTo(b.$2);
    }

    (DateTime, int)? anchorKey;
    int? anchorBalance;
    _Tx? anchorTx;
    for (final t in rows) {
      if (t.balanceAfter == null) continue;
      final k = (t.bankTime, t.id);
      if (anchorKey == null || cmp(k, anchorKey) > 0) {
        anchorKey = k;
        anchorBalance = t.balanceAfter;
        anchorTx = t;
      }
    }
    final manualAt = account.manualBalanceAt;
    if (account.manualBalance != null && manualAt != null) {
      final k = (manualAt, 1000000000000);
      final reportedNewer =
          anchorTx != null &&
          !anchorTx.createdAt.isBefore(manualAt) &&
          !anchorTx.bankTime.isBefore(manualAt.subtract(const Duration(minutes: 30)));
      if (anchorKey == null || (cmp(k, anchorKey) > 0 && !reportedNewer)) {
        anchorKey = k;
        anchorBalance = account.manualBalance;
      }
    }
    if (anchorKey == null || anchorBalance == null) {
      account
        ..balance = null
        ..balanceAsOf = null
        ..balanceDerived = false;
      return;
    }
    final key = anchorKey;
    final later = active.where((t) => cmp((t.bankTime, t.id), key) > 0).toList();
    final delta = later.fold<int>(0, (s, t) => s + (t.direction == 'in' ? t.amount : -t.amount));
    var asOf = key.$1;
    for (final t in later) {
      if (t.bankTime.isAfter(asOf)) asOf = t.bankTime;
    }
    account
      ..balance = anchorBalance + delta
      ..balanceDerived = later.isNotEmpty
      ..balanceAsOf = asOf;
  }

  // ------------------------------------------------------------------ cảnh báo (services/notify.py)

  static const Map<String, String> _reasonLabels = {
    'api_goal': 'mục tiêu vừa thay đổi',
    'api_account': 'số dư tài khoản vừa được cập nhật',
    'api_settings': 'cài đặt cảnh báo vừa thay đổi',
    'api_tx': 'giao dịch vừa được cập nhật',
    'rollover': 'bắt đầu tháng mới',
    'merge': 'số dư vừa được ngân hàng xác nhận',
    'backfill': 'vừa nhập các giao dịch cũ',
    'pair': 'vừa ghép chuyển khoản nội bộ',
  };

  String _accountLabel(_Account? acc) {
    if (acc == null) return '?';
    if (acc.name.isNotEmpty) return acc.name;
    return acc.last4 != null ? '${acc.bank} …${acc.last4}' : acc.bank;
  }

  TxInfo _txInfo(_Tx tx) {
    final cat = _category(tx.categoryId);
    final goal = _goal(tx.goalId);
    return TxInfo(
      id: tx.id,
      direction: tx.direction,
      amount: tx.amount,
      accountLabel: _accountLabel(_account(tx.accountId)),
      bankTime: tx.bankTime,
      description: tx.description,
      categoryLabel: cat == null ? null : '${cat.icon ?? ''} ${cat.name}'.trim(),
      balanceAfter: tx.balanceAfter,
      goalName: goal == null ? null : '${goal.name} (${goal.month.substring(5)}/${goal.month.substring(0, 4)})',
      internal: cat?.kind == 'transfer',
    );
  }

  List<(GoalView, int)> _decideBudgets(Evaluation ev) {
    final fired = <(GoalView, int)>[];
    for (final g in ev.goals) {
      if (g.type != 'budget') continue;
      String key(int th) => 'budget:${g.id}:$th:${ev.month}';
      final armed = {for (final th in budgetThresholds) th: _budgetArmed[key(th)] ?? true};
      final (th, next) = decideBudget(g, armed);
      next.forEach((t, v) => _budgetArmed[key(t)] = v);
      if (th != null) fired.add((g, th));
    }
    return fired;
  }

  _Alert _addAlert({
    required String kind,
    required String? level,
    required String title,
    required String message,
    String? month,
    int? transactionId,
    int? goalId,
    bool read = false,
    bool loud = true,
    bool deliver = true,
    DateTime? createdAt,
  }) {
    final alert = _Alert(
      id: _nextId('alert'),
      createdAt: createdAt ?? now(),
      kind: kind,
      level: level,
      month: month,
      goalId: goalId,
      transactionId: transactionId,
      title: title,
      message: message,
      read: read,
      loud: loud,
      deliverTelegram: deliver,
    );
    _alerts.add(alert);
    _maybePush(alert);
    return alert;
  }

  /// `push_outbox.should_push`: chỉ đẩy cảnh báo quan trọng (và thông báo thử), tới thiết bị đã đăng ký.
  bool _maybePush(_Alert alert) {
    final should = alert.kind == 'push_test' || (alert.loud && alert.deliverTelegram && !alert.read);
    if (!should || _devices.isEmpty || _closed || _seeding) return false;
    final push = DemoPush(
      title: alert.title,
      body: alert.message,
      data: {
        'alert_id': '${alert.id}',
        'kind': alert.kind,
        'level': alert.level ?? '',
        'transaction_id': alert.transactionId?.toString() ?? '',
        'goal_id': alert.goalId?.toString() ?? '',
        'month': alert.month ?? '',
      },
    );
    void deliver() {
      if (!_closed) _pushes.add(push);
    }

    if (pushDelay <= Duration.zero) {
      scheduleMicrotask(deliver);
    } else {
      late final Timer timer;
      timer = Timer(pushDelay, () {
        _timers.remove(timer);
        deliver();
      });
      _timers.add(timer);
    }
    return true;
  }

  /// `reevaluate_and_notify`: đánh giá tháng hiện tại, áp chính sách cảnh báo, ghi cảnh báo.
  Evaluation _reevaluate({required String reason, _Tx? tx, _Tx? editTx}) {
    final at = now();
    final ev = _evaluation(null, at: at);
    var floorReason = reason;
    if (tx != null && tx.direction == 'in' && !_isInternal(tx)) floorReason = 'inflow';
    final dec = decideFloor(_floorStates[ev.month], ev, floorReason, at);
    _floorStates[ev.month] = dec.state;
    final budgetFired = _decideBudgets(ev);
    final fc = _buildForecast(ev, at);
    final (fire, fcState) = decideForecast(_forecastStates[ev.month], fc, ev, at);
    _forecastStates[ev.month] = fcState;
    final fcFired = fire ? fc : null;
    _maybeUnknownNotice(ev);

    if (tx != null) {
      final loud = dec.notify || budgetFired.isNotEmpty || fire;
      if (loud || _settings.notifyEveryTx) {
        final (title, message) = composeTxMessage(_txInfo(tx), ev, dec, budgetFired, fcFired);
        _addAlert(
          kind: 'tx',
          level: dec.notify ? dec.level : ev.level,
          month: ev.month,
          transactionId: tx.id,
          title: title,
          message: message,
          loud: loud,
          read: !loud,
        );
      }
      return ev;
    }
    if (editTx != null) {
      final (title, message) = composeTxMessage(_txInfo(editTx), ev, dec, budgetFired);
      final existing =
          (_alerts.where((a) => a.kind == 'tx' && a.transactionId == editTx.id).toList()
                ..sort((a, b) => b.id.compareTo(a.id)))
              .firstOrNull;
      var reachable = false;
      if (existing != null) {
        existing
          ..title = title
          ..message = message;
        // Tin cũ (chưa quá 24 giờ) được sửa tại chỗ, nên cảnh báo mới chỉ lưu trong app.
        reachable = !existing.createdAt.isBefore(at.subtract(const Duration(hours: 24)));
      }
      _separateAlerts(ev, dec, budgetFired, reason, deliver: !reachable, fc: fcFired);
      return ev;
    }
    _separateAlerts(ev, dec, budgetFired, reason, deliver: true, fc: fcFired);
    return ev;
  }

  void _separateAlerts(
    Evaluation ev,
    FloorDecision dec,
    List<(GoalView, int)> budgetFired,
    String reason, {
    required bool deliver,
    Forecast? fc,
  }) {
    final mergeForecast = fc != null && dec.notify && deliver;
    if (dec.notify) {
      var (title, message) = composeFloorMessage(dec, ev, _reasonLabels[reason]);
      if (mergeForecast) message += '\n${forecastLines(fc).join('\n')}';
      _addAlert(
        kind: dec.kind == 'safe' ? 'safe' : 'floor',
        level: dec.level,
        month: ev.month,
        title: title,
        message: message,
        deliver: deliver,
      );
    }
    if (fc != null && !mergeForecast) {
      final (title, message) = composeForecastMessage(fc, ev);
      _addAlert(kind: 'forecast', level: 'WARNING', month: ev.month, title: title, message: message);
    }
    for (final (goal, th) in budgetFired) {
      final (title, message) = composeBudgetMessage(goal, th, ev);
      _addAlert(
        kind: 'budget',
        level: 'WARNING',
        month: ev.month,
        goalId: goal.id,
        title: title,
        message: message,
        deliver: deliver,
      );
    }
  }

  void _maybeUnknownNotice(Evaluation ev) {
    if (ev.level != 'UNKNOWN') {
      for (final a in _alerts) {
        if (a.kind == 'account' && a.level == 'UNKNOWN' && !a.read) a.read = true;
      }
      return;
    }
    if (!_unknownNotified.add(ev.month)) return;
    _addAlert(
      kind: 'account',
      level: 'UNKNOWN',
      month: ev.month,
      title: '❔ Chưa biết số dư',
      message:
          'App chưa biết số dư hiện tại của tài khoản được tính vào tổng. '
          'Mở app → Cài đặt → Tài khoản để nhập số dư, khi đó cảnh báo mức sàn mới hoạt động.',
    );
  }

  // ------------------------------------------------------------------ mục tiêu

  void _validateGoalCategory(String type, int? categoryId) {
    if (categoryId == null) {
      if (type == 'budget') throw const _HttpError(400, 'Ngân sách chi tiêu cần chọn danh mục');
      return;
    }
    final cat = _category(categoryId);
    if (cat == null) throw const _HttpError(400, 'Danh mục không tồn tại');
    if (cat.kind != 'expense') throw const _HttpError(400, 'Chỉ chọn được danh mục chi tiêu cho mục tiêu');
  }

  _Resp _goalView(_Goal goal, int status) {
    for (final g in _evaluation(goal.month).goals) {
      if (g.id == goal.id) return _Resp(status, g.toJson());
    }
    throw const _HttpError(404, 'Không tìm thấy mục tiêu');
  }

  _Resp _createGoal(_Json b) {
    final name = _str(b, 'name', min: 1, max: 80, required: true)!;
    final type = _choice(b, 'type', const ['reserve', 'budget']) ?? _invalid('type', 'Field required');
    final amount = _int(b, 'amount', gt: 0, le: 100000000000, required: true)!;
    final categoryId = _int(b, 'category_id');
    final month = _str(b, 'month');
    if (month != null && !isValidMonth(month)) {
      _invalid('month', 'Value error, month phải có dạng YYYY-MM', input: month);
    }
    final repeat = _bool(b, 'repeat_monthly') ?? true;
    final opening = _int(b, 'opening_spent', ge: 0) ?? 0;
    _validateGoalCategory(type, categoryId);
    final target = month ?? monthOf(now());
    _Goal? goal;
    if (categoryId != null && target.compareTo(monthOf(now())) > 0) {
      final prev = _autoGoalFor(categoryId, prevMonth(target));
      if (prev != null && prev.repeatMonthly && prev.type == type) goal = _ensureGoal(prev.seriesId, target);
    }
    if (goal == null) {
      goal = _Goal(
        id: _nextId('goal'),
        seriesId: _uuid(),
        name: '',
        type: type,
        amount: amount,
        categoryId: categoryId,
        month: target,
        createdAt: now(),
      );
      _goals.add(goal);
    }
    goal
      ..name = name.trim()
      ..amount = amount
      ..type = type
      ..repeatMonthly = repeat
      ..openingSpent = opening
      ..updatedAt = now();
    _reevaluate(reason: 'api_goal');
    return _goalView(goal, 201);
  }

  _Resp _updateGoal(int id, _Json b) {
    final goal = _goal(id);
    if (goal == null || goal.archived) throw const _HttpError(404, 'Không tìm thấy mục tiêu');
    final name = _str(b, 'name', min: 1, max: 80);
    final type = _choice(b, 'type', const ['reserve', 'budget']);
    final amount = _int(b, 'amount', gt: 0, le: 100000000000);
    final categoryId = _int(b, 'category_id');
    final repeat = _bool(b, 'repeat_monthly');
    final opening = _int(b, 'opening_spent', ge: 0);
    final newType = type ?? goal.type;
    final newCat = b.containsKey('category_id') ? categoryId : goal.categoryId;
    _validateGoalCategory(newType, newCat);
    goal
      ..type = newType
      ..categoryId = newCat;
    if (name != null && name.isNotEmpty) goal.name = name.trim();
    if (amount != null) goal.amount = amount;
    if (repeat != null) goal.repeatMonthly = repeat;
    if (opening != null) goal.openingSpent = opening;
    goal.updatedAt = now();
    for (final later in _goals.where(
      (g) => g.seriesId == goal.seriesId && g.month.compareTo(goal.month) > 0 && !g.archived,
    )) {
      later
        ..name = goal.name
        ..amount = goal.amount
        ..type = goal.type
        ..categoryId = goal.categoryId
        ..repeatMonthly = goal.repeatMonthly
        ..updatedAt = goal.updatedAt;
    }
    _reevaluate(reason: 'api_goal');
    return _goalView(goal, 200);
  }

  _Resp _deleteGoal(int id, bool stopSeries) {
    final goal = _goal(id);
    if (goal == null) throw const _HttpError(404, 'Không tìm thấy mục tiêu');
    goal
      ..archived = true
      ..updatedAt = now();
    if (stopSeries) {
      for (final g in _goals.where((g) => g.seriesId == goal.seriesId && g.month.compareTo(goal.month) >= 0)) {
        g
          ..repeatMonthly = false
          ..archived = true;
      }
    }
    _reevaluate(reason: 'api_goal');
    return const _Resp(204, null);
  }

  // ------------------------------------------------------------------ danh mục

  _Resp _createCategory(_Json b) {
    final name = _str(b, 'name', min: 1, max: 40, required: true)!;
    final kind = _choice(b, 'kind', const ['expense', 'income', 'transfer']) ?? 'expense';
    final icon = _str(b, 'icon', max: 8);
    if (_categories.any((c) => c.name == name.trim())) throw const _HttpError(400, 'Danh mục đã tồn tại');
    final cat = _Category(id: _nextId('category'), name: name.trim(), kind: kind, icon: icon, sortOrder: 80);
    _categories.add(cat);
    return _Resp(201, cat.toJson());
  }

  _Resp _createRule(int categoryId, _Json b) {
    if (_category(categoryId) == null) throw const _HttpError(404, 'Không tìm thấy danh mục');
    final raw = _str(b, 'pattern', min: 2, max: 80, required: true)!;
    final direction = _choice(b, 'direction', const ['out', 'in', 'any']) ?? 'out';
    final pattern = normalizePattern(raw);
    if (pattern.length < 2) throw const _HttpError(400, 'Cụm từ quá ngắn');
    final rule = DemoRule(
      id: _nextId('rule'),
      categoryId: categoryId,
      pattern: pattern,
      direction: direction,
      priority: 10,
      origin: 'user',
    );
    _rules.add(rule);
    return _Resp(201, _ruleJson(rule));
  }

  // ------------------------------------------------------------------ giao dịch

  _Resp _listTransactions(Map<String, String> q) {
    final month = _monthParam(q['month']);
    final uncategorized = _boolParam(q, 'uncategorized', false);
    final limit = _intParam(q, 'limit', 50, ge: 1, le: 500);
    final offset = _intParam(q, 'offset', 0, ge: 0);
    final (start, end) = monthBoundsUtc(month);
    final included = {for (final a in _includedAccounts()) a.id};
    final rows =
        _txs
            .where((t) => !t.bankTime.isBefore(start) && t.bankTime.isBefore(end))
            .where((t) => !uncategorized || _isUncategorized(t, included))
            .toList()
          ..sort((a, b) {
            final c = b.bankTime.compareTo(a.bankTime);
            return c != 0 ? c : b.id.compareTo(a.id);
          });
    return _Resp(200, {
      'items': [for (final t in rows.skip(offset).take(limit)) _txDict(t)],
      'total': rows.length,
    });
  }

  void _unpair(_Tx tx) {
    if (tx.pairId == null) return;
    final other = _tx(tx.pairId);
    tx.pairId = null;
    if (other != null && other.pairId == tx.id) {
      other.pairId = null;
      if (other.categorizedBy == 'pair') {
        other
          ..categoryId = null
          ..categorizedBy = 'none';
      }
    }
  }

  void _rememberRule(_Category cat, String direction, String rawPattern) {
    final pattern = normalizePattern(rawPattern);
    if (pattern.length < 2) throw const _HttpError(400, 'Cụm từ để nhớ luật quá ngắn');
    final existing = _rules.where((r) => r.pattern == pattern && r.direction == direction).firstOrNull;
    if (existing == null) {
      _rules.add(
        DemoRule(
          id: _nextId('rule'),
          categoryId: cat.id,
          pattern: pattern,
          direction: direction,
          priority: 10,
          origin: 'user',
        ),
      );
    } else {
      existing
        ..categoryId = cat.id
        ..origin = 'user'
        ..priority = 10;
    }
  }

  /// `mark_internal`: chuyển nội bộ — ghép với nửa còn lại nếu tìm thấy.
  void _markInternal(_Tx tx) {
    final transfer = _categoryByKey('transfer');
    final otherDir = tx.direction == 'out' ? 'in' : 'out';
    final cands = _txs.where((c) {
      final acc = _account(c.accountId);
      return c.direction == otherDir &&
          c.amount == tx.amount &&
          c.accountId != tx.accountId &&
          c.pairId == null &&
          c.status != 'excluded' &&
          c.bankTime.difference(tx.bankTime).inMinutes.abs() <= 30 &&
          acc != null &&
          acc.bank != 'CASH';
    }).toList();
    _unpair(tx);
    if (cands.isNotEmpty) {
      cands.sort(
        (a, b) => a.bankTime.difference(tx.bankTime).abs().compareTo(b.bankTime.difference(tx.bankTime).abs()),
      );
      final best = cands.first;
      for (final (t, other) in [(tx, best), (best, tx)]) {
        t
          ..pairId = other.id
          ..categoryId = transfer?.id
          ..goalId = null
          ..categorizedBy = 'user';
      }
      return;
    }
    tx
      ..categoryId = transfer?.id
      ..goalId = null
      ..categorizedBy = 'user';
  }

  void _setCategory(_Tx tx, int? categoryId, {String? rememberPattern}) {
    if (categoryId == null) {
      _unpair(tx);
      tx
        ..categoryId = null
        ..categorizedBy = 'none';
      return;
    }
    final cat = _category(categoryId);
    if (cat == null) throw const _HttpError(400, 'Danh mục không tồn tại');
    if (rememberPattern != null && rememberPattern.isNotEmpty) _rememberRule(cat, tx.direction, rememberPattern);
    if (cat.kind == 'transfer') {
      _markInternal(tx);
      return;
    }
    _unpair(tx);
    tx
      ..categoryId = cat.id
      ..categorizedBy = 'user';
    if (tx.goalId != null) {
      final goal = _goal(tx.goalId);
      if (goal == null || (goal.categoryId != null && goal.categoryId != cat.id)) tx.goalId = null;
    }
  }

  void _assignNextMonth(_Tx tx) {
    final goal = tx.goalId != null
        ? _goal(tx.goalId)
        : (tx.categoryId == null ? null : _autoGoalFor(tx.categoryId!, monthOf(tx.bankTime)));
    if (goal == null) throw const _HttpError(400, 'Giao dịch chưa thuộc mục tiêu nào — hãy chọn danh mục trước');
    if (goal.month.compareTo(monthOf(tx.bankTime)) > 0) return;
    final target = _ensureGoal(goal.seriesId, nextMonth(goal.month));
    if (target == null) throw const _HttpError(400, 'Không tạo được mục tiêu tháng sau');
    tx.goalId = target.id;
  }

  /// Như `s.rollback()` của backend: lỗi 400 giữa chừng (vd. đã loại trừ, phân loại, nhớ luật rồi mới thấy mục tiêu
  /// không tồn tại) không để lại thay đổi nào ở giao dịch, số dư, luật phân loại hay mục tiêu.
  _Resp _rollbackOnError(_Resp Function() handler) {
    final txs = [for (final t in _txs) (t, t.categoryId, t.goalId, t.categorizedBy, t.status, t.pairId, t.updatedAt)];
    final accounts = [for (final a in _accounts) (a, a.balance, a.balanceAsOf, a.balanceDerived)];
    final rules = [for (final r in _rules) (r, r.categoryId, r.priority, r.origin)];
    final goals = [for (final g in _goals) (g, g.archived, g.updatedAt)];
    final ids = Map.of(_ids);
    try {
      return handler();
    } on _HttpError {
      for (final (t, categoryId, goalId, categorizedBy, status, pairId, updatedAt) in txs) {
        t
          ..categoryId = categoryId
          ..goalId = goalId
          ..categorizedBy = categorizedBy
          ..status = status
          ..pairId = pairId
          ..updatedAt = updatedAt;
      }
      for (final (a, balance, balanceAsOf, balanceDerived) in accounts) {
        a
          ..balance = balance
          ..balanceAsOf = balanceAsOf
          ..balanceDerived = balanceDerived;
      }
      _rules
        ..clear()
        ..addAll([
          for (final (r, categoryId, priority, origin) in rules)
            r
              ..categoryId = categoryId
              ..priority = priority
              ..origin = origin,
        ]);
      _goals
        ..clear()
        ..addAll([
          for (final (g, archived, updatedAt) in goals)
            g
              ..archived = archived
              ..updatedAt = updatedAt,
        ]);
      _ids
        ..clear()
        ..addAll(ids);
      rethrow;
    }
  }

  _Resp _updateTransaction(int id, _Json b) => _rollbackOnError(() => _applyTransactionUpdate(id, b));

  _Resp _applyTransactionUpdate(int id, _Json b) {
    final tx = _txOr404(id);
    final categoryId = _int(b, 'category_id');
    final goalId = _int(b, 'goal_id');
    final forNextMonth = _bool(b, 'for_next_month');
    final excluded = _bool(b, 'excluded');
    final remember = _bool(b, 'remember_rule') ?? false;
    final pattern = _str(b, 'rule_pattern', max: 80);
    if (excluded != null) {
      if (excluded) {
        _unpair(tx);
        tx.status = 'excluded';
      } else if (tx.status == 'excluded') {
        tx.status = 'active';
      }
      final acc = _account(tx.accountId);
      if (acc != null) _recomputeBalance(acc);
    }
    if (b.containsKey('category_id')) {
      if (remember && (pattern == null || pattern.trim().isEmpty)) {
        throw const _HttpError(400, 'Cần nhập cụm từ (rule_pattern) để nhớ luật');
      }
      _setCategory(tx, categoryId, rememberPattern: remember ? pattern : null);
    }
    if (b.containsKey('goal_id')) {
      if (goalId != null) {
        final goal = _goal(goalId);
        if (goal == null || goal.archived) throw const _HttpError(400, 'Mục tiêu không tồn tại');
      }
      tx.goalId = goalId;
    }
    if (forNextMonth == true) _assignNextMonth(tx);
    tx.updatedAt = now();
    _reevaluate(reason: 'api_tx', editTx: tx);
    return _Resp(200, {'transaction': _txDict(tx), 'summary': _summaryPayload(monthOf(now()))});
  }

  _Account _cashAccount() {
    final existing = _accounts.where((a) => a.bank == 'CASH').firstOrNull;
    if (existing != null) return existing;
    final acc = _Account(
      id: _nextId('account'),
      bank: 'CASH',
      name: 'Tiền mặt / nhập tay',
      includeInTotal: false,
      createdAt: now(),
    );
    _accounts.add(acc);
    return acc;
  }

  _Resp _createTransaction(_Json b) {
    final direction = _choice(b, 'direction', const ['in', 'out']) ?? 'out';
    final amount = _int(b, 'amount', gt: 0, le: 100000000000, required: true)!;
    final description = _str(b, 'description', max: 300) ?? '';
    final categoryId = _int(b, 'category_id');
    final rawTime = _str(b, 'bank_time');
    final accountId = _int(b, 'account_id');
    final affects = _bool(b, 'affects_balance') ?? false;
    DateTime? bankTime;
    if (rawTime != null) {
      final parsed = DateTime.tryParse(rawTime);
      if (parsed == null) _invalid('bank_time', 'Input should be a valid datetime', input: rawTime);
      bankTime = parsed.toUtc();
    }
    final _Account acc;
    if (accountId != null) {
      acc = _account(accountId) ?? (throw const _HttpError(400, 'Tài khoản không tồn tại'));
    } else {
      acc = _cashAccount();
    }
    if (categoryId != null && _category(categoryId) == null) throw const _HttpError(400, 'Danh mục không tồn tại');
    final tx = _Tx(
      id: _nextId('tx'),
      accountId: acc.id,
      direction: direction,
      amount: amount,
      bankTime: bankTime ?? now(),
      description: description.trim(),
      categoryId: categoryId,
      categorizedBy: categoryId != null ? 'user' : 'none',
      isManual: true,
      affectsBalance: affects && acc.bank != 'CASH',
      sources: const ['manual'],
      createdAt: now(),
    );
    _txs.add(tx);
    if (tx.affectsBalance) _recomputeBalance(acc);
    _reevaluate(reason: 'api_tx');
    return _Resp(201, _txDict(tx));
  }

  _Resp _deleteTransaction(int id) {
    final tx = _txOr404(id);
    if (!tx.isManual) {
      throw const _HttpError(400, 'Chỉ xoá được giao dịch nhập tay — giao dịch ngân hàng hãy dùng "Loại trừ"');
    }
    _txs.remove(tx);
    final acc = _account(tx.accountId);
    if (acc != null) _recomputeBalance(acc);
    _reevaluate(reason: 'api_tx');
    return const _Resp(204, null);
  }

  // ------------------------------------------------------------------ tài khoản

  static String _normalizeBank(String bank) {
    final b = bank.trim();
    if (const ['OTHER', 'KHAC', 'KHÁC'].contains(b.toUpperCase())) return 'OTHER';
    final key = normalizeForMatch(b).replaceAll(' ', '');
    if (key.isEmpty) return 'OTHER';
    const aliases = {
      'vcb': 'VCB',
      'vietcombank': 'VCB',
      'vcbdigibank': 'VCB',
      'ngoaithuong': 'VCB',
      'mb': 'MB',
      'mbbank': 'MB',
      'mbb': 'MB',
      'quandoi': 'MB',
    };
    final upper = key.toUpperCase();
    return aliases[key] ?? (upper.length > 16 ? upper.substring(0, 16) : upper);
  }

  _Resp _createAccount(_Json b) {
    final bank = _str(b, 'bank', min: 1, max: 16, required: true)!;
    final name = _str(b, 'name', min: 1, max: 60, required: true)!;
    final rawNumber = _str(b, 'account_number', max: 32);
    final include = _bool(b, 'include_in_total') ?? true;
    final balance = _int(b, 'balance');
    final number = digitsOnly(rawNumber).isEmpty ? null : digitsOnly(rawNumber);
    if (number != null && _accounts.any((a) => a.accountNumber == number)) {
      throw const _HttpError(400, 'Số tài khoản đã tồn tại');
    }
    final acc = _Account(
      id: _nextId('account'),
      bank: _normalizeBank(bank),
      name: name.trim(),
      accountNumber: number,
      last4: number?.substring(math.max(0, number.length - 4)),
      includeInTotal: include,
      createdAt: now(),
    );
    if (balance != null) {
      acc
        ..manualBalance = balance
        ..manualBalanceAt = now();
    }
    _accounts.add(acc);
    _recomputeBalance(acc);
    _reevaluate(reason: 'api_account');
    return _Resp(201, acc.toJson());
  }

  _Resp _updateAccount(int id, _Json b) {
    final acc = _account(id);
    if (acc == null || acc.bank == 'CASH') throw const _HttpError(404, 'Không tìm thấy tài khoản');
    final name = _str(b, 'name', min: 1, max: 60);
    final rawNumber = _str(b, 'account_number', max: 32);
    final include = _bool(b, 'include_in_total');
    final confirmed = _bool(b, 'confirmed');
    final balance = _int(b, 'balance');
    final number = digitsOnly(rawNumber).isEmpty ? null : digitsOnly(rawNumber);
    // Kiểm tra trước khi đổi gì: backend báo 400 thì không commit, tên mới cũng không được lưu.
    if (b.containsKey('account_number') &&
        number != null &&
        _accounts.any((a) => a.accountNumber == number && a.id != acc.id)) {
      throw const _HttpError(400, 'Số tài khoản đã tồn tại');
    }
    if (name != null && name.isNotEmpty) acc.name = name.trim();
    if (b.containsKey('account_number')) {
      acc
        ..accountNumber = number
        ..last4 = number == null ? acc.last4 : number.substring(math.max(0, number.length - 4));
    }
    if (include != null) {
      acc.includeInTotal = include;
      if (include) acc.confirmed = true;
    }
    if (confirmed != null) acc.confirmed = confirmed;
    if (balance != null) {
      acc
        ..manualBalance = balance
        ..manualBalanceAt = now();
    }
    _recomputeBalance(acc);
    _reevaluate(reason: 'api_account');
    return _Resp(200, acc.toJson());
  }

  _Resp _deleteAccount(int id) {
    final acc = _account(id);
    if (acc == null || acc.bank == 'CASH') throw const _HttpError(404, 'Không tìm thấy tài khoản');
    if (_txs.any((t) => t.accountId == acc.id)) {
      throw const _HttpError(400, 'Tài khoản đã có giao dịch — hãy tắt "Tính vào tổng" thay vì xoá');
    }
    _accounts.remove(acc);
    _reevaluate(reason: 'api_account');
    return const _Resp(204, null);
  }

  // ------------------------------------------------------------------ cảnh báo, thiết bị, cài đặt

  _Resp _listAlerts(Map<String, String> q) {
    final unread = _boolParam(q, 'unread', false);
    final limit = _intParam(q, 'limit', 50, ge: 1, le: 500);
    final rows = _alerts.where((a) => !unread || !a.read).toList()..sort((a, b) => b.id.compareTo(a.id));
    return _Resp(200, [for (final a in rows.take(limit)) a.toJson()]);
  }

  _Resp _registerDevice(_Json b) {
    final token = _str(b, 'token', min: 10, max: 4096, required: true)!.trim();
    final platform = _choice(b, 'platform', const ['android', 'ios']) ?? 'android';
    final version = _str(b, 'app_version', max: 32);
    var device = _devices.where((d) => d.token == token).firstOrNull;
    var status = 200;
    if (device == null) {
      device = _Device(id: _nextId('device'), token: token, platform: platform, appVersion: version, at: now());
      status = 201;
      while (_devices.length >= 10) {
        _devices.removeAt(0);
      }
      _devices.add(device);
    } else {
      device
        ..platform = platform
        ..appVersion = version ?? device.appVersion
        ..lastSeenAt = now();
    }
    return _Resp(status, {
      'id': device.id,
      'platform': device.platform,
      'app_version': device.appVersion,
      'last_seen_at': isoZ(device.lastSeenAt),
      'push_enabled': true,
    });
  }

  _Resp _testPush() {
    _addAlert(
      kind: 'push_test',
      level: 'INFO',
      title: '🔔 Thử thông báo',
      message: 'Thông báo đẩy đang hoạt động. Cảnh báo quan trọng sẽ hiện như thế này.',
      read: true,
      deliver: false,
    );
    return const _Resp(202, {'queued': true, 'push_enabled': true});
  }

  _Resp _updateSettings(_Json b) {
    final percent = _int(b, 'warning_percent', ge: 0, le: 100);
    final minAmount = _int(b, 'warning_min_amount', ge: 0, le: 1000000000);
    final income = _int(b, 'expected_income_amount', ge: 0, le: 100000000000);
    final day = _int(b, 'expected_income_day', ge: 0, le: 31);
    final every = _bool(b, 'notify_every_tx');
    _settings = _Settings(
      warningPercent: percent ?? _settings.warningPercent,
      warningMinAmount: minAmount ?? _settings.warningMinAmount,
      expectedIncomeAmount: income ?? _settings.expectedIncomeAmount,
      expectedIncomeDay: day ?? _settings.expectedIncomeDay,
      notifyEveryTx: every ?? _settings.notifyEveryTx,
    );
    _reevaluate(reason: 'api_settings');
    return _Resp(200, _settings.toJson());
  }

  // ------------------------------------------------------------------ giả lập biến động số dư

  void _applyCategoryRules(_Tx tx) {
    final (catId, _) = categorize(tx.description, tx.direction, _rules, _categoryByKey('income')?.id);
    if (catId != null) {
      tx
        ..categoryId = catId
        ..categorizedBy = 'rule';
    }
  }

  String _referenceCode(DateTime at) {
    final t = toIct(at);
    final dayOfYear = t.difference(DateTime.utc(t.year)).inDays + 1;
    final tail = List.generate(7, (_) => _random.nextInt(10)).join();
    return 'FT${t.year % 100}${dayOfYear.toString().padLeft(3, '0')}$tail';
  }

  _Tx _bankTx({
    required _Account account,
    required String direction,
    required int amount,
    required DateTime at,
    required String description,
    String? counterName,
  }) {
    final signed = direction == 'in' ? amount : -amount;
    final tx = _Tx(
      id: _nextId('tx'),
      accountId: account.id,
      direction: direction,
      amount: amount,
      bankTime: at,
      description: description,
      referenceCode: _referenceCode(at),
      counterName: counterName,
      balanceAfter: account.balance == null ? null : account.balance! + signed,
      sources: const ['sepay'],
      createdAt: at,
    );
    _applyCategoryRules(tx);
    _txs.add(tx);
    _recomputeBalance(account);
    return tx;
  }

  /// Một biến động số dư như webhook SePay gửi về: thêm giao dịch ngân hàng (kèm số dư sau giao dịch),
  /// tự phân loại theo luật, tính lại mức an toàn và tạo cảnh báo (cảnh báo quan trọng được đẩy tới thiết bị).
  Future<DemoSimulation> simulateBankTx({
    required int accountId,
    required String direction,
    required int amount,
    required String description,
  }) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final account = _account(accountId);
    if (account == null || account.bank == 'CASH') throw ArgumentError.value(accountId, 'accountId');
    if (amount <= 0) throw ArgumentError.value(amount, 'amount');
    final firstNewAlert = (_ids['alert'] ?? 0) + 1;
    final tx = _bankTx(
      account: account,
      direction: direction == 'in' ? 'in' : 'out',
      amount: amount,
      at: now(),
      description: description.trim().isEmpty ? (direction == 'in' ? 'NHAN TIEN' : 'THANH TOAN') : description.trim(),
    );
    _sepayLastEvent = now();
    final ev = account.includeInTotal && account.confirmed
        ? _reevaluate(reason: 'tx', tx: tx)
        : _reevaluate(reason: 'api_tx');
    final created = _alerts.where((a) => a.id >= firstNewAlert).toList();
    final important = created.any((a) => a.kind == 'push_test' || (a.loud && a.deliverTelegram && !a.read));
    return DemoSimulation(
      transactionId: tx.id,
      alertTitles: [for (final a in created) a.title],
      important: important,
      pushed: important && _devices.isNotEmpty,
      level: ev.level,
      free: ev.free,
    );
  }

  // ------------------------------------------------------------------ dữ liệu mẫu

  void _seed() {
    _seeding = true;
    try {
      _seedData();
    } finally {
      _seeding = false;
    }
  }

  void _seedData() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _categories.clear();
    _rules.clear();
    _accounts.clear();
    _goals.clear();
    _txs.clear();
    _alerts.clear();
    _floorStates.clear();
    _budgetArmed.clear();
    _forecastStates.clear();
    _unknownNotified.clear();
    final deviceIds = _ids['device'];
    _ids.clear();
    if (deviceIds != null) _ids['device'] = deviceIds;

    for (final (key, name, kind, icon, order) in defaultCategories) {
      final cat = _Category(
        id: _nextId('category'),
        name: name,
        kind: kind,
        icon: icon,
        sortOrder: order,
        systemKey: key,
      );
      _categories.add(cat);
      final rules = defaultRules[key];
      if (rules == null) continue;
      final (patterns, direction, priority) = rules;
      for (final p in patterns) {
        _rules.add(
          DemoRule(
            id: _nextId('rule'),
            categoryId: cat.id,
            pattern: normalizePattern(p),
            direction: direction,
            priority: priority,
          ),
        );
      }
    }
    int cat(String key) => _categoryByKey(key)!.id;

    final at = now();
    final today = ictDate(at);
    final month = monthOf(at);
    final monthStart = monthBoundsUtc(month).$1;
    final sinceMonthStart = at.difference(monthStart);
    // Mốc muộn nhất của dữ liệu mẫu: 10 phút trước "bây giờ" (vừa qua nửa đêm ngày 1 thì lùi ít hơn, để vẫn ở
    // trong tháng này).
    final latest = at.subtract(
      sinceMonthStart < const Duration(minutes: 20) ? sinceMonthStart ~/ 2 : const Duration(minutes: 10),
    );
    // Khoảng cách giữa các giao dịch phải dồn lại: 7 phút, hoặc ngắn hơn nếu tháng mới bắt đầu chưa lâu.
    final roomInMonth = latest.difference(monthStart);
    final squeezeStep = roomInMonth < const Duration(minutes: 7 * 24) ? roomInMonth ~/ 24 : const Duration(minutes: 7);
    var squeeze = 0;

    /// Giờ VN [hour]:[minute] của [daysAgo] ngày trước; không bao giờ muộn hơn "bây giờ". Giờ đó còn ở tương lai
    /// (vd. mở bản dùng thử lúc 00:10 ngày 1) thì dồn về ngay trước "bây giờ" nhưng không lùi qua đầu tháng:
    /// khoản chi của tháng này phải ở lại tháng này để "Tiền ăn" vẫn là 2.000.000đ.
    DateTime when(int daysAgo, int hour, int minute) {
      final t = startOfDayUtc(today.subtract(Duration(days: daysAgo))).add(Duration(hours: hour, minutes: minute));
      if (!t.isAfter(latest)) return t;
      squeeze++;
      final squeezed = latest.subtract(squeezeStep * squeeze);
      return squeezed.isBefore(monthStart) ? monthStart : squeezed;
    }

    final created = when(13, 9, 0);
    final vcb = _Account(
      id: _nextId('account'),
      bank: 'VCB',
      name: 'VCB chính',
      accountNumber: '1023456789',
      last4: '6789',
      createdAt: created,
    );
    final mb = _Account(
      id: _nextId('account'),
      bank: 'MB',
      name: 'MB phụ',
      accountNumber: '0868123456',
      last4: '3456',
      createdAt: created.add(const Duration(minutes: 20)),
      manualBalance: 650000,
      manualBalanceAt: when(9, 21, 10),
    );
    _accounts.addAll([vcb, mb]);
    final cash = _cashAccount();

    _goals.addAll([
      _Goal(
        id: _nextId('goal'),
        seriesId: _uuid(),
        name: 'Tiền trọ',
        type: 'reserve',
        amount: 3000000,
        categoryId: cat('rent'),
        month: month,
        createdAt: created,
      ),
      _Goal(
        id: _nextId('goal'),
        seriesId: _uuid(),
        name: 'Tiền ăn',
        type: 'budget',
        amount: 5000000,
        categoryId: cat('food'),
        month: month,
        createdAt: created,
      ),
    ]);
    _settings = _Settings(expectedIncomeAmount: 15000000, expectedIncomeDay: 25);

    // Chi ăn uống (≈ 2.000.000đ cho mục tiêu "Tiền ăn") và 2 khoản chưa phân loại phải nằm trong tháng này.
    int inMonth(int daysAgo) => math.min(daysAgo, today.day - 1);
    // (tài khoản, ngày trước, giờ, phút, chiều, số tiền, nội dung)
    final bank = <(_Account, int, int, int, String, int, String)>[
      (vcb, 12, 8, 5, 'out', 38000, 'GRAB BIKE DI LAM'),
      (vcb, inMonth(12), 11, 48, 'out', 85000, 'GRABFOOD BUN BO HUE O XUAN'),
      (vcb, inMonth(11), 19, 20, 'out', 412000, 'BACH HOA XANH THANH TOAN QR'),
      (vcb, inMonth(10), 12, 5, 'out', 65000, 'SHOPEEFOOD COM TAM SA BI CHUONG'),
      (vcb, 10, 21, 40, 'out', 245000, 'VIETTEL INTERNET THANG ${toIct(at).month}'),
      (vcb, inMonth(9), 8, 15, 'out', 59000, 'HIGHLANDS COFFEE VINCOM'),
      (vcb, 9, 18, 10, 'out', 42000, 'GRAB BIKE VE NHA'),
      (vcb, 8, 9, 30, 'out', 456000, 'THANH TOAN TIEN DIEN EVN HCMC'),
      (vcb, inMonth(7), 20, 30, 'out', 460000, 'LAU NUONG GANG BAN BE'),
      (vcb, inMonth(6), 12, 10, 'out', 70000, 'COM TAM BA GHIEN'),
      (vcb, 6, 22, 15, 'out', 126000, 'XANH SM TAXI SAN BAY'),
      (vcb, inMonth(5), 18, 45, 'out', 356000, 'WINMART THANH TOAN THE'),
      (vcb, 4, 21, 0, 'out', 389000, 'SHOPEE THANH TOAN DON 2410ABC'),
      (vcb, inMonth(3), 12, 20, 'out', 92000, 'BAEMIN PHO BO GIA TRUYEN'),
      (mb, 3, 8, 40, 'out', 70000, 'GRAB BIKE DI HOC'),
      (vcb, inMonth(2), 9, 10, 'out', 45000, 'QR THANH TOAN CA PHE MUOI CHU LONG'),
      (vcb, 2, 15, 30, 'in', 89000, 'SHOPEE HOAN TIEN DON 2410ABC'),
      (vcb, inMonth(2), 19, 5, 'out', 285000, 'COOPMART XA LO HA NOI'),
      (vcb, inMonth(1), 7, 30, 'out', 66000, 'BANH MI HUYNH HOA'),
      (vcb, inMonth(1), 20, 45, 'out', 200000, 'CHUYEN TIEN CHO NGUYEN VAN NAM'),
    ];
    final payday = _settings.expectedIncomeDay;
    if (today.day > payday && today.day - payday <= 12) {
      bank.add((vcb, today.day - payday, 10, 0, 'in', 15000000, 'CONG TY TNHH ABC TRA LUONG THANG ${toIct(at).month}'));
    }
    final rows = [
      for (final (acc, daysAgo, h, m, dir, amount, text) in bank) (acc, when(daysAgo, h, m), dir, amount, text),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    // Số dư VCB sau giao dịch cuối = 9.420.000đ (VCB + MB = 10.000.000đ, được tiêu ≈ 4.000.000đ).
    const vcbFinal = 9420000;
    // Số dư nhập lúc thêm TK là mốc đầu; sau đó số dư ngân hàng báo kèm từng giao dịch thay mốc.
    final vcbNet = rows.where((r) => r.$1 == vcb).fold<int>(0, (s, r) => s + (r.$3 == 'in' ? r.$4 : -r.$4));
    vcb
      ..manualBalance = vcbFinal - vcbNet
      ..manualBalanceAt = created;
    _recomputeBalance(vcb);
    _recomputeBalance(mb);
    _Tx? latestBank;
    for (final (acc, t, dir, amount, text) in rows) {
      latestBank = _bankTx(account: acc, direction: dir, amount: amount, at: t, description: text);
    }
    _sepayLastEvent = latestBank?.createdAt;

    _txs.add(
      _Tx(
        id: _nextId('tx'),
        accountId: cash.id,
        direction: 'out',
        amount: 50000,
        bankTime: when(inMonth(4), 12, 30),
        description: 'Bún chả vỉa hè',
        categoryId: cat('food'),
        categorizedBy: 'user',
        isManual: true,
        affectsBalance: false,
        sources: const ['manual'],
        createdAt: when(inMonth(4), 12, 35),
      ),
    );

    // Trạng thái chống spam như thể máy chủ đã chạy từ trước.
    final ev = _evaluation(month, at: at);
    _floorStates[month] = FloorState(lastLevel: levelRank.containsKey(ev.level) ? ev.level : null);
    _decideBudgets(ev);
    final fc = _buildForecast(ev, at);
    _forecastStates[month] = decideForecast(null, fc, ev, at).$2;

    // Vài cảnh báo cũ (theo thứ tự thời gian).
    final pending = <(DateTime, void Function(DateTime))>[
      (
        created.add(const Duration(minutes: 25)),
        (t) => _addAlert(
          kind: 'push_test',
          level: 'INFO',
          title: '🔔 Thử thông báo',
          message: 'Thông báo đẩy đang hoạt động. Cảnh báo quan trọng sẽ hiện như thế này.',
          read: true,
          deliver: false,
          createdAt: t,
        ),
      ),
    ];
    if (latestBank != null) {
      final tx = latestBank;
      pending.add((
        tx.bankTime.add(const Duration(seconds: 4)),
        (t) {
          final (title, message) = composeTxMessage(
            _txInfo(tx),
            ev,
            FloorDecision(false, null, ev.level, FloorState()),
            const [],
          );
          _addAlert(
            kind: 'tx',
            level: ev.level,
            month: month,
            transactionId: tx.id,
            title: title,
            message: message,
            loud: false,
            read: true,
            createdAt: t,
          );
        },
      ));
    }
    // Bản tin sáng 08:00 hôm nay — chỉ khi đã qua 08:00: bản tin hôm qua phải mang số liệu (và tháng) của hôm qua,
    // mà dữ liệu mẫu chỉ có trạng thái hiện tại.
    final digestAt = startOfDayUtc(today).add(const Duration(hours: 8));
    if (!digestAt.isAfter(at)) {
      pending.add((
        digestAt,
        (t) {
          final (title, message) = composeDigest(ev, _uncategorizedCount(month), t, fc);
          final danger = ev.level == 'WARNING' || ev.level == 'DANGER';
          _addAlert(
            kind: 'digest',
            level: ev.level,
            month: month,
            title: title,
            message: message,
            loud: danger,
            read: !danger,
            createdAt: t,
          );
        },
      ));
    }
    pending.sort((a, b) => a.$1.compareTo(b.$1));
    for (final (t, add) in pending) {
      add(t);
    }
  }
}

// ---------------------------------------------------------------------- bản ghi

typedef _Json = Map<String, dynamic>;

class _Resp {
  const _Resp(this.status, this.body);

  final int status;
  final Object? body;
}

class _HttpError implements Exception {
  const _HttpError(this.status, this.detail);

  final int status;
  final Object detail;
}

class _Settings {
  _Settings({
    this.warningPercent = 10,
    this.warningMinAmount = 500000,
    this.expectedIncomeAmount = 0,
    this.expectedIncomeDay = 0,
    this.notifyEveryTx = true,
  });

  final int warningPercent;
  final int warningMinAmount;
  final int expectedIncomeAmount;
  final int expectedIncomeDay;
  final bool notifyEveryTx;

  EvalSettings get evalSettings => EvalSettings(
    warningPercent: warningPercent,
    warningMinAmount: warningMinAmount,
    expectedIncomeAmount: expectedIncomeAmount,
    expectedIncomeDay: expectedIncomeDay,
  );

  Map<String, Object?> toJson() => {
    'warning_percent': warningPercent,
    'warning_min_amount': warningMinAmount,
    'expected_income_amount': expectedIncomeAmount,
    'expected_income_day': expectedIncomeDay,
    'notify_every_tx': notifyEveryTx,
  };
}

class _Category {
  _Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.icon,
    required this.sortOrder,
    this.systemKey,
  });

  final int id;
  final String name;
  final String kind;
  final String? icon;
  final int sortOrder;
  final String? systemKey;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'icon': icon,
    'sort_order': sortOrder,
    'system_key': systemKey,
  };
}

class _Account {
  _Account({
    required this.id,
    required this.bank,
    required this.name,
    required this.createdAt,
    this.accountNumber,
    this.last4,
    this.includeInTotal = true,
    this.manualBalance,
    this.manualBalanceAt,
  });

  final int id;
  final String bank;
  String name;
  String? accountNumber;
  String? last4;
  bool includeInTotal;
  bool confirmed = true;
  int? balance;
  DateTime? balanceAsOf;
  bool balanceDerived = false;
  int? manualBalance;
  DateTime? manualBalanceAt;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'bank': bank,
    'name': name,
    'account_number': accountNumber,
    'last4': last4,
    'include_in_total': includeInTotal,
    'confirmed': confirmed,
    'balance': balance,
    'balance_as_of': isoZ(balanceAsOf),
    'balance_derived': balanceDerived,
    'manual_balance': manualBalance,
    'manual_balance_at': isoZ(manualBalanceAt),
  };
}

class _Goal {
  _Goal({
    required this.id,
    required this.seriesId,
    required this.name,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.month,
    required DateTime createdAt,
    this.repeatMonthly = true,
  }) : updatedAt = createdAt;

  final int id;
  final String seriesId;
  String name;
  String type;
  int amount;
  int? categoryId;
  final String month;
  bool repeatMonthly;
  int openingSpent = 0;
  bool archived = false;
  DateTime updatedAt;
}

class _Tx {
  _Tx({
    required this.id,
    required this.accountId,
    required this.direction,
    required this.amount,
    required this.bankTime,
    required this.description,
    required this.createdAt,
    required this.sources,
    this.referenceCode,
    this.counterName,
    this.balanceAfter,
    this.categoryId,
    this.categorizedBy = 'none',
    this.isManual = false,
    this.affectsBalance = true,
  }) : updatedAt = createdAt;

  final int id;
  final int accountId;
  final String direction;
  final int amount;
  final DateTime bankTime;
  final String description;
  final String? referenceCode;
  String? get counterAccount => null;
  final String? counterName;
  final int? balanceAfter;
  int? categoryId;
  int? goalId;
  String categorizedBy;
  String status = 'active';
  final bool isManual;
  final bool affectsBalance;
  int? pairId;
  final List<String> sources;
  final DateTime createdAt;
  DateTime updatedAt;
}

class _Alert {
  _Alert({
    required this.id,
    required this.createdAt,
    required this.kind,
    required this.level,
    required this.title,
    required this.message,
    required this.read,
    required this.loud,
    required this.deliverTelegram,
    this.month,
    this.goalId,
    this.transactionId,
  });

  final int id;
  final DateTime createdAt;
  final String kind;
  final String? level;
  final String? month;
  final int? goalId;
  final int? transactionId;
  String title;
  String message;
  bool read;
  final bool loud;
  final bool deliverTelegram;

  Map<String, Object?> toJson() => {
    'id': id,
    'created_at': isoZ(createdAt),
    'kind': kind,
    'level': level,
    'title': title,
    'message': message,
    'read': read,
    'transaction_id': transactionId,
    'goal_id': goalId,
  };
}

class _Device {
  _Device({
    required this.id,
    required this.token,
    required this.platform,
    required this.appVersion,
    required DateTime at,
  }) : createdAt = at,
       lastSeenAt = at;

  final int id;
  final String token;
  String platform;
  String? appVersion;
  final DateTime createdAt;
  DateTime lastSeenAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'platform': platform,
    'app_version': appVersion,
    'created_at': isoZ(createdAt),
    'last_seen_at': isoZ(lastSeenAt),
    'last_error': null,
  };
}
