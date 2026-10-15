# Critique (after redesign): Tổng quan (dashboard)

**DEGRADED: single-context** (impeccable `critique` done by hand in one verifier subagent. No sub-agent tool is
exposed, and the impeccable engine/detector is out of bounds under the Runtime boundary. The AGENTS.md native source
checks replace Assessment B and were run after the visual review.)

- **Target:** `mobile/lib/screens/dashboard_screen.dart`, `widgets/status_hero.dart`, `floor_ruler.dart`,
  `forecast_card.dart`, `goal_row.dart`, `account_row.dart`, `money_row.dart`, shell `screens/home_shell.dart`. Working
  tree on top of HEAD `c7fe25b` (uncommitted). The web artifact `mobile/build/web_artifact` (10:38:27) is newer than
  every file in `mobile/lib` (last edit 10:35:10), so the "after" shots show the final code.
- **Evidence:** every screenshot is the Flutter **web demo** in Chromium (Playwright). None come from a device or emulator.
  - `B/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/demo_web/before/`
  - `A/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/demo_web/after/`
  - `V/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/redesign_verify/critique/`
    (verifier captures. `shots360/` is the same harness run at 360x780 against a copy of the same artifact; crops and
    pixel samples are in the same folder.)

## Design Health Score (before → after)

| # | Heuristic | Before | After | Key issue now |
|---|-----------|-------:|------:|---------------|
| 1 | Visibility of System Status | 2 | 3 | Hero heading, numeral, ruler and freshness line answer "am I OK" at a glance. The push SnackBar is short, but its detail line is cut mid-timestamp |
| 2 | Match System / Real World | 3 | 3 | Plain binding terms. The forecast headline is still the server's "khoảng 17.260.571đ" (an 8-digit estimate) |
| 3 | User Control and Freedom | 3 | 3 | Pull-to-refresh, neutral offline strip with "Thử lại", balance sheet from an account row |
| 4 | Consistency and Standards | 2 | 3 | One container system. But the forecast headline is red in a WARNING state, and categories show as an emoji here and as icons on Giao dịch |
| 5 | Error Prevention | 3 | 3 | Read-mostly screen; FAB hidden, never disabled |
| 6 | Recognition Rather Than Recall | 3 | 4 | Accounts, goals, forecast and the "Cần bạn xem" to-dos are all on one screen |
| 7 | Flexibility and Efficiency | 2 | 3 | Row shortcuts (uncategorised → filtered list, account → balance sheet, goal → edit) |
| 8 | Aesthetic and Minimalist Design | 1 | 3 | One big number; flat list groups. The goal "repeat" icon sits alone on a line, and the FAB covers content in the first viewport |
| 9 | Error Recovery | 2 | 3 | Neutral strip with "Thử lại"; ErrorView without a cache |
| 10 | Help and Documentation | 2 | 3 | The ruler and legend explain how the floor is built |
| **Total** | | **23/40** | **31/40** | **Acceptable → Good** |

## Design Specificity Verdict

**Assessment (unanchored):** the dashboard is now authored for this product. The cobalt "Bát men lam" hero carries
the state heading, the 44 sp "được tiêu" numeral, and a meaning line that adds facts instead of repeating the heading.
The *thước mức sàn* shows the floor and the warning tick, and the legend sits under it (`A/dashboard-390x844-light.png`). In
WARNING the glaze turns butter (light) or umber (dark), and the free segment visibly stops before the tick
(`A/dashboard-after-atm-390x844-light.png`, `-dark.png`). The balance card, the traffic-light banner and the metric
pair are gone. The craft-floor "hero-metric template" is avoided because the number is explained by a ruler and
sentences, not by stat tiles. Accounts are on Tổng quan as the owner decided (`A/dashboard-scrolled-1280x800-light.png`).
At 1280 the app uses a NavigationRail with the FAB as its leading item and a 720 dp column
(`A/dashboard-1280x800-light.png`).

**Native source checks (replace the web detector):** `Color(0x` outside `lib/theme/`: 0. `Colors.*` outside the
theme: 0. All 14 grep hits are `StatusColors.of(...)`, so they are false positives. Literal `fontSize:`: one,
`money_text.dart:159`, a measurement copy (false positive). Every `IconButton` has a `tooltip`. `ListView(` without a
builder appears at `dashboard_screen.dart:74,144`, but it holds ≤ 10 goals + ≤ 5 accounts (acceptable). No `fromSeed`
and no Dynamic Color (`theme/color_schemes.dart:2`). No `FontStyle.italic`.

## What improved

- **The hierarchy is fixed.** "được tiêu" is the only large number. The balance and the floor became legend lines.
  The status is stated once.
- **Colour follows the system.** OK is cobalt and ordinary spending is never red. The badge is `primary` (Calm Badge).
  The offline strip is neutral (`widgets/state_views.dart:89-124`).
- **No more box soup.** "Cần bạn xem", the forecast, goals and accounts are flat `surfaceContainerLow` groups with
  no borders or shadows. "Cảnh báo gần đây" and the refresh button are removed.
- **Fixed from the earlier reviews:**
  - The uncategorised row is a button (not a checkbox), and goal rows read as one sentence (`test/redesign_test.dart:349`).
  - The push SnackBar floats above the FAB with a title, one line, "Xem" and 6 s (`push/push_navigator.dart:37-66`;
    `A/dashboard-after-atm-390x844-light.png`).
  - Wide windows use a rail and a 720 dp column.
- **Owner decisions are honoured.** DANGER shows the signed amount with "đã lấn vào tiền mục tiêu"
  (`status_hero.dart:139`). Accounts are on this screen and in Cài đặt. There is no Material You.

## Priority Issues (what still fails)

1. **[P2] In a WARNING state the loudest red on screen is the forecast, not the hero.**
   - *Evidence:* after the ATM simulation the hero is butter WARNING, but the forecast headline and its icon are
     `danger.foreground`. Pixel sample: (168, 55, 42) = `#A8372A` in the headline area of
     `A/dashboard-after-atm-390x844-light.png` and `-1280x800-light.png`.
   - *Source:* `forecast_card.dart:12-18` follows DESIGN.md › Forecast block (line 825: "`danger.foreground` (within 7
     days)"). That line conflicts with The Red Is Earned Rule (DESIGN.md:422), which allows red only for goal money
     in use, a failure, or a destructive action.
   - *Why it matters:* "Calm until it matters". The screen says "Sắp chạm" in the hero and "danger" in the forecast.
   - *Fix:* resolve the conflict in DESIGN.md. Recommended: the forecast uses `warning.foreground` for both severities
     and keeps `trending_down` as the "within 7 days" signal. Red appears only once the hero is DANGER.
   - *Command:* /impeccable colorize.
2. **[P2] Narrow `MoneyRow` text column: meta lines wrap, and the goal "repeat" icon is orphaned.**
   - *Evidence:* in `A/dashboard-scrolled-390x844-light.png` the "Tiền trọ" meta "Quỹ giữ · 🏠 Thuê trọ" wraps, and
     the repeat icon sits alone on the next line. At 360 dp the account title "VCB chính ··6789" also splits
     (`V/shots360/settings-360x780-light.png`, the same row component).
   - *Cause:* the trailing amount column takes the row's full height (`money_row.dart:107-120`), so the title and meta
     share about 152 dp at 390 and about 122 dp at 360. DESIGN.md:557 assumed 224 dp at 360 dp, but it ignored the
     16 dp gutter and the 16 dp row padding of the list group.
   - *Fix:* let only the title (and the amount caption) share the line with the amount. Move the meta out of the
     narrow column so it spans the full width, as `below` already does (`money_row.dart:108-121`). Correct the
     DESIGN.md arithmetic too.
   - *Command:* /impeccable layout.
3. **[P2] The FAB still covers content in the first viewport.**
   - *Evidence:* at rest, "Thêm mục tiêu" covers the forecast headline at 390x844 (`A/dashboard-390x844-light.png`).
     At 360x780 it covers the "Cần bạn xem" row's subtitle and the right part of that tappable row
     (`V/shots360/dashboard-360x780-light.png`).
   - *Cause:* only the 96 dp bottom clearance was added (`dashboard_screen.dart:75`). The earlier critique asked that
     the first viewport not end on a tappable control under the FAB.
   - *Fix:* keep the FAB extended at the top, shrink it to a 56 dp icon FAB once the list scrolls (the label returns
     at the top). If DESIGN's "always extended" has to stay, reserve FAB height after the hero instead.
   - *Command:* /impeccable adapt.
4. **[P3] The push SnackBar detail line is cut mid-timestamp.**
   - *Evidence:* "−3.500.000đ · VCB chính · 17:38 1…" (`A/dashboard-after-atm-390x844-light.png`).
   - *Fix:* drop the server time from the snackbar line (the snackbar means "now"), or cut at a "·" boundary
     (`push_navigator.dart:37-58`).
5. **[P3] At ≥ 840 dp the scrolled-under app bar is a floating slab.**
   - *Evidence:* the `surfaceContainer` tint covers only x = 380–1100 of the 1280 px window. The rest of the bar row
     stays `surface`. Samples: (237,240,245) inside vs (248,250,253) outside; dark (27,33,43) vs (17,22,31)
     (`A/dashboard-scrolled-1280x800-light.png`, `-dark.png`).
   - *Cause:* each tab's Scaffold is wrapped in `ContentColumn` (`home_shell.dart:100`, `widgets/adaptive.dart:36-56`).
   - *Fix:* keep the app bar full width (above the content column) and constrain only the body.

## Persona Red Flags

- **Casey (one-handed, outdoors, seconds after paying):** the answer is now instant (cobalt or butter glaze, 44 sp
  numeral). After the ATM payment, the red forecast headline below a butter hero sends a mixed signal. The FAB sits on
  the first actionable row at 360 dp.
- **Sam (TalkBack):** the hero is one node. The uncategorised row is a button. Goal rows read one sentence, with
  amounts as "… đồng" (tests). The level-change live region is implemented but was not observed in a screenshot run.
- **Chủ tài khoản after an ATM withdrawal:** the ruler shows exactly how close the floor is, and "Lương dự kiến chưa
  về: 15.000.000đ (ngày 25)" explains the way out. Good.

## Minor Observations

- The fixed digit cells are not what detaches the "−". The font's U+2212 has a 116-unit right side bearing (Be Vietnam
  Pro Bold: advance 661, xMax 545), plus 60 units before "3". That makes a 0.18 em gap (≈ 2.8 dp at 16 sp, ≈ 5 dp in the
  28 sp sheet header, which uses proportional digits). Fix it with negative tracking on the sign, not by dropping cells.
- Reserve goals print "Đã trả 0đ / 3.000.000đ" (`goal_row.dart:36`). DESIGN.md:818 says "Đã chi". "Đã trả" reads
  better for a Quỹ giữ, so update DESIGN.md.
- The goal meta keeps the category emoji ("🏠 Thuê trọ", `goal_row.dart:34`), while Giao dịch maps the same system
  category to a Material icon (`widgets/category_icon.dart:10-21`). Pick one representation.
- At ≥ 840 dp the rail "Thêm mục tiêu" FAB also shows on Giao dịch, Cảnh báo and Cài đặt (DESIGN.md:663 says "Only on
  Tổng quan"). See the transactions critique for the two-FAB case.
- The forecast's own "Cuối tháng dự kiến còn ~…" sentence is suppressed whenever the server headline contains the same
  number (`forecast_card.dart:86`). So the 8-digit "khoảng 17.260.571đ" headline wins over the client's "~" sentence.

## Questions to Consider

- Should a "floor within 7 days" forecast ever be redder than the hero? (DESIGN.md says yes in one place and no in another.)
- Would the dashboard read better if the meta line could run under the amount column?

Trend: first after-run for this target; before 23/40 → after 31/40.

Questions skipped: non-interactive verifier subagent with no question tool (5 priority issues listed).
