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

  /// Điều hướng bằng NavigationRail thay cho NavigationBar.
  bool get usesRail => index >= expanded.index;
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
