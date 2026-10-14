import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../utils/currency.dart';

/// Thẻ mục tiêu: tên, loại, danh mục, thanh tiến độ đã chi / số tiền, còn lại.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, this.onTap});

  final GoalView goal;
  final VoidCallback? onTap;

  Color _barColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (goal.overspent) return Colors.red.shade700;
    if (goal.isBudget && goal.usagePct >= 80) return Colors.orange.shade800;
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final category = goal.categoryName == null
        ? (goal.isReserve ? 'Tiết kiệm thuần' : 'Chưa chọn danh mục')
        : '${goal.categoryIcon ?? ''} ${goal.categoryName}'.trim();
    final remainingLabel = goal.isReserve ? 'Còn phải giữ' : 'Còn được chi';
    final over = goal.spent - goal.amount;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (goal.repeatMonthly)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Tooltip(
                        message: 'Lặp lại hằng tháng',
                        child: Icon(Icons.repeat, size: 18, color: scheme.outline),
                      ),
                    ),
                  _TypeChip(label: goal.typeLabel, reserve: goal.isReserve),
                ],
              ),
              const SizedBox(height: 2),
              Text(category, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  color: _barColor(context),
                  backgroundColor: scheme.surfaceContainerHighest,
                  semanticsLabel: 'Đã dùng ${goal.usagePct.toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đã chi ${formatVnd(goal.spent)} / ${formatVnd(goal.amount)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text('${goal.usagePct.toStringAsFixed(0)}%', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                over > 0 ? 'Vượt ${formatVnd(over)}' : '$remainingLabel ${formatVnd(goal.remaining)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: over > 0 ? Colors.red.shade700 : null,
                ),
              ),
              if (goal.openingSpent > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'Gồm ${formatVnd(goal.openingSpent)} đã chi trước khi dùng app',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              if (!goal.autoMatch) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Đã có mục tiêu khác cùng danh mục trong tháng — mục tiêu này chỉ tính '
                        'các giao dịch được gán trực tiếp.',
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.reserve});

  final String label;
  final bool reserve;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = reserve ? scheme.primaryContainer : scheme.tertiaryContainer;
    final fg = reserve ? scheme.onPrimaryContainer : scheme.onTertiaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg)),
    );
  }
}
