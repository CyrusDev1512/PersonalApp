import 'package:flutter/material.dart';

import '../models/level.dart';
import '../theme/status_colors.dart';
import '../theme/tokens.dart';

/// Nhóm hàng trên một mặt chung (DESIGN.md › Lists and containers): `surfaceContainerLow`, bo `lg` 16 dp,
/// không viền, không bóng, đệm dọc 4 dp; các hàng cách nhau bằng đường kẻ `outlineVariant` thụt vào 72 dp.
/// Là vật chứa duy nhất cho danh sách và không bao giờ chứa một vật chứa tô màu khác.
///
/// Cho nhóm ngắn (vài hàng). Danh sách dài dùng `ListView.builder` với [ListGroup.decoration] cho từng nhóm.
class ListGroup extends StatelessWidget {
  const ListGroup({super.key, required this.children, this.dividers = true});

  final List<Widget> children;
  final bool dividers;

  /// Khoảng thụt của đường kẻ = lề hàng 16 + đĩa 40 + khoảng 16.
  static const double dividerIndent = AppLayout.listRowPaddingH + AppLayout.listLeadingSize + Space.s4;

  static BoxDecoration decoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(Radii.lg),
  );

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && dividers) {
        // Trang trí: các hàng đã tách nhau bằng khoảng cách và chữ.
        items.add(const ExcludeSemantics(child: Divider(indent: dividerIndent)));
      }
      // Mỗi hàng là một nút đọc màn hình riêng: ListTile (và hàng có câu hỏi + nút) không tự tạo nút, nên
      // nếu không bọc thì nhãn và thao tác chạm của nó dính vào cả nhóm, đọc sai thứ tự.
      items.add(Semantics(container: true, child: children[i]));
    }
    return DecoratedBox(
      decoration: decoration(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.s1),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items),
          ),
        ),
      ),
    );
  }
}

/// Đĩa 40 dp đầu hàng: `surfaceContainerHighest` với icon `onSurfaceVariant`, hoặc chữ ngắn ("VCB", "MB"),
/// hoặc emoji danh mục do người dùng đặt.
class LeadingDisc extends StatelessWidget {
  const LeadingDisc({super.key, this.icon, this.text, this.background, this.foreground});

  /// Đĩa theo mức (hàng cảnh báo): nền `container`, icon `foreground` của mức.
  factory LeadingDisc.level(BuildContext context, Level level, {IconData? icon}) {
    final colors = level.colorsOf(context);
    return LeadingDisc(icon: icon ?? level.icon, background: colors.container, foreground: colors.foreground);
  }

  final IconData? icon;
  final String? text;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = foreground ?? scheme.onSurfaceVariant;
    return ExcludeSemantics(
      child: Container(
        width: AppLayout.listLeadingSize,
        height: AppLayout.listLeadingSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background ?? scheme.surfaceContainerHighest, shape: BoxShape.circle),
        child: icon != null
            ? Icon(icon, size: 20, color: fg)
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(Space.s1),
                  child: Text(text ?? '', maxLines: 1, style: theme.textTheme.labelMedium?.copyWith(color: fg)),
                ),
              ),
      ),
    );
  }
}

/// Màu của một pill (nhãn trạng thái không bấm được).
enum PillTone {
  ok,
  warning,
  danger,
  unknown,

  /// "Chưa phân loại": lời mời, `primaryContainer` (không phải lỗi).
  invitation,

  /// "Chuyển nội bộ": `tertiaryContainer`.
  transfer,

  /// "Ước tính sơ bộ": `surfaceContainerHighest`.
  neutral,
}

/// Pill trạng thái (không phải chip, không bấm được): cao 28 dp, bo `sm`, chữ `labelMedium`, icon 16 dp.
/// Tối đa một pill mỗi hàng, đặt dưới dòng phụ.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.tone = PillTone.neutral, this.icon});

  final String label;
  final PillTone tone;
  final IconData? icon;

  (Color, Color) _colors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    return switch (tone) {
      PillTone.ok => (status.ok.container, status.ok.onContainer),
      PillTone.warning => (status.warning.container, status.warning.onContainer),
      PillTone.danger => (status.danger.container, status.danger.onContainer),
      PillTone.unknown => (status.unknown.container, status.unknown.onContainer),
      PillTone.invitation => (scheme.primaryContainer, scheme.onPrimaryContainer),
      PillTone.transfer => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      PillTone.neutral => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(context);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(color: fg);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: DecoratedBox(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.sm)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: Space.s1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: Space.s1)],
              Flexible(child: Text(label, style: style)),
            ],
          ),
        ),
      ),
    );
  }
}
