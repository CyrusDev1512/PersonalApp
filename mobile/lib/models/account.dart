import 'json_utils.dart';

/// Tài khoản ngân hàng (hoặc ví tiền mặt `CASH`).
class Account {
  const Account({
    required this.id,
    required this.bank,
    required this.name,
    this.accountNumber,
    this.last4,
    this.includeInTotal = true,
    this.confirmed = true,
    this.balance,
    this.balanceAsOf,
    this.balanceDerived = false,
    this.manualBalance,
    this.manualBalanceAt,
  });

  final int id;

  /// `VCB`, `MB`, `OTHER` (có thể có mã khác, vd. `CASH`).
  final String bank;
  final String name;
  final String? accountNumber;
  final String? last4;
  final bool includeInTotal;

  /// `false` = TK lạ do webhook/email tự phát hiện, cần người dùng xác nhận.
  final bool confirmed;

  /// `null` = chưa biết số dư.
  final int? balance;
  final DateTime? balanceAsOf;

  /// `true` = số dư ước tính (cộng/trừ từ mốc).
  final bool balanceDerived;
  final int? manualBalance;
  final DateTime? manualBalanceAt;

  bool get balanceKnown => balance != null;
  bool get isCash => bank.toUpperCase() == 'CASH';

  /// Nhãn ngân hàng tiếng Việt.
  String get bankLabel => bankLabelOf(bank);

  /// "VCB chính · …6789".
  String get displayName {
    final tail = (last4 != null && last4!.isNotEmpty) ? ' · …$last4' : '';
    final base = name.isNotEmpty ? name : bankLabel;
    return '$base$tail';
  }

  factory Account.fromJson(JsonMap json) => Account(
        id: asInt(json['id']),
        bank: asString(json['bank'], 'OTHER'),
        name: asString(json['name']),
        accountNumber: asStringOrNull(json['account_number']),
        last4: asStringOrNull(json['last4']),
        includeInTotal: asBool(json['include_in_total'], true),
        confirmed: asBool(json['confirmed'], true),
        balance: asIntOrNull(json['balance']),
        balanceAsOf: asDateTime(json['balance_as_of']),
        balanceDerived: asBool(json['balance_derived']),
        manualBalance: asIntOrNull(json['manual_balance']),
        manualBalanceAt: asDateTime(json['manual_balance_at']),
      );
}

String bankLabelOf(String bank) => switch (bank.toUpperCase()) {
      'VCB' => 'Vietcombank',
      'MB' => 'MB Bank',
      'CASH' => 'Tiền mặt',
      'OTHER' => 'Khác',
      _ => bank,
    };
