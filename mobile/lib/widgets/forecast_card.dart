import 'package:flutter/material.dart';

import '../models/forecast.dart';
import '../utils/currency.dart';

/// Màu tiêu đề dự báo: đỏ (chạm mức sàn trong ≤ 7 ngày), hổ phách (chạm trong tháng), còn lại `null` (màu chữ thường).
Color? forecastColor(ForecastSeverity severity) => switch (severity) {
  ForecastSeverity.danger => Colors.red.shade700,
  ForecastSeverity.warning => Colors.amber.shade800,
  ForecastSeverity.neutral => null,
};

String _two(int v) => v.toString().padLeft(2, '0');

/// Thẻ "Dự báo cuối tháng" ở Tổng quan (ngay dưới banner trạng thái).
///
/// Ẩn khi không có dự báo (tháng cũ) hoặc `status = unavailable` (chưa biết số dư);
/// `insufficient_data` chỉ hiện một dòng chữ mờ.
class ForecastCard extends StatelessWidget {
  const ForecastCard({super.key, required this.forecast, this.month});

  final Forecast? forecast;

  /// Tháng ("YYYY-MM") của tổng quan, để biết ngày chạm mức sàn có nằm trong tháng không.
  final String? month;

  /// Có hiện thẻ không.
  static bool shouldShow(Forecast? forecast) => forecast != null && forecast.isDisplayable;

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    if (f == null || !shouldShow(f)) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final severity = f.severity(month: month);
    final color = forecastColor(severity);

    final children = <Widget>[
      Row(
        children: [
          Icon(_icon(f, severity), size: 20, color: color ?? scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dự báo cuối tháng',
              style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      if (f.isOk) ..._okContent(context, f, color) else ..._mutedContent(context, f),
    ];

    return Card(
      key: const Key('forecast_card'),
      margin: EdgeInsets.zero,
      shape: color == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withValues(alpha: 0.6)),
            ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  static IconData _icon(Forecast f, ForecastSeverity severity) {
    if (!f.isOk) return Icons.hourglass_empty;
    return switch (severity) {
      ForecastSeverity.danger => Icons.trending_down,
      ForecastSeverity.warning => Icons.warning_amber_rounded,
      ForecastSeverity.neutral => Icons.insights,
    };
  }

  /// Câu tóm tắt dự phòng khi server không gửi `headline`.
  static String _fallbackHeadline(Forecast f) {
    final hit = f.floorHitDate;
    if (hit != null) return 'Chi như hiện tại thì khoảng ngày ${_two(hit.day)}/${_two(hit.month)} sẽ chạm mức sàn';
    return 'Chi như hiện tại thì cuối tháng vẫn trên mức sàn';
  }

  List<Widget> _okContent(BuildContext context, Forecast f, Color? color) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall;
    final freeEnd = f.projectedFreeEnd;
    final safeDaily = f.safeDailySpend;
    final budgets = f.budgetsNeedingAttention;
    return [
      Text(
        f.headline ?? _fallbackHeadline(f),
        key: const Key('forecast_headline'),
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: color),
      ),
      for (final line in f.details) Padding(padding: const EdgeInsets.only(top: 4), child: Text(line, style: small)),
      if (safeDaily != null || freeEnd != null) const SizedBox(height: 8),
      if (safeDaily != null)
        _Fact(
          key: const Key('forecast_safe_daily'),
          icon: Icons.savings_outlined,
          text: 'Nên chi tối đa ~${formatVnd(safeDaily)}/ngày',
        ),
      if (freeEnd != null)
        _Fact(
          key: const Key('forecast_free_end'),
          icon: Icons.event_outlined,
          text: 'Được tiêu cuối tháng (dự kiến): ${formatVnd(freeEnd)}',
          color: freeEnd < 0 ? Colors.red.shade700 : null,
        ),
      if (budgets.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('Ngân sách vượt nhịp', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
        for (final b in budgets) _BudgetLine(budget: b),
      ],
      if (f.isLowConfidence) ...[
        const SizedBox(height: 8),
        Text(
          'Ước tính sơ bộ (mới có ${f.observedDays} ngày dữ liệu)',
          key: const Key('forecast_low_confidence'),
          style: small?.copyWith(fontStyle: FontStyle.italic, color: scheme.onSurfaceVariant),
        ),
      ],
    ];
  }

  List<Widget> _mutedContent(BuildContext context, Forecast f) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final main = f.headline ?? f.reason ?? 'Chưa đủ dữ liệu để dự báo cuối tháng.';
    final reason = f.reason;
    return [
      Text(main, key: const Key('forecast_headline'), style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
      if (reason != null && reason != main)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(reason, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ),
    ];
  }
}

class _Fact extends StatelessWidget {
  const _Fact({super.key, required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// "🍜 Tiền ăn: dự kiến 120% · gợi ý ~133.333đ/ngày".
class _BudgetLine extends StatelessWidget {
  const _BudgetLine({required this.budget});

  final BudgetPace budget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = budget;
    final color = b.isExceeded ? Colors.red.shade700 : Colors.amber.shade800;
    final suggested = b.suggestedDaily;
    final parts = [
      if (b.isExceeded) 'đã vượt',
      'dự kiến ${b.projectedPct.round()}%',
      if (suggested != null && suggested > 0) 'gợi ý ~${formatVnd(suggested)}/ngày',
    ];
    return Padding(
      key: Key('forecast_budget_${b.goalId ?? b.name}'),
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(b.isExceeded ? Icons.error_outline : Icons.speed, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: b.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ': ${parts.join(' · ')}'),
                ],
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
