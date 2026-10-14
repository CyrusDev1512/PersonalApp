import 'json_utils.dart';
import 'summary.dart';

/// Trạng thái giao dịch.
abstract final class TxStatus {
  static const active = 'active';

  /// Email đang chờ webhook khớp (chưa tính).
  static const pending = 'pending';

  /// Đã loại trừ (không tính).
  static const excluded = 'excluded';
}

/// Một giao dịch (biến động số dư hoặc nhập tay).
class Tx {
  const Tx({
    required this.id,
    required this.direction,
    required this.amount,
    this.accountId,
    this.accountName,
    this.bank,
    this.bankTime,
    this.timePrecision,
    this.description = '',
    this.referenceCode,
    this.counterAccount,
    this.counterName,
    this.balanceAfter,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.goalId,
    this.goalName,
    this.categorizedBy = 'none',
    this.status = TxStatus.active,
    this.isManual = false,
    this.affectsBalance = true,
    this.pairId,
    this.sources = const [],
    this.possibleDuplicateOf,
  });

  final int id;
  final int? accountId;
  final String? accountName;
  final String? bank;

  /// `in` | `out`.
  final String direction;
  final int amount;
  final DateTime? bankTime;
  final String? timePrecision;
  final String description;
  final String? referenceCode;
  final String? counterAccount;
  final String? counterName;
  final int? balanceAfter;
  final int? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final int? goalId;
  final String? goalName;
  final String categorizedBy;
  final String status;
  final bool isManual;
  final bool affectsBalance;
  final int? pairId;
  final List<String> sources;
  final int? possibleDuplicateOf;

  bool get isOut => direction == 'out';
  bool get isIn => !isOut;
  bool get isPending => status == TxStatus.pending;
  bool get isExcluded => status == TxStatus.excluded;
  bool get isPossibleDuplicate => possibleDuplicateOf != null;
  bool get isInternalTransfer => pairId != null;
  bool get isCategorized => categoryId != null || goalId != null || pairId != null;

  /// Khớp bộ lọc "Chưa phân loại" của server: khoản chi đang tính, chưa có danh mục/mục tiêu/cặp.
  bool get isUncategorized => isOut && !isCategorized && status == TxStatus.active;

  /// Tiêu đề hiển thị: mô tả, hoặc tên người chuyển/nhận nếu mô tả trống.
  String get title {
    if (description.trim().isNotEmpty) return description.trim();
    if (counterName != null && counterName!.trim().isNotEmpty) return counterName!.trim();
    return isOut ? 'Khoản chi' : 'Khoản thu';
  }

  factory Tx.fromJson(JsonMap json) => Tx(
    id: asInt(json['id']),
    accountId: asIntOrNull(json['account_id']),
    accountName: asStringOrNull(json['account_name']),
    bank: asStringOrNull(json['bank']),
    direction: asString(json['direction'], 'out') == 'in' ? 'in' : 'out',
    amount: asInt(json['amount']),
    bankTime: asDateTime(json['bank_time']),
    timePrecision: asStringOrNull(json['time_precision']),
    description: asString(json['description']),
    referenceCode: asStringOrNull(json['reference_code']),
    counterAccount: asStringOrNull(json['counter_account']),
    counterName: asStringOrNull(json['counter_name']),
    balanceAfter: asIntOrNull(json['balance_after']),
    categoryId: asIntOrNull(json['category_id']),
    categoryName: asStringOrNull(json['category_name']),
    categoryIcon: asStringOrNull(json['category_icon']),
    goalId: asIntOrNull(json['goal_id']),
    goalName: asStringOrNull(json['goal_name']),
    categorizedBy: asString(json['categorized_by'], 'none'),
    status: asString(json['status'], TxStatus.active),
    isManual: asBool(json['is_manual']),
    affectsBalance: asBool(json['affects_balance'], true),
    pairId: asIntOrNull(json['pair_id']),
    sources: asStringList(json['sources']),
    possibleDuplicateOf: asIntOrNull(json['possible_duplicate_of']),
  );
}

/// Kết quả GET /api/transactions.
class TxPage {
  const TxPage({required this.items, required this.total});

  final List<Tx> items;
  final int total;

  factory TxPage.fromJson(JsonMap json) {
    final items = asList(json['items'], Tx.fromJson);
    return TxPage(items: items, total: asIntOrNull(json['total']) ?? items.length);
  }
}

/// Kết quả PATCH /api/transactions/{id}: giao dịch mới + tổng quan đã tính lại.
class TxPatchResult {
  const TxPatchResult({required this.transaction, this.summary});

  final Tx transaction;
  final Summary? summary;

  factory TxPatchResult.fromJson(JsonMap json) {
    final rawSummary = json['summary'];
    return TxPatchResult(
      transaction: Tx.fromJson(asMap(json['transaction'])),
      summary: rawSummary is Map ? Summary.fromJson(asMap(rawSummary)) : null,
    );
  }
}
