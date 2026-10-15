// ThemeData "Bát men lam": bảng màu cố định, Be Vietnam Pro, mọi component theme trong DESIGN.md › Components.
// Màn hình không tự đặt màu / cỡ chữ / bo góc: đọc Theme.of(context), StatusColors và MoneyStyles.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_schemes.dart';
import 'status_colors.dart';
import 'tokens.dart';
import 'typography.dart';

/// Thanh hệ thống trong suốt, icon theo độ sáng của theme (DESIGN.md › Layout › System bars).
SystemUiOverlayStyle systemOverlayStyleFor(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: const Color(0x00000000),
    systemNavigationBarColor: const Color(0x00000000),
    systemNavigationBarDividerColor: const Color(0x00000000),
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
    // Android: icon tối trên theme sáng; iOS dùng statusBarBrightness (độ sáng của nền).
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: brightness,
  );
}

/// Kiểu nút cho các trường hợp theme mặc định không bao.
abstract final class AppButtonStyles {
  /// Nút xác nhận phá huỷ trong hộp thoại ("Xoá", "Ngắt kết nối"): nền `error` / chữ `onError`.
  static ButtonStyle destructiveFilled(ColorScheme scheme) =>
      FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError);

  /// Nút chữ mở hộp thoại phá huỷ: chữ `error`.
  static ButtonStyle destructiveText(ColorScheme scheme) => TextButton.styleFrom(foregroundColor: scheme.error);

  /// FAB phụ "Nhập tay" (Giao dịch): `secondaryContainer`, để màu men lam chỉ dành cho "Thêm mục tiêu".
  static Color secondaryFabBackground(ColorScheme scheme) => scheme.secondaryContainer;
  static Color secondaryFabForeground(ColorScheme scheme) => scheme.onSecondaryContainer;
}

/// Theme Material 3 của app (sáng hoặc tối).
///
/// [fontFamilyFallback]: họ font dự phòng cho ký tự Be Vietnam Pro không có (emoji danh mục, tiêu đề cảnh báo
/// của máy chủ). Áp cho mọi kiểu chữ, kể cả kiểu chữ của component theme. Bản dùng thử trên web truyền font
/// emoji / ký hiệu đã nạp sẵn để engine không đi tải font dự phòng; Android dùng font hệ thống.
ThemeData buildTheme(Brightness brightness, {List<String> fontFamilyFallback = const []}) {
  final dark = brightness == Brightness.dark;
  final scheme = dark ? darkColorScheme : lightColorScheme;
  final status = dark ? StatusColors.dark : StatusColors.light;
  final fallback = fontFamilyFallback.isEmpty ? null : fontFamilyFallback;
  final text = appTextTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
    decorationColor: scheme.onSurface,
    fontFamilyFallback: fallback,
  );

  const stadium = StadiumBorder();
  RoundedRectangleBorder rounded(double r) => RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
  const buttonMinSize = Size(64, AppLayout.touchTargetMin);
  final labelLarge = text.labelLarge!;
  final labelSmall = text.labelSmall!;

  bool selected(Set<WidgetState> s) => s.contains(WidgetState.selected);
  bool disabled(Set<WidgetState> s) => s.contains(WidgetState.disabled);

  /// Lớp trạng thái M3: hover 8%, focus 10%, nhấn 10% của màu nội dung.
  Color? stateLayer(Set<WidgetState> s, Color content) {
    if (s.contains(WidgetState.pressed)) return content.withValues(alpha: 0.10);
    if (s.contains(WidgetState.focused)) return content.withValues(alpha: 0.10);
    if (s.contains(WidgetState.hovered)) return content.withValues(alpha: 0.08);
    return null;
  }

  final outlineSide = BorderSide(color: scheme.outline);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: appFontFamily,
    fontFamilyFallback: fallback,
    textTheme: text,
    primaryTextTheme: appTextTheme.apply(
      bodyColor: scheme.onPrimary,
      displayColor: scheme.onPrimary,
      fontFamilyFallback: fallback,
    ),
    extensions: <ThemeExtension<dynamic>>[status, MoneyStyles.standard],
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    // Máy tính (bản demo web) mặc định thu nhỏ nút và vùng chạm: giữ đúng 48 dp như điện thoại.
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarThemeData(
      // Phẳng ở trạng thái nghỉ; nội dung cuộn dưới thanh thì chuyển sang surfaceContainer, không bóng.
      backgroundColor: WidgetStateColor.resolveWith(
        (s) => s.contains(WidgetState.scrolledUnder) ? scheme.surfaceContainer : scheme.surface,
      ),
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: Elevations.level0,
      scrolledUnderElevation: Elevations.level0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      actionsIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      systemOverlayStyle: systemOverlayStyleFor(brightness),
    ),
    // Nút: cao tối thiểu 48 dp; đệm dọc 8 dp để chữ phóng to (200%) không dính mép nút.
    filledButtonTheme: FilledButtonThemeData(
      // Không đặt màu ở đây: FilledButton (primary) và FilledButton.tonal (secondaryContainer) dùng chung theme này.
      style: FilledButton.styleFrom(
        minimumSize: buttonMinSize,
        padding: const EdgeInsets.symmetric(horizontal: Space.s6, vertical: Space.s2),
        shape: stadium,
        textStyle: labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            foregroundColor: scheme.primary,
            minimumSize: buttonMinSize,
            padding: const EdgeInsets.symmetric(horizontal: Space.s6, vertical: Space.s2),
            shape: stadium,
            textStyle: labelLarge,
          ).copyWith(
            side: WidgetStateBorderSide.resolveWith(
              (s) => disabled(s) ? BorderSide(color: scheme.onSurface.withValues(alpha: 0.12)) : outlineSide,
            ),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        minimumSize: buttonMinSize,
        padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s2),
        shape: stadium,
        textStyle: labelLarge,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      // Không dùng trong app (phẳng); nếu có thì cùng hình dáng với các nút khác.
      style: ElevatedButton.styleFrom(
        minimumSize: buttonMinSize,
        padding: const EdgeInsets.symmetric(horizontal: Space.s6, vertical: Space.s2),
        shape: stadium,
        textStyle: labelLarge,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: Elevations.level3,
      focusElevation: Elevations.level3,
      hoverElevation: 8,
      highlightElevation: Elevations.level3,
      shape: rounded(Radii.lg),
      extendedPadding: const EdgeInsetsDirectional.only(start: Space.s4, end: Space.s5),
      extendedIconLabelSpacing: Space.s3,
      extendedTextStyle: labelLarge,
      extendedSizeConstraints: const BoxConstraints(minHeight: 56, maxHeight: 56, minWidth: 80),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, AppLayout.touchTargetMin)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Space.s3)),
        shape: const WidgetStatePropertyAll(stadium),
        textStyle: WidgetStatePropertyAll(labelLarge),
        side: WidgetStatePropertyAll(outlineSide),
        backgroundColor: WidgetStateProperty.resolveWith((s) => selected(s) ? scheme.secondaryContainer : null),
        foregroundColor: WidgetStateProperty.resolveWith((s) {
          if (disabled(s)) return scheme.onSurface.withValues(alpha: 0.38);
          return selected(s) ? scheme.onSecondaryContainer : scheme.onSurface;
        }),
      ),
    ),
    // The One Cobalt Rule: rãnh công tắc bật dùng `secondary`, không phải `primary`.
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (disabled(s)) {
          return selected(s)
              ? scheme.onSurface.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.12);
        }
        return selected(s) ? scheme.secondary : scheme.surfaceContainerHighest;
      }),
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (disabled(s)) return selected(s) ? scheme.surface : scheme.onSurface.withValues(alpha: 0.38);
        return selected(s) ? scheme.onSecondary : scheme.outline;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((s) {
        if (selected(s)) return Colors.transparent;
        return disabled(s) ? scheme.onSurface.withValues(alpha: 0.12) : scheme.outline;
      }),
      overlayColor: WidgetStateProperty.resolveWith(
        (s) => stateLayer(s, selected(s) ? scheme.secondary : scheme.onSurface),
      ),
    ),
    // Không dùng Checkbox/Radio (công tắc và nút phân đoạn thay thế); nếu lọt vào thì cũng không tô men lam.
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => selected(s) && !disabled(s) ? scheme.secondary : null),
      checkColor: WidgetStatePropertyAll(scheme.onSecondary),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => selected(s) && !disabled(s) ? scheme.secondary : null),
    ),
    chipTheme: ChipThemeData(
      shape: rounded(Radii.sm),
      // Viền 1 dp `outline` khi chưa chọn (outlineVariant mặc định chỉ 1,5:1, không đọc ra là nút).
      side: WidgetStateBorderSide.resolveWith((s) {
        if (selected(s)) return BorderSide.none;
        if (disabled(s)) return BorderSide(color: scheme.onSurface.withValues(alpha: 0.12));
        return outlineSide;
      }),
      color: WidgetStateProperty.resolveWith((s) {
        if (selected(s)) return disabled(s) ? scheme.onSurface.withValues(alpha: 0.12) : scheme.secondaryContainer;
        return Colors.transparent;
      }),
      labelStyle: labelLarge.copyWith(
        color: WidgetStateColor.resolveWith((s) {
          if (disabled(s)) return scheme.onSurface.withValues(alpha: 0.38);
          return selected(s) ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
        }),
      ),
      checkmarkColor: scheme.onSecondaryContainer,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 18),
      padding: const EdgeInsets.symmetric(horizontal: Space.s2),
      elevation: Elevations.level0,
      pressElevation: Elevations.level0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      selectedShadowColor: Colors.transparent,
      showCheckmark: true,
    ),
    // The Calm Badge Rule: số đếm là thông tin, không phải báo động.
    badgeTheme: BadgeThemeData(
      backgroundColor: scheme.primary,
      textColor: scheme.onPrimary,
      textStyle: labelSmall,
      largeSize: 16,
      padding: const EdgeInsets.symmetric(horizontal: Space.s1),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 80,
      backgroundColor: scheme.surfaceContainer,
      elevation: Elevations.level0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.secondaryContainer,
      indicatorShape: stadium,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => labelSmall.copyWith(color: selected(s) ? scheme.onSurface : scheme.onSurfaceVariant),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(size: 24, color: selected(s) ? scheme.onSecondaryContainer : scheme.onSurfaceVariant),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainer,
      elevation: Elevations.level0,
      labelType: NavigationRailLabelType.all,
      groupAlignment: -1,
      useIndicator: true,
      indicatorColor: scheme.secondaryContainer,
      indicatorShape: stadium,
      minWidth: 80,
      selectedLabelTextStyle: labelSmall.copyWith(color: scheme.onSurface),
      unselectedLabelTextStyle: labelSmall.copyWith(color: scheme.onSurfaceVariant),
      selectedIconTheme: IconThemeData(size: 24, color: scheme.onSecondaryContainer),
      unselectedIconTheme: IconThemeData(size: 24, color: scheme.onSurfaceVariant),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s4),
      labelStyle: text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((s) {
        final color = s.contains(WidgetState.error)
            ? scheme.error
            : s.contains(WidgetState.focused)
            ? scheme.primary
            : disabled(s)
            ? scheme.onSurface.withValues(alpha: 0.38)
            : scheme.onSurfaceVariant;
        return text.bodyLarge!.copyWith(color: color);
      }),
      hintStyle: text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
      helperStyle: text.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
      // Câu hỗ trợ / lỗi ngắn (≤ 3 dòng ở 100%), nhưng không bao giờ bị cắt khi chữ phóng to (200% cần gấp đôi).
      helperMaxLines: 8,
      errorStyle: text.bodySmall!.copyWith(color: scheme.error),
      errorMaxLines: 8,
      suffixStyle: text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: outlineSide),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: outlineSide),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.onSurface.withValues(alpha: 0.12)),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      modalBackgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: Elevations.level1,
      modalElevation: Elevations.level1,
      modalBarrierColor: scheme.scrim.withValues(alpha: 0.32),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xxl))),
      clipBehavior: Clip.antiAlias,
      showDragHandle: true,
      dragHandleColor: scheme.onSurfaceVariant,
      // Màn rộng: bảng trượt không kéo giãn hết bề ngang (căn giữa, tối đa 640 dp).
      constraints: const BoxConstraints(maxWidth: AppLayout.sheetMaxWidth),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: Elevations.level3,
      shape: rounded(Radii.xxl),
      titleTextStyle: text.headlineSmall,
      contentTextStyle: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
      barrierColor: scheme.scrim.withValues(alpha: 0.32),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium!.copyWith(color: scheme.onInverseSurface),
      actionTextColor: scheme.inversePrimary,
      closeIconColor: scheme.onInverseSurface,
      elevation: Elevations.level3,
      shape: rounded(Radii.sm),
      insetPadding: const EdgeInsets.fromLTRB(Space.s4, Space.s1, Space.s4, Space.s3),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppLayout.listRowPaddingH),
      minTileHeight: AppLayout.listRowMinHeight,
      minLeadingWidth: AppLayout.listLeadingSize,
      horizontalTitleGap: Space.s4,
      titleTextStyle: text.titleMedium,
      subtitleTextStyle: text.bodyMedium!.copyWith(color: scheme.onSurfaceVariant),
      leadingAndTrailingTextStyle: text.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
      iconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      tileColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      linearMinHeight: 6,
      borderRadius: BorderRadius.circular(Radii.full),
      circularTrackColor: Colors.transparent,
      refreshBackgroundColor: scheme.surfaceContainerHigh,
    ),
    cardTheme: CardThemeData(
      // Phẳng và không viền (The Flat At Rest Rule); nổi bật bằng bậc tông, không bằng bóng.
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: Elevations.level0,
      shape: rounded(Radii.lg),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: Elevations.level2,
      shape: rounded(Radii.xs),
      textStyle: text.bodyLarge,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainer),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(Elevations.level2),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(Radii.xs)),
      textStyle: text.bodySmall!.copyWith(color: scheme.onInverseSurface),
    ),
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 24),
  );
}
