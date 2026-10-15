// Hệ thống thiết kế "Bát men lam": token Dart khớp design.json, tương phản WCAG, quy tắc component.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/main.dart' as app;
import 'package:personal_finance/models/level.dart';
import 'package:personal_finance/theme/theme.dart';

/// design.json nằm ở gốc repo (`flutter test` chạy trong mobile/).
Map<String, dynamic> _designJson() {
  final file = File('../.agents/design-state/design.json');
  if (!file.existsSync()) throw StateError('Không thấy ${file.absolute.path} (chạy flutter test trong mobile/)');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

String _toHex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Mọi vai trò của ColorScheme theo tên trong design.json.
Map<String, Color> _roles(ColorScheme s) => {
  'primary': s.primary,
  'onPrimary': s.onPrimary,
  'primaryContainer': s.primaryContainer,
  'onPrimaryContainer': s.onPrimaryContainer,
  'secondary': s.secondary,
  'onSecondary': s.onSecondary,
  'secondaryContainer': s.secondaryContainer,
  'onSecondaryContainer': s.onSecondaryContainer,
  'tertiary': s.tertiary,
  'onTertiary': s.onTertiary,
  'tertiaryContainer': s.tertiaryContainer,
  'onTertiaryContainer': s.onTertiaryContainer,
  'error': s.error,
  'onError': s.onError,
  'errorContainer': s.errorContainer,
  'onErrorContainer': s.onErrorContainer,
  'surface': s.surface,
  'onSurface': s.onSurface,
  'surfaceDim': s.surfaceDim,
  'surfaceBright': s.surfaceBright,
  'surfaceContainerLowest': s.surfaceContainerLowest,
  'surfaceContainerLow': s.surfaceContainerLow,
  'surfaceContainer': s.surfaceContainer,
  'surfaceContainerHigh': s.surfaceContainerHigh,
  'surfaceContainerHighest': s.surfaceContainerHighest,
  'onSurfaceVariant': s.onSurfaceVariant,
  'outline': s.outline,
  'outlineVariant': s.outlineVariant,
  'inverseSurface': s.inverseSurface,
  'onInverseSurface': s.onInverseSurface,
  'inversePrimary': s.inversePrimary,
  'shadow': s.shadow,
  'scrim': s.scrim,
  'surfaceTint': s.surfaceTint,
  'primaryFixed': s.primaryFixed,
  'primaryFixedDim': s.primaryFixedDim,
  'onPrimaryFixed': s.onPrimaryFixed,
  'onPrimaryFixedVariant': s.onPrimaryFixedVariant,
  'secondaryFixed': s.secondaryFixed,
  'secondaryFixedDim': s.secondaryFixedDim,
  'onSecondaryFixed': s.onSecondaryFixed,
  'onSecondaryFixedVariant': s.onSecondaryFixedVariant,
  'tertiaryFixed': s.tertiaryFixed,
  'tertiaryFixedDim': s.tertiaryFixedDim,
  'onTertiaryFixed': s.onTertiaryFixed,
  'onTertiaryFixedVariant': s.onTertiaryFixedVariant,
};

Map<String, Color?> _levelTokens(LevelColors c) => {
  'foreground': c.foreground,
  'container': c.container,
  'onContainer': c.onContainer,
  'heroBackground': c.heroBackground,
  'heroForeground': c.heroForeground,
  'heroBarReserved': c.heroBarReserved,
  'heroBarFree': c.heroBarFree,
};

// ---------------------------------------------------------------- WCAG 2.x (giống tools/contrast.py)

double _channel(double c) => c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) => 0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

class _Pair {
  const _Pair(this.name, this.fg, this.bg, this.min);

  final String name;
  final Color fg;
  final Color bg;
  final double min;
}

const _body = 4.5;
const _ui = 3.0;

/// Các cặp bắt buộc (chữ ≥ 4,5; thành phần giao diện ≥ 3) như .agents/design-state/tools/contrast.py,
/// tính trên giá trị Dart của theme.
List<_Pair> _requiredPairs(ThemeData theme) {
  final c = theme.colorScheme;
  final s = theme.extension<StatusColors>()!;
  final surfaces = {
    'surface': c.surface,
    'surfaceDim': c.surfaceDim,
    'surfaceBright': c.surfaceBright,
    'surfaceContainerLowest': c.surfaceContainerLowest,
    'surfaceContainerLow': c.surfaceContainerLow,
    'surfaceContainer': c.surfaceContainer,
    'surfaceContainerHigh': c.surfaceContainerHigh,
    'surfaceContainerHighest': c.surfaceContainerHighest,
  };
  final content = Map.of(surfaces)
    ..remove('surfaceDim')
    ..remove('surfaceBright');
  final pairs = <_Pair>[
    _Pair('onPrimary/primary', c.onPrimary, c.primary, _body),
    _Pair('onPrimaryContainer/primaryContainer', c.onPrimaryContainer, c.primaryContainer, _body),
    _Pair('onSecondary/secondary', c.onSecondary, c.secondary, _body),
    _Pair('onSecondaryContainer/secondaryContainer', c.onSecondaryContainer, c.secondaryContainer, _body),
    _Pair('onTertiary/tertiary', c.onTertiary, c.tertiary, _body),
    _Pair('onTertiaryContainer/tertiaryContainer', c.onTertiaryContainer, c.tertiaryContainer, _body),
    _Pair('onError/error', c.onError, c.error, _body),
    _Pair('onErrorContainer/errorContainer', c.onErrorContainer, c.errorContainer, _body),
    _Pair('onInverseSurface/inverseSurface', c.onInverseSurface, c.inverseSurface, _body),
    _Pair('inversePrimary/inverseSurface (snackbar action)', c.inversePrimary, c.inverseSurface, _body),
    _Pair('onPrimaryFixed/primaryFixed', c.onPrimaryFixed, c.primaryFixed, _body),
    _Pair('onPrimaryFixedVariant/primaryFixed', c.onPrimaryFixedVariant, c.primaryFixed, _body),
    _Pair('onPrimaryFixed/primaryFixedDim', c.onPrimaryFixed, c.primaryFixedDim, _body),
    _Pair('onSecondaryFixed/secondaryFixed', c.onSecondaryFixed, c.secondaryFixed, _body),
    _Pair('onSecondaryFixedVariant/secondaryFixed', c.onSecondaryFixedVariant, c.secondaryFixed, _body),
    _Pair('onSecondaryFixed/secondaryFixedDim', c.onSecondaryFixed, c.secondaryFixedDim, _body),
    _Pair('onTertiaryFixed/tertiaryFixed', c.onTertiaryFixed, c.tertiaryFixed, _body),
    _Pair('onTertiaryFixedVariant/tertiaryFixed', c.onTertiaryFixedVariant, c.tertiaryFixed, _body),
    _Pair('onTertiaryFixed/tertiaryFixedDim', c.onTertiaryFixed, c.tertiaryFixedDim, _body),
    for (final e in surfaces.entries) ...[
      _Pair('onSurface/${e.key}', c.onSurface, e.value, _body),
      _Pair('onSurfaceVariant/${e.key}', c.onSurfaceVariant, e.value, _body),
    ],
    for (final e in content.entries) ...[
      _Pair('primary/${e.key}', c.primary, e.value, _body),
      _Pair('error/${e.key}', c.error, e.value, _body),
      _Pair('tertiary/${e.key}', c.tertiary, e.value, _body),
      _Pair('secondary/${e.key}', c.secondary, e.value, _body),
    ],
    _Pair('onSurface/secondaryContainer (chip, indicator)', c.onSurface, c.secondaryContainer, _body),
    // Thành phần giao diện (≥ 3:1).
    _Pair('outline/surface (field border)', c.outline, c.surface, _ui),
    _Pair('outline/surfaceContainerLow', c.outline, c.surfaceContainerLow, _ui),
    _Pair('outline/surfaceContainerHigh', c.outline, c.surfaceContainerHigh, _ui),
    _Pair('primary (progress)/surfaceContainerHighest', c.primary, c.surfaceContainerHighest, _ui),
    _Pair('secondary (switch track)/surface', c.secondary, c.surface, _ui),
    _Pair('secondary (switch track)/surfaceContainerLow', c.secondary, c.surfaceContainerLow, _ui),
    _Pair('onSecondary (switch thumb)/secondary', c.onSecondary, c.secondary, _ui),
    _Pair('outline (unselected thumb)/surfaceContainerHighest', c.outline, c.surfaceContainerHighest, _ui),
    _Pair('primary (badge)/surfaceContainer', c.primary, c.surfaceContainer, _ui),
    _Pair('tertiary (demo button)/tertiaryContainer', c.tertiary, c.tertiaryContainer, _ui),
  ];
  final levels = {'ok': s.ok, 'warning': s.warning, 'danger': s.danger, 'unknown': s.unknown};
  for (final e in levels.entries) {
    final l = e.value;
    for (final bg in surfaces.entries) {
      pairs.add(_Pair('${e.key}.foreground/${bg.key}', l.foreground, bg.value, _body));
    }
    pairs
      ..add(_Pair('${e.key}.onContainer/container', l.onContainer, l.container, _body))
      ..add(_Pair('${e.key}.foreground (icon)/container', l.foreground, l.container, _ui))
      ..add(_Pair('${e.key}.heroForeground/heroBackground', l.heroForeground, l.heroBackground, _body));
    if (e.key != 'unknown') {
      pairs
        ..add(_Pair('${e.key}.heroBarReserved/heroBackground', l.heroBarReserved!, l.heroBackground, _ui))
        ..add(_Pair('${e.key}.heroBarFree/heroBackground', l.heroBarFree!, l.heroBackground, _ui))
        ..add(_Pair('${e.key}.tick/heroBackground (halo)', l.heroForeground, l.heroBackground, _ui))
        ..add(_Pair('${e.key}.foreground (bar)/surfaceContainerHighest', l.foreground, c.surfaceContainerHighest, _ui));
    }
  }
  return pairs;
}

void main() {
  final light = app.buildTheme(Brightness.light);
  final dark = app.buildTheme(Brightness.dark);
  final themes = {'light': light, 'dark': dark};
  final json = _designJson();

  group('token Dart = design.json', () {
    for (final name in ['light', 'dark']) {
      test('ColorScheme $name: đủ mọi vai trò, đúng giá trị', () {
        final expected = (json['color'] as Map<String, dynamic>)[name] as Map<String, dynamic>;
        final scheme = themes[name]!.colorScheme;
        final actual = _roles(scheme);
        expect(actual.keys.toSet(), expected.keys.toSet());
        for (final e in expected.entries) {
          expect(_toHex(actual[e.key]!), (e.value as String).toUpperCase(), reason: '$name.${e.key}');
        }
        expect(scheme, same(name == 'light' ? lightColorScheme : darkColorScheme));
        expect(scheme.brightness, name == 'light' ? Brightness.light : Brightness.dark);
      });

      test('StatusColors $name: bốn mức, đủ token, UNKNOWN không có màu thước', () {
        final expected = (json['statusColors'] as Map<String, dynamic>)[name] as Map<String, dynamic>;
        final status = themes[name]!.extension<StatusColors>()!;
        final levels = {'ok': status.ok, 'warning': status.warning, 'danger': status.danger, 'unknown': status.unknown};
        expect(levels.keys.toSet(), expected.keys.toSet());
        for (final level in expected.entries) {
          final tokens = _levelTokens(levels[level.key]!);
          final want = level.value as Map<String, dynamic>;
          for (final t in tokens.entries) {
            if (want.containsKey(t.key)) {
              expect(t.value, isNotNull, reason: '$name.${level.key}.${t.key}');
              expect(_toHex(t.value!), (want[t.key] as String).toUpperCase(), reason: '$name.${level.key}.${t.key}');
            } else {
              expect(t.value, isNull, reason: '$name.${level.key}.${t.key} không có trong design.json');
            }
          }
        }
      });
    }

    test('chữ: 15 vai trò Material 3 (sp, độ đậm, dòng, khoảng chữ, Be Vietnam Pro, leading even)', () {
      final typo = json['typography'] as Map<String, dynamic>;
      expect(appFontFamily, typo['flutterFontFamily']);
      final roles = typo['roles'] as Map<String, dynamic>;
      expect(roles, hasLength(15));
      for (final theme in themes.values) {
        final t = theme.textTheme;
        final byName = <String, TextStyle?>{
          'displayLarge': t.displayLarge,
          'displayMedium': t.displayMedium,
          'displaySmall': t.displaySmall,
          'headlineLarge': t.headlineLarge,
          'headlineMedium': t.headlineMedium,
          'headlineSmall': t.headlineSmall,
          'titleLarge': t.titleLarge,
          'titleMedium': t.titleMedium,
          'titleSmall': t.titleSmall,
          'bodyLarge': t.bodyLarge,
          'bodyMedium': t.bodyMedium,
          'bodySmall': t.bodySmall,
          'labelLarge': t.labelLarge,
          'labelMedium': t.labelMedium,
          'labelSmall': t.labelSmall,
        };
        expect(byName.keys.toSet(), roles.keys.toSet());
        for (final e in roles.entries) {
          final want = e.value as Map<String, dynamic>;
          final style = byName[e.key]!;
          expect(style.fontFamily, appFontFamily, reason: e.key);
          expect(style.fontSize, (want['fontSize'] as num).toDouble(), reason: e.key);
          expect(style.fontWeight, FontWeight.values.firstWhere((w) => w.value == want['fontWeight']), reason: e.key);
          expect(style.height, (want['height'] as num).toDouble(), reason: e.key);
          expect(style.letterSpacing, (want['letterSpacing'] as num).toDouble(), reason: e.key);
          expect(style.leadingDistribution, TextLeadingDistribution.even, reason: e.key);
          expect(style.fontStyle, isNot(FontStyle.italic), reason: e.key);
          expect(style.color, theme.colorScheme.onSurface, reason: e.key);
        }
      }
    });

    test('kiểu chữ số tiền: 6 kiểu, đơn vị "đ", cách đặt chữ số, ô chữ số theo độ đậm', () {
      final typo = json['typography'] as Map<String, dynamic>;
      final money = typo['money'] as Map<String, dynamic>;
      final styles = light.extension<MoneyStyles>()!;
      expect(dark.extension<MoneyStyles>(), isNotNull);
      final byName = {
        'moneyHero': styles.hero,
        'moneyLarge': styles.large,
        'moneyInput': styles.input,
        'moneyList': styles.list,
        'moneyBody': styles.body,
        'moneyInline': styles.inline,
      };
      expect(byName.keys.toSet(), money.keys.toSet());
      const modes = {
        'fixedCells': DigitMode.fixedCells,
        'proportional': DigitMode.proportional,
        'fixedCellsWhileCounting': DigitMode.fixedCellsWhileCounting,
      };
      for (final e in money.entries) {
        final want = e.value as Map<String, dynamic>;
        final spec = byName[e.key]!;
        expect(spec.numeral.fontFamily, appFontFamily, reason: e.key);
        expect(spec.numeral.fontSize, (want['size'] as num).toDouble(), reason: e.key);
        expect(spec.numeral.fontWeight!.value, want['weight'], reason: e.key);
        expect(spec.numeral.height, (want['height'] as num).toDouble(), reason: e.key);
        expect(spec.numeral.letterSpacing, (want['letterSpacing'] as num).toDouble(), reason: e.key);
        expect(spec.numeral.leadingDistribution, TextLeadingDistribution.even, reason: e.key);
        final unit = want['unit'] as Map<String, dynamic>;
        expect(spec.unit.fontSize, (unit['size'] as num).toDouble(), reason: '${e.key}.unit');
        expect(spec.unit.fontWeight!.value, unit['weight'], reason: '${e.key}.unit');
        expect(spec.digits, modes[want['digits']], reason: e.key);
        // Không dùng tnum (font không có): không FontFeature nào.
        expect(spec.numeral.fontFeatures, isNull, reason: e.key);
      }
      expect(styles.hero.maxTextScale, 1.3);
      final tab = typo['tabularFigures'] as Map<String, dynamic>;
      expect(tab['openTypeTnum'], isFalse);
      final cells = tab['digitCellEm'] as Map<String, dynamic>;
      expect(
        styles.digitCellEm.map((k, v) => MapEntry('$k', v)),
        cells.map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
      expect(styles.cellEmFor(FontWeight.w800), 0.723);
    });

    test('khoảng cách, bố cục, thước, bo góc, ngưỡng cỡ cửa sổ, độ nổi', () {
      final spacing = json['spacing'] as Map<String, dynamic>;
      expect(spacing, {
        's1': Space.s1,
        's2': Space.s2,
        's3': Space.s3,
        's4': Space.s4,
        's5': Space.s5,
        's6': Space.s6,
        's8': Space.s8,
        's10': Space.s10,
        's12': Space.s12,
        's16': Space.s16,
      });
      final layout = Map.of(json['layout'] as Map<String, dynamic>)..remove('largeTextRowBreak');
      expect(layout, {
        'gutterCompact': Gutter.compact,
        'gutterMedium': Gutter.medium,
        'gutterExpanded': Gutter.expanded,
        'contentMaxWidth': AppLayout.contentMaxWidth,
        'sheetMaxWidth': AppLayout.sheetMaxWidth,
        'heroPadding': HeroSpace.padding,
        'sectionGap': AppLayout.sectionGap,
        'headingToContent': AppLayout.headingToContent,
        'groupGap': AppLayout.groupGap,
        'inlineGap': AppLayout.inlineGap,
        'heroHeadingToNumeral': HeroSpace.headingToNumeral,
        'heroNumeralToMeaning': HeroSpace.numeralToMeaning,
        'heroMeaningToRuler': HeroSpace.meaningToRuler,
        'heroRulerToLegend': HeroSpace.rulerToLegend,
        'heroLegendRowGap': HeroSpace.legendRowGap,
        'heroBlockGap': HeroSpace.blockGap,
        'heroLineGap': HeroSpace.lineGap,
        'rulerBarHeight': Ruler.barHeight,
        'rulerSegmentGap': Ruler.segmentGap,
        'rulerTickWidth': Ruler.tickWidth,
        'rulerTickHeight': Ruler.tickHeight,
        'rulerTickHalo': Ruler.tickHalo,
        'rulerMissingStroke': Ruler.missingStroke,
        'listRowPaddingH': AppLayout.listRowPaddingH,
        'listRowMinHeight': AppLayout.listRowMinHeight,
        'listRowTwoLineMinHeight': AppLayout.listRowTwoLineMinHeight,
        'listLeadingSize': AppLayout.listLeadingSize,
        'fabClearance': AppLayout.fabClearance,
        'touchTargetMin': AppLayout.touchTargetMin,
        'touchTargetGap': AppLayout.touchTargetGap,
      });
      // "> 125%": textScaler.scale(16) > 20.
      expect(AppLayout.isLargeText(const TextScaler.linear(1.25)), isFalse);
      expect(AppLayout.isLargeText(const TextScaler.linear(1.3)), isTrue);
      expect(json['breakpoints'], {
        'compact': Breakpoints.compact,
        'medium': Breakpoints.medium,
        'expanded': Breakpoints.expanded,
        'large': Breakpoints.large,
      });
      expect(json['radius'], {
        'none': Radii.none,
        'xs': Radii.xs,
        'sm': Radii.sm,
        'md': Radii.md,
        'lg': Radii.lg,
        'xl': Radii.xl,
        'xxl': Radii.xxl,
        'full': Radii.full,
      });
      final elevation = json['elevation'] as Map<String, dynamic>;
      expect(
        {for (final e in elevation.entries) e.key: (e.value as Map<String, dynamic>)['dp']},
        {
          'level0': Elevations.level0,
          'level1': Elevations.level1,
          'level2': Elevations.level2,
          'level3': Elevations.level3,
        },
      );
      expect(Gutter.forWidth(360), Gutter.compact);
      expect(Gutter.forWidth(700), Gutter.medium);
      expect(Gutter.forWidth(1280), Gutter.expanded);
    });

    test('chuyển động: thời lượng, đường cong, màn đổi trạng thái ≤ 700 ms', () {
      final motion = json['motion'] as Map<String, dynamic>;
      int ms(Duration d) => d.inMilliseconds;
      expect(motion['durationsMs'], {
        'short2': ms(MotionDurations.short2),
        'short3': ms(MotionDurations.short3),
        'short4': ms(MotionDurations.short4),
        'medium1': ms(MotionDurations.medium1),
        'medium2': ms(MotionDurations.medium2),
        'medium4': ms(MotionDurations.medium4),
        'long1': ms(MotionDurations.long1),
        'long2': ms(MotionDurations.long2),
        'long4': ms(MotionDurations.long4),
      });
      final easing = motion['easing'] as Map<String, dynamic>;
      List<double> pts(Cubic c) => [c.a, c.b, c.c, c.d];
      List<double> want(String k) => (easing[k] as List).map((e) => (e as num).toDouble()).toList();
      expect(pts(Easings.standard), want('standard'));
      expect(pts(Easings.standardDecelerate), want('standardDecelerate'));
      expect(pts(Easings.standardAccelerate), want('standardAccelerate'));
      expect(pts(Easings.emphasizedDecelerate), want('emphasizedDecelerate'));
      expect(pts(Easings.emphasizedAccelerate), want('emphasizedAccelerate'));
      expect(easing['emphasized'], 'Curves.easeInOutCubicEmphasized');
      expect(Easings.emphasized, same(Curves.easeInOutCubicEmphasized));
      final usage = motion['usage'] as Map<String, dynamic>;
      int usageMs(String k) => (usage[k] as Map<String, dynamic>)['ms'] as int;
      expect(ms(MotionDurations.stateLayer), usageMs('stateLayer'));
      expect(ms(MotionDurations.listChange), usageMs('listChange'));
      expect(ms(MotionDurations.sheetEnter), usageMs('sheetEnter'));
      expect(ms(MotionDurations.sheetExit), usageMs('sheetExit'));
      expect(ms(MotionDurations.snackbar), usageMs('snackbar'));

      final sc = motion['statusChange'] as Map<String, dynamic>;
      int field(String group, String key) => (sc[group] as Map<String, dynamic>)[key] as int;
      expect(ms(StatusMotion.heroColor), field('heroColor', 'ms'));
      expect(ms(StatusMotion.numeralCount), field('numeralCount', 'ms'));
      expect(ms(StatusMotion.numeralSettle), field('numeralSettle', 'ms'));
      expect(ms(StatusMotion.numeralSettleDelay), field('numeralSettle', 'delayMs'));
      expect(ms(StatusMotion.headingExit), field('statusHeading', 'exitMs'));
      expect(ms(StatusMotion.headingEnter), field('statusHeading', 'enterMs'));
      expect(ms(StatusMotion.headingEnterDelay), field('statusHeading', 'enterDelayMs'));
      expect(StatusMotion.headingOffset, field('statusHeading', 'offsetDp'));
      expect(ms(StatusMotion.floorRuler), field('floorRuler', 'ms'));
      expect(ms(StatusMotion.total), sc['totalMaxMs']);
      final reduce = sc['reduceMotion'] as Map<String, dynamic>;
      expect(ms(StatusMotion.reduceMotionColor), (reduce['heroColor'] as Map<String, dynamic>)['ms']);
      // Mọi phần của màn chuyển kết thúc trong tổng thời lượng.
      for (final end in [
        StatusMotion.heroColor,
        StatusMotion.numeralSettleDelay + StatusMotion.numeralSettle,
        StatusMotion.headingEnterDelay + StatusMotion.headingEnter,
        StatusMotion.floorRuler,
      ]) {
        expect(end, lessThanOrEqualTo(StatusMotion.total));
      }
    });
  });

  group('tương phản WCAG (tính trong Dart)', () {
    for (final entry in themes.entries) {
      test('${entry.key}: chữ ≥ 4,5:1, thành phần giao diện ≥ 3:1', () {
        final failures = <String>[];
        final pairs = _requiredPairs(entry.value);
        expect(pairs.length, greaterThan(120));
        for (final p in pairs) {
          final r = contrastRatio(p.fg, p.bg);
          if (r < p.min) failures.add('${p.name}: ${r.toStringAsFixed(2)} < ${p.min}');
        }
        expect(failures, isEmpty);
      });
    }

    test('số trong hero đủ đọc ngoài trời (≥ 7:1) ở OK / WARNING / DANGER', () {
      for (final theme in themes.values) {
        final s = theme.extension<StatusColors>()!;
        for (final l in [s.ok, s.warning, s.danger]) {
          expect(contrastRatio(l.heroForeground, l.heroBackground), greaterThanOrEqualTo(7));
        }
      }
    });

    test('công thức tương phản khớp contrast.py (mốc trong DESIGN.md)', () {
      expect(contrastRatio(const Color(0xFFFFFFFF), const Color(0xFF2C4B9A)), closeTo(8.14, 0.01));
      expect(contrastRatio(const Color(0xFF835A03), const Color(0xFFDDE0E5)), closeTo(4.63, 0.01));
    });
  });

  group('component theo DESIGN.md', () {
    for (final entry in themes.entries) {
      final theme = entry.value;
      final c = theme.colorScheme;
      test('${entry.key}: Material 3, không fromSeed, phần mở rộng, vùng chạm 48 dp', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.extension<StatusColors>(), isNotNull);
        expect(theme.extension<MoneyStyles>(), isNotNull);
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
        expect(theme.visualDensity, VisualDensity.standard);
        expect(theme.scaffoldBackgroundColor, c.surface);
        expect(
          theme.pageTransitionsTheme.builders[TargetPlatform.android],
          isA<PredictiveBackPageTransitionsBuilder>(),
        );
        final overlay = theme.appBarTheme.systemOverlayStyle!;
        expect(overlay.statusBarColor, const Color(0x00000000));
        expect(overlay.systemNavigationBarContrastEnforced, isFalse);
        expect(
          overlay.statusBarIconBrightness,
          theme.brightness == Brightness.light ? Brightness.dark : Brightness.light,
        );
      });

      test('${entry.key}: The One Cobalt Rule — công tắc bật dùng secondary, huy hiệu primary (không error)', () {
        final sw = theme.switchTheme;
        expect(sw.trackColor!.resolve({WidgetState.selected}), c.secondary);
        expect(sw.thumbColor!.resolve({WidgetState.selected}), c.onSecondary);
        expect(sw.trackColor!.resolve({}), c.surfaceContainerHighest);
        expect(sw.thumbColor!.resolve({}), c.outline);
        expect(sw.trackOutlineColor!.resolve({}), c.outline);
        expect(theme.badgeTheme.backgroundColor, c.primary);
        expect(theme.badgeTheme.textColor, c.onPrimary);
        expect(theme.checkboxTheme.fillColor!.resolve({WidgetState.selected}), isNot(c.primary));
      });

      test('${entry.key}: nút stadium 48 dp, FAB primary bo 16, chip viền outline', () {
        final filled = theme.filledButtonTheme.style!;
        expect(filled.minimumSize!.resolve({})!.height, 48);
        expect(filled.shape!.resolve({}), isA<StadiumBorder>());
        expect(theme.outlinedButtonTheme.style!.side!.resolve({})!.color, c.outline);
        expect(theme.textButtonTheme.style!.minimumSize!.resolve({})!.height, 48);
        final fab = theme.floatingActionButtonTheme;
        expect(fab.backgroundColor, c.primary);
        expect(fab.foregroundColor, c.onPrimary);
        expect((fab.shape! as RoundedRectangleBorder).borderRadius, BorderRadius.circular(Radii.lg));
        expect(fab.elevation, Elevations.level3);
        final chip = theme.chipTheme;
        expect((chip.side! as WidgetStateBorderSide).resolve({})!.color, c.outline);
        expect((chip.side! as WidgetStateBorderSide).resolve({WidgetState.selected}), BorderSide.none);
        expect(chip.color!.resolve({WidgetState.selected}), c.secondaryContainer);
        expect((chip.shape! as RoundedRectangleBorder).borderRadius, BorderRadius.circular(Radii.sm));
      });

      test('${entry.key}: điều hướng, bảng trượt, snackbar, ô nhập, thẻ phẳng', () {
        final nav = theme.navigationBarTheme;
        expect(nav.height, 80);
        expect(nav.backgroundColor, c.surfaceContainer);
        expect(nav.indicatorColor, c.secondaryContainer);
        expect(nav.labelTextStyle!.resolve({})!.fontSize, theme.textTheme.labelSmall!.fontSize);
        expect(nav.labelTextStyle!.resolve({})!.fontWeight, FontWeight.w600);
        final rail = theme.navigationRailTheme;
        expect(rail.labelType, NavigationRailLabelType.all);
        expect(rail.selectedLabelTextStyle!.fontSize, theme.textTheme.labelSmall!.fontSize);
        expect(rail.indicatorColor, c.secondaryContainer);
        final sheet = theme.bottomSheetTheme;
        expect(sheet.constraints!.maxWidth, AppLayout.sheetMaxWidth);
        expect(sheet.backgroundColor, c.surfaceContainerLow);
        expect(sheet.showDragHandle, isTrue);
        expect(
          (sheet.shape! as RoundedRectangleBorder).borderRadius,
          const BorderRadius.vertical(top: Radius.circular(Radii.xxl)),
        );
        final snack = theme.snackBarTheme;
        expect(snack.behavior, SnackBarBehavior.floating);
        expect(snack.backgroundColor, c.inverseSurface);
        expect(snack.actionTextColor, c.inversePrimary);
        final input = theme.inputDecorationTheme;
        expect((input.enabledBorder! as OutlineInputBorder).borderSide.color, c.outline);
        expect((input.focusedBorder! as OutlineInputBorder).borderSide.width, 2);
        expect((input.focusedBorder! as OutlineInputBorder).borderSide.color, c.primary);
        expect((input.errorBorder! as OutlineInputBorder).borderSide.color, c.error);
        expect((input.enabledBorder! as OutlineInputBorder).borderRadius, BorderRadius.circular(Radii.md));
        expect(theme.cardTheme.elevation, 0);
        expect(theme.cardTheme.color, c.surfaceContainerLow);
        expect(theme.appBarTheme.scrolledUnderElevation, 0);
        expect(theme.dividerTheme.color, c.outlineVariant);
        expect(theme.progressIndicatorTheme.linearTrackColor, c.surfaceContainerHighest);
      });
    }

    test('font dự phòng (bản demo web: emoji) áp cho cả kiểu chữ của component theme', () {
      const fallback = ['Noto Color Emoji', 'DejaVu Sans'];
      final t = app.buildTheme(Brightness.light, fontFamilyFallback: fallback);
      expect(t.textTheme.bodyMedium!.fontFamilyFallback, fallback);
      expect(t.listTileTheme.titleTextStyle!.fontFamilyFallback, fallback);
      expect(t.snackBarTheme.contentTextStyle!.fontFamilyFallback, fallback);
      expect(t.chipTheme.labelStyle!.fontFamilyFallback, fallback);
      expect(t.navigationBarTheme.labelTextStyle!.resolve({})!.fontFamilyFallback, fallback);
      expect(light.textTheme.bodyMedium!.fontFamilyFallback, isNull);
    });

    test('Level → màu: info dùng nhóm secondary, các mức khác dùng StatusColors', () {
      final status = light.extension<StatusColors>()!;
      final c = light.colorScheme;
      expect(status.forLevel(Level.danger, c), same(status.danger));
      final info = status.forLevel(Level.info, c);
      expect(info.container, c.secondaryContainer);
      expect(info.foreground, c.secondary);
      // lerp thật (chuyển màu men của hero dựa vào nó).
      final mid = LevelColors.lerp(status.ok, status.danger, 0.5);
      expect(mid.heroBackground, Color.lerp(status.ok.heroBackground, status.danger.heroBackground, 0.5));
      expect(status.lerp(StatusColors.dark, 1).ok, StatusColors.dark.ok);
      expect(LevelColors.lerp(status.ok, status.unknown, 1).heroBarFree, status.unknown.heroForeground);
    });
  });

  group('font Be Vietnam Pro', () {
    test('pubspec khai báo 400/500/600/700/800, file là TrueType thật, có OFL', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('family: ${json['typography']['flutterFontFamily']}'));
      final assets = (json['typography'] as Map<String, dynamic>)['assets'] as Map<String, dynamic>;
      for (final e in assets.entries) {
        expect(pubspec, contains('asset: assets/fonts/${e.value}\n          weight: ${e.key}'));
        final bytes = File('assets/fonts/${e.value}').readAsBytesSync();
        expect(bytes.length, greaterThan(100000), reason: '${e.value}');
        // sfnt version 0x00010000 (TrueType).
        expect(bytes.sublist(0, 4), [0, 1, 0, 0], reason: '${e.value}');
      }
      expect(File('assets/fonts/OFL.txt').readAsStringSync(), contains('SIL Open Font License'));
      expect(pubspec, contains('- assets/fonts/OFL.txt'));
    });

    testWidgets('giấy phép OFL được đăng ký với LicenseRegistry (gọi nhiều lần không trùng)', (tester) async {
      registerFontLicenses();
      registerFontLicenses();
      final entries = await tester.runAsync(() => LicenseRegistry.licenses.toList());
      final ours = entries!.where((l) => l.packages.contains('Be Vietnam Pro')).toList();
      expect(ours, hasLength(1));
      expect(ours.single.paragraphs.map((p) => p.text).join('\n'), contains('SIL Open Font License'));
    });
  });
}
