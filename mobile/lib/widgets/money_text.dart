import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/status_colors.dart';
import '../theme/typography.dart';
import '../utils/currency.dart';

/// Dấu trước số tiền.
enum MoneySign {
  /// Âm thì "−" (U+2212), còn lại không dấu (số dư, được tiêu, mức sàn).
  natural,

  /// Luôn "−" (khoản chi).
  outgoing,

  /// Luôn "+" (khoản thu).
  incoming,

  /// Dương "+", âm "−", 0 không dấu.
  explicit,
}

/// Màu số tiền theo ý nghĩa (DESIGN.md › Money › Signed colours).
enum MoneyTone {
  /// Màu chữ đang dùng (DefaultTextStyle), vd. chữ trong status hero.
  inherit,

  /// Khoản chi: `onSurface` (chi tiêu không phải lỗi, không tô đỏ).
  outgoing,

  /// Khoản thu: `StatusColors.ok.foreground`.
  incoming,

  /// Chuyển nội bộ giữa các TK của mình: `onSurfaceVariant`.
  transfer,

  /// Đã loại trừ: `onSurfaceVariant`, gạch ngang.
  excluded,

  /// Đang chờ khớp: `onSurfaceVariant`.
  pending,
}

/// Dấu trừ thật (U+2212), không phải gạch nối.
const String minusSign = '−';

/// Đơn vị tiền, viết liền sau số.
const String vndUnit = 'đ';

/// Các phần của một số tiền đã định dạng: "~", dấu, "4.000.000", "đ".
@immutable
class MoneyParts {
  const MoneyParts({required this.amount, this.sign = '', required this.digits, this.estimate = false});

  factory MoneyParts.of(int amount, {MoneySign sign = MoneySign.natural, bool estimate = false}) {
    final abs = amount.abs();
    final s = switch (sign) {
      MoneySign.natural => amount < 0 ? minusSign : '',
      MoneySign.outgoing => abs == 0 ? '' : minusSign,
      MoneySign.incoming => abs == 0 ? '' : '+',
      MoneySign.explicit => amount < 0 ? minusSign : (amount > 0 ? '+' : ''),
    };
    return MoneyParts(amount: amount, sign: s, digits: formatGrouped(abs), estimate: estimate);
  }

  final int amount;

  /// "", "−" hoặc "+".
  final String sign;

  /// Phần số có dấu chấm nhóm nghìn, không dấu: "4.000.000".
  final String digits;

  /// Số ước tính của máy chủ (dự báo): thêm "~" phía trước.
  final bool estimate;

  String get leading => '${estimate ? '~' : ''}$sign';

  /// "~−4.000.000đ".
  String get text => '$leading$digits$vndUnit';

  /// Nhãn đọc màn hình: chữ số liền (không dấu chấm) + "đồng", "âm"/"cộng" khi có dấu.
  /// TalkBack đọc "bốn triệu đồng" thay vì "4 chấm 000".
  String get semanticsLabel {
    final value = amount.abs();
    final signWord = sign == minusSign ? 'âm ' : (sign == '+' ? 'cộng ' : '');
    return '${estimate ? 'khoảng ' : ''}$signWord$value đồng';
  }
}

/// Nhãn đọc màn hình của một số tiền (dùng trong câu / nhãn semantics ghép).
String spokenVnd(int amount, {MoneySign sign = MoneySign.natural}) => MoneyParts.of(amount, sign: sign).semanticsLabel;

/// Dựng chuỗi chữ cho số tiền: chữ số tỉ lệ, hoặc trong ô cố định (font không có `tnum`).
///
/// Ô cố định: mỗi chữ số nằm giữa một ô rộng bằng chữ số rộng nhất ở độ đậm đó (design.json ›
/// tabularFigures.digitCellEm), dấu "." và dấu "−"/"+" giữ bề rộng tự nhiên. Cách làm: đo bề rộng tự nhiên
/// từng ký tự rồi đặt `letterSpacing` riêng cho từng ký tự (khoảng trống sau ký tự này + nửa ô trước ký tự
/// sau), nên vẫn là một đoạn văn bản duy nhất (cùng đường chân chữ, gạch ngang liền mạch, chữ thuần đúng
/// "4.000.000đ"). Nửa ô trước ký tự đầu tiên trả về riêng ([MoneySpanLayout.leading]) để đặt bằng lề.
abstract final class MoneySpans {
  static final Map<String, double> _advances = {};
  static bool _listening = false;

  static void _ensureListening() {
    if (_listening) return;
    _listening = true;
    // Font nạp xong / đổi font hệ thống: số đo cũ không còn đúng.
    PaintingBinding.instance.systemFonts.addListener(_advances.clear);
  }

  /// Bề rộng tự nhiên (không letterSpacing) của ký tự [char] với [style] ở cỡ đã phóng.
  static double advance(String char, TextStyle style, TextScaler scaler) {
    _ensureListening();
    final size = scaler.scale(style.fontSize ?? 14);
    final key = '${style.fontFamily}|${style.fontWeight?.value}|${size.toStringAsFixed(3)}|$char';
    return _advances[key] ??= _measure(char, style);
  }

  static double _measure(String char, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: char, style: style.copyWith(letterSpacing: 0)),
      textDirection: TextDirection.ltr,
      // Đo ở cỡ đã phóng: style.fontSize đã được nhân trước khi gọi (xem [build]).
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  static bool _isDigit(String c) => c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

  /// Dấu "−" (U+2212) của Be Vietnam Pro có lề phải rộng (advance 661, xMax 545 / 1000) cộng lề trái của chữ số:
  /// khoảng hở ≈ 0,18 em trông như dấu bị tách khỏi số. Kéo chữ số lại gần 0,1 em.
  static const double minusTightenEm = 0.1;

  /// Phần đầu (dấu ước tính "~", dấu "−"/"+") thành các span; dấu "−" có letterSpacing âm ([minusTightenEm]).
  /// [fontSizePx]: cỡ chữ thật trên màn hình (đã phóng), [tracking]: letterSpacing đang dùng.
  static List<InlineSpan> leadingSpans(String leading, {required double fontSizePx, double tracking = 0}) {
    if (leading.isEmpty) return const [];
    final i = leading.indexOf(minusSign);
    if (i < 0) return [TextSpan(text: leading)];
    return [
      if (i > 0) TextSpan(text: leading.substring(0, i)),
      TextSpan(
        text: minusSign,
        style: TextStyle(letterSpacing: tracking - minusTightenEm * fontSizePx),
      ),
      if (i + 1 < leading.length) TextSpan(text: leading.substring(i + 1)),
    ];
  }

  /// Chuỗi chữ của [parts]. [cellEm]: bề rộng ô (em) theo độ đậm; `null` = chữ số tỉ lệ.
  static MoneySpanLayout build({
    required MoneyParts parts,
    required TextStyle numeral,
    required TextStyle unit,
    required TextScaler scaler,
    double? cellEm,
  }) {
    final unitSpan = TextSpan(text: vndUnit, style: unit);
    final body = '${parts.leading}${parts.digits}';
    if (cellEm == null) {
      return MoneySpanLayout(
        TextSpan(
          style: numeral,
          children: [
            ...leadingSpans(
              parts.leading,
              fontSizePx: scaler.scale(numeral.fontSize ?? 14),
              tracking: numeral.letterSpacing ?? 0,
            ),
            TextSpan(text: parts.digits),
            unitSpan,
          ],
        ),
      );
    }
    // Tắt kerning: các chữ số giống nhau liền nhau có cùng kiểu nên được ghép một run, và cặp "11" của font
    // sẽ kéo chúng lại gần nhau, phá ô cố định.
    numeral = numeral.copyWith(fontFeatures: [...?numeral.fontFeatures, const FontFeature.disable('kern')]);
    // Đo ở cỡ thật trên màn hình (đã phóng chữ); letterSpacing tính bằng dp, không bị phóng thêm.
    final scaledSize = scaler.scale(numeral.fontSize ?? 14);
    final measureStyle = numeral.copyWith(fontSize: scaledSize, letterSpacing: 0);
    double adv(String c) => advance(c, measureStyle, TextScaler.noScaling);
    final tracking = numeral.letterSpacing ?? 0;
    var cell = cellEm * scaledSize;
    for (var d = 0; d <= 9; d++) {
      final a = adv('$d');
      if (a > cell) cell = a; // font dự phòng có chữ số rộng hơn: ô phải chứa được chữ số.
    }
    final chars = body.split('');
    double lead(int i) => i < chars.length && _isDigit(chars[i]) ? (cell - adv(chars[i])) / 2 : 0;
    final children = <InlineSpan>[];
    for (var i = 0; i < chars.length; i++) {
      final c = chars[i];
      final trail = _isDigit(c)
          ? (cell - adv(c)) / 2
          : c == minusSign
          ? tracking - minusTightenEm * scaledSize
          : tracking;
      children.add(
        TextSpan(
          text: c,
          style: TextStyle(letterSpacing: trail + lead(i + 1)),
        ),
      );
    }
    children.add(unitSpan);
    return MoneySpanLayout(
      TextSpan(style: numeral, children: children),
      leading: lead(0),
    );
  }
}

/// Kết quả dựng chữ số tiền: [span] và khoảng lề đầu [leading] (nửa ô trước chữ số đầu tiên, 0 nếu tỉ lệ).
@immutable
class MoneySpanLayout {
  const MoneySpanLayout(this.span, {this.leading = 0});

  final TextSpan span;
  final double leading;
}

/// Màu của [tone] theo theme; `null` = giữ màu chữ đang dùng.
Color? moneyToneColor(BuildContext context, MoneyTone tone) {
  final scheme = Theme.of(context).colorScheme;
  return switch (tone) {
    MoneyTone.inherit => null,
    MoneyTone.outgoing => scheme.onSurface,
    MoneyTone.incoming => StatusColors.of(context).ok.foreground,
    MoneyTone.transfer || MoneyTone.excluded || MoneyTone.pending => scheme.onSurfaceVariant,
  };
}

/// Một số tiền theo kiểu chữ tiền của theme (DESIGN.md › Typography › Money).
///
/// - Định dạng đủ chữ số, "." nhóm nghìn, "đ" liền sau (nhỏ hơn ở [MoneyStyle.hero] / [MoneyStyle.large]);
///   âm và khoản chi dùng "−" (U+2212), khoản thu "+".
/// - [MoneyStyle.list] luôn đặt chữ số trong ô cố định để cột số tiền thẳng hàng; các kiểu khác tỉ lệ
///   (hero chỉ dùng ô khi đang đếm: [cells] = `true`).
/// - Đọc màn hình: một nhãn "4000000 đồng" ("âm …", "cộng …"), không đọc từng ký tự.
/// - Không xuống dòng: chỗ đặt số tiền phải đủ rộng (MoneyRow tự xếp dòng khi chữ lớn, hero co bằng FittedBox).
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.style = MoneyStyle.body,
    this.sign = MoneySign.natural,
    this.tone = MoneyTone.inherit,
    this.color,
    this.cells,
    this.estimate = false,
    this.textAlign,
  });

  final int amount;
  final MoneyStyle style;
  final MoneySign sign;
  final MoneyTone tone;

  /// Ghi đè màu (vd. màu chữ của hero); mặc định theo [tone].
  final Color? color;

  /// Ghi đè cách đặt chữ số: `true` = ô cố định, `false` = tỉ lệ, `null` = theo kiểu chữ.
  final bool? cells;

  /// Số ước tính của máy chủ ("~").
  final bool estimate;
  final TextAlign? textAlign;

  MoneyParts get parts => MoneyParts.of(amount, sign: sign, estimate: estimate);

  /// Bộ phóng chữ thực dùng cho [style] (hero không phóng quá 1,3×).
  static TextScaler textScalerFor(BuildContext context, MoneyStyle style) {
    final spec = MoneyStyles.of(context).spec(style);
    final scaler = MediaQuery.textScalerOf(context);
    final max = spec.maxTextScale;
    return max == null ? scaler : scaler.clamp(maxScaleFactor: max);
  }

  /// Chuỗi chữ của số tiền với màu [color] (dùng chung cho widget và đo bề rộng).
  static MoneySpanLayout buildSpan(
    BuildContext context,
    MoneyParts parts, {
    required MoneyStyle style,
    Color? color,
    bool? cells,
    bool strike = false,
  }) {
    final styles = MoneyStyles.of(context);
    final spec = styles.spec(style);
    final decoration = strike ? TextDecoration.lineThrough : null;
    final numeral = spec.numeral.copyWith(color: color, decoration: decoration, decorationColor: color);
    final unit = spec.unit.copyWith(color: color, decoration: decoration, decorationColor: color);
    final useCells = cells ?? spec.cellsAtRest;
    return MoneySpans.build(
      parts: parts,
      numeral: numeral,
      unit: unit,
      scaler: textScalerFor(context, style),
      cellEm: useCells ? styles.cellEmFor(spec.numeral.fontWeight) : null,
    );
  }

  /// Bề rộng (dp) số tiền chiếm khi vẽ ở [style] trong [context] (đã tính phóng chữ).
  static double measureWidth(
    BuildContext context,
    int amount, {
    MoneyStyle style = MoneyStyle.body,
    MoneySign sign = MoneySign.natural,
    bool? cells,
    bool estimate = false,
  }) {
    final layout = buildSpan(
      context,
      MoneyParts.of(amount, sign: sign, estimate: estimate),
      style: style,
      cells: cells,
    );
    final painter = TextPainter(
      text: layout.span,
      textDirection: TextDirection.ltr,
      textScaler: textScalerFor(context, style),
      maxLines: 1,
    )..layout();
    final width = painter.width + layout.leading;
    painter.dispose();
    return width;
  }

  /// Số tiền nằm trong một câu (`Text.rich`): chữ số tỉ lệ. Chỉ phần hiển thị: câu chứa nó cần nhãn đọc màn
  /// hình riêng, dùng [MoneySentence] thay vì tự ghép.
  static TextSpan inlineSpan(
    BuildContext context,
    MoneyParts parts, {
    MoneyStyle style = MoneyStyle.inline,
    MoneyTone tone = MoneyTone.inherit,
    Color? color,
  }) {
    final spec = MoneyStyles.of(context).spec(style);
    final c = color ?? moneyToneColor(context, tone);
    return TextSpan(
      style: spec.numeral.copyWith(color: c),
      children: [
        ...MoneySpans.leadingSpans(
          parts.leading,
          fontSizePx: MediaQuery.textScalerOf(context).scale(spec.numeral.fontSize ?? 14),
          tracking: spec.numeral.letterSpacing ?? 0,
        ),
        TextSpan(text: parts.digits),
        TextSpan(
          text: vndUnit,
          style: spec.unit.copyWith(color: c),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? moneyToneColor(context, tone) ?? DefaultTextStyle.of(context).style.color;
    final p = parts;
    final layout = buildSpan(
      context,
      p,
      style: style,
      color: effectiveColor,
      cells: cells,
      strike: tone == MoneyTone.excluded,
    );
    Widget text = Text.rich(
      layout.span,
      textScaler: textScalerFor(context, style),
      textAlign: textAlign,
      maxLines: 1,
      softWrap: false,
    );
    if (layout.leading > 0) {
      text = Padding(
        padding: EdgeInsetsDirectional.only(start: layout.leading),
        child: text,
      );
    }
    return Semantics(label: p.semanticsLabel, excludeSemantics: true, child: text);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('amount', amount))
      ..add(EnumProperty<MoneyStyle>('style', style))
      ..add(EnumProperty<MoneySign>('sign', sign));
  }
}

/// Một câu có số tiền xen giữa ("Đang chuyển giữa các TK: 2.000.000đ").
///
/// [segments]: `String` (chữ thường), `int` (số tiền, dấu tự nhiên) hoặc [MoneyParts] (có dấu / "~").
/// Số tiền vẽ theo [moneyStyle] (mặc định `moneyInline`), chữ số tỉ lệ; trình đọc màn hình đọc cả câu với
/// số tiền thành "… đồng".
class MoneySentence extends StatelessWidget {
  const MoneySentence(
    this.segments, {
    super.key,
    this.style,
    this.moneyStyle = MoneyStyle.inline,
    this.moneyColor,
    this.textAlign,
  });

  final List<Object> segments;
  final TextStyle? style;
  final MoneyStyle moneyStyle;

  /// Màu số tiền; mặc định cùng màu chữ của câu.
  final Color? moneyColor;
  final TextAlign? textAlign;

  static MoneyParts? _parts(Object s) => switch (s) {
    final MoneyParts p => p,
    final int v => MoneyParts.of(v),
    _ => null,
  };

  /// Câu đọc màn hình: số tiền thành "… đồng".
  static String spoken(List<Object> segments) => segments.map((s) => _parts(s)?.semanticsLabel ?? s.toString()).join();

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final color = moneyColor ?? base.color;
    return Semantics(
      label: spoken(segments),
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            for (final s in segments)
              if (_parts(s) case final p?)
                MoneyText.inlineSpan(context, p, style: moneyStyle, color: color)
              else
                TextSpan(text: s.toString()),
          ],
        ),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
