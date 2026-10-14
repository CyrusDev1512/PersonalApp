import 'package:flutter/material.dart';

import '../models/level.dart';

/// Màu theo mức: OK xanh lá, WARNING cam, DANGER đỏ, UNKNOWN xám.
Color levelColor(Level level) => switch (level) {
      Level.ok => Colors.green.shade700,
      Level.warning => Colors.orange.shade800,
      Level.danger => Colors.red.shade700,
      Level.unknown => Colors.blueGrey.shade600,
      Level.info => Colors.teal.shade700,
    };

IconData levelIcon(Level level) => switch (level) {
      Level.ok => Icons.check_circle,
      Level.warning => Icons.warning_amber_rounded,
      Level.danger => Icons.error,
      Level.unknown => Icons.help,
      Level.info => Icons.info,
    };

/// Banner trạng thái tổng quan, tô màu theo [level], kèm lý do từ server.
class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.level, this.reason, this.waitingIncome = false});

  final Level level;
  final String? reason;

  /// Đang thiếu nhưng sẽ đủ khi nhận lương.
  final bool waitingIncome;

  @override
  Widget build(BuildContext context) {
    final color = levelColor(level);
    final theme = Theme.of(context);
    final reasonText = reason?.trim() ?? '';
    return Semantics(
      container: true,
      label: 'Trạng thái: ${level.label}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(levelIcon(level), color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                  ),
                  if (reasonText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(reasonText, style: theme.textTheme.bodyMedium),
                  ],
                  if (waitingIncome) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Đang chờ lương — sẽ đủ khi nhận lương.',
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
