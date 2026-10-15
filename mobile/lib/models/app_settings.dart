import 'json_utils.dart';

/// Cài đặt cảnh báo trên server (GET/PUT /api/settings).
class AppSettings {
  const AppSettings({
    this.warningPercent = 10,
    this.warningMinAmount = 500000,
    this.expectedIncomeAmount = 0,
    this.expectedIncomeDay = 0,
    this.notifyEveryTx = true,
  });

  /// % mức sàn dùng làm vùng đệm cảnh báo.
  final int warningPercent;

  /// Vùng đệm tối thiểu (VND).
  final int warningMinAmount;

  /// 0 = không dùng lương dự kiến.
  final int expectedIncomeAmount;

  /// Ngày nhận lương trong tháng (1–31), 0 = chưa đặt.
  final int expectedIncomeDay;
  final bool notifyEveryTx;

  bool get usesExpectedIncome => expectedIncomeAmount > 0 && expectedIncomeDay > 0;

  AppSettings copyWith({
    int? warningPercent,
    int? warningMinAmount,
    int? expectedIncomeAmount,
    int? expectedIncomeDay,
    bool? notifyEveryTx,
  }) => AppSettings(
    warningPercent: warningPercent ?? this.warningPercent,
    warningMinAmount: warningMinAmount ?? this.warningMinAmount,
    expectedIncomeAmount: expectedIncomeAmount ?? this.expectedIncomeAmount,
    expectedIncomeDay: expectedIncomeDay ?? this.expectedIncomeDay,
    notifyEveryTx: notifyEveryTx ?? this.notifyEveryTx,
  );

  factory AppSettings.fromJson(JsonMap json) => AppSettings(
    warningPercent: asInt(json['warning_percent'], 10),
    warningMinAmount: asInt(json['warning_min_amount'], 500000),
    expectedIncomeAmount: asInt(json['expected_income_amount']),
    expectedIncomeDay: asInt(json['expected_income_day']),
    notifyEveryTx: asBool(json['notify_every_tx'], true),
  );

  JsonMap toJson() => {
    'warning_percent': warningPercent,
    'warning_min_amount': warningMinAmount,
    'expected_income_amount': expectedIncomeAmount,
    'expected_income_day': expectedIncomeDay,
    'notify_every_tx': notifyEveryTx,
  };
}
