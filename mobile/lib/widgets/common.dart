import 'package:flutter/material.dart';

import '../api/api_client.dart';

/// Thông báo lỗi ngắn ở cuối màn hình.
void showError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : 'Có lỗi xảy ra: $error';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Tiêu đề một nhóm nội dung.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Màn lỗi toàn trang có nút thử lại.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Nhãn nhỏ dạng huy hiệu (trạng thái giao dịch, TK chưa xác nhận…).
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 3)],
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
