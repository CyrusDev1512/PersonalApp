"""WCAG 2.x contrast and colour-vision check for the Chi tiêu tokens.

Usage: python3 -P -E contrast.py <design.json> [table.md] [summary.md] [hero.md]
Checks every text-on-surface and drawn-UI pair (light + dark), prints a summary, optionally writes markdown tables,
and exits 1 if any required pair is below its threshold or two status-hero glazes are too close.

Kinds and thresholds:
  body   4.5:1  text below 18.66 dp bold / 24 dp regular
  ui     3:1    non-text UI needed to see a control or its state (borders, bars, ticks, icons, thumbs)
  info   none   adjacent ruler segments separated by a 2 dp heroBackground gap, and the tick on the free segment
                (drawn with a 2 dp heroBackground halo); listed to show why the gap/halo is required
  exempt none   decorative or redundant edges (WCAG 1.4.11 does not require them): dividers, the goal-progress
                track, the navigation indicator and selected-chip fill (state also shown by a filled icon / check)
Hero distinctness: ΔE_OKLab between every pair of status-hero backgrounds of one theme, for normal vision and
protanopia / deuteranopia / tritanopia simulated with Machado et al. 2009 (severity 1.0) on linear sRGB.
Required >= 0.08 for normal, protan and deutan; tritan is reported (UNKNOWN is also told apart by its layout).
"""
import itertools
import json
import math
import sys


def _lin(c):
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _rgb(hex_):
    h = hex_.lstrip("#")
    return [_lin(int(h[i:i + 2], 16)) for i in (0, 2, 4)]


def luminance(hex_):
    r, g, b = _rgb(hex_)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(fg, bg):
    a, b = luminance(fg), luminance(bg)
    hi, lo = max(a, b), min(a, b)
    return (hi + 0.05) / (lo + 0.05)


CVD = {
    "normal": None,
    "protan": [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
    "deutan": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
    "tritan": [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}
CVD_REQUIRED = {"normal": 0.08, "protan": 0.08, "deutan": 0.08, "tritan": 0.0}


def _oklab(lrgb):
    r, g, b = (min(max(x, 0.0), 1.0) for x in lrgb)
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l, m, s = (x ** (1 / 3) for x in (l, m, s))
    return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


def delta_e(a, b, kind):
    def sim(h):
        v = _rgb(h)
        mtx = CVD[kind]
        return v if mtx is None else [sum(mtx[i][j] * v[j] for j in range(3)) for i in range(3)]
    return math.dist(_oklab(sim(a)), _oklab(sim(b)))


THRESH = {"body": 4.5, "large": 3.0, "ui": 3.0, "info": 0.0, "exempt": 0.0}

SURFACES = ["surface", "surfaceDim", "surfaceBright", "surfaceContainerLowest", "surfaceContainerLow",
            "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest"]
CONTENT_SURFACES = ["surface", "surfaceContainerLowest", "surfaceContainerLow", "surfaceContainer",
                    "surfaceContainerHigh", "surfaceContainerHighest"]
RULER_LEVELS = ("ok", "warning", "danger")


def pairs_for(theme, c, s):
    """Yield (group, fgName, bgName, fgHex, bgHex, kind)."""
    on_pairs = [
        ("onPrimary", "primary"), ("onPrimaryContainer", "primaryContainer"),
        ("onSecondary", "secondary"), ("onSecondaryContainer", "secondaryContainer"),
        ("onTertiary", "tertiary"), ("onTertiaryContainer", "tertiaryContainer"),
        ("onError", "error"), ("onErrorContainer", "errorContainer"),
        ("onInverseSurface", "inverseSurface"), ("inversePrimary", "inverseSurface"),
        ("onPrimaryFixed", "primaryFixed"), ("onPrimaryFixedVariant", "primaryFixed"),
        ("onPrimaryFixed", "primaryFixedDim"),
        ("onSecondaryFixed", "secondaryFixed"), ("onSecondaryFixedVariant", "secondaryFixed"),
        ("onSecondaryFixed", "secondaryFixedDim"),
        ("onTertiaryFixed", "tertiaryFixed"), ("onTertiaryFixedVariant", "tertiaryFixed"),
        ("onTertiaryFixed", "tertiaryFixedDim"),
    ]
    for fg, bg in on_pairs:
        yield ("on-role", fg, bg, c[fg], c[bg], "body")
    for bg in SURFACES:
        yield ("surface text", "onSurface", bg, c["onSurface"], c[bg], "body")
    for bg in SURFACES:
        yield ("surface text", "onSurfaceVariant", bg, c["onSurfaceVariant"], c[bg], "body")
    # accent text on content surfaces (TextButton labels, links, form errors)
    for role in ("primary", "error", "tertiary", "secondary"):
        for bg in CONTENT_SURFACES:
            yield ("accent text", role, bg, c[role], c[bg], "body")
    # chip/nav indicators carry onSurface text too
    yield ("accent text", "onSurface", "secondaryContainer", c["onSurface"], c["secondaryContainer"], "body")
    # non-text UI: field borders, unselected chip and segmented-button strokes, outlined buttons (all `outline`)
    for bg in ("surface", "surfaceContainerLow", "surfaceContainerHigh"):
        yield ("non-text", "outline", bg, c["outline"], c[bg], "ui")
    yield ("non-text", "primary (progress)", "surfaceContainerHighest", c["primary"], c["surfaceContainerHighest"], "ui")
    # Switch (themed: selected track secondary + thumb onSecondary; unselected track surfaceContainerHighest,
    # outline border and thumb)
    for bg in ("surface", "surfaceContainerLow"):
        yield ("switch", "secondary (selected track)", bg, c["secondary"], c[bg], "ui")
    yield ("switch", "onSecondary (thumb)", "secondary", c["onSecondary"], c["secondary"], "ui")
    yield ("switch", "outline (unselected thumb)", "surfaceContainerHighest", c["outline"], c["surfaceContainerHighest"], "ui")
    # Badge on the navigation bar (Calm Badge Rule: primary, never error)
    yield ("badge", "primary (badge)", "surfaceContainer", c["primary"], c["surfaceContainer"], "ui")
    # Demo button on the demo strip
    yield ("demo", "tertiary (button)", "tertiaryContainer", c["tertiary"], c["tertiaryContainer"], "ui")
    # Known low pairs that WCAG 1.4.11 does not require
    yield ("exempt", "outlineVariant (divider)", "surfaceContainerLow", c["outlineVariant"], c["surfaceContainerLow"], "exempt")
    yield ("exempt", "surfaceContainerHighest (goal track)", "surfaceContainerLow", c["surfaceContainerHighest"],
           c["surfaceContainerLow"], "exempt")
    yield ("exempt", "secondaryContainer (nav indicator)", "surfaceContainer", c["secondaryContainer"], c["surfaceContainer"], "exempt")
    yield ("exempt", "secondaryContainer (selected chip)", "surface", c["secondaryContainer"], c["surface"], "exempt")
    # status
    for lvl, t in s.items():
        for bg in SURFACES:
            yield (f"status {lvl}", f"{lvl}.foreground", bg, t["foreground"], c[bg], "body")
        yield (f"status {lvl}", f"{lvl}.onContainer", f"{lvl}.container", t["onContainer"], t["container"], "body")
        yield (f"status {lvl}", f"{lvl}.foreground (icon)", f"{lvl}.container", t["foreground"], t["container"], "ui")
        yield (f"status {lvl}", f"{lvl}.heroForeground", f"{lvl}.heroBackground", t["heroForeground"], t["heroBackground"], "body")
        if lvl in RULER_LEVELS:
            yield (f"status {lvl}", f"{lvl}.heroBarReserved", f"{lvl}.heroBackground", t["heroBarReserved"], t["heroBackground"], "ui")
            yield (f"status {lvl}", f"{lvl}.heroBarFree", f"{lvl}.heroBackground", t["heroBarFree"], t["heroBackground"], "ui")
            # the tick (heroForeground) is always drawn on heroBackground: on its own, or inside a 2 dp halo
            yield (f"status {lvl}", f"{lvl}.tick (heroForeground)", f"{lvl}.heroBackground (halo)",
                   t["heroForeground"], t["heroBackground"], "ui")
            # without the halo the tick would vanish on the free segment: informational, shows why the halo exists
            yield (f"status {lvl}", f"{lvl}.tick (heroForeground)", f"{lvl}.heroBarFree (no halo)",
                   t["heroForeground"], t["heroBarFree"], "info")
            # segments are separated by a 2dp gap of heroBackground, so this pair is informational only
            yield (f"status {lvl}", f"{lvl}.heroBarFree", f"{lvl}.heroBarReserved", t["heroBarFree"], t["heroBarReserved"], "info")
        if lvl != "unknown":
            # progress bars drawn in status foreground on the track
            yield (f"status {lvl}", f"{lvl}.foreground (bar)", "surfaceContainerHighest", t["foreground"], c["surfaceContainerHighest"], "ui")


def hero_rows(tokens):
    rows = []
    for theme in ("light", "dark"):
        s = tokens["statusColors"][theme]
        for a, b in itertools.combinations(("ok", "warning", "danger", "unknown"), 2):
            ha, hb = s[a]["heroBackground"], s[b]["heroBackground"]
            vals = {k: delta_e(ha, hb, k) for k in CVD}
            ok = all(vals[k] >= CVD_REQUIRED[k] for k in CVD)
            rows.append((theme, a, b, ha, hb, vals, ok))
    return rows


def main():
    tokens = json.load(open(sys.argv[1], encoding="utf-8"))
    out = sys.argv[2] if len(sys.argv) > 2 else None
    rows, fails = [], []
    mins = {}
    for theme in ("light", "dark"):
        c = tokens["color"][theme]
        s = tokens["statusColors"][theme]
        for group, fgn, bgn, fg, bg, kind in pairs_for(theme, c, s):
            r = ratio(fg, bg)
            ok = r >= THRESH[kind]
            rows.append((theme, group, fgn, bgn, fg, bg, kind, r, ok))
            key = (theme, kind)
            if key not in mins or r < mins[key][0]:
                mins[key] = (r, fgn, bgn)
            if not ok:
                fails.append(rows[-1])
    heroes = hero_rows(tokens)
    hero_fails = [h for h in heroes if not h[6]]
    hero_text = {}
    for theme in ("light", "dark"):
        s = tokens["statusColors"][theme]
        vals = [ratio(s[l]["heroForeground"], s[l]["heroBackground"]) for l in RULER_LEVELS]
        hero_text[theme] = (min(vals), max(vals))

    lines = ["| Theme | Group | Foreground | Background | Hex | Kind | Ratio | Pass |",
             "|---|---|---|---|---|---|---:|:---:|"]
    for theme, group, fgn, bgn, fg, bg, kind, r, ok in rows:
        mark = "yes" if ok else "NO"
        if kind in ("info", "exempt"):
            mark = "n/a"
        lines.append(f"| {theme} | {group} | {fgn} | {bgn} | {fg} on {bg} | {kind} | {r:.2f} | {mark} |")
    table = "\n".join(lines) + "\n"
    if out:
        open(out, "w", encoding="utf-8").write(table)

    required = [r for r in rows if r[6] in ("body", "ui")]
    summary_out = sys.argv[3] if len(sys.argv) > 3 else None
    if summary_out:
        names = {"body": "body text (>= 4.5)", "ui": "non-text UI (>= 3.0)",
                 "info": "gap / halo pairs (info)", "exempt": "exempt edges (not required)"}
        sm = [f"**{len(rows)} pairs listed, {len(required)} required, {len(fails)} below threshold; "
              f"{len(heroes)} hero-glaze pairs, {len(hero_fails)} too close.** Lowest ratio per theme and kind:", ""]
        sm += ["| Theme | Kind | Min ratio | Pair |", "|---|---|---:|---|"]
        for (theme, kind), (r, fgn, bgn) in sorted(mins.items()):
            sm.append(f"| {theme} | {names[kind]} | {r:.2f} | {fgn} on {bgn} |")
        sm += ["", "Hero numeral and hero text (heroForeground on heroBackground, OK / WARNING / DANGER): "
               + ", ".join(f"{t} {lo:.2f}-{hi:.2f}:1" for t, (lo, hi) in hero_text.items())
               + " (UNKNOWN shows no numeral)."]
        open(summary_out, "w", encoding="utf-8").write("\n".join(sm) + "\n")
    hero_out = sys.argv[4] if len(sys.argv) > 4 else None
    if hero_out:
        hl = ["| Theme | Glazes | Hex | Normal | Protan | Deutan | Tritan | Pass |",
              "|---|---|---|---:|---:|---:|---:|:---:|"]
        for theme, a, b, ha, hb, vals, ok in heroes:
            hl.append(f"| {theme} | {a} / {b} | {ha} / {hb} | " + " | ".join(f"{vals[k]:.3f}" for k in CVD)
                      + f" | {'yes' if ok else 'NO'} |")
        open(hero_out, "w", encoding="utf-8").write("\n".join(hl) + "\n")

    print(f"pairs listed: {len(rows)}  required: {len(required)}  failures: {len(fails)}  "
          f"hero pairs: {len(heroes)}  too close: {len(hero_fails)}")
    for (theme, kind), (r, fgn, bgn) in sorted(mins.items()):
        print(f"min {theme:5s} {kind:6s} {r:5.2f}  ({fgn} on {bgn}; threshold {THRESH[kind]})")
    for t, (lo, hi) in hero_text.items():
        print(f"hero text {t}: {lo:.2f}-{hi:.2f}")
    for k in CVD:
        m = min(heroes, key=lambda h: h[5][k])
        print(f"min hero dE {k:6s} {m[5][k]:.3f} ({m[0]} {m[1]}/{m[2]})")
    for f in fails:
        print("FAIL", f)
    for h in hero_fails:
        print("HERO TOO CLOSE", h)
    sys.exit(1 if fails or hero_fails else 0)


if __name__ == "__main__":
    main()
