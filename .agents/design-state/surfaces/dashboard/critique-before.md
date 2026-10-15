# Critique (before redesign): Tổng quan (dashboard)

**DEGRADED: single-context** (impeccable `critique` run by hand inside one workflow subagent: no sub-agent tool is
exposed, and the impeccable engine/detector is out of bounds under the Runtime boundary. Assessment A below was written
from the screenshots and code before the native source checks, which replace Assessment B, were run.)

- **Target:** `mobile/lib/screens/dashboard_screen.dart` with `widgets/status_banner.dart`, `widgets/forecast_card.dart`,
  `widgets/goal_card.dart`, `widgets/alert_tile.dart`, shell `screens/home_shell.dart`, theme `main.dart:30-34`.
  Line numbers refer to HEAD `10ba63c` (the before state; the working tree is being redesigned in parallel; at HEAD the screen files had not changed since 2026-10-14).
- **Evidence:** all screenshots come from the Flutter **web demo** (`lib/main_demo.dart`, in-app fake backend) in Chromium via
  Playwright, with TZ Asia/Ho_Chi_Minh unless stated. None come from a device or emulator.
  - `B/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/demo_web/before/`
    (harness run of 08:40: 390x844 @2x, 1280x800 @1x, light/dark).
  - `X/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/redesign/critique_extra/`
    (same artifact build: dashboard scrolled, TZ Europe/London, semantics dump of the flt-semantics tree).
  - The 1280 shots show the demo's 440 dp phone column (`demo/demo_controls.dart:41-87`), **not** the real app's wide
    layout (see issue 6).

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | State and amount are shown, but "được tiêu" is a secondary 22 sp metric. A status change is a silent number swap, and the push SnackBar hides the status for 8 s |
| 2 | Match System / Real World | 3 | Plain Vietnamese and the binding terms. "Mức sàn" needs its hint line, and the forecast says "khoảng 17.260.571đ" (false precision) |
| 3 | User Control and Freedom | 3 | Pull-to-refresh, chip shortcut, nothing destructive. The offline strip has no "Thử lại" |
| 4 | Consistency and Standards | 2 | Five container treatments for "look here"; hard-coded traffic-light colours beside theme roles; a chip exposed as a checkbox |
| 5 | Error Prevention | 3 | A read-mostly screen. The new-account question is answered inline with two buttons |
| 6 | Recognition Rather Than Recall | 3 | Labelled nav and chips. Accounts are missing here, so per-account balances need a trip to Cài đặt |
| 7 | Flexibility and Efficiency | 2 | Only the uncategorised shortcut. The refresh button duplicates auto-refresh |
| 8 | Aesthetic and Minimalist Design | 1 | The status is said three times; balance card, bordered banner, forecast card, chip, goal cards and recent alerts are stacked; the biggest number is the wrong one |
| 9 | Error Recovery | 2 | ErrorView with "Thử lại" when there is no cache. With a cache, a red strip with no action |
| 10 | Help and Documentation | 2 | Hint lines under the metrics. Nothing explains how the floor is built; the empty-goals card is good |
| **Total** | | **23/40** | **Acceptable** |

## Design Specificity Verdict

**LLM assessment (unanchored):** category-interchangeable. The screen is the generic finance template the brief refuses:
a balance card with two metric tiles, a traffic-light banner under it, then a forecast card and goal cards, all in
`ColorScheme.fromSeed(Colors.teal)` with platform Roboto (`main.dart:30-34`). None of "Bát men lam" exists yet:
there is no `lib/theme/`, no Be Vietnam Pro, no status hero, no floor ruler, no glaze change, no `MoneyText`. The product's
one idea ("được tiêu" = balance − floor, protected by a floor) is shown as two equal numbers side by side, and the total
balance, which the product does not care about, is the biggest number on screen. Another budgeting app could ship this
screen unchanged.

**Deterministic scan (native source checks replacing the web detector, dashboard scope):**

| Check | Result |
|---|---|
| `Color(0x` outside theme | 0. There is no `lib/theme/` at all; the scheme is `fromSeed(teal)` (`main.dart:32`) |
| `Colors.*` outside theme | 15 lines: `status_banner.dart:7-11`, `goal_card.dart:15,16,89`, `forecast_card.dart:8,9,114`, `dashboard_screen.dart:210,215,449`, `main.dart:32` |
| Literal `fontSize:` | 0 on this surface |
| `IconButton` without tooltip | 0 (`dashboard_screen.dart:60` has "Tải lại") |
| Hit targets < 48 dp | none found (ActionChip and FAB are padded) |
| Non-builder long lists | `ListView(` at `dashboard_screen.dart:85` holds at most about 10 goals + 5 alerts, which is acceptable |
| Emoji / glyphs as UI icons | none authored here. The category emoji in goal meta are user data (allowed); server emoji show up in "Cảnh báo gần đây" |
| Other rule breaks | synthesised italic `FontStyle.italic` (`status_banner.dart:69`); no money semantics (no `Semantics` on any amount) |

The scan agrees with the visual review on colour; it would not have caught the inverted hierarchy or the semantics
roles. No false positives.

## Overall Impression

What works is the information: every fact the owner needs is computed and present. What fails is the order and the
weight. The answer to "được tiêu bao nhiêu?" sits third in reading order at the size of a supporting stat, and the
same state is restated in three places. The single biggest opportunity is the status hero: one glazed object whose
numeral is "được tiêu", with the ruler explaining it and everything else demoted to rows.

## What's Working

- **Complete, honest data.** Freshness ("cập nhật lúc 20:45 14/10"), derived balance ("ước tính"), in-transit money,
  the pending salary, days left, a stale-balance threshold, and an offline state that keeps cached data
  (`dashboard_screen.dart:89, 198-304`).
- **The product's language is already right:** "Được tiêu thoải mái", "Mức sàn", "Cảnh báo khi dưới 600.000đ", "Tổng
  tiền còn phải giữ cho mục tiêu". The copy needs re-ordering, not rewriting.
- **Shortcuts that respect the job:** the uncategorised chip jumps to Giao dịch already filtered
  (`home_shell.dart:70-73`), and a goal tap opens its edit form.

## Priority Issues

1. **[P1] Hierarchy inverted; the status is restated three times.**
   *Why:* the first glance shows "10.000.000đ" in `headlineMedium` 700, while "4.000.000đ được tiêu" is a 22 sp metric in
   the second row, then a separate banner repeats "An toàn · Còn 4.000.000đ có thể tiêu thoải mái"
   (`B/dashboard-390x844-light.png`; `dashboard_screen.dart:238-283`, `status_banner.dart:57-64`). This breaks product
   principle 1 ("One number first") and the Numeral Leads Rule.
   *Fix:* replace `_BalanceCard`, `_Metric` and `StatusBanner` with the status hero from DESIGN.md › Status hero: heading
   with level icon; `moneyHero` numeral = `free` (signed in DANGER as "−350.000đ", meaning line "đã lấn vào tiền mục tiêu
   · còn 17 ngày", per the owner's decision); floor ruler; two-row legend ("Giữ cho mục tiêu", "Số dư"); context lines;
   freshness line.
   *Command:* /impeccable layout.
2. **[P1] Traffic-light colours are hard-coded, fail contrast and break The Red Is Earned Rule.**
   *Why:* "An toàn" is 3.39:1 on its green tint and "Sắp chạm mức mục tiêu" is 2.56:1 on its orange tint, both at
   16 sp/700, which needs 4.5:1. "500.000đ" in `Colors.orange.shade800` is 2.79:1 on the card (pixel-sampled from
   `B/dashboard-390x844-light.png` and `B/dashboard-after-atm-390x844-light.png`). The offline strip uses
   `errorContainer` (`dashboard_screen.dart:174`). OK is green, so cobalt never carries "you are fine"
   (`status_banner.dart:6-12`).
   *Fix:* `StatusColors` ThemeExtension with the DESIGN.md hero glazes (7.3:1 and up); a neutral offline strip
   (`surfaceContainerHigh`) with a "Thử lại" text button.
   *Command:* /impeccable colorize.
3. **[P1] Screen-reader semantics are wrong.**
   *Why:* the semantics dump shows "2 giao dịch chưa phân loại" exposed as `role=checkbox aria-checked=false`
   (ActionChip, `dashboard_screen.dart:113-121`). Each goal card collapses into one `progressbar` node: "Lặp lại hằng
   tháng Tiền trọ Quỹ giữ 🏠 Thuê trọ Đã dùng 0% Đã chi 0đ / 3.000.000đ 0% Còn phải giữ 3.000.000đ 0"
   (`goal_card.dart:30-33, 63-70`). The banner reads "Trạng thái: An toàn An toàn" (`status_banner.dart:37-40`). Amounts
   read as digit groups, not "… đồng". A level change is not announced.
   *Fix:* the "Cần bạn xem" row as a button-semantics `ListTile`; goal rows as `MergeSemantics` with a written label plus
   the progress value; one semantics node for the hero; `MoneyText` semantics; a live region on level change.
   *Command:* /impeccable audit.
4. **[P1] The foreground push SnackBar buries the dashboard.**
   *Why:* after the ATM simulation, a fixed, full-width SnackBar prints the whole Telegram body (11 lines with server
   emoji) for 8 s. It covers the WARNING banner, the goals and the FAB at exactly the moment the owner looks
   (`B/dashboard-after-atm-390x844-light.png`, `-dark`, `-1280x800-light`; `push/push_navigator.dart:33-44`).
   *Fix:* a floating SnackBar with the title and one short line (for example "Sắp chạm mức mục tiêu · −3.500.000đ VCB
   chính"), the "Xem" action, 6 s (DESIGN.md › Snackbars), above the FAB and the navigation bar.
   *Command:* /impeccable clarify.
5. **[P2] Box soup and duplicated content.**
   *Why:* a shadowed `Card`, a bordered tinted banner (`status_banner.dart:43-46`), a forecast `Card` with a coloured
   border (`forecast_card.dart:56-65`), an amber bordered health box (`dashboard_screen.dart:449-457`), an outlined chip,
   one `Card` per goal and a "Cảnh báo gần đây" card that repeats the Cảnh báo tab (`X/dash-scroll1-390-light.png`,
   `X/dash-scroll3-390-light.png`). This breaks The Flat At Rest Rule (shadows on content), the no-container-borders
   rule, and The Proximity Before Boxes Rule.
   *Fix:* flat list groups (`surfaceContainerLow`, radius 16, no border or shadow) for "Cần bạn xem", the forecast,
   goals and accounts; remove "Cảnh báo gần đây" and the app-bar refresh button.
   *Command:* /impeccable distill.

## Further Issues (ranked)

6. **[P2] No adaptive layout in the real app.** `HomeShell` always uses `NavigationBar` and has no max content width
   (`home_shell.dart:96-131`, `dashboard_screen.dart:85-88`), so at ≥ 840 dp the column stretches edge to edge. The demo
   hides this behind a 440 dp phone column (`demo/demo_controls.dart:67-87`).
   *Must:* `NavigationRail` (labelType all, FAB as `leading`) at ≥ 840 dp, a 720 dp centred content column, an optional
   two-pane split at ≥ 1200 dp.
7. **[P2] FAB off-spec.** It uses M3's `primaryContainer` default (pale teal) instead of `primary`; it is *disabled*
   (`onPressed: null`) when not connected and still shows over the ErrorView (`dashboard_screen.dart:64-68`). At rest it
   sits over the "Quỹ giữ" chip and the "Tiền ăn" card (`B/dashboard-390x844-light.png`, `X/dash-scroll1-390-light.png`).
   *Must:* `primary`/`onPrimary`, radius 16, hidden (never disabled) in the error-without-cache state; keep the 96 dp
   bottom clearance and make sure the first viewport ends on the ruler and legend, not on a tappable control under the FAB.
8. **[P2] No authored status-change moment.** The 30 s refresh swaps the numbers with no glaze tween, no count and no
   live-region announcement (DESIGN.md › The authored moment, with its Reduce motion fallback).
9. **[P2] Accounts are missing from Tổng quan.** The brief (owner decision) puts compact account rows here and in Cài đặt.
   Today per-account balances exist only in Cài đặt, and the UNKNOWN case is a separate `_UnknownBalanceCard`
   (`dashboard_screen.dart:333-379`).
10. **[P2] Stale and waiting states are coloured, not worded.** The stale freshness line turns amber and adds "(đã hơn 48
    giờ)" (`dashboard_screen.dart:209-256`). "Đang chờ lương — sẽ đủ khi nhận lương." is a synthesised italic
    (`status_banner.dart:65-71`). "Lương chờ nhận: 15.000.000đ (ngày 25)" sits in the balance card instead of the hero
    context lines.
11. **[P3] Negative amounts use an ASCII hyphen.** `formatGrouped` prefixes `-` (`utils/currency.dart:13`), so a DANGER
    `free` would render "-350.000đ". DESIGN.md requires "−" (U+2212).
12. **[P3] Loading is a bare `CircularProgressIndicator`** (`dashboard_screen.dart:42`); the brief asks for a static
    skeleton (hero block plus three rows).
13. **[P3] Section rhythm and heading role.** `SectionHeader` uses `titleMedium` with 16/6 dp padding (`common.dart:28-33`),
    against `titleLarge` with 32 dp between sections and 8 dp to content. The title reads "Mục tiêu tháng 10/2026"
    instead of "Mục tiêu tháng 10".
14. **[P3] Forecast block.** Coloured border and amber/red headline (`forecast_card.dart:8-9, 59-64`); "khoảng
    17.260.571đ" mixes "khoảng" with an exact figure. The brief wants two sentences in `moneyBody` with "~".
15. **[P3] Times use the device time zone.** "cập nhật lúc …" and the offline line go through `formatShortDateTime`, which
    calls `toLocal()` (`utils/dates.dart:48`; `dashboard_screen.dart:168, 250`). They must render in ICT via
    `lib/utils/dates.dart`.

## Persona Red Flags

- **Casey (one-handed, outdoors, seconds after paying):** has to read the balance card, the banner and the metric to
  find "được tiêu"; the green "4.000.000đ" is 3.73:1 on the card in daylight; after the payment push the SnackBar covers
  the answer for 8 s; the FAB sits on the goal list exactly where the thumb rests.
- **Sam (TalkBack):** hears "2 giao dịch chưa phân loại, hộp kiểm, chưa chọn"; each goal is a progress bar with a run-on
  label ending in "0"; "Trạng thái: An toàn An toàn"; amounts as digit groups; no announcement when the level changes.
- **Chủ tài khoản after an ATM withdrawal (project persona, PRODUCT.md › Users):** WARNING arrives as orange text on
  beige (2.56:1) plus a Telegram dump. Nothing shows how close the floor is (no ruler), and nothing says whether the
  pending salary will fix it.

## Minor Observations

- "Tổng số dư" uses `labelLarge` as a small label above the number (a kicker pattern the Numeral Leads Rule forbids).
- The next-month goals use a dense `ListTile` card with `titleSmall` trailing amounts (`dashboard_screen.dart:471-502`);
  the brief wants one collapsed row "Tháng 11 · 2 mục tiêu đã tạo trước".
- The empty-goals card uses a 40 dp `primary` flag icon and an OutlinedButton; the copy is good and should be kept.
- `_NewAccountCard` uses a FilledButton, a second cobalt fill on the screen (`dashboard_screen.dart:422`); the brief
  wants tonal "Tính vào tổng" with outlined "Không tính".

## Questions to Consider

- What if the total balance were only a legend line and "được tiêu" the only large number?
- Does Tổng quan need "Cảnh báo gần đây" at all, when the navigation badge and push already lead to the alert?
- Could the floor ruler carry the warning line so that the meaning line never has to repeat the buffer amount?

## What Must Change to Meet DESIGN.md

- [ ] `mobile/lib/theme/`: an explicit `ColorScheme` per brightness (no `fromSeed`, no Dynamic Color), `StatusColors`
  with a real `lerp`, `MoneyStyles`, Be Vietnam Pro bundled (400-800, OFL), tokens for spacing, radii, durations and
  easings; every component theme listed in DESIGN.md › Components.
- [ ] Status hero with the floor ruler, legend, context and freshness lines, and an UNKNOWN variant with its one filled
  button; a single semantics node; the authored moment with a Reduce motion fallback.
- [ ] A "Cần bạn xem" list group (uncategorised row with button semantics, new account, missing balance, ingest health).
- [ ] The forecast as a flat list group with sentences; goals as `MoneyRow`s in one list group (6 dp bar, fixed digit
  cells, large-text reflow, per-row semantics); next-month goals as one collapsed row; a compact accounts group using
  the shared account row.
- [ ] Remove "Cảnh báo gần đây", the refresh `IconButton`, `_UnknownBalanceCard` and the bordered boxes.
- [ ] FAB in `primary`, hidden (never disabled); a neutral offline strip with "Thử lại"; a skeleton for loading.
- [ ] A floating push SnackBar showing the title, one short line, "Xem" and 6 s; ICT times; `NavigationRail` at ≥ 840 dp
  with a 720 dp content column.

Trend: first run for this target, so there is no trend yet. The snapshot lives in this file (no `.impeccable/` directory
was created).

Questions skipped: non-interactive workflow subagent with no question tool; the owner's decisions on the open questions
came with the task (5 priority issues listed).
