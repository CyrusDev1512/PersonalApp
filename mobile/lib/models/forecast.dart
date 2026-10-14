import 'json_utils.dart';

/// Giá trị `status` của [Forecast].
abstract final class ForecastStatus {
  static const ok = 'ok';

  /// Chưa đủ ~3 ngày dữ liệu: chỉ có `reason` / `headline`.
  static const insufficientData = 'insufficient_data';

  /// Chưa biết số dư: không dự báo được (ẩn thẻ).
  static const unavailable = 'unavailable';
}

/// Giá trị `status` của [BudgetPace].
abstract final class BudgetPaceStatus {
  static const onTrack = 'on_track';

  /// Theo nhịp hiện tại sẽ vượt ngân sách > 5%.
  static const overPace = 'over_pace';

  /// Đã vượt ngân sách.
  static const exceeded = 'exceeded';
}

final RegExp _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');

/// "2026-10-25" (ngày theo giờ VN) -> `DateTime(2026, 10, 25)` giờ máy (không đổi múi giờ).
/// Sai định dạng -> `null`.
DateTime? parseLocalDate(Object? v) {
  if (v is! String) return null;
  final m = _isoDate.firstMatch(v.trim());
  if (m == null) return null;
  final year = int.parse(m.group(1)!);
  final month = int.parse(m.group(2)!);
  final day = int.parse(m.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime(year, month, day);
  // Loại ngày không tồn tại (vd. 31/02 bị DateTime đẩy sang tháng 3).
  if (date.month != month || date.day != day) return null;
  return date;
}

/// Nhịp chi của một mục tiêu ngân sách trong dự báo.
class BudgetPace {
  const BudgetPace({
    required this.name,
    required this.status,
    this.goalId,
    this.categoryIcon,
    this.spent = 0,
    this.amount = 0,
    this.dailyRate = 0,
    this.projectedSpent = 0,
    this.projectedPct = 0,
    this.suggestedDaily,
  });

  final int? goalId;
  final String name;
  final String? categoryIcon;
  final int spent;
  final int amount;

  /// Tốc độ chi hiện tại mỗi ngày.
  final int dailyRate;

  /// Dự kiến đã chi tới cuối tháng nếu giữ tốc độ hiện tại.
  final int projectedSpent;

  /// [projectedSpent] / [amount] × 100.
  final double projectedPct;

  /// `on_track` | `over_pace` | `exceeded`.
  final String status;

  /// Gợi ý chi tối đa mỗi ngày để không vượt; `null` khi không áp dụng.
  final int? suggestedDaily;

  bool get isOverPace => status == BudgetPaceStatus.overPace;
  bool get isExceeded => status == BudgetPaceStatus.exceeded;

  /// Cần hiện trên thẻ dự báo (sắp vượt hoặc đã vượt).
  bool get needsAttention => isOverPace || isExceeded;

  /// "🍜 Tiền ăn".
  String get label => [if (categoryIcon != null && categoryIcon!.trim().isNotEmpty) categoryIcon!.trim(), name].join(' ');

  factory BudgetPace.fromJson(JsonMap json) => BudgetPace(
    goalId: asIntOrNull(json['goal_id']),
    name: asString(json['name'], 'Ngân sách'),
    categoryIcon: asStringOrNull(json['category_icon']),
    spent: asInt(json['spent']),
    amount: asInt(json['amount']),
    dailyRate: asInt(json['daily_rate']),
    projectedSpent: asInt(json['projected_spent']),
    projectedPct: asDouble(json['projected_pct']),
    status: asString(json['status'], BudgetPaceStatus.onTrack),
    suggestedDaily: asIntOrNull(json['suggested_daily']),
  );
}

/// Mức độ của thẻ dự báo (quyết định màu tiêu đề).
enum ForecastSeverity {
  /// Chạm mức sàn trong ≤ 7 ngày: đỏ.
  danger,

  /// Chạm mức sàn trong tháng này: hổ phách.
  warning,

  /// Không chạm mức sàn / chưa đủ dữ liệu: màu thường.
  neutral,
}

/// Dự báo cuối tháng (`summary.forecast`, xem docs/api.md mục "Dự báo").
class Forecast {
  const Forecast({
    required this.status,
    this.confidence = 'normal',
    this.reason,
    this.observedDays = 0,
    this.windowDays = 0,
    this.dailySpend,
    this.cappedAmount = 0,
    this.cappedCount = 0,
    this.projectedFreeEnd,
    this.projectedBudgetOverrun = 0,
    this.incomePending = 0,
    this.floorHitDate,
    this.daysUntilFloorHit,
    this.recoversOn,
    this.safeDailySpend,
    this.headline,
    this.details = const [],
    this.budgets = const [],
  });

  /// Ngưỡng "sắp chạm mức sàn" (ngày) để tô đỏ.
  static const dangerDays = 7;

  /// `ok` | `insufficient_data` | `unavailable`.
  final String status;

  /// `normal` | `low` (ước tính sơ bộ).
  final String confidence;
  final String? reason;

  /// Số ngày đã có dữ liệu dùng để tính tốc độ chi.
  final int observedDays;
  final int windowDays;

  /// Tốc độ chi ngoài mục tiêu mỗi ngày.
  final int? dailySpend;

  /// Phần khoản lớn bất thường bị giới hạn khi tính tốc độ chi.
  final int cappedAmount;
  final int cappedCount;

  /// "Được tiêu thoải mái" dự kiến vào cuối tháng (có thể âm).
  final int? projectedFreeEnd;
  final int projectedBudgetOverrun;
  final int incomePending;

  /// Ngày (giờ VN, dạng ngày địa phương không có giờ) dự kiến chạm mức sàn; `null` nếu không chạm.
  final DateTime? floorHitDate;
  final int? daysUntilFloorHit;

  /// Ngày dự kiến hồi phục trên mức sàn (vd. nhờ lương); `null` nếu không.
  final DateTime? recoversOn;

  /// Chi ngoài mục tiêu tối đa mỗi ngày để cuối tháng vẫn trên mức sàn; `null` khi không áp dụng.
  final int? safeDailySpend;

  /// Câu tóm tắt tiếng Việt do server soạn.
  final String? headline;

  /// Các dòng giải thích tiếng Việt do server soạn.
  final List<String> details;
  final List<BudgetPace> budgets;

  bool get isOk => status == ForecastStatus.ok;
  bool get isInsufficientData => status == ForecastStatus.insufficientData;
  bool get isUnavailable => status == ForecastStatus.unavailable;
  bool get isLowConfidence => confidence == 'low';

  /// Ngân sách sắp vượt / đã vượt (hiện trên thẻ).
  List<BudgetPace> get budgetsNeedingAttention => budgets.where((b) => b.needsAttention).toList();

  /// Có gì để hiện không (ẩn khi `unavailable` hoặc trạng thái lạ không kèm nội dung).
  bool get isDisplayable {
    if (isUnavailable) return false;
    if (isOk) return true;
    return (headline?.trim().isNotEmpty ?? false) || (reason?.trim().isNotEmpty ?? false) || isInsufficientData;
  }

  /// Đỏ nếu chạm mức sàn trong ≤ 7 ngày, hổ phách nếu chạm trong tháng [month] ("YYYY-MM"), còn lại thường.
  ForecastSeverity severity({String? month}) {
    if (!isOk) return ForecastSeverity.neutral;
    final hit = floorHitDate;
    final days = daysUntilFloorHit;
    if (days != null && days <= dangerDays) return ForecastSeverity.danger;
    if (hit != null && _inMonth(hit, month)) return ForecastSeverity.warning;
    return ForecastSeverity.neutral;
  }

  static bool _inMonth(DateTime date, String? month) {
    final m = month == null ? null : RegExp(r'^(\d{4})-(\d{2})$').firstMatch(month);
    if (m == null) return true;
    return date.year == int.parse(m.group(1)!) && date.month == int.parse(m.group(2)!);
  }

  factory Forecast.fromJson(JsonMap json) => Forecast(
    status: asString(json['status'], ForecastStatus.unavailable),
    confidence: asString(json['confidence'], 'normal'),
    reason: _nonBlank(json['reason']),
    observedDays: asInt(json['observed_days']),
    windowDays: asInt(json['window_days']),
    dailySpend: asIntOrNull(json['daily_spend']),
    cappedAmount: asInt(json['capped_amount']),
    cappedCount: asInt(json['capped_count']),
    projectedFreeEnd: asIntOrNull(json['projected_free_end']),
    projectedBudgetOverrun: asInt(json['projected_budget_overrun']),
    incomePending: asInt(json['income_pending']),
    floorHitDate: parseLocalDate(json['floor_hit_date']),
    daysUntilFloorHit: asIntOrNull(json['days_until_floor_hit']),
    recoversOn: parseLocalDate(json['recovers_on']),
    safeDailySpend: asIntOrNull(json['safe_daily_spend']),
    headline: _nonBlank(json['headline']),
    details: asStringList(json['details']).where((d) => d.trim().isNotEmpty).toList(),
    budgets: asList(json['budgets'], BudgetPace.fromJson),
  );
}

String? _nonBlank(Object? v) {
  final s = asStringOrNull(v)?.trim();
  return s == null || s.isEmpty ? null : s;
}
