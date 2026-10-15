import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Cỡ cửa sổ theo Material 3 (window size class).
enum WindowClass {
  /// < 600 dp: điện thoại dọc.
  compact,

  /// 600–839 dp.
  medium,

  /// 840–1199 dp: NavigationRail.
  expanded,

  /// ≥ 1200 dp.
  large;

  static WindowClass forWidth(double width) => width >= Breakpoints.large
      ? large
      : width >= Breakpoints.expanded
      ? expanded
      : width >= Breakpoints.medium
      ? medium
      : compact;

  static WindowClass of(BuildContext context) => forWidth(MediaQuery.sizeOf(context).width);

  /// Cửa sổ thấp hơn mức này (điện thoại xoay ngang) giữ NavigationBar dù đủ rộng: rail không cuộn, có FAB ở
  /// đầu, chữ lớn sẽ đẩy mục cuối ra khỏi màn hình.
  static const double railMinHeight = 480;

  /// Điều hướng bằng NavigationRail thay cho NavigationBar.
  bool get usesRail => index >= expanded.index;

  /// NavigationRail khi cửa sổ vừa đủ rộng (≥ 840 dp) vừa đủ cao (≥ [railMinHeight]).
  static bool railFor(Size size) => forWidth(size.width).usesRail && size.height >= railMinHeight;
}

/// Cột nội dung căn giữa, rộng tối đa [maxWidth] (720 dp): màn hình rộng không kéo giãn bố cục điện thoại.
///
/// Phần thừa hai bên tô màu `surface` như nền trang. Cột hẹp hơn [maxWidth] thì không làm gì.
class ContentColumn extends StatelessWidget {
  const ContentColumn({super.key, required this.child, this.maxWidth = AppLayout.contentMaxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return child;
        return ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: maxWidth, child: child),
          ),
        );
      },
    );
  }
}

/// Cho màn hình con biết khung chính đang đặt hành động chính ("Thêm mục tiêu") ở NavigationRail,
/// để màn Tổng quan không hiện FAB thứ hai.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.primaryActionInRail, required super.child});

  final bool primaryActionInRail;

  /// `false` khi không nằm trong khung chính (test dựng một màn riêng lẻ).
  static bool primaryActionInRailOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()?.primaryActionInRail ?? false;

  @override
  bool updateShouldNotify(ShellScope oldWidget) => oldWidget.primaryActionInRail != primaryActionInRail;
}

/// Khung một màn hình trên cửa sổ rộng: Scaffold (app bar, màu nền khi cuộn dưới thanh) rộng hết vùng, chỉ thân
/// màn hình nằm trong cột 720 dp ([ContentColumn]). Cho con cháu biết lề thừa mỗi bên ([ContentInset]) để app bar
/// canh tiêu đề và nút theo mép cột, FAB và SnackBar nằm trong cột.
///
/// Điện thoại (vùng hẹp hơn cột): lề thừa 0, không đổi gì.
class ContentFrame extends StatelessWidget {
  const ContentFrame({super.key, required this.child, this.maxWidth = AppLayout.contentMaxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = constraints.maxWidth > maxWidth ? (constraints.maxWidth - maxWidth) / 2 : 0.0;
        if (inset == 0) return ContentInset(value: 0, child: child);
        final theme = Theme.of(context);
        final snack = theme.snackBarTheme;
        final base = snack.insetPadding ?? EdgeInsets.zero;
        final resolved = base.resolve(Directionality.of(context));
        return ContentInset(
          value: inset,
          child: Theme(
            data: theme.copyWith(
              snackBarTheme: snack.copyWith(
                insetPadding: resolved.copyWith(left: resolved.left + inset, right: resolved.right + inset),
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Lề thừa mỗi bên của cột nội dung (dp); 0 trên điện thoại hoặc ngoài [ContentFrame].
class ContentInset extends InheritedWidget {
  const ContentInset({super.key, required this.value, required super.child});

  final double value;

  static double of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ContentInset>()?.value ?? 0;

  @override
  bool updateShouldNotify(ContentInset oldWidget) => oldWidget.value != value;
}

/// App bar nhỏ M3 rộng hết màn hình, tiêu đề và nút hành động canh theo mép cột nội dung (lề + [ContentInset]).
/// Chữ của nút chữ ("Đọc hết") thẳng mép phải với nội dung: đệm cuối = lề − 12 dp đệm trong của nút.
class ContentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ContentAppBar({super.key, required this.title, this.actions});

  final Widget title;
  final List<Widget>? actions;

  /// Đệm ngang bên trong nút chữ và nút icon (vùng chạm 48 dp quanh icon 24 dp).
  static const double _buttonInset = Space.s3;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final gutter = Gutter.of(context);
    final inset = ContentInset.of(context);
    return AppBar(
      title: title,
      titleSpacing: gutter + inset,
      actions: actions,
      actionsPadding: EdgeInsetsDirectional.only(end: inset + (gutter - _buttonInset).clamp(0, gutter)),
    );
  }
}

/// Vị trí FAB "cuối, nổi" nhưng tính theo mép cột nội dung (không trôi ra mép cửa sổ rộng).
class ContentFabLocation extends StandardFabLocation with FabEndOffsetX, FabFloatOffsetY {
  const ContentFabLocation._(this.inset);

  final double inset;

  static FloatingActionButtonLocation of(BuildContext context) {
    final inset = ContentInset.of(context);
    return inset == 0 ? FloatingActionButtonLocation.endFloat : ContentFabLocation._(inset);
  }

  @override
  double getOffsetX(ScaffoldPrelayoutGeometry scaffoldGeometry, double adjustment) {
    final x = super.getOffsetX(scaffoldGeometry, adjustment);
    return scaffoldGeometry.textDirection == TextDirection.rtl ? x + inset : x - inset;
  }

  @override
  bool operator ==(Object other) => other is ContentFabLocation && other.inset == inset;

  @override
  int get hashCode => inset.hashCode;
}
