import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models/level.dart';
import '../models/summary.dart';
import '../theme/status_colors.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../utils/dates.dart';
import 'first_line_icon.dart';
import 'floor_ruler.dart';
import 'money_text.dart';

/// Số dư cũ hơn ngưỡng này thì dòng cập nhật đổi thành "Số dư chưa cập nhật N ngày".
const Duration heroStaleAfter = Duration(hours: 48);

/// Số liệu status hero cần (lấy từ GET /api/summary bằng [StatusHeroData.fromSummary]).
@immutable
class StatusHeroData {
  const StatusHeroData({
    required this.level,
    this.free,
    this.balance,
    this.floor = 0,
    this.buffer = 0,
    this.daysLeft,
    this.waitingIncome = false,
    this.salaryDay,
    this.pendingSalary = 0,
    this.inTransit = 0,
    this.balanceDerived = false,
    this.balanceAsOf,
    this.offline = false,
    this.dataLoadedAt,
    this.missingBalanceAccount,
  });

  factory StatusHeroData.fromSummary(Summary s, {bool offline = false, DateTime? dataLoadedAt}) {
    final missing = s.accountsMissingBalance;
    return StatusHeroData(
      level: s.level,
      free: s.free,
      balance: s.balanceKnown ? s.balance : null,
      floor: s.floor,
      buffer: s.buffer,
      daysLeft: s.daysLeft,
      waitingIncome: s.waitingIncome,
      salaryDay: s.expectedIncome?.day,
      pendingSalary: s.expectedIncome?.pending ?? 0,
      inTransit: s.inTransit,
      balanceDerived: s.anyBalanceDerived,
      balanceAsOf: s.balanceAsOf,
      offline: offline,
      dataLoadedAt: dataLoadedAt,
      missingBalanceAccount: missing.isEmpty ? null : missing.first.displayName,
    );
  }

  final Level level;

  /// Được tiêu = số dư − mức sàn; âm khi đã lấn vào tiền mục tiêu.
  final int? free;
  final int? balance;
  final int floor;
  final int buffer;
  final int? daysLeft;

  /// WARNING vì đang chờ lương (số dư có thể dưới mức sàn).
  final bool waitingIncome;

  /// Ngày nhận lương dự kiến trong tháng.
  final int? salaryDay;

  /// Lương dự kiến chưa về (đồng).
  final int pendingSalary;
  final int inTransit;

  /// Có TK tính vào tổng đang dùng số dư ước tính.
  final bool balanceDerived;
  final DateTime? balanceAsOf;

  /// Lần tải gần nhất thất bại, đang hiện số liệu cũ.
  final bool offline;

  /// Thời điểm tải được số liệu đang hiện (dùng cho dòng "Đang offline · số liệu lúc …").
  final DateTime? dataLoadedAt;

  /// TK đầu tiên được tính vào tổng nhưng chưa có số dư ("Vietcombank · …1234"); `null` = chưa có TK nào.
  final String? missingBalanceAccount;

  /// Có đủ số liệu để vẽ số "được tiêu" và thước.
  bool get known =>
      free != null && balance != null && (level == Level.ok || level == Level.warning || level == Level.danger);

  /// Mức hiển thị: thiếu số liệu thì là UNKNOWN.
  Level get displayLevel => known ? level : Level.unknown;

  RulerGeometry? get geometry => known ? RulerGeometry.compute(balance: balance!, floor: floor, buffer: buffer) : null;
}

/// Status hero: vật thể đầu tiên của Tổng quan, men đổi màu theo trạng thái tiền (DESIGN.md › Status hero).
///
/// Từ trên xuống: tiêu đề trạng thái (icon + `Level.label`), số "được tiêu" (`moneyHero`), dòng ý nghĩa,
/// thước mức sàn, chú giải hai hàng, dòng ngữ cảnh (chỉ khi đúng), dòng cập nhật. UNKNOWN: tiêu đề, một câu
/// hướng dẫn và nút "Nhập số dư" / "Thêm tài khoản" ([onUnknownAction]).
///
/// Chuyển động được dàn dựng duy nhất của app: khi số "được tiêu" hoặc mức đổi (không bao giờ ở lần vẽ đầu),
/// men chuyển màu 450 ms, số đếm 550 ms trong ô cố định rồi mờ chuyển sang chữ số tỉ lệ 150 ms, thước co giãn
/// 500 ms; riêng khi đổi mức thì tiêu đề cũ bay lên mờ đi, tiêu đề mới hiện lên và trình đọc màn hình được báo
/// "Trạng thái: …". Tổng ≤ 700 ms. "Xoá hiệu ứng động": chỉ đổi màu 150 ms, còn lại đổi ngay.
class StatusHero extends StatefulWidget {
  const StatusHero({super.key, required this.data, this.now, this.onUnknownAction});

  final StatusHeroData data;

  /// Giờ hiện tại (test truyền vào); mặc định `DateTime.now()`.
  final DateTime? now;

  /// UNKNOWN: mở bảng "Nhập số dư" (có TK chưa có số dư) hoặc "Thêm tài khoản". `null` = ẩn nút.
  final VoidCallback? onUnknownAction;

  /// Câu báo cho trình đọc màn hình khi đổi mức.
  static String announcementFor(StatusHeroData data) {
    final level = data.displayLevel;
    if (!data.known) return 'Trạng thái: ${level.label}.';
    return 'Trạng thái: ${level.label}. Được tiêu ${spokenVnd(data.free!)}.';
  }

  /// Dòng ý nghĩa dưới số (chữ thuần, dùng cho test và nhãn).
  static String meaningText(StatusHeroData data) {
    final days = data.daysLeft == null ? '' : ' · còn ${data.daysLeft} ngày';
    return switch (data.displayLevel) {
      Level.warning when data.waitingIncome =>
        'đang chờ lương${(data.salaryDay ?? 0) > 0 ? ' ngày ${data.salaryDay}' : ''} · lương về sẽ đủ',
      Level.warning => 'dưới vùng đệm ${MoneyParts.of(data.buffer).text}$days',
      Level.danger => 'đã lấn vào tiền mục tiêu$days',
      _ => 'được tiêu thoải mái$days',
    };
  }

  @override
  State<StatusHero> createState() => _StatusHeroState();
}

class _StatusHeroState extends State<StatusHero> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, value: 1, duration: StatusMotion.total);

  // Trạng thái đang hiện ngay trước lần đổi gần nhất (điểm bắt đầu của chuyển động).
  StatusHeroData? _fromData;
  LevelColors? _fromColors;
  double? _fromFree;
  RulerGeometry? _fromGeometry;
  Level? _fromLevel;
  bool _levelChanged = false;
  bool _reduced = false;

  /// MediaQuery.disableAnimations ở lần build gần nhất.
  bool _reduceMotion = false;

  static double _frac(Duration d) => d.inMicroseconds / StatusMotion.total.inMicroseconds;

  static final Interval _colorInterval = Interval(0, _frac(StatusMotion.heroColor), curve: StatusMotion.heroColorCurve);
  static final Interval _countInterval = Interval(
    0,
    _frac(StatusMotion.numeralCount),
    curve: StatusMotion.numeralCountCurve,
  );
  static final Interval _settleInterval = Interval(
    _frac(StatusMotion.numeralSettleDelay),
    _frac(StatusMotion.numeralSettleDelay + StatusMotion.numeralSettle),
    curve: StatusMotion.numeralSettleCurve,
  );
  static final Interval _rulerInterval = Interval(
    0,
    _frac(StatusMotion.floorRuler),
    curve: StatusMotion.floorRulerCurve,
  );
  static final Interval _fadeInterval = Interval(0, _frac(StatusMotion.rulerFade));
  static final Interval _headingExit = Interval(
    0,
    _frac(StatusMotion.headingExit),
    curve: StatusMotion.headingExitCurve,
  );
  static final Interval _headingEnter = Interval(
    _frac(StatusMotion.headingEnterDelay),
    _frac(StatusMotion.headingEnterDelay + StatusMotion.headingEnter),
    curve: StatusMotion.headingEnterCurve,
  );

  bool get _animating => _controller.value < 1 && _fromColors != null;

  LevelColors _colorsFor(Level level) => StatusColors.of(context).forLevel(level, Theme.of(context).colorScheme);

  double _t(Interval interval) => _reduced ? 1 : interval.transform(_controller.value);

  double get _colorT => _reduced
      ? StatusMotion.reduceMotionColorCurve.transform(_controller.value)
      : _colorInterval.transform(_controller.value);

  /// Màu đang hiện khi đích là [target].
  LevelColors _currentColors(StatusHeroData target) {
    final to = _colorsFor(target.displayLevel);
    final from = _fromColors;
    if (!_animating || from == null) return to;
    return LevelColors.lerp(from, to, _colorT);
  }

  double? _currentFree(StatusHeroData target) {
    final to = target.known ? target.free!.toDouble() : null;
    final from = _fromFree;
    if (!_animating || from == null || to == null) return to;
    return lerpDouble(from, to, _t(_countInterval));
  }

  RulerGeometry? _currentGeometry(StatusHeroData target) {
    final to = target.geometry;
    final from = _fromGeometry;
    if (!_animating || from == null || to == null) return to;
    return RulerGeometry.lerp(from, to, _t(_rulerInterval));
  }

  @override
  void didUpdateWidget(StatusHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.data;
    final after = widget.data;
    final levelChanged = before.displayLevel != after.displayLevel;
    final freeChanged = before.free != after.free || before.known != after.known;
    if (!levelChanged && !freeChanged) return;
    // Bắt đầu từ đúng thứ đang hiện (kể cả khi chuyển động trước chưa xong).
    _fromColors = _currentColors(before);
    _fromFree = _currentFree(before);
    _fromGeometry = _currentGeometry(before);
    _fromData = before;
    _fromLevel = before.displayLevel;
    _levelChanged = levelChanged;
    _reduced = _reduceMotion;
    _controller
      ..duration = _reduced ? StatusMotion.reduceMotionColor : StatusMotion.total
      ..forward(from: 0);
    if (levelChanged) _announce(after);
  }

  void _announce(StatusHeroData data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !MediaQuery.supportsAnnounceOf(context)) return;
      // Nền tảng không hỗ trợ thông báo (Android mới): tiêu đề là live region, đổi chữ thì tự được đọc.
      SemanticsService.sendAnnouncement(View.of(context), StatusHero.announcementFor(data), Directionality.of(context));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    final liveRegion = !MediaQuery.supportsAnnounceOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final data = widget.data;
        final colors = _currentColors(data);
        // Vào UNKNOWN: 150 ms đầu vẫn hiện bố cục cũ để thước kịp mờ đi.
        final fadeT = _t(_fadeInterval);
        final from = _fromData;
        final leavingKnown = _animating && !_reduced && !data.known && from != null && from.known && fadeT < 1;
        final enteringKnown = _animating && !_reduced && data.known && from != null && !from.known;
        final layoutData = leavingKnown ? from : data;
        final rulerOpacity = leavingKnown ? 1 - fadeT : (enteringKnown ? fadeT : 1.0);

        final fg = colors.heroForeground;
        final theme = Theme.of(context);
        final children = <Widget>[
          _heading(layoutData.displayLevel, fg, liveRegion),
          if (layoutData.known)
            ..._knownBody(layoutData, colors, rulerOpacity, theme)
          else
            ..._unknownBody(layoutData, theme),
        ];
        // Mỗi phần của hero là một nút đọc màn hình riêng (tiêu đề, số, ý nghĩa, thước, từng hàng chú giải).
        return Semantics(
          container: true,
          explicitChildNodes: true,
          child: DecoratedBox(
            key: const Key('status_hero'),
            decoration: BoxDecoration(color: colors.heroBackground, borderRadius: BorderRadius.circular(Radii.xl)),
            child: Padding(
              padding: const EdgeInsets.all(HeroSpace.padding),
              child: IconTheme.merge(
                data: IconThemeData(color: fg),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: fg),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _headingRow(Level level, Color fg) {
    final style = Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700, color: fg);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FirstLineIcon(level.icon, size: 24, textStyle: style),
        const SizedBox(width: Space.s2),
        Expanded(child: Text(level.label, style: style)),
      ],
    );
  }

  Widget _heading(Level level, Color fg, bool liveRegion) {
    // Cùng một cấu trúc ở mọi trạng thái: nút semantics của tiêu đề (live region) giữ nguyên danh tính,
    // nên khi đổi mức chỉ nhãn của nó đổi và Android đọc nhãn mới.
    final current = Semantics(container: true, header: true, liveRegion: liveRegion, child: _headingRow(level, fg));
    final previous = _fromLevel;
    final animate = _animating && !_reduced && _levelChanged && previous != null && previous != level;
    final exitT = animate ? _t(_headingExit) : 1.0;
    final enterT = animate ? _t(_headingEnter) : 1.0;
    const offset = StatusMotion.headingOffset;
    return Stack(
      key: const Key('status_hero_heading'),
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: enterT,
          alwaysIncludeSemantics: true,
          child: Transform.translate(offset: Offset(0, offset * (1 - enterT)), child: current),
        ),
        if (exitT < 1)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ExcludeSemantics(
              child: Opacity(
                opacity: 1 - exitT,
                child: Transform.translate(offset: Offset(0, -offset * exitT), child: _headingRow(previous!, fg)),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _knownBody(StatusHeroData data, LevelColors colors, double rulerOpacity, ThemeData theme) {
    final fg = colors.heroForeground;
    final text = theme.textTheme;
    final small = text.bodySmall!.copyWith(color: fg);
    final now = widget.now ?? DateTime.now();
    final geometry = _currentGeometry(data) ?? data.geometry!;
    final contextLines = <Widget>[
      if (data.inTransit > 0) MoneySentence(['Đang chuyển giữa các TK: ', data.inTransit], style: small),
      if (data.pendingSalary > 0 && !data.waitingIncome)
        MoneySentence([
          'Lương dự kiến chưa về: ',
          data.pendingSalary,
          if ((data.salaryDay ?? 0) > 0) ' (ngày ${data.salaryDay})',
        ], style: small),
    ];
    final freshness = _freshnessLines(data, now, small);
    return [
      const SizedBox(height: HeroSpace.headingToNumeral),
      _numeral(data, fg),
      const SizedBox(height: HeroSpace.numeralToMeaning),
      _meaning(data, text.titleSmall!.copyWith(color: fg)),
      const SizedBox(height: HeroSpace.meaningToRuler),
      FloorRuler(
        key: const Key('floor_ruler'),
        geometry: geometry,
        colors: colors,
        opacity: rulerOpacity,
        semanticLabel: FloorRuler.describe(
          balance: data.balance!,
          floor: data.floor,
          free: data.free!,
          buffer: data.buffer,
        ),
      ),
      const SizedBox(height: HeroSpace.rulerToLegend),
      _LegendRow(label: 'Giữ cho mục tiêu', amount: data.floor, color: fg),
      const SizedBox(height: HeroSpace.legendRowGap),
      _LegendRow(
        label: data.balanceDerived ? 'Số dư · ước tính' : 'Số dư',
        amount: data.balance!,
        color: fg,
        amountKey: const Key('total_balance'),
      ),
      if (contextLines.isNotEmpty) ...[
        const SizedBox(height: HeroSpace.blockGap),
        for (var i = 0; i < contextLines.length; i++) ...[
          if (i > 0) const SizedBox(height: HeroSpace.lineGap),
          contextLines[i],
        ],
      ],
      if (freshness.isNotEmpty) ...[
        const SizedBox(height: HeroSpace.blockGap),
        for (var i = 0; i < freshness.length; i++) ...[
          if (i > 0) const SizedBox(height: HeroSpace.lineGap),
          freshness[i],
        ],
      ],
    ];
  }

  List<Widget> _freshnessLines(StatusHeroData data, DateTime now, TextStyle small) {
    final asOf = data.balanceAsOf;
    final lines = <Widget>[];
    if (asOf != null) {
      final age = now.difference(asOf);
      if (age > heroStaleAfter) {
        lines.add(
          _IconLine(
            key: const Key('balance_as_of'),
            icon: Icons.schedule,
            text: 'Số dư chưa cập nhật ${age.inDays} ngày',
            style: small.copyWith(fontWeight: FontWeight.w600),
          ),
        );
      } else {
        lines.add(
          Text('Cập nhật lúc ${formatTimeOrDateIct(asOf, now)}', key: const Key('balance_as_of'), style: small),
        );
      }
    }
    if (data.offline) {
      final at = data.dataLoadedAt ?? asOf;
      lines.add(
        _IconLine(
          icon: Icons.cloud_off,
          text: at == null ? 'Đang offline' : 'Đang offline · số liệu lúc ${formatTimeOrDateIct(at, now)}',
          style: small,
        ),
      );
    }
    return lines;
  }

  Widget _meaning(StatusHeroData data, TextStyle style) {
    final days = data.daysLeft == null ? '' : ' · còn ${data.daysLeft} ngày';
    if (data.displayLevel == Level.warning && !data.waitingIncome) {
      return MoneySentence(['dưới vùng đệm ', data.buffer, days], key: const Key('status_hero_meaning'), style: style);
    }
    return Text(StatusHero.meaningText(data), key: const Key('status_hero_meaning'), style: style);
  }

  Widget _numeral(StatusHeroData data, Color fg) {
    final target = data.free!;
    final label = MoneyParts.of(target).semanticsLabel;
    final from = _fromFree;
    Widget child;
    final counting = _animating && !_reduced && from != null && from.round() != target;
    if (!counting) {
      child = _fitted(MoneyText(target, style: MoneyStyle.hero, color: fg));
    } else {
      final start = from.round();
      // Khung đếm rộng bằng số dài hơn trong hai đầu, nên tỉ lệ co của FittedBox đứng yên suốt lúc đếm
      // (thêm chữ số hay hiện dấu "−" giữa chừng không làm số co lại).
      final cellsWidth = math.max(
        MoneyText.measureWidth(context, start, style: MoneyStyle.hero, cells: true),
        MoneyText.measureWidth(context, target, style: MoneyStyle.hero, cells: true),
      );
      Widget cellsBox(int value) => _fitted(
        SizedBox(
          width: cellsWidth,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: MoneyText(value, style: MoneyStyle.hero, color: fg, cells: true),
          ),
        ),
      );
      final countT = _t(_countInterval);
      if (countT < 1) {
        final value = lerpDouble(start, target, countT)!.round();
        child = cellsBox(value);
      } else {
        final settle = _t(_settleInterval);
        child = Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            Opacity(opacity: 1 - settle, child: cellsBox(target)),
            Opacity(
              opacity: settle,
              child: _fitted(MoneyText(target, style: MoneyStyle.hero, color: fg)),
            ),
          ],
        );
      }
    }
    return Semantics(
      key: const Key('status_hero_free'),
      container: true,
      label: label,
      excludeSemantics: true,
      child: child,
    );
  }

  Widget _fitted(Widget child) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: child);

  List<Widget> _unknownBody(StatusHeroData data, ThemeData theme) {
    final account = data.missingBalanceAccount;
    final sentence = account == null
        ? 'Thêm tài khoản và nhập số dư hiện tại để app tính được phần được tiêu.'
        : 'Nhập số dư hiện tại của $account để app tính được phần được tiêu.';
    final action = widget.onUnknownAction;
    final now = widget.now ?? DateTime.now();
    final small = theme.textTheme.bodySmall!.copyWith(color: DefaultTextStyle.of(context).style.color);
    final offline = data.offline ? _freshnessLines(data, now, small) : const <Widget>[];
    return [
      const SizedBox(height: HeroSpace.headingToNumeral),
      Text(sentence, style: theme.textTheme.bodyMedium!.copyWith(color: DefaultTextStyle.of(context).style.color)),
      if (action != null) ...[
        const SizedBox(height: Space.s4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: account == null
              ? FilledButton.icon(
                  key: const Key('add_account'),
                  onPressed: action,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm tài khoản'),
                )
              : FilledButton.icon(
                  key: const Key('enter_balance'),
                  onPressed: action,
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Nhập số dư'),
                ),
        ),
      ],
      if (offline.isNotEmpty) ...[const SizedBox(height: HeroSpace.blockGap), ...offline],
    ];
  }
}

/// Một hàng chú giải: nhãn ở đầu, số tiền ở cuối; không đủ chỗ thì số tiền xuống dòng, vẫn căn cuối.
class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.label, required this.amount, required this.color, this.amountKey});

  final String label;
  final int amount;
  final Color color;
  final Key? amountKey;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: color);
    final scaler = MediaQuery.textScalerOf(context);
    return MergeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: labelStyle),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          final labelWidth = painter.width;
          painter.dispose();
          final amountWidth = MoneyText.measureWidth(context, amount, style: MoneyStyle.inline);
          final money = MoneyText(amount, key: amountKey, style: MoneyStyle.inline, color: color);
          if (labelWidth + Space.s3 + amountWidth <= constraints.maxWidth) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(label, style: labelStyle)),
                const SizedBox(width: Space.s3),
                money,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: labelStyle),
              Align(alignment: AlignmentDirectional.centerEnd, child: money),
            ],
          );
        },
      ),
    );
  }
}

/// Dòng có icon 16 dp đứng trước (dòng cập nhật cũ, offline).
class _IconLine extends StatelessWidget {
  const _IconLine({super.key, required this.icon, required this.text, required this.style});

  final IconData icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FirstLineIcon(icon, size: 16, textStyle: style),
        const SizedBox(width: Space.s1),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

/// Khung xương tĩnh khi tải lần đầu (không shimmer, không spinner): tiêu đề, khối số 60% × 44 dp, thước.
class StatusHeroSkeleton extends StatelessWidget {
  const StatusHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget bar({required double widthFactor, required double height}) => FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(Radii.sm)),
      ),
    );
    return Semantics(
      label: 'Đang tải tổng quan',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(Radii.xl)),
        child: Padding(
          padding: const EdgeInsets.all(HeroSpace.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              bar(widthFactor: 0.4, height: 24),
              const SizedBox(height: HeroSpace.headingToNumeral + 4),
              bar(widthFactor: 0.6, height: 44),
              const SizedBox(height: HeroSpace.meaningToRuler + 24),
              Container(
                height: Ruler.barHeight,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Radii.full),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
