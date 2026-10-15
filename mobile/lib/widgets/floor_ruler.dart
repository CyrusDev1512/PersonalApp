import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/status_colors.dart';
import '../theme/tokens.dart';
import 'money_text.dart';

/// Hình học của thước mức sàn, theo tỉ lệ [0, 1] của miền `max(số dư, mức sàn + vùng đệm)`.
///
/// - Đoạn giữ cho mục tiêu: [0, [reservedEnd]] (tô `heroBarReserved`).
/// - Đoạn còn thiếu (DANGER, chờ lương): [[reservedEnd], [missingEnd]] (chỉ viền 1,5 dp).
/// - Đoạn được tiêu: [[freeStart], [freeEnd]] (tô `heroBarFree`), rỗng khi số dư chưa vượt mức sàn.
/// - Vạch báo [tick] ở mức sàn + vùng đệm; `null` khi không có mục tiêu (mức sàn = 0).
@immutable
class RulerGeometry {
  const RulerGeometry({
    required this.reservedEnd,
    required this.missingEnd,
    required this.freeStart,
    required this.freeEnd,
    this.tick,
    this.tickOpacity = 1,
  });

  /// Từ số liệu tổng quan (đồng). Số âm coi như 0.
  factory RulerGeometry.compute({required int balance, required int floor, required int buffer}) {
    final b = math.max(balance, 0).toDouble();
    final f = math.max(floor, 0).toDouble();
    final u = math.max(buffer, 0).toDouble();
    if (f == 0) {
      // Chưa có mục tiêu: một đoạn được tiêu, không vạch báo (máy chủ luôn để mức OK).
      return RulerGeometry(reservedEnd: 0, missingEnd: 0, freeStart: 0, freeEnd: b > 0 ? 1 : 0, tickOpacity: 0);
    }
    final domain = math.max(b, f + u);
    final reserved = math.min(b, f) / domain;
    return RulerGeometry(
      reservedEnd: reserved,
      missingEnd: b < f ? f / domain : reserved,
      freeStart: f / domain,
      freeEnd: b > f ? b / domain : f / domain,
      tick: (f + u) / domain,
    );
  }

  final double reservedEnd;
  final double missingEnd;
  final double freeStart;
  final double freeEnd;
  final double? tick;
  final double tickOpacity;

  bool get hasMissing => missingEnd > reservedEnd;
  bool get hasFree => freeEnd > freeStart;

  static RulerGeometry lerp(RulerGeometry a, RulerGeometry b, double t) {
    double mix(double x, double y) => lerpDouble(x, y, t)!;
    final tick = a.tick == null ? b.tick : (b.tick == null ? a.tick : mix(a.tick!, b.tick!));
    return RulerGeometry(
      reservedEnd: mix(a.reservedEnd, b.reservedEnd),
      missingEnd: mix(a.missingEnd, b.missingEnd),
      freeStart: mix(a.freeStart, b.freeStart),
      freeEnd: mix(a.freeEnd, b.freeEnd),
      tick: tick,
      tickOpacity: mix(a.tick == null ? 0 : a.tickOpacity, b.tick == null ? 0 : b.tickOpacity),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RulerGeometry &&
      other.reservedEnd == reservedEnd &&
      other.missingEnd == missingEnd &&
      other.freeStart == freeStart &&
      other.freeEnd == freeEnd &&
      other.tick == tick &&
      other.tickOpacity == tickOpacity;

  @override
  int get hashCode => Object.hash(reservedEnd, missingEnd, freeStart, freeEnd, tick, tickOpacity);
}

/// Thước mức sàn (*thước mức sàn*): thanh 12 dp, các đoạn cách nhau 2 dp màu men, vạch báo 2 × 20 dp có
/// quầng 2 dp màu men để không lẫn vào đoạn được tiêu cùng màu (DESIGN.md › Status hero, mục 4).
class FloorRuler extends StatelessWidget {
  const FloorRuler({super.key, required this.geometry, required this.colors, this.semanticLabel, this.opacity = 1});

  final RulerGeometry geometry;
  final LevelColors colors;
  final String? semanticLabel;
  final double opacity;

  /// Nhãn đọc màn hình: "Số dư … đồng, giữ cho mục tiêu … đồng, được tiêu … đồng, báo khi được tiêu dưới … đồng".
  static String describe({required int balance, required int floor, required int free, required int buffer}) {
    final parts = <String>[
      'Số dư ${spokenVnd(balance)}',
      if (floor > 0) 'giữ cho mục tiêu ${spokenVnd(floor)}',
      'được tiêu ${spokenVnd(free)}',
      if (floor > 0) 'báo khi được tiêu dưới ${spokenVnd(buffer)}',
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: const Size(double.infinity, Ruler.tickHeight),
      painter: FloorRulerPainter(geometry: geometry, colors: colors, opacity: opacity),
    );
    return Semantics(
      container: true,
      label: semanticLabel,
      child: SizedBox(height: Ruler.tickHeight, width: double.infinity, child: paint),
    );
  }
}

class FloorRulerPainter extends CustomPainter {
  FloorRulerPainter({required this.geometry, required this.colors, this.opacity = 1});

  final RulerGeometry geometry;
  final LevelColors colors;
  final double opacity;

  Color _a(Color c) => c.withValues(alpha: c.a * opacity.clamp(0, 1));

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final w = size.width;
    const top = (Ruler.tickHeight - Ruler.barHeight) / 2;
    const half = Ruler.segmentGap / 2;
    const r = Ruler.barHeight / 2;

    // Đoạn [s, e] (px), lùi 1 dp ở cạnh tiếp giáp đoạn khác để chừa khe 2 dp màu men.
    Rect? segment(double s, double e) {
      var x0 = s * w;
      var x1 = e * w;
      if (x0 > 0.5) x0 += half;
      if (x1 < w - 0.5) x1 -= half;
      if (x1 - x0 < 1) return null;
      return Rect.fromLTRB(x0, top, x1, top + Ruler.barHeight);
    }

    RRect pill(Rect rect) => RRect.fromRectAndRadius(rect, Radius.circular(math.min(r, rect.width / 2)));

    final reserved = segment(0, geometry.reservedEnd);
    if (reserved != null) canvas.drawRRect(pill(reserved), Paint()..color = _a(colors.barReserved));

    if (geometry.hasMissing) {
      final missing = segment(geometry.reservedEnd, geometry.missingEnd);
      if (missing != null) {
        const inset = Ruler.missingStroke / 2;
        canvas.drawRRect(
          pill(missing.deflate(inset)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = Ruler.missingStroke
            ..color = _a(colors.barReserved),
        );
      }
    }

    if (geometry.hasFree) {
      final free = segment(geometry.freeStart, geometry.freeEnd);
      if (free != null) canvas.drawRRect(pill(free), Paint()..color = _a(colors.barFree));
    }

    final tick = geometry.tick;
    final tickAlpha = geometry.tickOpacity.clamp(0.0, 1.0);
    if (tick != null && tickAlpha > 0) {
      const halfTick = Ruler.tickWidth / 2;
      final x = (tick * w).clamp(halfTick, w - halfTick);
      // Quầng màu men cắt vạch ra khỏi đoạn nó đi qua.
      final halo = Rect.fromLTRB(
        x - halfTick - Ruler.tickHalo,
        top,
        x + halfTick + Ruler.tickHalo,
        top + Ruler.barHeight,
      );
      canvas.drawRect(halo, Paint()..color = _a(colors.heroBackground).withValues(alpha: tickAlpha * opacity));
      canvas.drawRect(
        Rect.fromLTRB(x - halfTick, 0, x + halfTick, Ruler.tickHeight),
        Paint()..color = _a(colors.heroForeground).withValues(alpha: tickAlpha * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(FloorRulerPainter oldDelegate) =>
      oldDelegate.geometry != geometry || oldDelegate.colors != colors || oldDelegate.opacity != opacity;
}
