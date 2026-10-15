// Hằng số thiết kế "Bát men lam" (khoảng cách, bố cục, bo góc, độ cao, chuyển động).
// Nguồn: .agents/design-state/design.json; test/theme_test.dart so từng giá trị với file đó.
// Màn hình đọc các hằng số này thay vì viết số cứng.
import 'package:flutter/widgets.dart';

/// Thang khoảng cách 4 dp (design.json › spacing).
abstract final class Space {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
}

/// Ngưỡng bề rộng cửa sổ (window size class của Material 3).
abstract final class Breakpoints {
  static const double compact = 0;
  static const double medium = 600;

  /// Từ đây dùng NavigationRail thay cho NavigationBar.
  static const double expanded = 840;
  static const double large = 1200;
}

/// Lề hai bên nội dung theo cỡ cửa sổ.
abstract final class Gutter {
  static const double compact = 16;
  static const double medium = 24;
  static const double expanded = 32;

  /// Lề cho bề rộng [width] (dp).
  static double forWidth(double width) => width >= Breakpoints.expanded
      ? expanded
      : width >= Breakpoints.medium
      ? medium
      : compact;

  static double of(BuildContext context) => forWidth(MediaQuery.sizeOf(context).width);
}

/// Bố cục chung (design.json › layout).
abstract final class AppLayout {
  /// Cột nội dung rộng tối đa, căn giữa trên màn hình rộng.
  static const double contentMaxWidth = 720;

  /// Bảng trượt (bottom sheet) rộng tối đa.
  static const double sheetMaxWidth = 640;

  /// Bảng trượt cao tối đa 88% màn hình (chừa chỗ chạm ra ngoài để đóng).
  static const double sheetMaxHeightFactor = 0.88;

  /// Ràng buộc cho `showModalBottomSheet(constraints: …)`: truyền `constraints` sẽ thay hẳn ràng buộc của theme,
  /// nên luôn kèm bề rộng tối đa.
  static BoxConstraints sheetConstraints(BuildContext context) =>
      BoxConstraints(maxWidth: sheetMaxWidth, maxHeight: MediaQuery.sizeOf(context).height * sheetMaxHeightFactor);
  static const double sectionGap = 32;
  static const double headingToContent = 8;
  static const double groupGap = 12;
  static const double inlineGap = 8;
  static const double listRowPaddingH = 16;
  static const double listRowMinHeight = 56;
  static const double listRowTwoLineMinHeight = 72;
  static const double listLeadingSize = 40;

  /// Khoảng trống cuối danh sách để hàng cuối không nằm dưới FAB.
  static const double fabClearance = 96;
  static const double touchTargetMin = 48;
  static const double touchTargetGap = 8;

  /// Chữ lớn hơn 125%: hàng có số tiền xếp số tiền xuống dòng riêng (`textScaler.scale(16) > 20`).
  static const double largeTextProbe = 16;
  static const double largeTextLimit = 20;

  static bool isLargeText(TextScaler scaler) => scaler.scale(largeTextProbe) > largeTextLimit;
}

/// Khoảng cách bên trong status hero (DESIGN.md › Status hero).
abstract final class HeroSpace {
  static const double padding = 20;
  static const double headingToNumeral = 4;
  static const double numeralToMeaning = 4;
  static const double meaningToRuler = 16;
  static const double rulerToLegend = 12;
  static const double legendRowGap = 4;
  static const double blockGap = 12;
  static const double lineGap = 4;

  /// Chữ số của hero không phóng quá mức này (đã là cỡ hiển thị lớn).
  static const double numeralMaxTextScale = 1.3;
}

/// Thước mức sàn (floor ruler).
abstract final class Ruler {
  static const double barHeight = 12;
  static const double segmentGap = 2;
  static const double tickWidth = 2;
  static const double tickHeight = 20;
  static const double tickHalo = 2;
  static const double missingStroke = 1.5;
}

/// Bo góc (design.json › radius).
abstract final class Radii {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 28;
  static const double full = 999;
}

/// Độ nổi (dp). Chỉ FAB, snackbar, hộp thoại (level3) và menu (level2) có bóng.
abstract final class Elevations {
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
}

/// Thời lượng Material 3 (design.json › motion.durationsMs).
///
/// Không đặt tên `Durations` vì Flutter đã có `Durations` trong material.
abstract final class MotionDurations {
  static const Duration short2 = Duration(milliseconds: 100);
  static const Duration short3 = Duration(milliseconds: 150);
  static const Duration short4 = Duration(milliseconds: 200);
  static const Duration medium1 = Duration(milliseconds: 250);
  static const Duration medium2 = Duration(milliseconds: 300);
  static const Duration medium4 = Duration(milliseconds: 400);
  static const Duration long1 = Duration(milliseconds: 450);
  static const Duration long2 = Duration(milliseconds: 500);
  static const Duration long4 = Duration(milliseconds: 600);

  /// Phản hồi trạng thái (state layer, chọn chip, chuyển tab).
  static const Duration stateLayer = short3;

  /// Danh sách thay đổi.
  static const Duration listChange = medium1;
  static const Duration sheetEnter = medium4;
  static const Duration sheetExit = short4;
  static const Duration snackbar = medium1;
}

/// Đường cong Material 3 (design.json › motion.easing).
abstract final class Easings {
  static const Cubic standard = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Cubic standardDecelerate = Cubic(0.0, 0.0, 0.0, 1.0);
  static const Cubic standardAccelerate = Cubic(0.3, 0.0, 1.0, 1.0);
  static const Cubic emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Cubic emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
}

/// Chuyển động duy nhất được "dàn dựng": status hero đổi trạng thái (design.json › motion.statusChange).
abstract final class StatusMotion {
  static const Duration heroColor = Duration(milliseconds: 450);
  static const Curve heroColorCurve = Easings.emphasized;
  static const Duration numeralCount = Duration(milliseconds: 550);
  static const Curve numeralCountCurve = Easings.emphasizedDecelerate;
  static const Duration numeralSettle = Duration(milliseconds: 150);
  static const Duration numeralSettleDelay = Duration(milliseconds: 550);
  static const Curve numeralSettleCurve = Easings.standard;
  static const Duration headingExit = Duration(milliseconds: 150);
  static const Curve headingExitCurve = Easings.emphasizedAccelerate;
  static const Duration headingEnter = Duration(milliseconds: 250);
  static const Duration headingEnterDelay = Duration(milliseconds: 100);
  static const Curve headingEnterCurve = Easings.emphasizedDecelerate;
  static const double headingOffset = 8;
  static const Duration floorRuler = Duration(milliseconds: 500);
  static const Curve floorRulerCurve = Easings.emphasizedDecelerate;

  /// Thước hiện / ẩn khi vào hoặc rời trạng thái UNKNOWN.
  static const Duration rulerFade = Duration(milliseconds: 150);

  /// Tổng thời lượng tối đa của cả màn chuyển.
  static const Duration total = Duration(milliseconds: 700);

  /// "Xoá hiệu ứng động": chỉ đổi màu nền trong 150 ms, còn lại đổi ngay.
  static const Duration reduceMotionColor = Duration(milliseconds: 150);
  static const Curve reduceMotionColorCurve = Easings.standard;
}
