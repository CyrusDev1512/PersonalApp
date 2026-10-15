import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../utils/currency.dart';
import 'first_line_icon.dart';

/// Icon "đang bận" 18 dp cho nút đang chạy (nút giữ nguyên chữ, chỉ đổi icon: DESIGN.md › Buttons › States).
class BusyIcon extends StatelessWidget {
  const BusyIcon({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(strokeWidth: 2, color: color ?? IconTheme.of(context).color),
  );
}

/// Dòng lỗi gắn với một hành động (lưu thất bại…): icon `error_outline` + chữ `bodyMedium` màu `error`.
class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.error);
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FirstLineIcon(Icons.error_outline, size: 18, textStyle: style),
          const SizedBox(width: Space.s2),
          Expanded(child: Text(message, style: style)),
        ],
      ),
    );
  }
}

/// Thanh hành động dính ở đáy form / bảng trượt: nút chính rộng hết hàng, nằm trên bàn phím (đặt làm phần tử
/// cuối của một Column có phần cuộn `Expanded` phía trên, trong Scaffold `resizeToAvoidBottomInset`).
///
/// [error]: thông báo lỗi ngay trên nút chính. [secondary]: nút chữ rộng hết hàng ở dòng riêng bên dưới.
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({super.key, required this.primary, this.secondary, this.error, this.horizontalPadding});

  final Widget primary;
  final Widget? secondary;
  final String? error;

  /// Mặc định theo lề của cửa sổ (16 / 24 / 32 dp).
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final h = horizontalPadding ?? Gutter.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(h, Space.s3, h, Space.s3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[InlineError(error!), const SizedBox(height: Space.s3)],
              primary,
              if (secondary != null) ...[const SizedBox(height: Space.s2), secondary!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ô nhập số tiền (DESIGN.md › Inputs › Money fields): cao 64 dp, chữ `moneyInput` (chữ số tỉ lệ), hậu tố "đ",
/// bàn phím số, tự nhóm nghìn khi gõ. Gợi ý là ví dụ ("VD: 3.000.000"), không phải nhãn.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.hint = 'VD: 3.000.000',
    this.helper,
    this.validator,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.onFieldSubmitted,
    this.textInputAction,
    this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = MoneyStyles.of(context).input;
    final scheme = theme.colorScheme;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      inputFormatters: const [VndInputFormatter()],
      style: money.numeral.copyWith(color: enabled ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.38)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        errorText: errorText,
        suffixText: 'đ',
        suffixStyle: money.unit.copyWith(color: scheme.onSurfaceVariant),
        constraints: const BoxConstraints(minHeight: 64),
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s4),
      ),
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}

/// Một lựa chọn của [AdaptiveSegmentedButton].
@immutable
class SegmentChoice<T> {
  const SegmentChoice(this.value, this.label, {this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Nút phân đoạn cho lựa chọn hai (ba) chiều, nhãn ngắn; khi một nhãn không vừa nửa hàng (đo bằng TextPainter
/// theo cỡ chữ hiện tại, vd. "Tháng 1/2027" ở 130%, mọi nhãn ở 200%) thì xếp dọc, mỗi đoạn rộng hết hàng
/// (DESIGN.md › Inputs › Segmented buttons). Đoạn đã chọn: `secondaryContainer` kèm dấu tích.
class AdaptiveSegmentedButton<T> extends StatelessWidget {
  const AdaptiveSegmentedButton({super.key, required this.choices, required this.selected, this.onChanged});

  final List<SegmentChoice<T>> choices;
  final T selected;

  /// `null` = vô hiệu.
  final ValueChanged<T>? onChanged;

  /// Bề rộng một đoạn cần cho [label] (đệm 12 + icon 18 + khoảng 8 + chữ + đệm 12 + viền và dư một chút).
  static double segmentWidthFor(BuildContext context, String label) {
    final style = Theme.of(context).textTheme.labelLarge;
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return Space.s3 + 18 + Space.s2 + width + Space.s3 + 2 + Space.s2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final per = constraints.maxWidth / choices.length;
        final vertical = choices.any((c) => segmentWidthFor(context, c.label) > per);
        final button = SegmentedButton<T>(
          direction: vertical ? Axis.vertical : Axis.horizontal,
          // Ngang: chia đều bề rộng. Dọc: rộng hết hàng nhờ ràng buộc bề rộng chặt bên dưới (expandedInsets
          // theo chiều dọc sẽ đòi chiều cao vô hạn trong danh sách cuộn).
          expandedInsets: vertical ? null : EdgeInsets.zero,
          segments: [
            for (final c in choices)
              ButtonSegment<T>(
                value: c.value,
                label: Text(c.label, softWrap: true),
                icon: c.icon == null ? null : Icon(c.icon),
              ),
          ],
          selected: {selected},
          onSelectionChanged: onChanged == null ? null : (s) => onChanged!(s.first),
        );
        return vertical ? SizedBox(width: constraints.maxWidth, child: button) : button;
      },
    );
  }
}

/// Nhãn nhỏ phía trên một nhóm điều khiển ("Loại mục tiêu", "Tháng"): `titleSmall`, không viết hoa.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s2),
      child: Text(text, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface)),
    );
  }
}

/// Dòng giải thích dưới một điều khiển không phải ô nhập (nút phân đoạn "Quỹ giữ / Ngân sách"…): `bodySmall`
/// `onSurfaceVariant`, thụt vào bằng đệm trong của ô nhập (16 dp) để thẳng hàng với chữ hỗ trợ của các ô nhập.
class SupportingText extends StatelessWidget {
  const SupportingText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: Space.s4),
      child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}
