/// Bản Dart rút gọn nhưng đúng ngữ nghĩa của `backend/app/engine/` (evaluator.py, alerts.py, forecast.py,
/// messages.py) và `clock.py` — dùng cho máy chủ giả của bản dùng thử. Hàm thuần, không giữ trạng thái.
library;

import 'dart:math' as math;

import 'demo_text.dart';

// ------------------------------------------------------------------ thời gian (clock.py)

/// Giờ Việt Nam (UTC+7, không có giờ mùa hè).
const Duration ictOffset = Duration(hours: 7);

String _two(int v) => v.toString().padLeft(2, '0');

/// DateTime UTC mà các trường (năm, tháng, ngày, giờ…) là giờ Việt Nam.
DateTime toIct(DateTime dt) => dt.toUtc().add(ictOffset);

/// Ngày (giờ VN) của [dt], dạng `DateTime.utc(y, m, d)`.
DateTime ictDate(DateTime dt) {
  final t = toIct(dt);
  return DateTime.utc(t.year, t.month, t.day);
}

String monthOf(DateTime dt) {
  final t = toIct(dt);
  return '${t.year}-${_two(t.month)}';
}

(int, int) parseYm(String month) {
  final parts = month.split('-');
  return (int.parse(parts[0]), int.parse(parts[1]));
}

bool isValidMonth(String month) {
  final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(month);
  if (m == null) return false;
  final year = int.parse(m.group(1)!);
  final mon = int.parse(m.group(2)!);
  return mon >= 1 && mon <= 12 && year >= 2000 && year <= 2100;
}

String shiftYm(String month, int delta) {
  final (year, mon) = parseYm(month);
  final idx = year * 12 + (mon - 1) + delta;
  return '${(idx ~/ 12).toString().padLeft(4, '0')}-${_two(idx % 12 + 1)}';
}

String nextMonth(String month) => shiftYm(month, 1);
String prevMonth(String month) => shiftYm(month, -1);

/// [đầu tháng, đầu tháng sau) theo giờ VN, trả về UTC.
(DateTime, DateTime) monthBoundsUtc(String month) {
  final (y, m) = parseYm(month);
  final (ny, nm) = parseYm(nextMonth(month));
  return (DateTime.utc(y, m, 1).subtract(ictOffset), DateTime.utc(ny, nm, 1).subtract(ictOffset));
}

int daysInMonth(String month) {
  final (y, m) = parseYm(month);
  return DateTime.utc(y, m + 1, 0).day;
}

DateTime startOfDayUtc(DateTime date) => DateTime.utc(date.year, date.month, date.day).subtract(ictOffset);

/// ISO-8601 UTC có hậu tố Z, chính xác tới giây (`clock.iso_z`).
String? isoZ(DateTime? dt) {
  if (dt == null) return null;
  final u = dt.toUtc();
  return '${u.year.toString().padLeft(4, '0')}-${_two(u.month)}-${_two(u.day)}'
      'T${_two(u.hour)}:${_two(u.minute)}:${_two(u.second)}Z';
}

/// "YYYY-MM-DD" của một ngày.
String isoDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${_two(date.month)}-${_two(date.day)}';

String ddmm(DateTime date) => '${_two(date.day)}/${_two(date.month)}';

/// "14:05 15/10" theo giờ VN.
String hhmmDdmm(DateTime dt) {
  final t = toIct(dt);
  return '${_two(t.hour)}:${_two(t.minute)} ${_two(t.day)}/${_two(t.month)}';
}

int _daysBetween(DateTime from, DateTime to) => to.difference(from).inDays;

// ------------------------------------------------------------------ evaluator.py

const Map<String, int> levelRank = {'OK': 0, 'WARNING': 1, 'DANGER': 2};
const double incomeReceivedRatio = 0.7;
const int paydayGraceDays = 3;

class GoalIn {
  const GoalIn({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.month,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.seriesId = '',
    this.repeatMonthly = true,
    this.openingSpent = 0,
    this.rank,
  });

  final int id;
  final String name;
  final String type;
  final int amount;
  final String month;
  final int? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String seriesId;
  final bool repeatMonthly;
  final int openingSpent;
  final int? rank;
}

class TxIn {
  const TxIn({
    required this.id,
    required this.direction,
    required this.amount,
    required this.bankTime,
    this.categoryId,
    this.goalId,
  });

  final int id;
  final String direction;
  final int amount;
  final DateTime bankTime;
  final int? categoryId;
  final int? goalId;
}

class EvalSettings {
  const EvalSettings({
    this.warningPercent = 10,
    this.warningMinAmount = 500000,
    this.expectedIncomeAmount = 0,
    this.expectedIncomeDay = 0,
  });

  final int warningPercent;
  final int warningMinAmount;
  final int expectedIncomeAmount;
  final int expectedIncomeDay;
}

class GoalView {
  const GoalView({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.month,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.seriesId,
    required this.repeatMonthly,
    required this.openingSpent,
    required this.spent,
    required this.remaining,
    required this.usagePct,
    required this.autoMatch,
  });

  final int id;
  final String name;
  final String type;
  final int amount;
  final String month;
  final int? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String seriesId;
  final bool repeatMonthly;
  final int openingSpent;
  final int spent;
  final int remaining;
  final double usagePct;
  final bool autoMatch;

  Map<String, Object?> toJson() => {
    'id': id,
    'series_id': seriesId,
    'name': name,
    'type': type,
    'amount': amount,
    'category_id': categoryId,
    'category_name': categoryName,
    'category_icon': categoryIcon,
    'month': month,
    'repeat_monthly': repeatMonthly,
    'opening_spent': openingSpent,
    'spent': spent,
    'remaining': remaining,
    'usage_pct': usagePct,
    'auto_match': autoMatch,
  };
}

class Evaluation {
  const Evaluation({
    required this.month,
    required this.balance,
    required this.inTransit,
    required this.floor,
    required this.free,
    required this.buffer,
    required this.level,
    required this.levelReason,
    required this.waitingIncome,
    required this.expectedPending,
    required this.daysLeft,
    required this.goals,
  });

  final String month;
  final int? balance;
  final int inTransit;
  final int floor;
  final int? free;
  final int buffer;
  final String level;
  final String levelReason;
  final bool waitingIncome;
  final int expectedPending;
  final int daysLeft;
  final List<GoalView> goals;

  bool get balanceKnown => balance != null;
  int get deficit => free != null && free! < 0 ? -free! : 0;

  Map<String, Object?> toJson() => {
    'month': month,
    'level': level,
    'level_reason': levelReason,
    'balance': balance,
    'balance_known': balanceKnown,
    'in_transit': inTransit,
    'floor': floor,
    'free': free,
    'buffer': buffer,
    'waiting_income': waitingIncome,
    'days_left': daysLeft,
    'goals': [for (final g in goals) g.toJson()],
  };
}

int _signedSpend(TxIn tx) => tx.direction == 'out' ? tx.amount : -tx.amount;

/// Mỗi (danh mục, tháng) chỉ goal của chuỗi tạo sớm nhất được tự khớp theo danh mục.
Set<int> autoMatchIds(List<GoalIn> goals) {
  final sorted = [...goals]
    ..sort((a, b) {
      final c = (a.rank ?? a.id).compareTo(b.rank ?? b.id);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  final seen = <String>{};
  final out = <int>{};
  for (final g in sorted) {
    if (g.categoryId == null) continue;
    if (!seen.add('${g.categoryId}|${g.month}')) continue;
    out.add(g.id);
  }
  return out;
}

/// {tx_id: goal_id}: giao dịch nào được tính cho mục tiêu nào.
Map<int, int> attributeGoals(List<GoalIn> goals, List<TxIn> txs) {
  final auto = autoMatchIds(goals);
  final ids = {for (final g in goals) g.id};
  final byCatMonth = {
    for (final g in goals)
      if (auto.contains(g.id)) '${g.categoryId}|${g.month}': g.id,
  };
  final out = <int, int>{};
  for (final tx in txs) {
    if (tx.goalId != null) {
      if (ids.contains(tx.goalId)) out[tx.id] = tx.goalId!;
      continue;
    }
    if (tx.categoryId == null) continue;
    final gid = byCatMonth['${tx.categoryId}|${monthOf(tx.bankTime)}'];
    if (gid != null) out[tx.id] = gid;
  }
  return out;
}

List<GoalView> computeGoalViews(List<GoalIn> goals, List<TxIn> txs) {
  final auto = autoMatchIds(goals);
  final totals = {for (final g in goals) g.id: 0};
  final byId = {for (final t in txs) t.id: t};
  attributeGoals(goals, txs).forEach((txId, gid) => totals[gid] = totals[gid]! + _signedSpend(byId[txId]!));
  final sorted = [...goals]
    ..sort((a, b) {
      final c = (a.type != 'reserve' ? 1 : 0).compareTo(b.type != 'reserve' ? 1 : 0);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  return [
    for (final g in sorted)
      () {
        final spent = math.max(0, g.openingSpent + totals[g.id]!);
        return GoalView(
          id: g.id,
          name: g.name,
          type: g.type,
          amount: g.amount,
          month: g.month,
          categoryId: g.categoryId,
          categoryName: g.categoryName,
          categoryIcon: g.categoryIcon,
          seriesId: g.seriesId,
          repeatMonthly: g.repeatMonthly,
          openingSpent: g.openingSpent,
          spent: spent,
          remaining: math.max(0, g.amount - spent),
          usagePct: g.amount > 0 ? pyRound1(spent * 100.0 / g.amount) : 0.0,
          autoMatch: auto.contains(g.id) || g.categoryId == null,
        );
      }(),
  ];
}

int expectedIncomePending(EvalSettings s, DateTime today, String month, int incomeReceived) {
  final amount = s.expectedIncomeAmount;
  final day = s.expectedIncomeDay;
  if (amount <= 0 || day < 1 || day > 31) return 0;
  if (monthOf(startOfDayUtc(today)) != month) return 0;
  if (incomeReceived >= amount * incomeReceivedRatio) return 0;
  final payday = math.min(day, daysInMonth(month));
  return today.day <= payday + paydayGraceDays ? amount : 0;
}

int computeBuffer(int floor, EvalSettings s) => math.max(pyRound(floor * s.warningPercent / 100), s.warningMinAmount);

int daysLeftInMonth(String month, DateTime today) {
  if (monthOf(startOfDayUtc(today)) != month) return 0;
  return daysInMonth(month) - today.day + 1;
}

Evaluation evaluate({
  required String month,
  required List<GoalIn> goals,
  required List<TxIn> txs,
  required int? balance,
  required EvalSettings settings,
  required DateTime today,
  int inTransit = 0,
  int incomeReceived = 0,
}) {
  final views = computeGoalViews(goals, txs);
  final floor = views.fold<int>(0, (sum, v) => sum + v.remaining);
  final buffer = computeBuffer(floor, settings);
  final pending = expectedIncomePending(settings, today, month, incomeReceived);
  final daysLeft = daysLeftInMonth(month, today);

  Evaluation result(String level, String reason, int? free, {bool waiting = false}) => Evaluation(
    month: month,
    balance: balance,
    inTransit: inTransit,
    floor: floor,
    free: free,
    buffer: buffer,
    level: level,
    levelReason: reason,
    waitingIncome: waiting,
    expectedPending: pending,
    daysLeft: daysLeft,
    goals: views,
  );

  if (balance == null) return result('UNKNOWN', 'Chưa biết số dư — hãy nhập số dư hiện tại của tài khoản', null);
  final free = balance + inTransit - floor;
  if (views.isEmpty) return result('OK', 'Chưa có mục tiêu nào — bấm "Thêm mục tiêu" để bắt đầu', free);
  if (free >= buffer) return result('OK', 'Còn ${vnd(free)} có thể tiêu thoải mái', free);
  if (free >= 0) return result('WARNING', 'Chỉ còn ${vnd(free)} trên mức sàn ${vnd(floor)}', free);
  if (pending > 0 && free + pending >= 0) {
    return result(
      'WARNING',
      'Đang thiếu ${vnd(-free)} so với mức sàn, sẽ đủ khi nhận lương (ngày ${settings.expectedIncomeDay})',
      free,
      waiting: true,
    );
  }
  return result('DANGER', 'Đã lấn ${vnd(-free)} vào tiền dành cho mục tiêu', free);
}

// ------------------------------------------------------------------ alerts.py

const Duration repeatGap = Duration(hours: 2);
const int hysteresisMin = 200000;
const List<int> budgetThresholds = [80, 100];
const double budgetRearmGap = 5.0;

class FloorState {
  FloorState({this.lastLevel, this.lastDeficit, Map<String, DateTime>? notified}) : notified = notified ?? {};

  String? lastLevel;
  int? lastDeficit;
  final Map<String, DateTime> notified;

  FloorState copy() => FloorState(lastLevel: lastLevel, lastDeficit: lastDeficit, notified: {...notified});
}

class FloorDecision {
  const FloorDecision(this.notify, this.kind, this.level, this.state);

  final bool notify;

  /// worse | safe | escalate
  final String? kind;
  final String level;
  final FloorState state;
}

int hysteresis(int buffer) => math.max(pyRound(buffer * 0.1), hysteresisMin);

String _effectiveLevel(String prev, Evaluation ev) {
  final raw = ev.level;
  if (levelRank[raw]! >= levelRank[prev]!) return raw;
  final free = ev.free!;
  final h = hysteresis(ev.buffer);
  if (prev == 'DANGER') {
    if (free >= ev.buffer + h) return 'OK';
    if (free >= h || ev.waitingIncome) return 'WARNING';
    return 'DANGER';
  }
  return free >= ev.buffer + h ? 'OK' : 'WARNING';
}

/// reason: 'inflow' (tiền vào), 'tx', 'api_*', ...
FloorDecision decideFloor(FloorState? state, Evaluation ev, String reason, DateTime now) {
  state ??= FloorState();
  if (ev.level == 'UNKNOWN') return FloorDecision(false, null, 'UNKNOWN', state);
  final prev = levelRank.containsKey(state.lastLevel) ? state.lastLevel! : 'OK';
  final eff = _effectiveLevel(prev, ev);
  final next = state.copy();
  var notify = false;
  String? kind;
  if (levelRank[eff]! > levelRank[prev]!) {
    final last = state.notified[eff];
    if (last == null || now.difference(last) >= repeatGap) {
      notify = true;
      kind = 'worse';
      next.notified[eff] = now;
    }
    if (eff == 'DANGER') next.lastDeficit = ev.deficit;
  } else if (levelRank[eff]! < levelRank[prev]!) {
    if (eff == 'OK' && reason == 'inflow') {
      final last = state.notified['SAFE'];
      if (last == null || now.difference(last) >= repeatGap) {
        notify = true;
        kind = 'safe';
        next.notified['SAFE'] = now;
      }
    }
    if (eff != 'DANGER') next.lastDeficit = null;
  } else if (eff == 'DANGER') {
    final deficit = ev.deficit;
    final lastDeficit = (state.lastDeficit ?? 0) != 0 ? state.lastDeficit! : deficit;
    if (deficit >= lastDeficit + math.max(ev.buffer, pyRound(lastDeficit * 0.25))) {
      notify = true;
      kind = 'escalate';
      next.lastDeficit = deficit;
    } else if (state.lastDeficit == null) {
      next.lastDeficit = deficit;
    }
  }
  next.lastLevel = eff;
  return FloorDecision(notify, kind, eff, next);
}

/// (ngưỡng cao nhất vừa vượt, trạng thái armed mới). Chỉ áp cho goal ngân sách.
(int?, Map<int, bool>) decideBudget(GoalView goal, Map<int, bool> armed) {
  final next = {for (final th in budgetThresholds) th: armed[th] ?? true};
  if (goal.type != 'budget' || goal.amount <= 0) return (null, next);
  int? fired;
  for (final th in budgetThresholds) {
    if (goal.usagePct >= th) {
      if (next[th]!) {
        next[th] = false;
        fired = th;
      }
    } else if (goal.usagePct < th - budgetRearmGap) {
      next[th] = true;
    }
  }
  return (fired, next);
}

const int forecastHorizonDays = 7;
const int forecastRearmDays = 10;
const int forecastMinShortfall = 200000;
const int forecastEscalateDays = 3;
const Duration forecastEscalateGap = Duration(hours: 24);

class ForecastState {
  ForecastState({this.armed = true, this.lastSentAt, this.lastHit});

  bool armed;
  DateTime? lastSentAt;
  DateTime? lastHit;

  ForecastState copy() => ForecastState(armed: armed, lastSentAt: lastSentAt, lastHit: lastHit);
}

(bool, ForecastState) decideForecast(ForecastState? state, Forecast? fc, Evaluation ev, DateTime now) {
  state ??= ForecastState();
  final next = state.copy();
  if (fc == null || fc.status != 'ok' || !(ev.level == 'OK' || ev.level == 'WARNING') || ev.goals.isEmpty) {
    return (false, next);
  }
  final days = fc.daysUntilFloorHit;
  if (days == 0 || (ev.free != null && ev.free! < 0)) return (false, next);
  if (days == null || days >= forecastRearmDays) {
    next.armed = true;
    return (false, next);
  }
  final material = fc.minProjectedFree != null && fc.minProjectedFree! <= -forecastMinShortfall;
  if (days > forecastHorizonDays || !material) return (false, next);
  if (state.armed) {
    next
      ..armed = false
      ..lastSentAt = now
      ..lastHit = fc.floorHitDate;
    return (true, next);
  }
  final earlier =
      state.lastHit != null &&
      fc.floorHitDate != null &&
      _daysBetween(fc.floorHitDate!, state.lastHit!) >= forecastEscalateDays;
  if (earlier && (state.lastSentAt == null || now.difference(state.lastSentAt!) >= forecastEscalateGap)) {
    next
      ..lastSentAt = now
      ..lastHit = fc.floorHitDate;
    return (true, next);
  }
  return (false, next);
}

// ------------------------------------------------------------------ forecast.py

class OutflowIn {
  const OutflowIn({required this.id, required this.amount, required this.day, this.goalId});

  final int id;
  final int amount;

  /// Ngày theo giờ VN.
  final DateTime day;
  final int? goalId;
}

const int _windowDays = 14;
const int _minDays = 3;
const int _fullDays = 7;
const int _largeMin = 1000000;
const int _largeMedianFactor = 3;
const double _budgetTolPct = 5.0;

class BudgetPace {
  const BudgetPace({
    required this.goalId,
    required this.name,
    required this.categoryIcon,
    required this.spent,
    required this.amount,
    required this.dailyRate,
    required this.projectedSpent,
    required this.projectedPct,
    required this.status,
    required this.suggestedDaily,
  });

  final int goalId;
  final String name;
  final String? categoryIcon;
  final int spent;
  final int amount;
  final int dailyRate;
  final int projectedSpent;
  final double projectedPct;
  final String status;
  final int suggestedDaily;

  Map<String, Object?> toJson() => {
    'goal_id': goalId,
    'name': name,
    'category_icon': categoryIcon,
    'spent': spent,
    'amount': amount,
    'daily_rate': dailyRate,
    'projected_spent': projectedSpent,
    'projected_pct': projectedPct,
    'status': status,
    'suggested_daily': suggestedDaily,
  };
}

class Forecast {
  Forecast({
    required this.status,
    required this.headline,
    this.confidence = 'normal',
    this.reason,
    this.observedDays = 0,
    this.windowDays = 0,
    this.dailySpend = 0,
    this.cappedAmount = 0,
    this.cappedCount = 0,
    this.projectedFreeEnd,
    this.projectedBudgetOverrun = 0,
    this.incomePending = 0,
    this.floorHitDate,
    this.daysUntilFloorHit,
    this.recoversOn,
    this.minProjectedFree,
    this.safeDailySpend,
    this.details = const [],
    this.budgets = const [],
  });

  final String status;
  String headline;
  final String confidence;
  final String? reason;
  final int observedDays;
  final int windowDays;
  final int dailySpend;
  final int cappedAmount;
  final int cappedCount;
  final int? projectedFreeEnd;
  final int projectedBudgetOverrun;
  final int incomePending;
  final DateTime? floorHitDate;
  final int? daysUntilFloorHit;
  final DateTime? recoversOn;
  final int? minProjectedFree;
  final int? safeDailySpend;
  List<String> details;
  final List<BudgetPace> budgets;

  Map<String, Object?> toJson() => {
    'status': status,
    'confidence': confidence,
    'reason': reason,
    'observed_days': observedDays,
    'window_days': windowDays,
    'daily_spend': dailySpend,
    'capped_amount': cappedAmount,
    'capped_count': cappedCount,
    'projected_free_end': projectedFreeEnd,
    'projected_budget_overrun': projectedBudgetOverrun,
    'income_pending': incomePending,
    'floor_hit_date': floorHitDate == null ? null : isoDate(floorHitDate!),
    'days_until_floor_hit': daysUntilFloorHit,
    'recovers_on': recoversOn == null ? null : isoDate(recoversOn!),
    'safe_daily_spend': safeDailySpend,
    'headline': headline,
    'details': details,
    'budgets': [for (final b in budgets) b.toJson()],
  };
}

int _median(List<int> values) {
  final s = [...values]..sort();
  final n = s.length;
  if (n.isOdd) return s[n ~/ 2];
  return ((s[n ~/ 2 - 1] + s[n ~/ 2]) / 2).truncate();
}

/// (tổng đã giới hạn khoản lớn, phần bị bỏ, số khoản bị giới hạn).
(int, int, int) cappedTotal(List<int> amounts, {int? floorCap}) {
  if (amounts.isEmpty) return (0, 0, 0);
  final medianCap = amounts.length >= 3 ? _largeMedianFactor * _median(amounts) : 0;
  final cap = math.max(floorCap ?? _largeMin, medianCap);
  var counted = 0;
  var excess = 0;
  var n = 0;
  for (final a in amounts) {
    counted += math.min(a, cap);
    if (a > cap) {
      excess += a - cap;
      n++;
    }
  }
  return (counted, excess, n);
}

List<(BudgetPace, double, bool)> _budgetPaces(
  List<GoalView> goals,
  List<OutflowIn> outflows, {
  required DateTime monthStart,
  required DateTime today,
  required int observed,
  required int daysLeft,
  required int dim,
  required int remainingDays,
}) {
  final out = <(BudgetPace, double, bool)>[];
  for (final g in goals) {
    if (g.type != 'budget' || g.amount <= 0) continue;
    final amounts = [
      for (final o in outflows)
        if (o.goalId == g.id && !o.day.isBefore(monthStart) && !o.day.isAfter(today)) o.amount,
    ];
    final planDaily = g.amount / dim;
    final (counted, _, _) = cappedTotal(amounts, floorCap: pyRound(2 * planDaily));
    final bDays = math.max(observed, 1);
    final prior = math.max(0, g.amount - g.spent) / math.max(remainingDays, 1);
    final observedRate = counted / bDays;
    final reliable = bDays >= _fullDays;
    double rate;
    if (bDays < _minDays) {
      rate = prior;
    } else if (!reliable) {
      final w = bDays / _fullDays;
      rate = w * observedRate + (1 - w) * prior;
    } else {
      rate = observedRate;
    }
    final projected = g.spent + rate * remainingDays;
    final pct = pyRound1(projected * 100.0 / g.amount);
    final String status;
    if (g.spent > g.amount) {
      status = 'exceeded';
    } else if (reliable && pct > 100 + _budgetTolPct) {
      status = 'over_pace';
    } else {
      status = 'on_track';
    }
    out.add((
      BudgetPace(
        goalId: g.id,
        name: g.name,
        categoryIcon: g.categoryIcon,
        spent: g.spent,
        amount: g.amount,
        dailyRate: pyRound(rate),
        projectedSpent: pyRound(projected),
        projectedPct: pct,
        status: status,
        suggestedDaily: math.max(0, g.amount - g.spent) ~/ math.max(daysLeft, 1),
      ),
      rate,
      reliable,
    ));
  }
  return out;
}

Forecast forecast({
  required Evaluation ev,
  required List<OutflowIn> outflows,
  required DateTime today,
  required DateTime dataSince,
  int incomeDay = 0,
  int? baselineRate,
  List<OutflowIn> refunds = const [],
}) {
  if (!ev.balanceKnown || ev.free == null || ev.daysLeft <= 0) {
    return Forecast(status: 'unavailable', headline: 'Chưa đủ thông tin để dự báo');
  }
  final (year, mon) = parseYm(ev.month);
  final monthStart = DateTime.utc(year, mon, 1);
  final dim = daysInMonth(ev.month);
  final obsStart = dataSince.isAfter(monthStart) ? dataSince : monthStart;
  final observed = _daysBetween(obsStart, today) + 1;
  final windowFloor = today.subtract(const Duration(days: _windowDays - 1));
  final winStart = obsStart.isAfter(windowFloor) ? obsStart : windowFloor;
  final window = _daysBetween(winStart, today) + 1;

  bool inWindow(DateTime d) => !d.isBefore(winStart) && !d.isAfter(today);
  final amounts = [
    for (final o in outflows)
      if (o.goalId == null && inWindow(o.day)) o.amount,
  ];
  var (counted, excess, nCapped) = cappedTotal(amounts);
  final refunded = refunds.where((r) => r.goalId == null && inWindow(r.day)).fold<int>(0, (s, r) => s + r.amount);
  counted = math.max(0, counted - refunded);
  final rateObs = window > 0 ? counted / window : 0.0;

  var confidence = 'normal';
  double rate;
  if (observed < _minDays) {
    if (baselineRate == null) {
      const msg = 'Chưa đủ dữ liệu để dự báo (cần ít nhất $_minDays ngày)';
      return Forecast(
        status: 'insufficient_data',
        headline: msg,
        reason: msg,
        observedDays: math.max(observed, 0),
        windowDays: math.max(window, 0),
      );
    }
    rate = baselineRate.toDouble();
    confidence = 'low';
  } else if (observed < _fullDays) {
    confidence = 'low';
    if (baselineRate != null) {
      final w = observed / _fullDays;
      rate = w * rateObs + (1 - w) * baselineRate;
    } else {
      rate = rateObs;
    }
  } else {
    rate = rateObs;
  }

  final remaining = ev.daysLeft - 1;
  final paces = _budgetPaces(
    ev.goals,
    outflows,
    monthStart: monthStart,
    today: today,
    observed: observed,
    daysLeft: ev.daysLeft,
    dim: dim,
    remainingDays: remaining,
  );

  double overrun(int d) {
    var total = 0.0;
    for (final (p, r, reliable) in paces) {
      if (reliable) total += math.max(0.0, p.spent + r * d - p.amount) - math.max(0, p.spent - p.amount);
    }
    return total;
  }

  var pending = ev.expectedPending;
  final monthEnd = DateTime.utc(year, mon, dim);
  DateTime? salaryDay;
  if (pending > 0 && incomeDay >= 1) {
    final payday = DateTime.utc(year, mon, math.min(incomeDay, dim));
    final tomorrow = today.add(const Duration(days: 1));
    salaryDay = payday.isAfter(tomorrow) ? payday : tomorrow;
    if (salaryDay.isAfter(monthEnd)) {
      salaryDay = null;
      pending = 0;
    }
  }

  final free = ev.free!;
  DateTime? hit = free < 0 ? today : null;
  DateTime? recovers;
  var minFree = free;
  var value = free.toDouble();
  for (var d = 1; d <= remaining; d++) {
    final day = today.add(Duration(days: d));
    final paid = salaryDay != null && !day.isBefore(salaryDay);
    value = free - rate * d - overrun(d) + (paid ? pending : 0);
    minFree = math.min(minFree, value.truncate());
    if (value < 0 && hit == null) {
      hit = day;
    } else if (value >= 0 && hit != null && recovers == null && paid) {
      recovers = day;
    }
  }
  final projectedEnd = remaining > 0 ? value.truncate() : free;
  final totalOverrun = overrun(remaining).truncate();
  var minLimit = double.infinity;
  for (var k = 1; k <= ev.daysLeft; k++) {
    final day = today.add(Duration(days: k - 1));
    final paid = salaryDay != null && !day.isBefore(salaryDay);
    final available = free + (paid ? pending : 0) - overrun(k - 1);
    minLimit = math.min(minLimit, available / k);
  }
  final safeDaily = math.max(0, minLimit.truncate());

  final fc = Forecast(
    status: 'ok',
    headline: '',
    confidence: confidence,
    observedDays: observed,
    windowDays: window,
    dailySpend: pyRound(rate),
    cappedAmount: excess,
    cappedCount: nCapped,
    projectedFreeEnd: projectedEnd,
    projectedBudgetOverrun: totalOverrun,
    incomePending: pending,
    floorHitDate: hit,
    daysUntilFloorHit: hit == null ? null : _daysBetween(today, hit),
    recoversOn: recovers,
    minProjectedFree: minFree,
    safeDailySpend: safeDaily,
    budgets: [for (final (p, _, _) in paces) p],
  );
  fc.headline = _headline(fc, today);
  fc.details = _details(fc, baselineUsed: confidence == 'low' && baselineRate != null);
  return fc;
}

String _headline(Forecast fc, DateTime today) {
  final hit = fc.floorHitDate;
  if (hit != null) {
    var text = hit == today
        ? 'Số dư đang thấp hơn mức sàn'
        : 'Chi như hiện tại thì khoảng ngày ${ddmm(hit)} sẽ chạm mức sàn';
    if (fc.recoversOn != null) text += ' (đủ lại khi nhận lương ngày ${ddmm(fc.recoversOn!)})';
    return text;
  }
  return 'Chi như hiện tại, cuối tháng còn khoảng ${vnd(fc.projectedFreeEnd)} được tiêu';
}

List<String> _details(Forecast fc, {required bool baselineUsed}) {
  final source = baselineUsed ? 'ước tính theo tháng trước' : '${fc.windowDays} ngày gần nhất';
  final lines = ['Tốc độ chi ngoài mục tiêu: ~${vnd(fc.dailySpend)}/ngày ($source)'];
  if (fc.cappedCount > 0) {
    lines.add('Không tính phần vượt của ${fc.cappedCount} khoản chi lớn (${vnd(fc.cappedAmount)})');
  }
  if (fc.safeDailySpend != null) {
    lines.add('Gợi ý: chi ngoài mục tiêu tối đa ~${vnd(fc.safeDailySpend)}/ngày để giữ trên mức sàn');
  }
  for (final b in fc.budgets) {
    final icon = b.categoryIcon ?? '📊';
    if (b.status == 'over_pace') {
      lines.add(
        '$icon ${b.name}: với tốc độ này sẽ dùng ${fmt0(b.projectedPct)}% ngân sách'
        ' — nên chi tối đa ~${vnd(b.suggestedDaily)}/ngày',
      );
    } else if (b.status == 'exceeded') {
      lines.add('$icon ${b.name}: đã vượt ngân sách ${vnd(b.spent - b.amount)}');
    }
  }
  if (fc.confidence == 'low') lines.add('Ước tính sơ bộ: mới có ${fc.observedDays} ngày dữ liệu');
  return lines;
}

// ------------------------------------------------------------------ messages.py

const Map<String, String> levelTitles = {
  'OK': '✅ An toàn',
  'WARNING': '⚠️ Sắp chạm mức mục tiêu',
  'DANGER': '🔴 Đã lấn vào tiền mục tiêu',
  'UNKNOWN': '❔ Chưa biết số dư',
};

class TxInfo {
  const TxInfo({
    required this.id,
    required this.direction,
    required this.amount,
    required this.accountLabel,
    required this.bankTime,
    required this.description,
    required this.categoryLabel,
    required this.balanceAfter,
    this.goalName,
    this.internal = false,
  });

  final int id;
  final String direction;
  final int amount;
  final String accountLabel;
  final DateTime bankTime;
  final String description;
  final String? categoryLabel;
  final int? balanceAfter;
  final String? goalName;
  final bool internal;
}

List<String> statusLines(Evaluation ev) {
  if (!ev.balanceKnown) return ['❔ Chưa biết số dư — mở app và nhập số dư hiện tại.'];
  final lines = ['Số dư: ${vnd(ev.balance)}'];
  if (ev.inTransit != 0) lines.add('Đang chờ ghép chuyển nội bộ: ${vnd(ev.inTransit.abs())}');
  if (ev.goals.isNotEmpty) lines.add('Mức sàn: ${vnd(ev.floor)} · Được tiêu: ${vnd(ev.free)}');
  return lines;
}

String budgetLine(GoalView goal, int threshold, int daysLeft) {
  final icon = goal.categoryIcon ?? '📊';
  final left = goal.amount - goal.spent;
  final head = '$icon ${goal.name} đã dùng ${fmt0(goal.usagePct)}% (${vnd(goal.spent)}/${vnd(goal.amount)})';
  if (left <= 0) return left < 0 ? '$head — đã vượt ${vnd(-left)}' : '$head — đã hết ngân sách';
  if (daysLeft > 0) return '$head — còn ${vnd(left)} cho $daysLeft ngày (~${vnd(left ~/ daysLeft)}/ngày)';
  return '$head — còn ${vnd(left)}';
}

String? decisionLine(FloorDecision dec, Evaluation ev) {
  if (!dec.notify) return null;
  if (dec.kind == 'safe') return '✅ An toàn trở lại: ${ev.levelReason}';
  if (dec.kind == 'escalate') return '🔴 Thâm hụt tăng lên ${vnd(ev.deficit)} so với mức sàn';
  return '${levelTitles[dec.level] ?? ''}: ${ev.levelReason}';
}

String txTitle(TxInfo tx, FloorDecision? dec, List<(GoalView, int)> budgetFired) {
  if (dec != null && dec.notify) {
    if (dec.kind == 'safe') return '✅ An toàn trở lại';
    return levelTitles[dec.level] ?? 'Cảnh báo';
  }
  if (budgetFired.isNotEmpty) {
    return budgetFired.every((b) => b.$2 < 100) ? '📊 Ngân sách sắp hết' : '📊 Đã dùng hết ngân sách';
  }
  if (tx.internal) return '↔️ Chuyển nội bộ';
  return tx.direction == 'out' ? '💸 Chi ${vnd(tx.amount)}' : '💰 Nhận ${vnd(tx.amount)}';
}

List<String> forecastLines(Forecast fc) => [
  '📉 Dự báo: ${fc.headline}',
  ...fc.details.where((d) => d.startsWith('Gợi ý')),
];

(String, String) composeForecastMessage(Forecast fc, Evaluation ev) {
  final lines = [fc.headline];
  if (ev.daysLeft > 0) lines.add('Còn ${ev.daysLeft} ngày trong tháng.');
  lines.addAll(fc.details);
  return ('📉 Dự báo chạm mức sàn', lines.join('\n'));
}

(String, String) composeTxMessage(
  TxInfo tx,
  Evaluation ev,
  FloorDecision? dec,
  List<(GoalView, int)> budgetFired, [
  Forecast? fc,
]) {
  final sign = tx.direction == 'out' ? '−' : '+';
  final lines = ['$sign${vnd(tx.amount)} · ${tx.accountLabel} · ${hhmmDdmm(tx.bankTime)}'];
  if (tx.description.isNotEmpty) {
    final d = tx.description;
    lines.add('Nội dung: ${d.length > 200 ? d.substring(0, 200) : d}');
  }
  if (tx.internal) {
    lines.add('Danh mục: ↔️ Chuyển nội bộ (không tính chi tiêu)');
  } else {
    lines.add('Danh mục: ${tx.categoryLabel ?? '(chưa phân loại)'}');
  }
  if (tx.goalName != null) lines.add('Tính cho mục tiêu: ${tx.goalName}');
  lines.addAll(statusLines(ev));
  final dl = dec == null ? null : decisionLine(dec, ev);
  if (dl != null) {
    lines.add(dl);
  } else if (ev.level == 'WARNING' || ev.level == 'DANGER') {
    lines.add('${levelTitles[ev.level]}: ${ev.levelReason}');
  }
  for (final (goal, th) in budgetFired) {
    lines.add(budgetLine(goal, th, ev.daysLeft));
  }
  if (fc != null) lines.addAll(forecastLines(fc));
  var title = txTitle(tx, dec, budgetFired);
  if (fc != null && !(dec != null && dec.notify) && budgetFired.isEmpty) title = '📉 Dự báo chạm mức sàn';
  return (title, lines.join('\n'));
}

(String, String) composeFloorMessage(FloorDecision dec, Evaluation ev, [String? reasonLabel]) {
  final title = dec.kind == 'safe' ? '✅ An toàn trở lại' : (levelTitles[dec.level] ?? 'Cảnh báo');
  final lines = [ev.levelReason, ...statusLines(ev)];
  if (reasonLabel != null) lines.add('Lý do: $reasonLabel');
  return (title, lines.join('\n'));
}

(String, String) composeBudgetMessage(GoalView goal, int threshold, Evaluation ev) =>
    (threshold >= 100 ? '📊 Đã dùng hết ngân sách' : '📊 Ngân sách sắp hết', budgetLine(goal, threshold, ev.daysLeft));

(String, String) composeDigest(Evaluation ev, int uncategorized, DateTime now, [Forecast? fc]) {
  final t = toIct(now);
  final title = '☀️ Bản tin tài chính ${_two(t.day)}/${_two(t.month)}';
  final lines = ['${levelTitles[ev.level] ?? ev.level} — ${ev.levelReason}', ...statusLines(ev)];
  for (final g in ev.goals) {
    final kind = g.type == 'reserve' ? 'Quỹ giữ' : 'Ngân sách';
    lines.add(
      '• ${g.categoryIcon ?? '🎯'} ${g.name} ($kind): ${vnd(g.spent)}/${vnd(g.amount)} · còn cần ${vnd(g.remaining)}',
    );
  }
  if (ev.daysLeft > 0) lines.add('Còn ${ev.daysLeft} ngày trong tháng.');
  if (fc != null && fc.status == 'ok') {
    lines.add('📈 Dự báo: ${fc.headline}');
    for (final d in fc.details) {
      if (d.startsWith('Gợi ý') || d.startsWith('🍜') || d.startsWith('📊') || d.contains('ngân sách')) {
        lines.add('   $d');
      }
    }
  }
  if (uncategorized > 0) lines.add('🏷️ $uncategorized giao dịch chưa phân loại — gõ /uncat để phân loại.');
  return (title, lines.join('\n'));
}
