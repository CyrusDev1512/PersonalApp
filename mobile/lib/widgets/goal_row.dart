import 'package:flutter/material.dart';

import '../models/forecast.dart';
import '../models/goal.dart';
import '../theme/status_colors.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'list_group.dart';
import 'money_row.dart';
import 'money_text.dart';
import 'state_views.dart';

/// Hàng tiến độ một mục tiêu trong nhóm "Mục tiêu tháng 10" (DESIGN.md › Goal progress row).
///
/// Đĩa đầu hàng theo loại (Quỹ giữ / Ngân sách), tên, dòng phụ "Quỹ giữ · 🏠 Thuê trọ" (+ icon lặp lại),
/// số còn lại ở cuối kèm "còn phải giữ" / "còn được chi", thanh 6 dp và chú thích tiến độ. Không phải thẻ: các
/// hàng nằm chung một nhóm, không viền màu.
///
/// Đọc màn hình: một câu gọn cho cả hàng (tên, loại, số còn lại, tiến độ), không đọc thanh tiến độ riêng.
class GoalRow extends StatelessWidget {
  const GoalRow({super.key, required this.goal, this.pace, this.onTap});

  final GoalView goal;

  /// Nhịp chi của ngân sách này trong dự báo (để báo "Theo nhịp này sẽ vượt …").
  final BudgetPace? pace;
  final VoidCallback? onTap;

  int get _over => goal.spent - goal.amount;
  bool get _paidOff => goal.isReserve && goal.amount > 0 && goal.remaining <= 0 && _over <= 0;

  String get _category => goal.categoryName == null
      ? (goal.isReserve ? 'Tiết kiệm thuần' : 'Chưa chọn danh mục')
      : [if ((goal.categoryIcon ?? '').trim().isNotEmpty) goal.categoryIcon!.trim(), goal.categoryName!].join(' ');

  String get _spentVerb => goal.isReserve ? 'Đã trả' : 'Đã chi';
  String get _percent => '${goal.usagePct.toStringAsFixed(0)}%';

  /// Số dự kiến vượt theo nhịp chi (chỉ khi dự báo nói ngân sách này sẽ vượt nhưng chưa vượt).
  int? get _paceOverrun {
    final p = pace;
    if (p == null || !p.isOverPace || _over > 0) return null;
    final overrun = p.projectedSpent - p.amount;
    return overrun > 0 ? overrun : null;
  }

  /// Câu đọc màn hình của cả hàng.
  String semanticLabel() {
    final parts = <String>[
      goal.name,
      '${goal.typeLabel}, $_category',
      if (goal.repeatMonthly) 'Lặp lại hằng tháng',
      if (_paidOff)
        'Đã trả xong'
      else
        '${goal.isReserve ? 'Còn phải giữ' : 'Còn được chi'} ${spokenVnd(goal.remaining)}',
      if (_over > 0)
        'Vượt ${spokenVnd(_over)}'
      else
        '$_spentVerb ${spokenVnd(goal.spent)} trên ${spokenVnd(goal.amount)}, ${goal.usagePct.toStringAsFixed(0)} phần trăm',
      if (_paceOverrun case final o?) 'Theo nhịp này sẽ vượt khoảng ${spokenVnd(o)}',
    ];
    return '${parts.join('. ')}.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);
    final small = theme.textTheme.bodySmall!.copyWith(color: scheme.onSurfaceVariant);
    final over = _over;
    final barColor = over > 0
        ? status.danger.foreground
        : goal.isBudget && goal.usagePct >= 80
        ? status.warning.foreground
        : _paidOff
        ? status.ok.foreground
        : scheme.primary;

    final captions = <Widget>[
      if (over > 0)
        MoneySentence([
          'Vượt ',
          over,
        ], style: small.copyWith(color: status.danger.foreground, fontWeight: FontWeight.w600))
      else
        MoneySentence(['$_spentVerb ', goal.spent, ' / ', goal.amount, ' · $_percent'], style: small),
      if (_paceOverrun case final o?)
        MoneySentence([
          'Theo nhịp này sẽ vượt ',
          MoneyParts.of(o, estimate: true),
        ], style: small.copyWith(color: status.warning.foreground)),
      if (goal.openingSpent > 0) MoneySentence(['Gồm ', goal.openingSpent, ' đã chi trước khi dùng app'], style: small),
      if (!goal.autoMatch)
        const InlineNote(
          icon: Icons.info_outline,
          text:
              'Đã có mục tiêu khác cùng danh mục trong tháng, mục tiêu này chỉ tính các giao dịch được gán '
              'trực tiếp.',
        ),
    ];

    return MoneyRow(
      key: ValueKey('goal_row_${goal.id}'),
      leading: LeadingDisc(icon: goal.isReserve ? Icons.savings_outlined : Icons.shopping_basket_outlined),
      title: Text(goal.name),
      // Icon "lặp lại" nằm ngay sau chữ (cùng dòng cuối khi chữ xuống dòng), không trôi ra mép phải.
      meta: Text.rich(
        TextSpan(
          children: [
            // U+2060 (word joiner): icon "lặp lại" không bao giờ bị đẩy một mình xuống dòng mới.
            TextSpan(text: '${goal.typeLabel} · $_category${goal.repeatMonthly ? '\u2060' : ''}'),
            if (goal.repeatMonthly)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: Space.s1),
                  child: Icon(Icons.repeat, size: 16, color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
      amount: MoneyText(goal.remaining, style: MoneyStyle.list),
      amountCaption: _paidOff
          ? Text(
              'Đã trả xong',
              style: small.copyWith(color: status.ok.foreground, fontWeight: FontWeight.w600),
            )
          : Text(goal.isReserve ? 'còn phải giữ' : 'còn được chi'),
      below: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressBar(key: ValueKey('goal_progress_${goal.id}'), value: goal.progress, color: barColor),
          const SizedBox(height: Space.s2),
          for (var i = 0; i < captions.length; i++) ...[if (i > 0) const SizedBox(height: Space.s1), captions[i]],
        ],
      ),
      semanticLabel: semanticLabel(),
      onTap: onTap,
    );
  }
}

/// Thanh tiến độ 6 dp bo tròn, rãnh `surfaceContainerHighest`, không có chấm cuối (trang trí: đã có chú thích).
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({super.key, required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.full),
        child: SizedBox(
          height: 6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: track),
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: value.clamp(0.0, 1.0),
                child: ColoredBox(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
