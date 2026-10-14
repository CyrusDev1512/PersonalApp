import 'package:flutter/material.dart';

import '../models/alert.dart';
import '../utils/dates.dart';
import 'status_banner.dart';

/// Một dòng cảnh báo: icon màu theo mức, tiêu đề (đậm nếu chưa đọc), nội dung, thời gian.
class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert, this.onTap, this.dense = false});

  final Alert alert;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = levelColor(alert.level);
    final time = alert.createdAt == null ? '' : formatShortDateTime(alert.createdAt!);
    return ListTile(
      dense: dense,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(levelIcon(alert.level), color: color),
      title: Text(
        alert.title.isEmpty ? alert.level.label : alert.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: alert.read ? FontWeight.normal : FontWeight.w700),
      ),
      subtitle: Text(
        [if (alert.message.isNotEmpty) alert.message, if (time.isNotEmpty) time].join('\n'),
        maxLines: dense ? 2 : 4,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: alert.read
          ? null
          : Semantics(
              label: 'Chưa đọc',
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
              ),
            ),
    );
  }
}
