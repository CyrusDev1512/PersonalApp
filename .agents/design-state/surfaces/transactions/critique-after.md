# Critique (after redesign): Giao dịch (list, categorise sheet, Nhập tay)

**DEGRADED: single-context** (impeccable `critique` done by hand in one verifier subagent. No sub-agent tool, and the
impeccable engine/detector is out of bounds. The AGENTS.md native source checks replace Assessment B.)

- **Target:** `mobile/lib/screens/transactions_screen.dart` (`TxTile`, day groups), `screens/tx_action_sheet.dart`,
  `screens/manual_tx_screen.dart`, `widgets/money_row.dart`, `widgets/category_icon.dart`. Working tree on HEAD `c7fe25b`.
  The artifact is newer than every `lib/` edit.
- **Evidence:** Flutter **web demo** in Chromium only (no device or emulator).
  - `B/` = `…/scratchpad/demo_web/before/`
  - `A/` = `…/scratchpad/demo_web/after/`
  - `X/` = `…/scratchpad/demo_web/after/extra/`
  - `V/` = `…/scratchpad/redesign_verify/critique/` (verifier 360x780 run in `shots360/`, crops)
  - `…` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8`

## Design Health Score (before → after)

| # | Heuristic | Before | After | Key issue now |
|---|-----------|-------:|------:|---------------|
| 1 | Visibility of System Status | 3 | 3 | Count on the filter chip and day totals. The totals only cover loaded pages |
| 2 | Match System / Real World | 2 | 3 | Spending is `onSurface` with "−", the source reads "SePay", and day headings are natural. Titles are cut at 360 dp |
| 3 | User Control and Freedom | 2 | 3 | The sheet is one form with one save, plus "Hoàn tác" for a category change or exclusion |
| 4 | Consistency and Standards | 1 | 3 | One pill, one row component. Categories are icons here but emoji on Tổng quan, and two FABs show at ≥ 840 dp |
| 5 | Error Prevention | 2 | 3 | Nothing commits on tap; the save label names the change |
| 6 | Recognition Rather Than Recall | 3 | 3 | Day groups and a category in the meta. At 360 dp "CHUYEN TIEN CHO NGUYEN…" loses the payee |
| 7 | Flexibility and Efficiency | 2 | 2 | No "Lưu và mở giao dịch tiếp theo"; only about 3 rows per phone viewport |
| 8 | Aesthetic and Minimalist Design | 2 | 2 | Calm colours, but rows are ~150 dp: meta lines wrap and each row takes 4-6 text lines |
| 9 | Error Recovery | 2 | 3 | Sheet failures show above the sticky button; the reload strip is neutral |
| 10 | Help and Documentation | 3 | 3 | Switch subtitles; helper under "Gán vào mục tiêu" |
| **Total** | | **22/40** | **28/40** | **Acceptable → Good (70%)** |

## Design Specificity Verdict

**Assessment (unanchored):** the screen now speaks the system. Day groups ("Hôm nay", "Hôm qua", "Thứ Ba, 13/10") carry
"Đã chi …" totals. The uncategorised pill is a cobalt-tinted invitation, not a red badge. Outgoing amounts are
`onSurface` with "−", and "Nhập tay" is a `secondaryContainer` FAB (`A/transactions-390x844-light.png`). The
categorise sheet is one form with a sticky "Lưu danh mục". It is 640 dp wide and centred on desktop
(`A/tx-action-sheet-1280x800-dark.png`), so the "full-width sheet" issue is fixed. Times stay in Vietnam time with the
browser in London (`X/transactions-london-390-light.png`: 20:45 / 07:30, the same as the ICT run). The weak point is
density: the redesign spends the phone width on the amount column and the group inset, not on the bank text.

**Native source checks:** no `Color(0x`/`Colors.*` outside the theme (StatusColors hits only). Month buttons have
tooltips ("Tháng trước" / "Tháng sau", `transactions_screen.dart:309-316`). The long list is
`ListView.builder` (`transactions_screen.dart:415`). The two plain `ListView(`s hold a skeleton or an empty state
(`:373, :385`).

## What improved

- Red/green amounts, six bordered badges, "↑" glyph avatars and the error-red "Chưa phân loại" are gone. Only one pill
  shows, by priority.
- The filter is "Tất cả" / "Chưa phân loại · 3", with the count visible.
- The sheet no longer commits on a single tap. The button label follows the change ("Lưu danh mục" / "Bỏ phân loại" /
  "Lưu thay đổi"). "Nhớ luật" is a switch, not a checkbox (`A/tx-action-sheet-390x844-light.png` vs
  `B/tx-action-sheet-390x844-light.png`).
- ICT everywhere in the list and the sheet ("17:38 15/10/2026").

## Priority Issues (what still fails)

1. **[P1] Rows lost half their density, and bank titles are cut at the DESIGN reference width.**
   - *Evidence at 390x844:* 3 transactions fit in the first viewport, against 6 before (`A/` vs
     `B/transactions-390x844-light.png`). Each meta line wraps ("VCB chính · 17:38 · / SePay"), and the first row is
     153 dp tall.
   - *Evidence at 360x780:* titles are ellipsised after about 11 characters a line: "RUT TIEN / ATM VCB L…",
     "CHUYEN TIEN / CHO NGUYEN…" (`V/shots360/transactions-360x780-light.png`). The payee, which is how the owner
     recognises a transfer, is lost.
   - *Cause:* `MoneyRow` puts the amount beside the whole text column (`money_row.dart:107-120`). "−3.500.000đ" in
     cells is about 112 dp. With the 16 dp gutter, 16 dp row padding, 40 dp disc and two 16 dp gaps, the text column is
     about 142 dp at 390 and about 112 dp at 360. DESIGN.md:557 assumed 224 dp.
   - *Why it matters:* "Fast hands, short sessions". Clearing the uncategorised pile and scanning the month need
     density and the full payee text.
   - *Fix:*
     - Let only the title line share the row with the amount; move the meta out of the narrow column so it spans the full width under both, as the `below` pill already does (`money_row.dart:108-121`).
     - Consider a full-bleed list group at compact width, so the gutter is not spent twice.
     - Correct the DESIGN.md arithmetic and the 125% large-text threshold derived from it.
   - *Command:* /impeccable layout.
2. **[P3] Two FABs at ≥ 840 dp.**
   - *Evidence:* on Giao dịch the rail shows the cobalt "Thêm mục tiêu" FAB (x 12–187) and the screen shows "Nhập tay"
     (x 947–1083) (`A/transactions-1280x800-light.png`).
   - *Rules:* android.md:38 "Never stack FABs". DESIGN.md:663 "Only on Tổng quan".
   - *Fix:* show the rail FAB only while Tổng quan is selected, or make the rail item a plain destination action on
     other tabs.
3. **[P3] Category representation differs between screens, and DESIGN.md was not updated.**
   - *Evidence:* system categories render as Material icons in the leading disc and the chips ("🍜 Ăn uống" became the
     `restaurant_outlined` icon plus "Ăn uống"; `category_icon.dart:10-21`). Tổng quan still prints "🏠 Thuê trọ"
     (`goal_row.dart:34`).
   - *Rule:* DESIGN.md:675 specifies chips as "<emoji> <tên danh mục>".
   - *Fix:* either document the icon mapping in DESIGN.md › Chips and use it in goal meta too, or return to emoji.
4. **[P3] The "−" sign is detached in list and sheet amounts ("− 3.500.000đ").**
   - *Evidence:* crop `V/amount_cells.png`.
   - *Cause:* the font's U+2212 (advance 661, xMax 545, Bold) plus the "3" left side bearing (60) leave about 0.18 em.
     The cell lead before "3" adds only about 0.3 dp at 16 sp, so the gap is mostly the font's own spacing, not the
     digit cells. The sheet header (28 sp, proportional digits) shows the same gap.
   - *Fix:* a negative `letterSpacing` on the sign span in `MoneySpans.build` (`money_text.dart:134-185`).
5. **[P3] Chip rows in the sheet have uneven gaps.**
   - *Evidence:* 8 dp between chips but about 22 dp between rows (`A/tx-action-sheet-1280x800-dark.png`: chips 34 dp
     tall, rows 22 px apart at 1x).
   - *Cause:* `runSpacing: Space.s2` (`tx_action_sheet.dart:454-456`) plus the padded 48 dp tap target.
   - *Fix:* set `runSpacing` to 0 and let the tap-target padding provide the gap, or tighten the chips' tap target
     inside the Wrap with a visual 8 dp `runSpacing`.

## Persona Red Flags

- **Chủ tài khoản clearing "chưa phân loại" after a Telegram alert:** the sheet is clear and safe now. Back in the list,
  only 3 rows fit and titles are cut at 360 dp, so they cannot see which "CHUYEN TIEN CHO NGUYEN…" is which. There is
  still no "Lưu và mở giao dịch tiếp theo".
- **Alex (power user):** categorising 3 items still takes 3 open → choose → save → close cycles.
- **Sam (TalkBack):** each row is one merged button node (`money_row.dart:146-153`). The amount is "… đồng".

## Minor Observations

- Day totals count only loaded pages (50 per page). The builder acknowledged this.
- "Nhớ luật cho giao dịch tương tự" is disabled until a category is chosen, with no hint why
  (`A/tx-action-sheet-390x844-light.png`).
- Nhập tay's "Thời gian" shows the device time zone (`utils/dates.dart:56-58`, `manual_tx_screen.dart:237`) while the
  list shows ICT. This only matters outside Vietnam.
- The "Tải thêm" busy state is a bare 32 dp spinner (`transactions_screen.dart:425`). DESIGN prefers busy buttons that
  keep their label.

## Questions to Consider

- Should the source ("SePay"/"Email") move to the sheet, so the meta fits one line?
- Is the payee more important than the account name in the meta for this owner?

Trend: before 22/40 → after 28/40.

Questions skipped: non-interactive verifier subagent with no question tool (5 priority issues listed).
