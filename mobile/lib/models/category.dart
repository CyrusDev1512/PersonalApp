import 'json_utils.dart';

/// Danh mục chi tiêu / thu nhập / chuyển nội bộ.
class Category {
  const Category({
    required this.id,
    required this.name,
    this.kind = 'expense',
    this.icon,
    this.sortOrder = 0,
    this.systemKey,
  });

  final int id;
  final String name;

  /// `expense`, `income`, `transfer`. Chỉ `expense` được chọn cho mục tiêu.
  final String kind;
  final String? icon;
  final int sortOrder;
  final String? systemKey;

  bool get isExpense => kind == 'expense';
  bool get isIncome => kind == 'income';
  bool get isTransfer => kind == 'transfer';

  /// "🍜 Ăn uống".
  String get label => (icon == null || icon!.isEmpty) ? name : '$icon $name';

  factory Category.fromJson(JsonMap json) => Category(
    id: asInt(json['id']),
    name: asString(json['name']),
    kind: asString(json['kind'], 'expense'),
    icon: asStringOrNull(json['icon']),
    sortOrder: asInt(json['sort_order']),
    systemKey: asStringOrNull(json['system_key']),
  );
}
