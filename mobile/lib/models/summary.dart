import 'account.dart';
import 'alert.dart';
import 'goal.dart';
import 'json_utils.dart';
import 'level.dart';

/// Lương dự kiến trong tổng quan.
class ExpectedIncome {
  const ExpectedIncome({required this.amount, required this.day, this.pending = 0});

  final int amount;
  final int day;

  /// Số tiền lương đang chờ nhận trong tháng.
  final int pending;

  factory ExpectedIncome.fromJson(JsonMap json) =>
      ExpectedIncome(amount: asInt(json['amount']), day: asInt(json['day']), pending: asInt(json['pending']));
}

/// Sức khoẻ nguồn dữ liệu (webhook, email).
class IngestHealth {
  const IngestHealth({
    this.stale = false,
    this.warnings = const [],
    this.errorEvents = 0,
    this.unparsedEvents = 0,
    this.sources = const {},
  });

  /// `true` = nguồn dữ liệu đang có vấn đề (= [warnings] không rỗng).
  final bool stale;

  /// Thông báo tiếng Việt do server soạn sẵn (email lỗi, quá lâu không có webhook…), hiện nguyên văn.
  final List<String> warnings;
  final int errorEvents;
  final int unparsedEvents;

  /// Thông tin thô từng nguồn (`sepay`, `casso`, `email`…).
  final Map<String, JsonMap> sources;

  bool get hasProblems => stale || warnings.isNotEmpty || errorEvents > 0 || unparsedEvents > 0 || emailError != null;

  String? get emailError => asStringOrNull(sources['email']?['last_error']);

  factory IngestHealth.fromJson(JsonMap json) {
    final rawSources = asMap(json['sources']);
    final warnings = asStringList(json['warnings']).where((w) => w.trim().isNotEmpty).toList();
    return IngestHealth(
      stale: asBool(json['stale'], warnings.isNotEmpty),
      warnings: warnings,
      errorEvents: asInt(json['error_events']),
      unparsedEvents: asInt(json['unparsed_events']),
      sources: {for (final e in rawSources.entries) e.key: asMap(e.value)},
    );
  }
}

/// Kết quả GET /api/summary.
class Summary {
  const Summary({
    required this.month,
    required this.level,
    this.generatedAt,
    this.levelReason,
    this.balance,
    this.balanceKnown = false,
    this.balanceAsOf,
    this.inTransit = 0,
    this.floor = 0,
    this.free,
    this.buffer = 0,
    this.waitingIncome = false,
    this.expectedIncome,
    this.daysLeft,
    this.accounts = const [],
    this.goals = const [],
    this.uncategorizedCount = 0,
    this.unreadAlerts = 0,
    this.latestAlerts = const [],
    this.ingestHealth = const IngestHealth(),
  });

  final String month;
  final DateTime? generatedAt;
  final Level level;
  final String? levelReason;

  /// `null` khi chưa biết số dư.
  final int? balance;
  final bool balanceKnown;
  final DateTime? balanceAsOf;
  final int inTransit;

  /// Mức sàn = tổng tiền còn phải giữ cho các mục tiêu.
  final int floor;

  /// Được tiêu thoải mái = số dư − mức sàn (`null` khi chưa biết số dư).
  final int? free;
  final int buffer;
  final bool waitingIncome;
  final ExpectedIncome? expectedIncome;
  final int? daysLeft;
  final List<Account> accounts;
  final List<GoalView> goals;
  final int uncategorizedCount;
  final int unreadAlerts;
  final List<Alert> latestAlerts;
  final IngestHealth ingestHealth;

  /// Có TK tính vào tổng mà số dư chỉ là ước tính.
  bool get anyBalanceDerived => accounts.any((a) => a.includeInTotal && a.balanceKnown && a.balanceDerived);

  /// TK tính vào tổng nhưng chưa biết số dư.
  List<Account> get accountsMissingBalance =>
      accounts.where((a) => a.includeInTotal && !a.balanceKnown && !a.isCash).toList();

  /// TK lạ chưa xác nhận.
  List<Account> get unconfirmedAccounts => accounts.where((a) => !a.confirmed).toList();

  Summary copyWith({List<Alert>? latestAlerts, int? unreadAlerts}) => Summary(
    month: month,
    level: level,
    generatedAt: generatedAt,
    levelReason: levelReason,
    balance: balance,
    balanceKnown: balanceKnown,
    balanceAsOf: balanceAsOf,
    inTransit: inTransit,
    floor: floor,
    free: free,
    buffer: buffer,
    waitingIncome: waitingIncome,
    expectedIncome: expectedIncome,
    daysLeft: daysLeft,
    accounts: accounts,
    goals: goals,
    uncategorizedCount: uncategorizedCount,
    unreadAlerts: unreadAlerts ?? this.unreadAlerts,
    latestAlerts: latestAlerts ?? this.latestAlerts,
    ingestHealth: ingestHealth,
  );

  factory Summary.fromJson(JsonMap json) {
    final rawIncome = json['expected_income'];
    final balance = asIntOrNull(json['balance']);
    return Summary(
      month: asString(json['month']),
      generatedAt: asDateTime(json['generated_at']),
      level: Level.parse(json['level']),
      levelReason: asStringOrNull(json['level_reason']),
      balance: balance,
      balanceKnown: asBool(json['balance_known'], balance != null),
      balanceAsOf: asDateTime(json['balance_as_of']),
      inTransit: asInt(json['in_transit']),
      floor: asInt(json['floor']),
      free: asIntOrNull(json['free']),
      buffer: asInt(json['buffer']),
      waitingIncome: asBool(json['waiting_income']),
      expectedIncome: rawIncome is Map ? ExpectedIncome.fromJson(asMap(rawIncome)) : null,
      daysLeft: asIntOrNull(json['days_left']),
      accounts: asList(json['accounts'], Account.fromJson),
      goals: asList(json['goals'], GoalView.fromJson),
      uncategorizedCount: asInt(json['uncategorized_count']),
      unreadAlerts: asInt(json['unread_alerts']),
      latestAlerts: asList(json['latest_alerts'], Alert.fromJson),
      ingestHealth: IngestHealth.fromJson(asMap(json['ingest_health'])),
    );
  }
}
