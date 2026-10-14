import 'json_utils.dart';

/// Loại mục tiêu: `reserve` = Quỹ giữ, `budget` = Ngân sách chi tiêu.
abstract final class GoalType {
  static const reserve = 'reserve';
  static const budget = 'budget';

  /// Nhãn ngắn trên thẻ mục tiêu.
  static String shortLabel(String type) => type == budget ? 'Ngân sách' : 'Quỹ giữ';

  /// Nhãn đầy đủ trong form.
  static String label(String type) => type == budget ? 'Ngân sách chi tiêu' : 'Quỹ giữ';
}

/// Mục tiêu của một tháng kèm số đã chi / còn lại do server tính.
class GoalView {
  const GoalView({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.month,
    this.seriesId,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.repeatMonthly = false,
    this.openingSpent = 0,
    this.spent = 0,
    this.remaining = 0,
    this.usagePct = 0,
    this.autoMatch = true,
  });

  final int id;
  final String? seriesId;
  final String name;
  final String type;
  final int amount;
  final int? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String month;
  final bool repeatMonthly;
  final int openingSpent;
  final int spent;
  final int remaining;

  /// spent / amount × 100, có thể > 100.
  final double usagePct;

  /// `false` = đã có mục tiêu khác cùng danh mục trong tháng → chỉ tính giao dịch gán trực tiếp.
  final bool autoMatch;

  bool get isReserve => type != GoalType.budget;
  bool get isBudget => type == GoalType.budget;
  String get typeLabel => GoalType.shortLabel(type);

  /// Tỉ lệ cho thanh tiến độ (0..1).
  double get progress {
    if (amount <= 0) return 0;
    final p = spent / amount;
    return p.isNaN ? 0 : p.clamp(0.0, 1.0).toDouble();
  }

  bool get overspent => spent > amount;

  factory GoalView.fromJson(JsonMap json) {
    final amount = asInt(json['amount']);
    final spent = asInt(json['spent']);
    return GoalView(
      id: asInt(json['id']),
      seriesId: asStringOrNull(json['series_id']),
      name: asString(json['name']),
      type: asString(json['type'], GoalType.reserve),
      amount: amount,
      categoryId: asIntOrNull(json['category_id']),
      categoryName: asStringOrNull(json['category_name']),
      categoryIcon: asStringOrNull(json['category_icon']),
      month: asString(json['month']),
      repeatMonthly: asBool(json['repeat_monthly']),
      openingSpent: asInt(json['opening_spent']),
      spent: spent,
      remaining: asIntOrNull(json['remaining']) ?? (amount - spent < 0 ? 0 : amount - spent),
      usagePct: json['usage_pct'] == null ? (amount > 0 ? spent * 100 / amount : 0) : asDouble(json['usage_pct']),
      autoMatch: asBool(json['auto_match'], true),
    );
  }
}

/// Dữ liệu form tạo / sửa mục tiêu (body của POST/PATCH /api/goals).
class GoalInput {
  const GoalInput({
    required this.name,
    required this.type,
    required this.amount,
    this.categoryId,
    this.month,
    this.repeatMonthly = true,
    this.openingSpent = 0,
  });

  final String name;
  final String type;
  final int amount;
  final int? categoryId;
  final String? month;
  final bool repeatMonthly;
  final int openingSpent;

  /// [includeMonth] = false cho PATCH (không đổi được tháng của mục tiêu).
  JsonMap toJson({bool includeMonth = true}) => {
    'name': name,
    'type': type,
    'amount': amount,
    'category_id': categoryId,
    if (includeMonth && month != null) 'month': month,
    'repeat_monthly': repeatMonthly,
    'opening_spent': openingSpent,
  };
}
