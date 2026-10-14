/// Mức cảnh báo của tổng quan / cảnh báo (`level` trong API).
enum Level {
  ok('OK'),
  warning('WARNING'),
  danger('DANGER'),
  unknown('UNKNOWN'),

  /// Cảnh báo thông tin (bản tin, TK mới…) không mang mức OK/WARNING/DANGER.
  info('INFO');

  const Level(this.code);

  final String code;

  static Level parse(Object? raw) {
    final s = raw?.toString().trim().toUpperCase();
    for (final level in Level.values) {
      if (level.code == s) return level;
    }
    return raw == null ? Level.unknown : Level.info;
  }

  /// Nhãn hiển thị theo docs/api.md.
  String get label => switch (this) {
        Level.ok => 'An toàn',
        Level.warning => 'Sắp chạm mức mục tiêu',
        Level.danger => 'Đã lấn vào tiền dành cho mục tiêu',
        Level.unknown => 'Chưa biết số dư',
        Level.info => 'Thông tin',
      };
}
