// Chữ "Bát men lam": Be Vietnam Pro cho mọi vai trò (design.json › typography).
// Cỡ chữ là sp (theo cài đặt cỡ chữ của Android), `height` là hệ số dòng của Flutter.
import 'package:flutter/material.dart';

/// Họ font khai báo trong pubspec.yaml (assets/fonts/BeVietnamPro-*.ttf, 400/500/600/700/800).
const String appFontFamily = 'BeVietnamPro';

TextStyle _role(double size, FontWeight weight, double height, double tracking) => TextStyle(
  fontFamily: appFontFamily,
  fontSize: size,
  fontWeight: weight,
  height: height,
  letterSpacing: tracking,
  leadingDistribution: TextLeadingDistribution.even,
);

/// 15 vai trò Material 3 (màu do ThemeData gắn theo bảng màu).
final TextTheme appTextTheme = TextTheme(
  displayLarge: _role(56, FontWeight.w800, 1.12, -1.1),
  displayMedium: _role(45, FontWeight.w800, 1.16, -0.8),
  displaySmall: _role(36, FontWeight.w700, 1.22, -0.5),
  headlineLarge: _role(32, FontWeight.w700, 1.25, -0.3),
  headlineMedium: _role(28, FontWeight.w700, 1.29, -0.2),
  headlineSmall: _role(24, FontWeight.w700, 1.42, 0.0),
  titleLarge: _role(22, FontWeight.w700, 1.45, 0.0),
  titleMedium: _role(16, FontWeight.w600, 1.5, 0.1),
  titleSmall: _role(14, FontWeight.w600, 1.43, 0.1),
  bodyLarge: _role(16, FontWeight.w400, 1.5, 0.1),
  bodyMedium: _role(15, FontWeight.w400, 1.47, 0.1),
  bodySmall: _role(13, FontWeight.w400, 1.46, 0.15),
  labelLarge: _role(14, FontWeight.w600, 1.43, 0.1),
  labelMedium: _role(13, FontWeight.w600, 1.38, 0.2),
  labelSmall: _role(12, FontWeight.w600, 1.33, 0.3),
);

/// Các kiểu chữ số tiền (DESIGN.md › Typography › Money).
enum MoneyStyle {
  /// Số "được tiêu" lớn trong status hero.
  hero,

  /// Một số tiền làm tiêu đề bảng trượt.
  large,

  /// Chữ trong ô nhập tiền.
  input,

  /// Số tiền cuối hàng trong danh sách (cột thẳng hàng).
  list,

  /// Số tiền trong câu bodyLarge.
  body,

  /// Số tiền trong chú thích, chú giải, dòng tiến độ.
  inline,
}

/// Cách đặt chữ số. Font không có `tnum`, nên "ô cố định" do MoneyText tự dàn.
enum DigitMode {
  proportional,

  /// Luôn trong ô cố định (cột số tiền trong danh sách).
  fixedCells,

  /// Tỉ lệ khi đứng yên, ô cố định khi đang đếm (hero).
  fixedCellsWhileCounting,
}

/// Một kiểu số tiền: chữ số, đơn vị "đ", cách đặt chữ số.
@immutable
class MoneyStyleSpec {
  const MoneyStyleSpec({required this.numeral, required this.unit, required this.digits, this.maxTextScale});

  final TextStyle numeral;
  final TextStyle unit;
  final DigitMode digits;

  /// Giới hạn phóng chữ (hero: 1.3), `null` = theo cài đặt hệ thống.
  final double? maxTextScale;

  /// Chữ số nằm trong ô cố định khi không đếm.
  bool get cellsAtRest => digits == DigitMode.fixedCells;

  MoneyStyleSpec lerpTo(MoneyStyleSpec other, double t) => MoneyStyleSpec(
    numeral: TextStyle.lerp(numeral, other.numeral, t)!,
    unit: TextStyle.lerp(unit, other.unit, t)!,
    digits: t < 0.5 ? digits : other.digits,
    maxTextScale: t < 0.5 ? maxTextScale : other.maxTextScale,
  );
}

TextStyle _money(double size, FontWeight weight, double height, double tracking) => TextStyle(
  fontFamily: appFontFamily,
  fontSize: size,
  fontWeight: weight,
  height: height,
  letterSpacing: tracking,
  leadingDistribution: TextLeadingDistribution.even,
);

/// Kiểu chữ số tiền của theme (`Theme.of(context).extension<MoneyStyles>()`).
@immutable
class MoneyStyles extends ThemeExtension<MoneyStyles> {
  const MoneyStyles({
    required this.hero,
    required this.large,
    required this.input,
    required this.list,
    required this.body,
    required this.inline,
    required this.digitCellEm,
  });

  final MoneyStyleSpec hero;
  final MoneyStyleSpec large;
  final MoneyStyleSpec input;
  final MoneyStyleSpec list;
  final MoneyStyleSpec body;
  final MoneyStyleSpec inline;

  /// Bề rộng ô chữ số (em) theo độ đậm = chữ số rộng nhất của Be Vietnam Pro ở độ đậm đó.
  final Map<int, double> digitCellEm;

  static final MoneyStyles standard = MoneyStyles(
    hero: MoneyStyleSpec(
      numeral: _money(44, FontWeight.w800, 1.08, -0.9),
      unit: _money(26, FontWeight.w700, 1.08, -0.9),
      digits: DigitMode.fixedCellsWhileCounting,
      maxTextScale: 1.3,
    ),
    large: MoneyStyleSpec(
      numeral: _money(28, FontWeight.w800, 1.15, -0.4),
      unit: _money(18, FontWeight.w700, 1.15, -0.4),
      digits: DigitMode.proportional,
    ),
    input: MoneyStyleSpec(
      numeral: _money(28, FontWeight.w800, 1.15, -0.4),
      unit: _money(18, FontWeight.w700, 1.15, -0.4),
      digits: DigitMode.proportional,
    ),
    list: MoneyStyleSpec(
      numeral: _money(16, FontWeight.w700, 1.35, 0.0),
      unit: _money(16, FontWeight.w700, 1.35, 0.0),
      digits: DigitMode.fixedCells,
    ),
    body: MoneyStyleSpec(
      numeral: _money(16, FontWeight.w700, 1.5, 0.1),
      unit: _money(16, FontWeight.w700, 1.5, 0.1),
      digits: DigitMode.proportional,
    ),
    inline: MoneyStyleSpec(
      numeral: _money(14, FontWeight.w600, 1.43, 0.0),
      unit: _money(14, FontWeight.w600, 1.43, 0.0),
      digits: DigitMode.proportional,
    ),
    digitCellEm: const {400: 0.71, 500: 0.713, 600: 0.716, 700: 0.72, 800: 0.723},
  );

  static MoneyStyles of(BuildContext context) => Theme.of(context).extension<MoneyStyles>() ?? standard;

  MoneyStyleSpec spec(MoneyStyle style) => switch (style) {
    MoneyStyle.hero => hero,
    MoneyStyle.large => large,
    MoneyStyle.input => input,
    MoneyStyle.list => list,
    MoneyStyle.body => body,
    MoneyStyle.inline => inline,
  };

  /// Ô chữ số (em) cho [weight]; độ đậm không có trong bảng lấy giá trị gần nhất.
  double cellEmFor(FontWeight? weight) {
    final w = (weight ?? FontWeight.w400).value;
    final exact = digitCellEm[w];
    if (exact != null) return exact;
    final keys = digitCellEm.keys.toList()..sort((a, b) => (a - w).abs().compareTo((b - w).abs()));
    return keys.isEmpty ? 0.72 : digitCellEm[keys.first]!;
  }

  @override
  MoneyStyles copyWith({
    MoneyStyleSpec? hero,
    MoneyStyleSpec? large,
    MoneyStyleSpec? input,
    MoneyStyleSpec? list,
    MoneyStyleSpec? body,
    MoneyStyleSpec? inline,
    Map<int, double>? digitCellEm,
  }) => MoneyStyles(
    hero: hero ?? this.hero,
    large: large ?? this.large,
    input: input ?? this.input,
    list: list ?? this.list,
    body: body ?? this.body,
    inline: inline ?? this.inline,
    digitCellEm: digitCellEm ?? this.digitCellEm,
  );

  @override
  MoneyStyles lerp(covariant MoneyStyles? other, double t) {
    if (other == null) return this;
    return MoneyStyles(
      hero: hero.lerpTo(other.hero, t),
      large: large.lerpTo(other.large, t),
      input: input.lerpTo(other.input, t),
      list: list.lerpTo(other.list, t),
      body: body.lerpTo(other.body, t),
      inline: inline.lerpTo(other.inline, t),
      digitCellEm: t < 0.5 ? digitCellEm : other.digitCellEm,
    );
  }
}
