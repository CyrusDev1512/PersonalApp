# Critique (before redesign): Giao dịch (list, categorise sheet, Nhập tay)

**DEGRADED: single-context** (impeccable `critique` run by hand inside one workflow subagent: no sub-agent tool is
exposed, and the engine/detector is out of bounds under the Runtime boundary. Native source checks replace Assessment B
and were run after the design review.)

- **Targets:** `mobile/lib/screens/transactions_screen.dart` (`TransactionsScreen`, `TxTile`),
  `screens/tx_action_sheet.dart`, `screens/manual_tx_screen.dart`. Line numbers refer to HEAD `10ba63c` (the before state; the working tree is being redesigned in parallel).
- **Evidence:** Flutter **web demo** in Chromium via Playwright, not a device or emulator.
  - `B/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/demo_web/before/`
    (`transactions-*`, `tx-action-sheet-*`, TZ Asia/Ho_Chi_Minh).
  - `X/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/redesign/critique_extra/`
    (`transactions-390-london.png`, `alerts-390-london.png`: the same build with the browser TZ set to Europe/London).
  - Nhập tay is not in the before set and is reviewed from code. At 1280 the demo's 440 dp column hides the sheet's real
    width (issue 5).

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | SnackBars after each sheet action, a reload-error strip. The filter chip has no count and the list loads behind a spinner |
| 2 | Match System / Real World | 2 | Spending painted red like an error; "↑" for money out; raw "sepay" in the meta |
| 3 | User Control and Freedom | 2 | One tap on "Loại trừ", "Tính cho tháng sau" or a goal commits and closes the sheet; no "Hoàn tác" |
| 4 | Consistency and Standards | 1 | Six differently coloured bordered badges; red/green amounts; glyph, emoji and icon avatars mixed; two commit models in one sheet; a checkbox |
| 5 | Error Prevention | 2 | Instant commits drop a pending category choice; the delete confirm uses the primary fill |
| 6 | Recognition Rather Than Recall | 3 | Category chips with the user's emoji; month navigator with tooltips |
| 7 | Flexibility and Efficiency | 2 | No "Lưu và mở giao dịch tiếp theo"; categorising three items means three full round trips |
| 8 | Aesthetic and Minimalist Design | 2 | Rows of about 110 dp with a pill under each; full-width dividers; no day grouping |
| 9 | Error Recovery | 2 | Sheet errors print at the bottom of the scroll, far from the button; the reload strip is red |
| 10 | Help and Documentation | 3 | Rule and goal helpers in the sheet; a guidance box on Nhập tay |
| **Total** | | **22/40** | **Acceptable** |

## Design Specificity Verdict

**LLM assessment:** generic bank-statement list: red minus, green plus, a pill per row, a FAB. The product's distinctive
ideas (an uncategorised pile to clear, internal transfers that are neither income nor spending, money counted for next
month, possible duplicates) are all present, but as six look-alike bordered badges, so none of them reads as more
important than another. The categorise sheet, which is the screen's real task, is a long scroll of mixed controls with
its save button in the middle.

**Deterministic scan (native checks, this surface):**

| Check | Result |
|---|---|
| `Colors.*` outside theme | 6 lines: `transactions_screen.dart:353,354,412,415`, `tx_action_sheet.dart:218,228` (red, green, amber, deepOrange) |
| Literal `fontSize:` | **1**: `transactions_screen.dart:369` (`TextStyle(fontSize: 18)` for the avatar glyph) |
| `IconButton` without tooltip | 0 ("Tháng trước" / "Tháng sau", `:233-243`) |
| Hit targets < 48 dp | none (chips padded) |
| Non-builder long lists | none: the list is `ListView.separated` (`:288`); `ListView(` at `:274` is the empty state only |
| Emoji / glyphs as UI icons | **3**: "↑"/"↓" avatars (`:368`), "🎯" goal badge (`:408-409`); category emoji are user data (allowed) |

The scan catches the glyph avatars and hard-coded colours that the review flagged. It does not catch the commit-model
problem or the time-zone bug.

## Overall Impression

The data model is rich and correct; the presentation flattens it. The biggest opportunity is the row anatomy from the
brief: a leading category disc, an amount in neutral `onSurface` with fixed digit cells, and at most one pill, plus a
categorise sheet with a single sticky "Lưu danh mục".

## What's Working

- **Long-list hygiene:** `ListView.separated`, 50-item pages with "Tải thêm (N)", the request id guarding stale
  responses, and rows that update in place after the sheet (`transactions_screen.dart:124-204, 288-307`).
- **The sheet knows the edge cases:** a possible-duplicate hint, the pending email match, assignment to another month's
  goal kept visible as a disabled item (`tx_action_sheet.dart:196-198, 321-326`), and a rule pattern prefilled from the
  server suggestion.
- **The reload strip keeps cached rows visible** instead of blanking the list (`transactions_screen.dart:259-260`).

## Priority Issues

1. **[P1] Ordinary spending is painted as an error.**
   *Why:* outgoing amounts use `Colors.red.shade700` and incoming `Colors.green.shade700` (`transactions_screen.dart:350-354`;
   the sheet header at `tx_action_sheet.dart:216-219`). "Chưa phân loại" is an `error`-coloured badge (`:403-404`) and the
   reload strip uses `errorContainer` (`:321-336`), which breaks The Red Is Earned Rule. Contrast also fails at 14 sp/700:
   "+89.000đ" is 3.92:1 on the light row and "−200.000đ" is 3.71:1 on the dark row (pixel-sampled from
   `B/transactions-390x844-light.png` and `-dark.png`).
   *Fix:* out = `onSurface` with "−", in = `StatusColors.ok.foreground` with "+", internal transfer = `onSurfaceVariant`;
   the "Chưa phân loại" pill in `primaryContainer` (an invitation); the reload strip neutral (`surfaceContainerHigh`).
   *Command:* /impeccable colorize.
2. **[P1] Badge pile, glyph avatars and raw metadata.**
   *Why:* up to six bordered `StatusBadge`s per row (category, Chuyển nội bộ, 🎯 goal, Đang chờ khớp, Đã loại trừ, Có
   thể trùng, Nhập tay; `:395-417`) in hand-picked colours; "↑"/"↓" text glyphs at a literal 18 sp as avatars (`:365-371`);
   the source printed raw as "sepay" (`:358`; `B/transactions-390x844-light.png`).
   *Fix:* a 40 dp leading disc with the category emoji, or `north_east` / `south_west` when uncategorised; meta
   "VCB chính · 14:32 · SePay"; **at most one pill** by priority (Có thể trùng > Đang chờ khớp > Chưa phân loại >
   Chuyển nội bộ); goal, "Nhập tay" and "Đã loại trừ" as meta text with `flag_outlined`.
   *Command:* /impeccable distill.
3. **[P1] The categorise sheet mixes two commit models.**
   *Why:* category chips wait for the filled button, but the "Gán vào mục tiêu" dropdown (`tx_action_sheet.dart:328-334`),
   "Tính cho tháng sau" (`:360-363`) and "Loại trừ" (`:373-375`) PATCH and close the sheet on a single tap. A chip picked
   before tapping "Loại trừ" is silently dropped, and nothing offers "Hoàn tác". For an uncategorised transaction the
   only filled button reads a disabled "Bỏ phân loại" (`:283-292`; `B/tx-action-sheet-390x844-light.png`). The "Nhớ luật"
   control is a `CheckboxListTile` (`:263-269`), and DESIGN.md does not use checkboxes.
   *Fix:* one form with one sticky full-width "Lưu danh mục" ("Bỏ phân loại" only when clearing a set category); goal,
   "Tính cho tháng sau" and the rule as switch or dropdown fields saved with it; "Loại trừ" as a secondary action with a
   SnackBar "Hoàn tác"; snackbar "Đã phân loại" · "Hoàn tác". Keep `tx_goal` and `tx_counted_later`.
   *Command:* /impeccable harden.
4. **[P1] Transaction times use the device time zone.**
   *Why:* `formatShortDateTime` and `formatDateTime` call `toLocal()` (`utils/dates.dart:48, 51`; used at
   `transactions_screen.dart:357`, `tx_action_sheet.dart:202`). With the browser in Europe/London the transfer reads
   "14:45 14/10" in Giao dịch while its alert body says "20:45 14/10" (`X/transactions-390-london.png` against
   `X/alerts-390-london.png`). The month filter is ICT (`currentMonthIct`), so rows near midnight can land under the wrong
   day.
   *Fix:* format every bank and created time in ICT through `lib/utils/dates.dart` (UTC + 7 h).
   *Command:* /impeccable harden.
5. **[P2] The sheet is full-width on wide windows.**
   *Why:* `showTxActionSheet` passes `constraints: BoxConstraints(maxHeight: …)` (`tx_action_sheet.dart:30`), which
   replaces M3's default 640 dp max width, so at 1280 dp the sheet spans the window. The demo's 440 dp column hides this
   in `B/tx-action-sheet-1280x800-*.png`.
   *Fix:* `BoxConstraints(maxWidth: 640, maxHeight: 0.88 × height)` (DESIGN.md › Bottom sheets), as the demo sheet
   already does (`demo/demo_controls.dart:351`).
   *Command:* /impeccable adapt.

## Further Issues (ranked)

6. **[P2] No day groups.** Rows are separated by full-width dividers (`:292`); the brief wants "Hôm nay", "Hôm qua", "Thứ
   Hai, 12/10" headings in `titleSmall` with one list group per day and inset dividers.
7. **[P2] The FAB is wrong for this screen.** "Thêm giao dịch" in the same pale-teal `primaryContainer` as Tổng quan's FAB
   (`:216-220`) should be "Nhập tay" (`edit_note`) in `secondaryContainer`. At rest it covers the meta of the row
   underneath ("09:10 13/" is cut in `B/transactions-390x844-light.png`); the 96 dp end padding is already there.
8. **[P2] The amount sits beside a two-line title inside `ListTile.title`** (`:372-388`), with no large-text reflow, no
   fixed digit cells (owner decision: fixed cells for list amounts) and no "… đồng" semantics. Build a `MoneyRow`.
9. **[P2] The month row is a `Wrap` with `spaceBetween`** (`:225-256`): month and chip float and re-wrap by width, and the
   chip says "Chưa phân loại" with no count. The brief has a month row, then chips "Tất cả" / "Chưa phân loại · 3".
10. **[P2] Sheet layout and errors.** The save button sits mid-sheet rather than in a sticky bar; the API error prints at the
    very bottom (`:385`); the duplicate hint is `Colors.deepOrange` text (`:228`); the delete confirm uses a primary
    `FilledButton` (`:170`). Categories load behind a bare `LinearProgressIndicator` (`:243`).
11. **[P3] Loading and empty states.** A full-screen spinner (`transactions_screen.dart:268`) instead of six skeleton rows;
    the empty states are one centred line with no `bodySmall` explanation ("Giao dịch từ Vietcombank và MB sẽ tự hiện…").
12. **[P3] Nhập tay.** A tinted `secondaryContainer` box above the form (`manual_tx_screen.dart:125-136`); save at the end
    of the scroll (`:231-237`); the generic success message "Đã thêm giao dịch" (`:103`) instead of "Đã thêm khoản chi
    50.000đ"; the amount field is not focused on open; list loading errors only appear as a SnackBar.

## Persona Red Flags

- **Casey (clearing the pile one-handed):** opens a row, picks "🍜 Ăn uống", then has to find "Lưu danh mục" mid-sheet,
  and starts over from the list for the next row. Tapping "Tính cho tháng sau" by mistake commits instantly.
- **Sam (TalkBack):** amounts read as "trừ 3.500.000 đ" digit groups; the avatar glyph "↑" is read aloud; each row's
  pill adds a separate border-only announcement; the remember-rule control is announced as a checkbox.
- **Riley (edge cases):** with the phone set abroad, times shift by hours against Telegram; a row with a duplicate flag, a
  pending match and a goal shows three badges that wrap to a third line.

## Minor Observations

- The bank descriptions show in upper case as received; this is correct (data), and the two-line cap holds.
- Excluded rows strike the title instead of the amount; the brief strikes the amount in `onSurfaceVariant`.
- The demo simulate sheet uses `arrow_upward` / `arrow_downward` while Nhập tay uses `north_east` / `south_west`; keep
  one pair app-wide.

## Questions to Consider

- What if, from the "Chưa phân loại" filter, saving went straight to the next uncategorised transaction?
- Would a day total of outgoing spend in each group heading help pace, or add noise? (Open in the brief.)

## What Must Change to Meet DESIGN.md

- [ ] `MoneyRow`-based `TxTile`: leading disc, `titleMedium` title (2 lines), `bodySmall` meta in ICT with "SePay",
  trailing `moneyList` in fixed digit cells with signed neutral colours, at most one pill, stacked layout above 125%.
- [ ] Day groups in list groups with inset dividers; chips "Tất cả" / "Chưa phân loại · N"; skeleton rows; worded empty
  states; a neutral reload strip.
- [ ] FAB "Nhập tay" in `secondaryContainer`.
- [ ] Categorise sheet: `moneyLarge` header in neutral colour, icon-plus-text notices, chips, a "Nhớ luật" switch, goal
  dropdown, "Tính cho tháng sau" switch tile, "Loại trừ" tile, sticky "Lưu danh mục", "Hoàn tác" SnackBar, max width
  640 dp, `error` filled delete confirm.
- [ ] Nhập tay: segmented "Khoản chi" / "Khoản thu", focused money field, sticky "Lưu giao dịch", specific success copy.

Trend: first run for this target, so there is no trend yet. The snapshot lives in this file.

Questions skipped: non-interactive workflow subagent with no question tool; the owner's decisions came with the task
(5 priority issues listed).
