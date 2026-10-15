# Critique (after redesign): Thêm / Sửa mục tiêu (goal form)

**DEGRADED: single-context** (impeccable `critique` done by hand in one verifier subagent. No sub-agent tool, and the
engine/detector is out of bounds. The AGENTS.md native source checks replace Assessment B.)

- **Target:** `mobile/lib/screens/goal_form_screen.dart`, `widgets/form_parts.dart` (`MoneyField`). Working tree on
  HEAD `c7fe25b`.
- **Evidence:** Flutter **web demo** in Chromium only.
  - `B/` = `…/scratchpad/demo_web/before/`
  - `A/` = `…/scratchpad/demo_web/after/`
  - `V/` = `…/scratchpad/redesign_verify/critique/shots360/` (verifier 360x780 run)
  - `…` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8`
  - The edit mode and the delete dialogs were reviewed in code only; no shot was taken.

## Design Health Score (before → after)

| # | Heuristic | Before | After | Key issue now |
|---|-----------|-------:|------:|---------------|
| 1 | Visibility of System Status | 3 | 3 | Busy sticky button, snackbars. No impact line (skipped by the owner's decision, so this is not scored as a defect) |
| 2 | Match System / Real World | 3 | 3 | Short type labels with a one-line explanation. The default category reads "Tiết kiệm thuần (không gắn danh mụ…" |
| 3 | User Control and Freedom | 3 | 3 | Back cancels; delete asks first |
| 4 | Consistency and Standards | 2 | 3 | Themed segmented buttons and switch, red destructive buttons. Helper texts sit at two different insets |
| 5 | Error Prevention | 2 | 3 | Non-recurring goals get only "Huỷ" / "Xoá"; suggestions fill the type and category |
| 6 | Recognition Rather Than Recall | 3 | 3 | Suggestion chips, "Tháng 10" / "Tháng 11". The chosen category is cut off |
| 7 | Flexibility and Efficiency | 2 | 3 | Sticky save, suggestion chips, focus moves to the first invalid field |
| 8 | Aesthetic and Minimalist Design | 2 | 3 | "Đã chi trước khi dùng app" folded under "Thêm tuỳ chọn"; type first |
| 9 | Error Recovery | 3 | 3 | Specific inline messages; a failed save keeps the form |
| 10 | Help and Documentation | 3 | 3 | Per-type and per-category helpers |
| **Total** | | **26/40** | **30/40** | **Acceptable → Good** |

## Design Specificity Verdict

**Assessment (unanchored):** the form now follows the brief's order and is calmer. The segmented "Quỹ giữ" /
"Ngân sách" comes first, with one explanatory line. Then the name with suggestion chips "Tiền trọ" / "Tiền ăn" /
"Tiết kiệm", the 64 dp money field with an "đ" suffix and a "VD: 3.000.000" placeholder, the category, the month as
"Tháng 10" / "Tháng 11", a slate (not cobalt) "Lặp lại hằng tháng" switch, and a sticky full-width cobalt
"Tạo mục tiêu" (`A/goal-form-390x844-light.png` vs `B/goal-form-390x844-light.png`). The before shot's wrapped
"Tháng này (10/2026)" segment and its check-icon save button are gone. At 1280 the form is a centred 656 dp column with
a sticky bar (`A/goal-form-1280x800-dark.png`).

**Native source checks:** no hard-coded colours or font sizes. The delete `IconButton` has the tooltip "Xoá mục tiêu"
and is `scheme.error` (`goal_form_screen.dart:286-290`). Confirmations use `AppButtonStyles.destructiveFilled`
(`:219-245`). The `ListView(` at `:299` is a short form (fine).

## What improved

- Type first, with short segment labels that fit at 390 and 360 (`V/goal-form-360x780-light.png`).
- The sticky primary button never scrolls away; the rare opening-spent field is folded away.
- The delete dialog is honest: red filled confirm, and no "Xoá và dừng lặp lại" for non-recurring goals (code).
- Validation focuses the first invalid field (builder's tests; not re-run here).

## Priority Issues (what still fails)

1. **[P2] The default category value is cut off on phones.**
   - *Evidence:* "Tiết kiệm thuần (không gắn danh mụ…" at 390 (`A/goal-form-390x844-light.png`, light and dark) and
     "(không gắn dan…" at 360 (`V/goal-form-360x780-light.png`). It fits only at 1280.
   - *Why it matters:* this is the preselected value for a Quỹ giữ, so the first thing the owner reads in the field
     is truncated. The helper underneath repeats "Tiết kiệm thuần" anyway.
   - *Fix:* label the item "Tiết kiệm thuần" (`goal_form_screen.dart:476`) and let the helper carry "không gắn
     danh mục". Alternatively, allow two lines in the selected item.
   - *Command:* /impeccable clarify.
2. **[P3] Helper texts sit at two different insets.**
   - *Evidence:* the type helper is flush with the field edge (x = 16 dp), while the dropdown helper is indented to the
     M3 helper inset (x ≈ 36 dp) (`A/goal-form-390x844-light.png`). Two helper styles appear on one form.
   - *Fix:* render the type explanation as the segmented control's helper at the same 16 dp inset as field helpers,
     or move both to the flush style.
3. **[P3] The suggestion chips look like filter chips.**
   - *Evidence:* "Tiền trọ" / "Tiền ăn" / "Tiết kiệm" are 1 dp outlined, 32 dp chips identical to the unselected filter
     chips on Giao dịch and Cảnh báo (`A/goal-form-390x844-light.png`).
   - *Fix:* use M3 suggestion/assist styling (leading `add` or a type icon) so they read as "fill this in". This is low
     risk because the brief marks them as inferred.

## Persona Red Flags

- **Chủ tài khoản at the start of the month (one-handed):** type → suggestion → amount → save works without scrolling
  to the button. Picking "Tiết kiệm" fills the type and category, but the category field then shows a cut-off label.
- **Sam (TalkBack):** the segmented labels are short and spoken. The sticky button keeps its label while busy.

## Minor Observations

- On a phone, "Lặp lại hằng tháng" (switch-tile title, `titleMedium`) reads larger than the section labels "Loại mục
  tiêu" / "Tháng" (`titleSmall`).
- The money field placeholder is `bodyLarge` while typed digits use `moneyInput` (28 sp/800). The field jumps in
  weight on the first keystroke. This is DESIGN-compliant but noticeable.
- The impact line was skipped per the owner's decision (it needs a server preview).

## Questions to Consider

- Should "Tiết kiệm" as a suggestion also set "Tiết kiệm thuần", or a "Tiết kiệm" category when one exists?

Trend: before 26/40 → after 30/40.

Questions skipped: non-interactive verifier subagent with no question tool (3 priority issues listed).
