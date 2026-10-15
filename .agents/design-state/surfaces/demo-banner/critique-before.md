# Critique (before redesign): Demo banner "Bản dùng thử · dữ liệu giả" (+ simulate sheet)

**DEGRADED: single-context** (impeccable `critique` run by hand inside one workflow subagent: no sub-agent tool is
exposed, and the engine/detector is out of bounds under the Runtime boundary. Native source checks replace Assessment B
and were run after the design review.)

- **Target:** `mobile/lib/demo/demo_controls.dart` (`DemoShell`, `DemoBanner`, `DemoSimulateSheet`), wired in
  `demo/demo_app.dart` and `main_demo.dart`. Line numbers refer to HEAD `10ba63c` (the before state; the working tree is being redesigned in parallel).
- **Evidence:** Flutter **web demo** in Chromium via Playwright (this surface exists only on the web), TZ
  Asia/Ho_Chi_Minh.
  - `B/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/demo_web/before/`
    (the strip at the top of every shot; `simulate-sheet-390x844-light.png`, `simulate-sheet-1280x800-dark.png`).

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | The button disables while simulating; a SnackBar explains when no push follows |
| 2 | Match System / Real World | 3 | "Bản dùng thử · dữ liệu giả" is unambiguous; "webhook SePay" is fine for the owner but opaque to a guest |
| 3 | User Control and Freedom | 3 | "Đặt lại dữ liệu demo"; reconnect after a disconnect |
| 4 | Consistency and Standards | 2 | The demo control uses the product's primary fill; 36 dp target; a forced line break in the label |
| 5 | Error Prevention | 3 | Amount validated; the reset has no confirmation (low stakes in a demo) |
| 6 | Recognition Rather Than Recall | 3 | Presets list the amount and the expected categorisation |
| 7 | Flexibility and Efficiency | 3 | One-tap presets plus a custom entry |
| 8 | Aesthetic and Minimalist Design | 3 | Compact strip; the sheet is a long form under a preset card |
| 9 | Error Recovery | 3 | "Nhập số tiền lớn hơn 0" inline |
| 10 | Help and Documentation | 3 | The sheet explains what a simulation does |
| **Total** | | **29/40** | **Good** |

## Design Specificity Verdict

**LLM assessment:** the strip does its job (no one will mistake the demo for real money), but its single control is
the loudest fill on every screen: a dark-teal `FilledButton` that out-shouts the product's own primary action, "Thêm
mục tiêu" (`B/dashboard-390x844-light.png`: the demo button is the darkest element at the top, while the FAB is pale
teal). The label is squeezed into two lines by a 112 dp cap.

**Deterministic scan (native checks, this surface):** `Colors.*`: 0 · `Color(0x`: 0 · literal `fontSize:`: 0 ·
`IconButton`: none · **hit targets < 48 dp: 2** (`demo_controls.dart:186-189` and `:198-201`: `shrinkWrap` +
`VisualDensity.compact` + `minimumSize: Size(0, 36)`) · lists: the preset `Card` holds 4 rows (fine) · emoji as icon:
none ("→" appears in prose helper text at `:492`, acceptable). The scan finds the target-size problem the visual review
would miss.

## Overall Impression

A well-behaved preview harness (fonts bundled, no network, semantics on, a clear label) whose control is styled as if it
were the product. The biggest opportunity: a celadon `tertiary` button at a full 48 dp, in an `OverflowBar` that moves
it to a second row instead of ellipsizing anything.

## What's Working

- **The label is one semantics node** ("Bản dùng thử · dữ liệu giả", `:235-239`), and the banner sits above every route
  in its own semantics container so modal barriers do not hide it (`:57-63`).
- **Honest feedback:** when a simulation creates no push, a SnackBar says why ("… không tạo cảnh báo quan trọng nên
  không có thông báo đẩy (bản thật cũng vậy) — xem ở tab Cảnh báo", `:150-158`).
- **Self-contained:** fonts are loaded from relative URLs, so there are no external requests (the harness reports 0
  blocked requests), and the simulate sheet already uses `maxWidth: 640` (`:351`).

## Priority Issues

1. **[P1] The demo spends the product's primary colour.**
   *Why:* `FilledButton.icon` with the default `primary` (`:182-211`) is the strongest fill on every screen and competes
   with "Thêm mục tiêu" (The One Cobalt Rule).
   *Fix:* a filled `tertiary` / `onTertiary` button (celadon on the `tertiaryContainer` strip), `labelLarge`, 16 dp start
   with the icon, 24 dp end.
   *Command:* /impeccable colorize.
2. **[P1] The touch target is below 48 dp.**
   *Why:* `tapTargetSize: shrinkWrap`, `VisualDensity.compact`, 36 dp minimum height (`:186-189, 198-201`).
   *Fix:* `MaterialTapTargetSize.padded`, a 48 dp minimum; strip height at least 48 dp.
   *Command:* /impeccable harden.
3. **[P2] The label and button are squeezed and ellipsized.**
   *Why:* `labelMedium` (`:180`), a forced line break "Bản dùng thử\ndữ liệu giả" (`:241`) under a 112 dp cap (`:223`),
   and `maxLines` with an ellipsis on both texts (`:192, 247-248`). At 360 dp or 130% text the button reads "Giả lập
   biến động s…".
   *Fix:* lay out like `OverflowBar`: one row when both fit at their natural width (about 480 dp at 100%), otherwise
   the button moves to a second row, end-aligned (88 dp strip; 94 dp at 130%). Never ellipsize. Use `labelLarge` and
   keep "số dư" in the button text.
   *Command:* /impeccable adapt.
4. **[P2] The phone column masks the real wide layout.**
   *Why:* above 600 dp the shell clamps the app to a 440 dp column and rewrites `MediaQuery.size` (`:41-87`), so the
   1280 screenshots (`B/*-1280x800-*.png`) never show the real app's expanded layout, which today stretches edge to edge
   (see `dashboard/critique-before.md`, issue 6).
   *Fix:* once the app has `NavigationRail` at ≥ 840 dp and a 720 dp content column, drop the clamp (or keep it only
   below 840 dp) so the demo previews the real adaptive layout. Update the screenshot harness if any semantics labels
   move.
   *Command:* /impeccable adapt.

## Further Issues (ranked)

5. **[P3] Simulate sheet details.** The title is in `titleLarge` while other sheets use `headlineSmall`; presets sit in an
   elevated `Card` (`:440-456`, a shadow on content); "Tạo biến động" is another primary fill (`:507-512`); the direction
   icons are `arrow_upward` / `arrow_downward` while the app's Nhập tay uses `north_east` / `south_west` (`:462-463`);
   "Đặt lại dữ liệu demo" has no confirmation.
6. **[P3] Disconnected label on narrow screens** shortens the button to "Kết nối lại" (with full semantics, `:204-210`);
   with the `OverflowBar` layout the full "Kết nối lại bản dùng thử" fits on its own row.

## Persona Red Flags

- **A guest opening the shared demo link:** the first thing the eye lands on is a dark "Giả lập biến động số dư"
  button, not the product's state; the label beside it is two cramped lines.
- **Sam (TalkBack, web):** the label is announced well; the 36 dp button is hard to hit on touch screens.

## Minor Observations

- Strip colour: in the current seed theme `tertiaryContainer` is pale blue in light mode and slate in dark; with the
  Bát men lam scheme it becomes celadon (`#CDEEEA` / `#184642`), which no state glaze resembles.
- The demo snackbars run for 6 s with long explanations; acceptable for a demo, but keep them under three lines.

## Questions to Consider

- Should tapping the label explain the demo ("Số liệu chỉ để minh hoạ, không phải tài khoản thật."), or is the
  always-visible strip enough? (Open in the brief.)

## What Must Change to Meet DESIGN.md

- [ ] A filled `tertiary` demo button at 48 dp, `labelLarge`, `Icons.bolt` / `Icons.link`.
- [ ] An `OverflowBar`-style two-row fallback, with neither text ellipsized; label `labelLarge` with
  `Icons.science_outlined` 18 dp.
- [ ] Remove the 440 dp clamp at ≥ 840 dp once the app is adaptive.
- [ ] Colours from the theme only (already true; keep it), keys `demo_simulate`, `demo_reconnect` and presets unchanged.

Trend: first run for this target, so there is no trend yet. The snapshot lives in this file.

Questions skipped: non-interactive workflow subagent with no question tool; the owner's decisions came with the task
(4 priority issues listed).
