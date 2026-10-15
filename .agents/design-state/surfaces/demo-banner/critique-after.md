# Critique (after redesign): Demo banner "Bản dùng thử · dữ liệu giả" (+ simulate sheet)

**DEGRADED: single-context** (impeccable `critique` done by hand in one verifier subagent. No sub-agent tool, and the
engine/detector is out of bounds. The AGENTS.md native source checks replace Assessment B.)

- **Target:** `mobile/lib/demo/demo_controls.dart` (`DemoBanner`, simulate sheet). Working tree on HEAD `c7fe25b`.
- **Evidence:** Flutter **web demo** in Chromium only.
  - `B/` = `…/scratchpad/demo_web/before/`
  - `A/` = `…/scratchpad/demo_web/after/`
  - `X/` = `…/scratchpad/demo_web/after/extra/`
  - `V/` = `…/scratchpad/redesign_verify/critique/` (crops `banner390.png`, `banner1280.png`; pixel samples below)
  - `…` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8`

## Design Health Score (before → after)

| # | Heuristic | Before | After | Key issue now |
|---|-----------|-------:|------:|---------------|
| 1 | Visibility of System Status | 3 | 3 | Busy state disables the button and keeps its label |
| 2 | Match System / Real World | 3 | 3 | Unambiguous label; "webhook SePay" in the sheet is still opaque to a guest |
| 3 | User Control and Freedom | 3 | 3 | Reset and reconnect paths kept |
| 4 | Consistency and Standards | 2 | 3 | Celadon `tertiary` button (One Cobalt Rule kept), 48 dp target, `labelLarge`. The pill touches the strip edges |
| 5 | Error Prevention | 3 | 3 | Amount validated |
| 6 | Recognition Rather Than Recall | 3 | 3 | Presets list amount and expected categorisation with icon discs |
| 7 | Flexibility and Efficiency | 3 | 3 | One-tap presets plus custom entry |
| 8 | Aesthetic and Minimalist Design | 3 | 3 | Label on one line with no ellipsis. But the button pill sits flush on the strip's edge |
| 9 | Error Recovery | 3 | 3 | Inline amount error |
| 10 | Help and Documentation | 3 | 3 | The sheet explains what a simulation does |
| **Total** | | **29/40** | **30/40** | **Good → Good** |

## Design Specificity Verdict

**Assessment (unanchored):** the strip now reads as "not the app's state". It uses `tertiaryContainer` celadon with
`science_outlined` and the label "Bản dùng thử · dữ liệu giả" on one line (it wrapped to two lines in
`B/dashboard-390x844-light.png`). The single demo button is filled `tertiary`, not cobalt. Below about 480 dp the
button moves to a second row, end-aligned, and neither text is cut (`A/dashboard-390x844-light.png`). At 1280 it is
one row (`A/dashboard-1280x800-light.png`). The simulate sheet matches the app: preset rows with 40 dp icon discs and
inset dividers, a segmented "Tiền ra" / "Tiền vào", and the money field (`A/simulate-sheet-390x844-light.png`). At 1280
the sheet is 640 dp wide (`A/simulate-sheet-1280x800-dark.png`).

**Native source checks:** no hard-coded colours (`scheme.tertiary` / `onTertiary` / `tertiaryContainer`,
`demo_controls.dart:155-163`). The button is `MaterialTapTargetSize.padded` (`:165`). Text widths are measured with
`TextPainter`, so the label is never ellipsised (`:191-207`).

## What improved

- The cobalt demo button became celadon `tertiary`, so cobalt stays reserved for "Thêm mục tiêu".
- `labelMedium` became `labelLarge`; the 36 dp shrink-wrapped target became 48 dp.
- The 112 dp label cap and its ellipsis are replaced by the OverflowBar-style two-row fallback.

## Priority Issues (what still fails)

1. **[P2] The button pill sits flush on the strip edge; there is no vertical breathing room.**
   - *Evidence at 390x844:* the `tertiary` pill (45,102,97) runs from y = 72 px to 167 px (36–84 dp), and the strip
     ends at y = 168 px, where the page `surface` (248,250,253) starts. The pill's bottom edge is the strip's bottom
     edge (`V/banner390.png`, `A/dashboard-390x844-light.png`).
   - *Evidence at 1280x800:* the pill fills the whole 48 dp strip from y = 0 to 47 px (`V/banner1280.png`).
   - *Cause:*
     - The visual button is 48 dp (theme `buttonMinSize`, `theme/app_theme.dart:61`).
     - The one-row layout is `minHeight: 48` with no padding (`demo_controls.dart:209-219`).
     - The two-row layout gives the button no bottom padding (`:224-229`).
     - The brief's own arithmetic (12 + 20 + 8 + 48 = 88 dp) assumed the 48 dp was a touch target around a smaller
       visual button.
   - *Why it matters:* it is on every demo screen, at the top of the first viewport. The button looks like it is
     sliding off the banner, which reads as unfinished.
   - *Fix:* add 8 dp vertical padding around the button in both layouts (the strip becomes 56 dp in one row and
     96 dp in two rows). The alternative is a 40 dp visual button inside the 48 dp padded target, as M3 does.
   - *Command:* /impeccable polish.

## Persona Red Flags

- **A guest shown the demo:** they cannot mistake it for real money (strip plus label). "Giả lập biến động số dư" is
  the obvious action, and the resulting WARNING moment and compact snackbar are visible
  (`A/dashboard-after-atm-390x844-light.png`).

## Minor Observations

- In two-row mode the strip takes 84 dp of a 844 dp phone viewport, with the label row mostly empty to its right.
  This is acceptable for a preview build.
- "Kết nối lại bản dùng thử" shows correctly after disconnecting (`X/connect-390-light.png`).

Trend: before 29/40 → after 30/40.

Questions skipped: fewer than 3 priority issues listed (1).
