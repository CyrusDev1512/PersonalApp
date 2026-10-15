import 'package:flutter/material.dart';

import '../models/account.dart';
import '../theme/typography.dart';
import '../utils/dates.dart';
import 'list_group.dart';
import 'money_row.dart';
import 'money_text.dart';

/// Hàng tài khoản dùng chung cho Tổng quan và Cài đặt (DESIGN.md › Lists and containers › Account row).
///
/// Đĩa đầu hàng có tên ngân hàng viết tắt ("VCB", "MB"), tiền mặt dùng `payments_outlined`; tiêu đề
/// "VCB chính ··6789"; dòng phụ "Vietcombank · cập nhật 14:32" (+ "ước tính", "không tính vào tổng"); số dư
/// `moneyList` ở cuối hoặc "chưa biết số dư"; pill "Chưa xác nhận" cho TK tự phát hiện. Không có mũi tên.
class AccountRow extends StatelessWidget {
  const AccountRow({super.key, required this.account, this.onTap, this.now});

  final Account account;
  final VoidCallback? onTap;

  /// Giờ hiện tại (test); dùng để viết "14:32" hay "14:32 12/10".
  final DateTime? now;

  /// Dòng phụ dạng chữ thuần.
  static String metaFor(Account a, DateTime now) {
    final asOf = a.balanceAsOf;
    return [
      if (a.name.isNotEmpty && a.name != a.bankLabel) a.bankLabel,
      if (asOf != null) 'cập nhật ${formatTimeOrDateIct(asOf, now)}',
      if (a.balanceKnown && a.balanceDerived) 'ước tính',
      if (!a.includeInTotal || !a.confirmed) 'không tính vào tổng',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final a = account;
    final theme = Theme.of(context);
    final meta = metaFor(a, now ?? DateTime.now());
    return MoneyRow(
      leading: a.isCash ? const LeadingDisc(icon: Icons.payments_outlined) : LeadingDisc(text: a.bankShort),
      title: Text(a.displayName),
      meta: meta.isEmpty ? null : Text(meta),
      amount: a.balanceKnown
          ? MoneyText(a.balance!, style: MoneyStyle.list)
          : Text(
              'chưa biết số dư',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
      below: a.confirmed
          ? null
          : const Pill('Chưa xác nhận', tone: PillTone.warning, icon: Icons.new_releases_outlined),
      onTap: onTap,
    );
  }
}
