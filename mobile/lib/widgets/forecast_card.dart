import 'package:flutter/material.dart';

import '../models/forecast.dart';
import '../theme/status_colors.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../utils/currency.dart';
import 'first_line_icon.dart';
import 'list_group.dart';
import 'money_text.dart';

/// Màu tiêu đề dự báo: `danger.foreground` (chạm mức sàn trong ≤ 7 ngày), `warning.foreground` (chạm trong
/// tháng), còn lại `null` (màu chữ thường `onSurface`).
Color? forecastColor(BuildContext context, ForecastSeverity severity) {
  final status = StatusColors.of(context);
  return switch (severity) {
    ForecastSeverity.danger => status.danger.foreground,
    ForecastSeverity.warning => status.warning.foreground,
    ForecastSeverity.neutral => null,
  };
}

String _two(int v) => v.toString().padLeft(2, '0');

/// Khối "Dự báo cuối tháng" ở Tổng quan (DESIGN.md › Forecast block): một nhóm phẳng, không viền màu.
///
/// Dòng đầu: icon 20 dp + câu tóm tắt của máy chủ (`titleSmall` 600), màu theo mức độ. Sau đó tối đa hai câu
/// có số tiền ("Nên chi tối đa ~120.000đ mỗi ngày", "Cuối tháng dự kiến còn / thiếu ~…") rồi các dòng
/// `details` của máy chủ (bỏ dòng trùng ý với hai câu trên). Một số lớn duy nhất của Tổng quan nằm ở hero, nên
/// ở đây là câu, không phải ô số liệu.
///
/// Ẩn khi không có dự báo (tháng cũ) hoặc `status = unavailable` (chưa biết số dư); `insufficient_data` chỉ
/// hiện một dòng chữ mờ.
class ForecastCard extends StatelessWidget {
  const ForecastCard({super.key, required this.forecast, this.month});

  final Forecast? forecast;

  /// Tháng ("YYYY-MM") của tổng quan, để biết ngày chạm mức sàn có nằm trong tháng không.
  final String? month;

  /// Có hiện khối không.
  static bool shouldShow(Forecast? forecast) => forecast != null && forecast.isDisplayable;

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    if (f == null || !shouldShow(f)) return const SizedBox.shrink();
    return Container(
      key: const Key('forecast_card'),
      decoration: ListGroup.decoration(context),
      padding: const EdgeInsets.all(Space.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: f.isOk ? _okContent(context, f) : _mutedContent(context, f),
      ),
    );
  }

  static IconData _icon(ForecastSeverity severity) => switch (severity) {
    ForecastSeverity.danger => Icons.trending_down,
    ForecastSeverity.warning => Icons.warning_amber_rounded,
    ForecastSeverity.neutral => Icons.insights,
  };

  /// Câu tóm tắt dự phòng khi máy chủ không gửi `headline`.
  static String _fallbackHeadline(Forecast f) {
    final hit = f.floorHitDate;
    if (hit != null) return 'Chi như hiện tại thì khoảng ngày ${_two(hit.day)}/${_two(hit.month)} sẽ chạm mức sàn';
    return 'Chi như hiện tại thì cuối tháng vẫn trên mức sàn';
  }

  List<Widget> _okContent(BuildContext context, Forecast f) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final severity = f.severity(month: month);
    final color = forecastColor(context, severity);
    final headlineStyle = theme.textTheme.titleSmall!.copyWith(color: color ?? scheme.onSurface);
    final headline = f.headline ?? _fallbackHeadline(f);
    final body = theme.textTheme.bodyLarge!.copyWith(color: scheme.onSurface);
    final small = theme.textTheme.bodySmall!.copyWith(color: scheme.onSurfaceVariant);

    final safe = f.safeDailySpend;
    final freeEnd = f.projectedFreeEnd;
    // Câu tóm tắt của máy chủ có thể đã nói số được tiêu cuối tháng.
    final showFreeEnd = freeEnd != null && !headline.contains(formatGrouped(freeEnd.abs()));
    final safeText = safe == null ? null : '~${formatGrouped(safe)}đ';
    // Dòng chi tiết trùng ý với câu "Nên chi tối đa …" (cùng số tiền) thì không lặp lại.
    final details = [
      for (final line in f.details)
        if (safeText == null || !line.contains(safeText)) line,
    ];
    final lowConfidenceInDetails = details.any((d) => d.contains('Ước tính sơ bộ'));

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FirstLineIcon(_icon(severity), size: 20, textStyle: headlineStyle, color: color ?? scheme.onSurfaceVariant),
          const SizedBox(width: Space.s2),
          Expanded(child: Text(headline, key: const Key('forecast_headline'), style: headlineStyle)),
        ],
      ),
      if (safe != null) ...[
        const SizedBox(height: Space.s3),
        MoneySentence(
          ['Nên chi tối đa ', MoneyParts.of(safe, estimate: true), ' mỗi ngày'],
          key: const Key('forecast_safe_daily'),
          style: body,
          moneyStyle: MoneyStyle.body,
        ),
      ],
      if (showFreeEnd) ...[
        SizedBox(height: safe != null ? Space.s1 : Space.s3),
        MoneySentence(
          freeEnd < 0
              ? ['Cuối tháng dự kiến thiếu ', MoneyParts.of(-freeEnd, estimate: true), ' cho mục tiêu']
              : ['Cuối tháng dự kiến còn ', MoneyParts.of(freeEnd, estimate: true), ' được tiêu'],
          key: const Key('forecast_free_end'),
          style: body,
          moneyStyle: MoneyStyle.body,
        ),
      ],
      if (details.isNotEmpty) const SizedBox(height: Space.s3),
      for (var i = 0; i < details.length; i++)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : Space.s1),
          child: Text(details[i], style: small),
        ),
      if (f.isLowConfidence && !lowConfidenceInDetails) ...[
        const SizedBox(height: Space.s3),
        const Pill('Ước tính sơ bộ'),
      ],
    ];
  }

  List<Widget> _mutedContent(BuildContext context, Forecast f) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final main = f.headline ?? f.reason ?? 'Chưa đủ dữ liệu để dự báo cuối tháng.';
    final reason = f.reason;
    return [
      Text(
        main,
        key: const Key('forecast_headline'),
        style: theme.textTheme.bodyMedium?.copyWith(color: muted),
      ),
      if (reason != null && reason != main)
        Padding(
          padding: const EdgeInsets.only(top: Space.s1),
          child: Text(reason, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
        ),
    ];
  }
}
