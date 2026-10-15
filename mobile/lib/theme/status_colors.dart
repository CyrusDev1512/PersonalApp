// Màu trạng thái OK / WARNING / DANGER / UNKNOWN (ThemeExtension), chép 1:1 từ design.json › statusColors.
import 'package:flutter/material.dart';

import '../models/level.dart';

/// Bộ màu của một mức.
///
/// [foreground]: icon và chữ trạng thái ngắn trên mọi nền; [container] / [onContainer]: pill, đĩa icon ở hàng
/// cảnh báo; nhóm `hero*` chỉ dùng cho status hero. UNKNOWN không có thước nên [heroBarReserved] /
/// [heroBarFree] là `null`.
@immutable
class LevelColors {
  const LevelColors({
    required this.foreground,
    required this.container,
    required this.onContainer,
    required this.heroBackground,
    required this.heroForeground,
    this.heroBarReserved,
    this.heroBarFree,
  });

  final Color foreground;
  final Color container;
  final Color onContainer;

  /// Màu men của status hero.
  final Color heroBackground;

  /// Mọi chữ, icon và vạch báo (tick) trong hero.
  final Color heroForeground;

  /// Đoạn "giữ cho mục tiêu" của thước mức sàn.
  final Color? heroBarReserved;

  /// Đoạn "được tiêu" của thước mức sàn.
  final Color? heroBarFree;

  /// Màu thanh thước; mức không có thước (UNKNOWN) lấy màu chữ hero để chuyển màu không bị trong suốt.
  Color get barReserved => heroBarReserved ?? heroForeground;
  Color get barFree => heroBarFree ?? heroForeground;

  LevelColors copyWith({
    Color? foreground,
    Color? container,
    Color? onContainer,
    Color? heroBackground,
    Color? heroForeground,
    Color? heroBarReserved,
    Color? heroBarFree,
  }) => LevelColors(
    foreground: foreground ?? this.foreground,
    container: container ?? this.container,
    onContainer: onContainer ?? this.onContainer,
    heroBackground: heroBackground ?? this.heroBackground,
    heroForeground: heroForeground ?? this.heroForeground,
    heroBarReserved: heroBarReserved ?? this.heroBarReserved,
    heroBarFree: heroBarFree ?? this.heroBarFree,
  );

  /// Nội suy từng màu; thiếu màu thước ở một phía thì dùng màu chữ hero của phía đó.
  static LevelColors lerp(LevelColors a, LevelColors b, double t) {
    if (identical(a, b)) return a;
    Color mix(Color x, Color y) => Color.lerp(x, y, t)!;
    final hasBars = a.heroBarReserved != null || b.heroBarReserved != null;
    return LevelColors(
      foreground: mix(a.foreground, b.foreground),
      container: mix(a.container, b.container),
      onContainer: mix(a.onContainer, b.onContainer),
      heroBackground: mix(a.heroBackground, b.heroBackground),
      heroForeground: mix(a.heroForeground, b.heroForeground),
      heroBarReserved: hasBars ? mix(a.barReserved, b.barReserved) : null,
      heroBarFree: hasBars ? mix(a.barFree, b.barFree) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LevelColors &&
      other.foreground == foreground &&
      other.container == container &&
      other.onContainer == onContainer &&
      other.heroBackground == heroBackground &&
      other.heroForeground == heroForeground &&
      other.heroBarReserved == heroBarReserved &&
      other.heroBarFree == heroBarFree;

  @override
  int get hashCode =>
      Object.hash(foreground, container, onContainer, heroBackground, heroForeground, heroBarReserved, heroBarFree);
}

/// Màu trạng thái của theme (`Theme.of(context).extension<StatusColors>()`).
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({required this.ok, required this.warning, required this.danger, required this.unknown});

  final LevelColors ok;
  final LevelColors warning;
  final LevelColors danger;
  final LevelColors unknown;

  static const StatusColors light = StatusColors(
    ok: LevelColors(
      foreground: Color(0xFF256C2C),
      container: Color(0xFFD0F1D0),
      onContainer: Color(0xFF0D3511),
      heroBackground: Color(0xFF2C4B9A),
      heroForeground: Color(0xFFFFFFFF),
      heroBarReserved: Color(0xFF92A9D9),
      heroBarFree: Color(0xFFFFFFFF),
    ),
    warning: LevelColors(
      foreground: Color(0xFF835A03),
      container: Color(0xFFFEE3AD),
      onContainer: Color(0xFF452902),
      heroBackground: Color(0xFFFEE3AD),
      heroForeground: Color(0xFF452902),
      heroBarReserved: Color(0xFF9C7A42),
      heroBarFree: Color(0xFF452902),
    ),
    danger: LevelColors(
      foreground: Color(0xFFA8372A),
      container: Color(0xFFFFDDD7),
      onContainer: Color(0xFF551912),
      heroBackground: Color(0xFF983529),
      heroForeground: Color(0xFFFFFFFF),
      heroBarReserved: Color(0xFFDFB1A9),
      heroBarFree: Color(0xFFFFFFFF),
    ),
    unknown: LevelColors(
      foreground: Color(0xFF525B69),
      container: Color(0xFFE2E7EF),
      onContainer: Color(0xFF242C38),
      heroBackground: Color(0xFFE2E7EF),
      heroForeground: Color(0xFF242C38),
    ),
  );

  static const StatusColors dark = StatusColors(
    ok: LevelColors(
      foreground: Color(0xFF90D192),
      container: Color(0xFF234024),
      onContainer: Color(0xFFCFEFCF),
      heroBackground: Color(0xFF203A7E),
      heroForeground: Color(0xFFDBE6FE),
      heroBarReserved: Color(0xFF7C95CA),
      heroBarFree: Color(0xFFDBE6FE),
    ),
    warning: LevelColors(
      foreground: Color(0xFFEDC06B),
      container: Color(0xFF503816),
      onContainer: Color(0xFFFEE5B3),
      heroBackground: Color(0xFF362207),
      heroForeground: Color(0xFFFEE5B3),
      heroBarReserved: Color(0xFF9C7947),
      heroBarFree: Color(0xFFFEE5B3),
    ),
    danger: LevelColors(
      foreground: Color(0xFFEFA598),
      container: Color(0xFF6C2B22),
      onContainer: Color(0xFFFFDDD7),
      heroBackground: Color(0xFF912F23),
      heroForeground: Color(0xFFFEF2F0),
      heroBarReserved: Color(0xFFE2B0A7),
      heroBarFree: Color(0xFFFEF2F0),
    ),
    unknown: LevelColors(
      foreground: Color(0xFFB0B8C4),
      container: Color(0xFF2B323D),
      onContainer: Color(0xFFE2E7ED),
      heroBackground: Color(0xFF2F3640),
      heroForeground: Color(0xFFE2E7ED),
    ),
  );

  /// Bộ màu theo theme hiện tại (luôn có: buildTheme đăng ký cho cả sáng và tối).
  static StatusColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<StatusColors>() ?? (theme.brightness == Brightness.dark ? dark : light);
  }

  /// Bộ màu của [level]. `Level.info` không phải trạng thái tiền: dùng nhóm màu secondary của [scheme].
  LevelColors forLevel(Level level, ColorScheme scheme) => switch (level) {
    Level.ok => ok,
    Level.warning => warning,
    Level.danger => danger,
    Level.unknown => unknown,
    Level.info => LevelColors(
      foreground: scheme.secondary,
      container: scheme.secondaryContainer,
      onContainer: scheme.onSecondaryContainer,
      heroBackground: scheme.secondaryContainer,
      heroForeground: scheme.onSecondaryContainer,
    ),
  };

  @override
  StatusColors copyWith({LevelColors? ok, LevelColors? warning, LevelColors? danger, LevelColors? unknown}) =>
      StatusColors(
        ok: ok ?? this.ok,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        unknown: unknown ?? this.unknown,
      );

  @override
  StatusColors lerp(covariant StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      ok: LevelColors.lerp(ok, other.ok, t),
      warning: LevelColors.lerp(warning, other.warning, t),
      danger: LevelColors.lerp(danger, other.danger, t),
      unknown: LevelColors.lerp(unknown, other.unknown, t),
    );
  }
}

/// Màu và icon của một mức theo theme đang dùng.
extension StatusX on Level {
  LevelColors colorsOf(BuildContext context) => StatusColors.of(context).forLevel(this, Theme.of(context).colorScheme);

  /// Icon trạng thái (bản tô đặc: DESIGN.md › Components, "filled only for … status icons").
  IconData get icon => switch (this) {
    Level.ok => Icons.check_circle,
    Level.warning => Icons.warning_rounded,
    Level.danger => Icons.error,
    Level.unknown => Icons.help,
    Level.info => Icons.info,
  };
}
