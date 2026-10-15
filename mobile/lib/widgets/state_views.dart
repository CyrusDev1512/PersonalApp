import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'first_line_icon.dart';

/// Màn lỗi khi chưa có dữ liệu nào: icon `cloud_off`, [title], thông báo của máy chủ, nút "Thử lại"
/// (hành động duy nhất của màn hình lúc đó, nên là nút filled).
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry, this.title, this.icon = Icons.cloud_off});

  final String message;
  final VoidCallback? onRetry;

  /// Câu nói vấn đề ("Không tải được tổng quan"); `null` = chỉ hiện [message].
  final String? title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: Space.s3),
            if (title != null) ...[
              Text(title!, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              const SizedBox(height: Space.s1),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: title == null
                  ? theme.textTheme.bodyMedium
                  : theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Space.s4),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Trạng thái trống bình thản (không minh hoạ): icon, câu chính, câu giải thích, một hành động chữ.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.icon, required this.title, this.message, this.action});

  final IconData? icon;
  final String title;
  final String? message;

  /// Thường là `TextButton` ("Tạo mục tiêu đầu tiên").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 32, color: scheme.onSurfaceVariant), const SizedBox(height: Space.s3)],
          Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          if (message != null) ...[
            const SizedBox(height: Space.s1),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (action != null) ...[const SizedBox(height: Space.s2), action!],
        ],
      ),
    );
  }
}

/// Dải trung tính khi không tải lại được nhưng vẫn còn dữ liệu cũ (offline, lỗi máy chủ): `surfaceContainerHigh`,
/// icon `onSurfaceVariant`, chữ `onSurface`, nút chữ "Thử lại". Không bao giờ tô đỏ (The Red Is Earned Rule):
/// số liệu cũ vẫn đúng để xem.
class OfflineStrip extends StatelessWidget {
  const OfflineStrip({super.key, required this.title, this.message, this.onRetry, this.icon = Icons.cloud_off});

  /// "Đang offline, không kết nối được máy chủ" hoặc thông báo của máy chủ.
  final String title;

  /// "Đang hiện số liệu tải lúc 14:32."
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.s4, Space.s3, Space.s2, Space.s3),
      decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(Radii.md)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface)),
                if (message != null)
                  Text(message!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

/// Ghi chú nhỏ trong hàng: icon 18 dp + chữ `bodySmall` (không hộp màu lồng nhau).
class InlineNote extends StatelessWidget {
  const InlineNote({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
    this.bold = false,
  });

  /// Số liệu cũ: "Số dư chưa cập nhật 2 ngày" với icon đồng hồ, chữ đậm 600, màu trung tính.
  const InlineNote.stale({super.key, required this.text})
    : icon = Icons.schedule,
      iconColor = null,
      textColor = null,
      bold = true;

  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.bodySmall?.copyWith(
      color: textColor ?? scheme.onSurfaceVariant,
      fontWeight: bold ? FontWeight.w600 : null,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FirstLineIcon(icon, size: 18, textStyle: style!, color: iconColor ?? scheme.onSurfaceVariant),
        const SizedBox(width: Space.s2),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

/// Khung xương tĩnh cho danh sách đang tải lần đầu (không shimmer, không spinner).
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget block(double widthFactor, double height) => FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(Radii.xs)),
      ),
    );
    return Semantics(
      label: 'Đang tải',
      container: true,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < rows; i++)
              SizedBox(
                height: AppLayout.listRowTwoLineMinHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppLayout.listRowPaddingH),
                  child: Row(
                    children: [
                      Container(
                        width: AppLayout.listLeadingSize,
                        height: AppLayout.listLeadingSize,
                        decoration: BoxDecoration(color: scheme.surfaceContainerHigh, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: Space.s4),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            block(0.7, 14),
                            const SizedBox(height: Space.s2),
                            block(0.45, 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
