"""Single source for the Chi tiêu design tokens.

Colours are authored as OKLCH anchors and converted to sRGB hex (chroma reduced until in gamut).
Writes design.json (argv[1]): colours, status sets, type and money styles, spacing (hero gaps included), motion and
components (a superset of the DESIGN.md front matter: it also carries borderColor). Prints nothing else. From the repo
root:
    python3 -P -E .agents/design-state/tools/build_tokens.py .agents/design-state/design.json
    python3 -P -E .agents/design-state/tools/contrast.py .agents/design-state/design.json [table.md] [summary.md] [hero.md]
contrast.py exits 1 on any failing pair or too-close hero glazes. Then update the values quoted in DESIGN.md
(front matter, tables, contrast appendix) to match.
"""
import json
import math
import sys

# ---------------------------------------------------------------- colour maths

def _oklch_to_linear_srgb(L, C, h):
    a = C * math.cos(math.radians(h))
    b = C * math.sin(math.radians(h))
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    return (
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )


def _encode(c):
    c = min(max(c, 0.0), 1.0)
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def hexc(L, C, h):
    c = C
    while c > 0 and not all(-1e-6 <= x <= 1 + 1e-6 for x in _oklch_to_linear_srgb(L, c, h)):
        c -= 0.002
    r, g, b = (round(_encode(x) * 255) for x in _oklch_to_linear_srgb(L, max(c, 0.0), h))
    return f"#{r:02X}{g:02X}{b:02X}"


WHITE = (1.0, 0.0, 0.0)
BLACK = (0.0, 0.0, 0.0)

# Hues (OKLCH degrees)
H_PRI = 265   # men lam: Bát Tràng cobalt
H_SEC = 260   # slate glaze
H_TER = 188   # men ngọc: celadon jade
H_NEU = 262   # porcelain / night glaze neutrals, tinted by the cobalt
H_OK, H_WARN, H_DANGER, H_UNK = 145, 78, 30, 258

LIGHT = {
    "primary": (0.435, 0.135, H_PRI), "onPrimary": WHITE,
    "primaryContainer": (0.925, 0.040, H_PRI), "onPrimaryContainer": (0.300, 0.110, H_PRI),
    "secondary": (0.470, 0.045, H_SEC), "onSecondary": WHITE,
    # secondaryContainer is a low-chroma slate, darker than primaryContainer, so tonal buttons, the navigation
    # indicator and selected chips never look like the primary "invitation" container (was ΔE 0.011 apart).
    "secondaryContainer": (0.885, 0.018, 252), "onSecondaryContainer": (0.290, 0.040, H_SEC),
    "tertiary": (0.470, 0.060, H_TER), "onTertiary": WHITE,
    "tertiaryContainer": (0.925, 0.035, H_TER), "onTertiaryContainer": (0.290, 0.045, H_TER),
    "error": (0.500, 0.150, H_DANGER), "onError": WHITE,
    "errorContainer": (0.925, 0.038, H_DANGER), "onErrorContainer": (0.310, 0.090, H_DANGER),
    "surface": (0.984, 0.004, H_NEU), "onSurface": (0.215, 0.018, H_NEU),
    "surfaceDim": (0.905, 0.008, H_NEU), "surfaceBright": (0.984, 0.004, H_NEU),
    "surfaceContainerLowest": WHITE,
    "surfaceContainerLow": (0.968, 0.006, H_NEU),
    "surfaceContainer": (0.955, 0.007, H_NEU),
    "surfaceContainerHigh": (0.942, 0.008, H_NEU),
    "surfaceContainerHighest": (0.927, 0.009, H_NEU),
    "onSurfaceVariant": (0.430, 0.022, H_NEU),
    "outline": (0.575, 0.018, H_NEU), "outlineVariant": (0.855, 0.012, H_NEU),
    "inverseSurface": (0.300, 0.016, H_NEU), "onInverseSurface": (0.955, 0.006, H_NEU),
    "inversePrimary": (0.810, 0.085, H_PRI),
    "shadow": BLACK, "scrim": BLACK, "surfaceTint": (0.435, 0.135, H_PRI),
}

DARK = {
    "primary": (0.810, 0.085, H_PRI), "onPrimary": (0.280, 0.110, H_PRI),
    "primaryContainer": (0.370, 0.120, H_PRI), "onPrimaryContainer": (0.925, 0.040, H_PRI),
    "secondary": (0.800, 0.035, H_SEC), "onSecondary": (0.280, 0.035, H_SEC),
    "secondaryContainer": (0.360, 0.040, H_SEC), "onSecondaryContainer": (0.920, 0.024, H_SEC),
    "tertiary": (0.810, 0.055, H_TER), "onTertiary": (0.270, 0.045, H_TER),
    "tertiaryContainer": (0.360, 0.050, H_TER), "onTertiaryContainer": (0.925, 0.035, H_TER),
    "error": (0.790, 0.090, H_DANGER), "onError": (0.300, 0.100, H_DANGER),
    "errorContainer": (0.380, 0.095, H_DANGER), "onErrorContainer": (0.925, 0.038, H_DANGER),
    "surface": (0.200, 0.020, H_NEU), "onSurface": (0.925, 0.008, H_NEU),
    "surfaceDim": (0.200, 0.020, H_NEU), "surfaceBright": (0.350, 0.020, H_NEU),
    "surfaceContainerLowest": (0.165, 0.018, H_NEU),
    "surfaceContainerLow": (0.225, 0.021, H_NEU),
    "surfaceContainer": (0.245, 0.022, H_NEU),
    "surfaceContainerHigh": (0.280, 0.022, H_NEU),
    "surfaceContainerHighest": (0.315, 0.022, H_NEU),
    "onSurfaceVariant": (0.790, 0.020, H_NEU),
    "outline": (0.630, 0.018, H_NEU), "outlineVariant": (0.410, 0.018, H_NEU),
    "inverseSurface": (0.925, 0.008, H_NEU), "onInverseSurface": (0.260, 0.016, H_NEU),
    "inversePrimary": (0.435, 0.135, H_PRI),
    "shadow": BLACK, "scrim": BLACK, "surfaceTint": (0.810, 0.085, H_PRI),
}

FIXED = {  # M3 fixed roles: identical in both themes
    "primaryFixed": (0.925, 0.040, H_PRI), "primaryFixedDim": (0.810, 0.085, H_PRI),
    "onPrimaryFixed": (0.220, 0.090, H_PRI), "onPrimaryFixedVariant": (0.370, 0.120, H_PRI),
    "secondaryFixed": (0.885, 0.018, 252), "secondaryFixedDim": (0.800, 0.035, H_SEC),
    "onSecondaryFixed": (0.210, 0.035, H_SEC), "onSecondaryFixedVariant": (0.360, 0.040, H_SEC),
    "tertiaryFixed": (0.925, 0.035, H_TER), "tertiaryFixedDim": (0.810, 0.055, H_TER),
    "onTertiaryFixed": (0.210, 0.040, H_TER), "onTertiaryFixedVariant": (0.360, 0.050, H_TER),
}

# Status ThemeExtension. hero* = the dashboard status hero in that level.
# Hero glazes are separated by lightness, not only hue, so no two levels merge for protan/deutan eyes
# (contrast.py checks ΔE_OKLab >= 0.08 between every pair of hero backgrounds, Machado 2009 simulation):
#   light: OK and DANGER are the two deep glazes (cobalt vs iron red: blue-yellow axis), WARNING and UNKNOWN pale;
#   dark:  WARNING is the darkest glaze, DANGER the brightest, OK and UNKNOWN in between.
# UNKNOWN has no floor ruler, so it has no heroBar* tokens.
STATUS = {
    "light": {
        "ok": {
            "foreground": (0.470, 0.120, H_OK), "container": (0.925, 0.055, H_OK), "onContainer": (0.290, 0.075, H_OK),
            "heroBackground": LIGHT["primary"], "heroForeground": LIGHT["onPrimary"], "heroBarReserved": (0.735, 0.075, H_PRI),
        },
        "warning": {
            "foreground": (0.500, 0.105, H_WARN), "container": (0.925, 0.075, H_WARN + 6), "onContainer": (0.310, 0.065, H_WARN - 8),
            "heroBackground": (0.925, 0.075, H_WARN + 6), "heroForeground": (0.310, 0.065, H_WARN - 8), "heroBarReserved": (0.600, 0.085, H_WARN),
        },
        "danger": {
            "foreground": (0.500, 0.150, H_DANGER), "container": (0.925, 0.038, H_DANGER), "onContainer": (0.310, 0.090, H_DANGER),
            "heroBackground": (0.470, 0.135, H_DANGER), "heroForeground": WHITE, "heroBarReserved": (0.800, 0.055, H_DANGER),
        },
        "unknown": {
            "foreground": (0.470, 0.025, H_UNK), "container": (0.927, 0.012, H_UNK), "onContainer": (0.290, 0.025, H_UNK),
            "heroBackground": (0.927, 0.012, H_UNK), "heroForeground": (0.290, 0.025, H_UNK),
        },
    },
    "dark": {
        "ok": {
            "foreground": (0.800, 0.110, H_OK), "container": (0.340, 0.060, H_OK), "onContainer": (0.920, 0.055, H_OK),
            "heroBackground": DARK["primaryContainer"], "heroForeground": DARK["onPrimaryContainer"], "heroBarReserved": (0.670, 0.085, H_PRI),
        },
        "warning": {
            "foreground": (0.830, 0.115, H_WARN + 4), "container": (0.360, 0.060, H_WARN - 6), "onContainer": (0.930, 0.070, H_WARN + 6),
            "heroBackground": (0.270, 0.050, H_WARN - 8), "heroForeground": (0.930, 0.070, H_WARN + 6), "heroBarReserved": (0.600, 0.080, H_WARN - 3),
        },
        "danger": {
            "foreground": (0.790, 0.090, H_DANGER), "container": (0.380, 0.095, H_DANGER), "onContainer": (0.925, 0.038, H_DANGER),
            "heroBackground": (0.450, 0.135, H_DANGER), "heroForeground": (0.970, 0.015, H_DANGER), "heroBarReserved": (0.800, 0.060, H_DANGER),
        },
        "unknown": {
            "foreground": (0.780, 0.020, H_UNK), "container": (0.315, 0.022, H_UNK), "onContainer": (0.925, 0.010, H_UNK),
            "heroBackground": (0.330, 0.020, H_UNK), "heroForeground": (0.925, 0.010, H_UNK),
        },
    },
}

# ---------------------------------------------------------------- type

FAMILY = "Be Vietnam Pro"
FLUTTER_FAMILY = "BeVietnamPro"

# role: (size sp, weight, line-height multiplier, letterSpacing sp)
TYPE = {
    "displayLarge":   (56, 800, 1.12, -1.1),
    "displayMedium":  (45, 800, 1.16, -0.8),
    "displaySmall":   (36, 700, 1.22, -0.5),
    "headlineLarge":  (32, 700, 1.25, -0.3),
    "headlineMedium": (28, 700, 1.29, -0.2),
    "headlineSmall":  (24, 700, 1.42, 0.0),   # >= 1.42: sheet/dialog titles can quote user text in capitals
    "titleLarge":     (22, 700, 1.45, 0.0),   # >= 1.42: wrapping headings may hold stacked capitals
    "titleMedium":    (16, 600, 1.50, 0.1),
    "titleSmall":     (14, 600, 1.43, 0.1),
    "bodyLarge":      (16, 400, 1.50, 0.1),
    "bodyMedium":     (15, 400, 1.47, 0.1),
    "bodySmall":      (13, 400, 1.46, 0.15),
    "labelLarge":     (14, 600, 1.43, 0.1),
    "labelMedium":    (13, 600, 1.38, 0.2),
    "labelSmall":     (12, 600, 1.33, 0.3),
}

# money family. The font has no tnum (see DESIGN.md), so MoneyText can lay digits out in fixed cells of the widest
# digit. digits: "fixedCells" = always (amounts that form a column), "fixedCellsWhileCounting" = only during the
# hero count animation (proportional at rest), "proportional" = never.
MONEY = {
    "moneyHero":   {"digits": "fixedCellsWhileCounting", "size": 44, "weight": 800, "height": 1.08, "letterSpacing": -0.9,
                    "unit": {"size": 26, "weight": 700}, "use": "Hero 'được tiêu' amount on the dashboard"},
    "moneyLarge":  {"digits": "proportional", "size": 28, "weight": 800, "height": 1.15, "letterSpacing": -0.4,
                    "unit": {"size": 18, "weight": 700}, "use": "Single amount heading a sheet (categorise sheet, alert detail)"},
    "moneyInput":  {"digits": "proportional", "size": 28, "weight": 800, "height": 1.15, "letterSpacing": -0.4,
                    "unit": {"size": 18, "weight": 700}, "use": "Text inside money fields (unit is the field suffix)"},
    "moneyList":   {"digits": "fixedCells", "size": 16, "weight": 700, "height": 1.35, "letterSpacing": 0.0,
                    "unit": {"size": 16, "weight": 700}, "use": "Trailing amounts in list rows (transactions, goals, accounts)"},
    "moneyBody":   {"digits": "proportional", "size": 16, "weight": 700, "height": 1.5, "letterSpacing": 0.1,
                    "unit": {"size": 16, "weight": 700}, "use": "Amounts inside bodyLarge sentences (forecast facts)"},
    "moneyInline": {"digits": "proportional", "size": 14, "weight": 600, "height": 1.43, "letterSpacing": 0.0,
                    "unit": {"size": 14, "weight": 600}, "use": "Amounts inside captions, legend and progress lines"},
}
DIGIT_CELL_EM = {"400": 0.710, "500": 0.713, "600": 0.716, "700": 0.720, "800": 0.723}

# ---------------------------------------------------------------- layout, shape, motion

SPACING = {"s1": 4, "s2": 8, "s3": 12, "s4": 16, "s5": 20, "s6": 24, "s8": 32, "s10": 40, "s12": 48, "s16": 64}
LAYOUT = {
    "gutterCompact": 16, "gutterMedium": 24, "gutterExpanded": 32,
    "contentMaxWidth": 720, "sheetMaxWidth": 640,
    "heroPadding": 20, "sectionGap": 32, "headingToContent": 8, "groupGap": 12, "inlineGap": 8,
    # status hero, top to bottom (see DESIGN.md › Status hero)
    "heroHeadingToNumeral": 4, "heroNumeralToMeaning": 4, "heroMeaningToRuler": 16, "heroRulerToLegend": 12,
    "heroLegendRowGap": 4, "heroBlockGap": 12, "heroLineGap": 4,
    "rulerBarHeight": 12, "rulerSegmentGap": 2, "rulerTickWidth": 2, "rulerTickHeight": 20, "rulerTickHalo": 2,
    "rulerMissingStroke": 1.5,
    # list rows: 56 one-line, 72 two-line (the standard money row: title + meta)
    "listRowPaddingH": 16, "listRowMinHeight": 56, "listRowTwoLineMinHeight": 72, "listLeadingSize": 40,
    "largeTextRowBreak": "stack the trailing amount under the meta when textScaler.scale(16) > 20 (font scale > 125%)",
    "fabClearance": 96, "touchTargetMin": 48, "touchTargetGap": 8,
}
BREAKPOINTS = {"compact": 0, "medium": 600, "expanded": 840, "large": 1200}
RADIUS = {"none": 0, "xs": 4, "sm": 8, "md": 12, "lg": 16, "xl": 24, "xxl": 28, "full": 999}
ELEVATION = {
    "level0": {"dp": 0, "shadow": False, "use": "Everything at rest: surfaces, containers, list groups, hero, app bar, navigation bar"},
    "level1": {"dp": 1, "shadow": False, "use": "Modal bottom sheet (sits on scrim, tonal only)"},
    "level2": {"dp": 3, "shadow": True, "use": "Menus, dropdown overlays"},
    "level3": {"dp": 6, "shadow": True, "use": "FAB, snackbar, dialog"},
}
MOTION = {
    "durationsMs": {"short2": 100, "short3": 150, "short4": 200, "medium1": 250, "medium2": 300,
                     "medium4": 400, "long1": 450, "long2": 500, "long4": 600},
    "easing": {
        "standard": [0.2, 0.0, 0.0, 1.0],
        "standardDecelerate": [0.0, 0.0, 0.0, 1.0],
        "standardAccelerate": [0.3, 0.0, 1.0, 1.0],
        "emphasizedDecelerate": [0.05, 0.7, 0.1, 1.0],
        "emphasizedAccelerate": [0.3, 0.0, 0.8, 0.15],
        "emphasized": "Curves.easeInOutCubicEmphasized",
    },
    "usage": {
        "stateLayer": {"ms": 150, "easing": "standard"},
        "chipSelect": {"ms": 150, "easing": "standard"},
        "listChange": {"ms": 250, "easing": "standard"},
        "sheetEnter": {"ms": 400, "easing": "emphasizedDecelerate"},
        "sheetExit": {"ms": 200, "easing": "emphasizedAccelerate"},
        "tabSwitch": {"ms": 150, "easing": "standard", "kind": "fade"},
        "snackbar": {"ms": 250, "easing": "emphasizedDecelerate"},
    },
    "statusChange": {
        "trigger": {
            "glazeNumeralRuler": "summary.level or summary.free differs from the last value the hero showed (never on first paint)",
            "headingAndAnnouncement": "summary.level differs only",
        },
        "heroColor": {"ms": 450, "easing": "emphasized"},
        "numeralCount": {"ms": 550, "easing": "emphasizedDecelerate", "digits": "fixed cells",
                          "fitScale": "frozen at the smaller FittedBox scale of the start and end values"},
        "numeralSettle": {"ms": 150, "easing": "standard", "delayMs": 550, "kind": "crossfade fixed cells -> proportional"},
        "statusHeading": {"exitMs": 150, "exitEasing": "emphasizedAccelerate", "enterMs": 250,
                           "enterEasing": "emphasizedDecelerate", "enterDelayMs": 100, "offsetDp": 8},
        "floorRuler": {"ms": 500, "easing": "emphasizedDecelerate"},
        "totalMaxMs": 700,
        "reduceMotion": {"heroColor": {"ms": 150, "easing": "standard"}, "numeral": "instant", "statusHeading": "instant",
                          "floorRuler": "instant"},
    },
}

# ---------------------------------------------------------------- components
# Light-theme references in the DESIGN.md front-matter format; the dark theme resolves the same roles.
# Each entry maps to a ThemeData component theme (see DESIGN.md › Components and › Appendix: Flutter mapping).

def _c(role):
    return "{colors.light-" + role + "}"


def _t(role):
    return "{typography." + role + "}"


def _r(name):
    return "{rounded." + name + "}"


COMPONENTS = {
    "button-filled": {"backgroundColor": _c("primary"), "textColor": _c("onPrimary"), "typography": _t("labelLarge"),
                      "rounded": _r("full"), "height": "48dp", "padding": "0 24dp"},
    "button-filled-destructive": {"backgroundColor": _c("error"), "textColor": _c("onError"), "typography": _t("labelLarge"),
                                  "rounded": _r("full"), "height": "48dp", "padding": "0 24dp"},
    "button-tonal": {"backgroundColor": _c("secondaryContainer"), "textColor": _c("onSecondaryContainer"),
                     "typography": _t("labelLarge"), "rounded": _r("full"), "height": "48dp", "padding": "0 24dp"},
    "button-outlined": {"textColor": _c("primary"), "borderColor": _c("outline"), "typography": _t("labelLarge"),
                        "rounded": _r("full"), "height": "48dp", "padding": "0 24dp"},
    "button-text": {"textColor": _c("primary"), "typography": _t("labelLarge"), "rounded": _r("full"),
                    "height": "48dp", "padding": "0 12dp"},
    "fab-add-goal": {"backgroundColor": _c("primary"), "textColor": _c("onPrimary"), "typography": _t("labelLarge"),
                     "rounded": _r("lg"), "height": "56dp", "padding": "0 20dp"},
    "fab-manual-entry": {"backgroundColor": _c("secondaryContainer"), "textColor": _c("onSecondaryContainer"),
                         "typography": _t("labelLarge"), "rounded": _r("lg"), "height": "56dp", "padding": "0 20dp"},
    "chip-filter": {"textColor": _c("onSurfaceVariant"), "borderColor": _c("outline"), "typography": _t("labelLarge"),
                    "rounded": _r("sm"), "height": "32dp", "padding": "0 12dp"},
    "chip-filter-selected": {"backgroundColor": _c("secondaryContainer"), "textColor": _c("onSecondaryContainer"),
                             "typography": _t("labelLarge"), "rounded": _r("sm"), "height": "32dp", "padding": "0 12dp"},
    "segmented-button-selected": {"backgroundColor": _c("secondaryContainer"), "textColor": _c("onSecondaryContainer"),
                                  "borderColor": _c("outline"), "typography": _t("labelLarge"), "rounded": _r("full"),
                                  "height": "48dp", "padding": "0 12dp"},
    "switch-selected": {"backgroundColor": _c("secondary"), "textColor": _c("onSecondary"), "rounded": _r("full"),
                        "height": "32dp", "width": "52dp"},
    "switch-unselected": {"backgroundColor": _c("surfaceContainerHighest"), "textColor": _c("outline"),
                          "borderColor": _c("outline"), "rounded": _r("full"), "height": "32dp", "width": "52dp"},
    "badge": {"backgroundColor": _c("primary"), "textColor": _c("onPrimary"), "typography": _t("labelSmall"),
              "rounded": _r("full"), "height": "16dp", "padding": "0 4dp"},
    "status-pill-warning": {"backgroundColor": "{colors.light-status-warning-container}",
                            "textColor": "{colors.light-status-warning-onContainer}", "typography": _t("labelMedium"),
                            "rounded": _r("sm"), "height": "28dp", "padding": "0 10dp"},
    "list-group": {"backgroundColor": _c("surfaceContainerLow"), "rounded": _r("lg"), "padding": "4dp 0"},
    "list-row": {"textColor": _c("onSurface"), "typography": _t("titleMedium"), "height": "72dp", "padding": "0 16dp"},
    "input-outlined": {"textColor": _c("onSurface"), "borderColor": _c("outline"), "typography": _t("bodyLarge"),
                       "rounded": _r("md"), "height": "56dp", "padding": "0 16dp"},
    "input-money": {"textColor": _c("onSurface"), "borderColor": _c("outline"), "typography": "{typography.moneyInput}",
                    "rounded": _r("md"), "height": "64dp", "padding": "0 16dp"},
    "navigation-bar": {"backgroundColor": _c("surfaceContainer"), "textColor": _c("onSurfaceVariant"),
                       "typography": _t("labelSmall"), "height": "80dp"},
    "navigation-indicator": {"backgroundColor": _c("secondaryContainer"), "textColor": _c("onSecondaryContainer"),
                             "rounded": _r("full"), "height": "32dp", "width": "64dp"},
    "bottom-sheet": {"backgroundColor": _c("surfaceContainerLow"), "rounded": _r("xxl"), "padding": "0 20dp 20dp"},
    "snackbar": {"backgroundColor": _c("inverseSurface"), "textColor": _c("onInverseSurface"),
                 "typography": _t("bodyMedium"), "rounded": _r("sm"), "padding": "0 16dp"},
    "status-hero-ok": {"backgroundColor": "{colors.light-status-ok-heroBackground}",
                       "textColor": "{colors.light-status-ok-heroForeground}", "typography": "{typography.moneyHero}",
                       "rounded": _r("xl"), "padding": "20dp"},
    "status-hero-warning": {"backgroundColor": "{colors.light-status-warning-heroBackground}",
                            "textColor": "{colors.light-status-warning-heroForeground}",
                            "typography": "{typography.moneyHero}", "rounded": _r("xl"), "padding": "20dp"},
    "status-hero-danger": {"backgroundColor": "{colors.light-status-danger-heroBackground}",
                           "textColor": "{colors.light-status-danger-heroForeground}",
                           "typography": "{typography.moneyHero}", "rounded": _r("xl"), "padding": "20dp"},
    "status-hero-unknown": {"backgroundColor": "{colors.light-status-unknown-heroBackground}",
                            "textColor": "{colors.light-status-unknown-heroForeground}", "typography": _t("titleMedium"),
                            "rounded": _r("xl"), "padding": "20dp"},
    "floor-ruler": {"backgroundColor": "{colors.light-status-ok-heroBarReserved}",
                    "textColor": "{colors.light-status-ok-heroBarFree}", "rounded": _r("full"), "height": "12dp"},
    "goal-progress-track": {"backgroundColor": _c("surfaceContainerHighest"), "rounded": _r("full"), "height": "6dp"},
    "demo-banner": {"backgroundColor": _c("tertiaryContainer"), "textColor": _c("onTertiaryContainer"),
                    "typography": _t("labelLarge"), "height": "48dp", "padding": "0 12dp 0 16dp"},
    "demo-button": {"backgroundColor": _c("tertiary"), "textColor": _c("onTertiary"), "typography": _t("labelLarge"),
                    "rounded": _r("full"), "height": "48dp", "padding": "0 24dp 0 16dp"},
}

# ---------------------------------------------------------------- assemble

def conv(d):
    return {k: hexc(*v) for k, v in d.items()}


def main(out_path):
    fixed = conv(FIXED)
    light = {**conv(LIGHT), **fixed}
    dark = {**conv(DARK), **fixed}
    status = {t: {lvl: conv(v) for lvl, v in levels.items()} for t, levels in STATUS.items()}
    for t in status:
        for lvl in status[t]:
            if "heroBarReserved" in status[t][lvl]:  # levels with a floor ruler
                status[t][lvl]["heroBarFree"] = status[t][lvl]["heroForeground"]
    tokens = {
        "schemaVersion": 1,
        "name": "Chi tiêu",
        "maturity": "seed: chosen before implementation; re-run impeccable document (scan) after mobile/lib/theme exists",
        "northStar": "Bát men lam",
        "source": "generated by .agents/design-state/tools/build_tokens.py from OKLCH anchors; edit the anchors there, not this file",
        "color": {"light": light, "dark": dark},
        "statusColors": status,
        "typography": {
            "fontFamily": FAMILY, "flutterFontFamily": FLUTTER_FAMILY,
            "assets": {"400": "BeVietnamPro-Regular.ttf", "500": "BeVietnamPro-Medium.ttf", "600": "BeVietnamPro-SemiBold.ttf",
                        "700": "BeVietnamPro-Bold.ttf", "800": "BeVietnamPro-ExtraBold.ttf"},
            "leadingDistribution": "even",
            "roles": {k: {"fontSize": s, "fontWeight": w, "height": h, "letterSpacing": ls} for k, (s, w, h, ls) in TYPE.items()},
            "money": MONEY,
            "tabularFigures": {"openTypeTnum": False, "strategy": "fixed digit cells", "digitCellEm": DIGIT_CELL_EM,
                                "minusSign": "U+2212", "groupSeparator": ".", "unit": "đ"},
        },
        "spacing": SPACING,
        "layout": LAYOUT,
        "breakpoints": BREAKPOINTS,
        "radius": RADIUS,
        "elevation": ELEVATION,
        "motion": MOTION,
        "components": COMPONENTS,
    }
    with open(out_path, "w", encoding="utf-8") as fh:
        json.dump(tokens, fh, ensure_ascii=False, indent=2)
        fh.write("\n")


if __name__ == "__main__":
    main(sys.argv[1])
