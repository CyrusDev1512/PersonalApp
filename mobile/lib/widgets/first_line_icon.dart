import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Icon đứng trước một đoạn chữ, căn giữa theo dòng đầu tiên của đoạn (kể cả khi chữ phóng to và xuống dòng).
///
/// Icon không phóng theo cỡ chữ (Material), nên ở 200% icon nằm giữa dòng chữ thay vì dính lên mép trên.
class FirstLineIcon extends StatelessWidget {
  const FirstLineIcon(this.icon, {super.key, required this.size, required this.textStyle, this.color});

  final IconData icon;
  final double size;

  /// Kiểu chữ của đoạn đi kèm (cỡ chữ và hệ số dòng quyết định chiều cao dòng đầu).
  final TextStyle textStyle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final line = scaler.scale(textStyle.fontSize ?? 14) * (textStyle.height ?? 1.2);
    return SizedBox(
      width: size,
      height: math.max(size, line),
      child: Center(
        child: Icon(icon, size: size, color: color ?? textStyle.color),
      ),
    );
  }
}
