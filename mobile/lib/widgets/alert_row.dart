import 'package:flutter/material.dart';

import '../models/alert.dart';
import '../models/level.dart';
import '../theme/status_colors.dart';
import '../theme/tokens.dart';
import '../utils/dates.dart';
import '../utils/text.dart';
import 'list_group.dart';

/// Tiêu đề hiển thị của cảnh báo: bỏ emoji đầu câu của máy chủ (icon theo mức đã nói điều đó); trống thì
/// dùng nhãn của mức.
String alertDisplayTitle(Alert alert) {
  final title = stripLeadingEmoji(alert.title);
  return title.isEmpty ? alert.level.label : title;
}

/// Icon theo loại cho cảnh báo thông tin (INFO) và thông báo thường (giao dịch, bản tin khi vẫn an toàn).
IconData alertKindIcon(String kind) => switch (kind) {
  'digest' => Icons.summarize_outlined,
  'account' => Icons.account_balance_outlined,
  'health' => Icons.sync_problem,
  'tx' => Icons.receipt_long_outlined,
  'budget' => Icons.shopping_basket_outlined,
  'forecast' => Icons.insights,
  _ => Icons.info_outline,
};

/// Đĩa đầu hàng của một cảnh báo: màu và icon theo mức; INFO, thông báo giao dịch và bản tin khi vẫn an
/// toàn dùng `secondaryContainer` với icon theo loại (một khoản chi bình thường không phải "thành công").
class AlertDisc extends StatelessWidget {
  const AlertDisc({super.key, required this.alert});

  final Alert alert;

  bool get _neutral =>
      alert.level == Level.info || (alert.level == Level.ok && (alert.kind == 'tx' || alert.kind == 'digest'));

  @override
  Widget build(BuildContext context) {
    if (_neutral) {
      final scheme = Theme.of(context).colorScheme;
      return LeadingDisc(
        icon: alertKindIcon(alert.kind),
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      );
    }
    return LeadingDisc.level(context, alert.level);
  }
}

/// Một hàng cảnh báo (DESIGN.md › Alert row): đĩa theo mức, tiêu đề (đậm khi chưa đọc), nội dung 2 dòng (đã bỏ
/// emoji đầu dòng và lời nhắc lệnh bot), giờ "14:32" (giờ Việt Nam; ngày nằm ở tiêu đề nhóm) và chấm chưa đọc.
/// Không viền màu.
///
/// Chữ lớn hơn 125%: giờ và chấm chưa đọc xuống dưới tiêu đề, tiêu đề rộng hết hàng và được nhiều dòng hơn (như
/// quy tắc chữ lớn của MoneyRow), để tiêu đề ngắn không bị cắt.
class AlertRow extends StatelessWidget {
  const AlertRow({super.key, required this.alert, this.onTap});

  final Alert alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final large = AppLayout.isLargeText(MediaQuery.textScalerOf(context));
    final time = alert.createdAt == null ? null : formatTimeIct(alert.createdAt!);
    final message = cleanAlertMessage(alert.message);
    final timeText = time == null ? null : Text(time, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant));
    final dot = alert.read
        ? null
        : Semantics(
            label: 'Chưa đọc',
            child: Container(
              key: ValueKey('alert_unread_${alert.id}'),
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
            ),
          );
    final title = Text(
      alertDisplayTitle(alert),
      maxLines: large ? 4 : 2,
      overflow: TextOverflow.ellipsis,
      style: text.titleMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: alert.read ? FontWeight.w500 : FontWeight.w700,
      ),
    );
    final body = message.isEmpty
        ? null
        : Text(
            message,
            maxLines: large ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          );
    final List<Widget> children;
    if (large) {
      children = [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              if (timeText != null || dot != null)
                Wrap(spacing: Space.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [?timeText, ?dot]),
              ?body,
            ],
          ),
        ),
      ];
    } else {
      children = [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, ?body]),
        ),
        const SizedBox(width: Space.s3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ?timeText,
            if (dot != null) ...[const SizedBox(height: Space.s2), dot],
          ],
        ),
      ];
    }
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppLayout.listRowTwoLineMinHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppLayout.listRowPaddingH, vertical: Space.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AlertDisc(alert: alert),
                  const SizedBox(width: Space.s4),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Màu chữ / icon của một mức trên nền thường (dùng ở chi tiết cảnh báo).
Color levelForeground(BuildContext context, Level level) => level.colorsOf(context).foreground;
