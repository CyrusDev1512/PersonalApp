# Critique (before redesign): Thêm / Sửa mục tiêu (goal form)

**DEGRADED: single-context** (impeccable `critique` run by hand inside one workflow subagent: no sub-agent tool is
exposed, and the engine/detector is out of bounds under the Runtime boundary. Native source checks replace Assessment B
and were run after the design review.)

- **Target:** `mobile/lib/screens/goal_form_screen.dart` (route `/goal`). Line numbers refer to HEAD `10ba63c` (the
  before state; the working tree is being redesigned in parallel; at HEAD the file had not changed since 2026-10-14).
- **Evidence:** Flutter **web demo** in Chromium via Playwright, TZ Asia/Ho_Chi_Minh, not a device or emulator.
  - `B/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/demo_web/before/`
    (`goal-form-390x844-light.png`, `-dark`, `goal-form-1280x800-light.png`, `-dark`).
  - The delete dialog, validation and saving states are not in the before set; they are reviewed from code.

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Busy icon on save, success SnackBar. Nothing shows what the goal will do to "được tiêu" |
| 2 | Match System / Real World | 3 | The type helper explains Quỹ giữ / Ngân sách in plain words; "Tiết kiệm thuần" is opaque |
| 3 | User Control and Freedom | 3 | Back cancels; delete asks first; no undo after delete |
| 4 | Consistency and Standards | 2 | One segment label wraps to two lines while its neighbour does not; M3 default switch fill; the destructive action is the primary fill |
| 5 | Error Prevention | 2 | The delete dialog offers "Xoá và dừng lặp lại" as the filled default, even for goals that do not repeat |
| 6 | Recognition Rather Than Recall | 3 | Months offered as choices; helper text per type |
| 7 | Flexibility and Efficiency | 2 | No suggestion chips; the save button is only reachable at the end of the scroll |
| 8 | Aesthetic and Minimalist Design | 2 | The rare "Đã chi trước khi dùng app" field is always shown; long three-line helpers |
| 9 | Error Recovery | 3 | Specific inline messages ("Nhập số tiền", "Ngân sách chi tiêu cần chọn danh mục"); a failed save keeps the form |
| 10 | Help and Documentation | 3 | Per-type and per-category helper lines |
| **Total** | | **26/40** | **Acceptable** |

## Design Specificity Verdict

**LLM assessment:** a stock Material form: fields stacked in implementation order, with the save button at the end of the
scroll. It is clear and correct, but nothing tells the owner that this form is the product's control ("Goals are the
control"): there is no consequence line, and the money field looks like any text field (dense, 48 dp, Roboto, no example).
The pale-teal selected segments and the teal switch are M3 seed defaults, not the Bát men lam roles.

**Deterministic scan (native checks, this surface):** `Colors.*`: 0 · `Color(0x`: 0 · literal `fontSize:`: 0 ·
`IconButton` without tooltip: 0 (the delete button has "Xoá mục tiêu", `goal_form_screen.dart:196-200`) · hit targets:
fine · `ListView(` at `:206` is a short form (fine) · emoji: none. The dense input theme (`main.dart:33`,
`isDense: true`) makes every field about 48 dp tall, short of DESIGN.md's 56 dp (64 dp for money). The scan finds
nothing that the review did not; the real problems here are interaction problems.

## Overall Impression

The form works and its validation is good, but it asks for decisions in the wrong order and hides the commit. The
biggest opportunity is a sticky "Tạo mục tiêu" bar, with "Loại mục tiêu" first and a one-line consequence ("ước tính")
just above the button.

## What's Working

- **Validation copy is specific and Vietnamese** (`goal_form_screen.dart:219-224, 255-260, 96-99, 315-319`), and a
  failed save keeps everything typed (`:132-136`).
- **The series hint** ("Tháng này đã có "Tiền ăn" lặp lại … sẽ được cập nhật thay vì tạo thêm", `:278-286`) explains a
  server rule exactly when it applies.
- **The busy state keeps the label** and swaps the icon for an 18 dp spinner (`:322-329`), as DESIGN.md asks.

## Priority Issues

1. **[P1] Wrong order and a hidden commit.**
   *Why:* "Tên mục tiêu" comes before "Loại mục tiêu", although the type changes the meaning of every other field. The
   filled "Tạo mục tiêu" sits after the opening-spent field at the end of the `ListView` (`goal_form_screen.dart:206-330`;
   `B/goal-form-390x844-light.png`), so with the keyboard up on a 360x640 phone it is off-screen.
   *Fix:* the type segmented button first, then name, amount, category, month, repeat; "Đã chi trước khi dùng app" behind
   a collapsed "Thêm tuỳ chọn"; a full-width filled button in a sticky bottom bar that rides above the keyboard (keep
   `Key('goal_save')`), without the check icon.
   *Command:* /impeccable layout.
2. **[P1] The delete dialog defaults to the most destructive choice.**
   *Why:* every goal gets "Huỷ", "Chỉ xoá tháng này" and a **filled primary** "Xoá và dừng lặp lại", whether it repeats
   or not (`:143-164`; the content text changes, the actions do not). For a one-off goal, the emphasised button
   offers a meaningless series stop, and nothing uses the earned red.
   *Fix:* non-recurring goals get "Huỷ" and a filled `error` "Xoá"; recurring goals get "Huỷ", "Chỉ xoá tháng này" and a
   filled `error` "Xoá và dừng lặp lại". Cap the quoted name at two lines in a `headlineSmall` title (line height 1.42).
   *Command:* /impeccable harden.
3. **[P2] Segmented buttons overflow their halves.**
   *Why:* "Tháng này (10/2026)" wraps to two lines while "Tháng sau (11/2026)" fits on one, and "Ngân sách chi tiêu" with
   its icon barely fits at 390 dp (`B/goal-form-390x844-light.png`; `:229-244, 270-277`). At 360 dp or 130% text both
   break, and there is no vertical fallback.
   *Fix:* short labels "Quỹ giữ" / "Ngân sách" and "Tháng 10" / "Tháng 11" ("Tháng 1/2027" across a year); the full
   term goes in the helper line; switch to `Axis.vertical` with full-width segments when a label does not fit (measured
   with `TextPainter`).
   *Command:* /impeccable adapt.
4. **[P2] The money fields are not money fields.**
   *Why:* "Số tiền" is a dense 48 dp field in Roboto `bodyLarge` with no example placeholder (`:248-261`;
   `B/goal-form-1280x800-light.png`, where the field is about 40 px tall). DESIGN.md asks for 64 dp `moneyInput`
   (28 sp/800), suffix "đ" and the placeholder "VD: 3.000.000".
   *Fix:* a shared money field widget (also used by the account and balance sheets and Nhập tay).
   *Command:* /impeccable typeset.
5. **[P2] The consequence is invisible.**
   *Why:* creating "Tiền trọ 3.000.000đ" raises the floor and lowers "được tiêu", but the form never says so. The owner
   learns it only on Tổng quan.
   *Fix (client-only; the owner ruled out a server preview):* for new current-month goals, one `bodyMedium` line above
   the sticky button computed from the cached summary and labelled as an estimate: "Mức sàn tháng 10 tăng 3.000.000đ ·
   được tiêu còn khoảng 1.000.000đ (ước tính)", with "· sẽ ở mức cảnh báo" in `warning.foreground` when the result falls
   under the buffer. Hide it when there is no summary, for next month, and when editing.
   *Command:* /impeccable clarify.

## Further Issues (ranked)

6. **[P2] Category loading is a bare `LinearProgressIndicator`** (`:358`), and the failure is plain text in a Row with no
   error colour (`:351-356`). The brief asks for a disabled "Danh mục" field with the helper "Đang tải danh mục…" or
   "Không tải được danh mục." in `error` plus "Thử lại".
7. **[P2] The switch uses M3's default primary track** (`:288-298`; teal fill in `B/goal-form-390x844-light.png`). The One
   Cobalt Rule requires a `secondary` track; the switch's subtitles are good and should be kept.
8. **[P3] Validation does not move focus** to the first invalid field (`_formKey.currentState?.validate()` only, `:103`).
9. **[P3] Helper copy is long.** Three `bodySmall` lines for the type, "vd." in lower case against "VD:" elsewhere
   (`:185-189`). The brief has one shorter line per type that names the full term.
10. **[P3] No suggestion chips** ("Tiền trọ", "Tiền ăn", "Tiết kiệm") under the name for a new goal. This is a cheap,
    client-only idea from the brief, optional.
11. **[P3] Section labels "Loại mục tiêu" and "Tháng"** use `labelLarge` as small headings above controls. That is
    acceptable for form groups, but they should be the segmented button's own label in the redesign.

## Persona Red Flags

- **Casey (one-handed):** types the amount, then must dismiss the keyboard and scroll to find "Tạo mục tiêu"; the month
  choice sits mid-screen in a two-line segment.
- **Sam (TalkBack):** the segmented button's selection is announced, but the helper under it is a detached `Text`, and the
  delete dialog's three buttons give no hint which one is destructive.
- **Riley (edge cases):** in December the second segment becomes "Tháng sau (01/2027)" and wraps; an 80-character
  all-caps name ("TIỀN ĂN TẾT …") in the delete title is not capped; deleting a one-off goal offers "dừng lặp lại".

## Minor Observations

- The edit mode shows the month as plain `bodyLarge` text "Tháng 10/2026" under a "Tháng" label: fine, keep it read-only.
- The success SnackBars are good ("Đã thêm mục tiêu "Tiền trọ"", "Đã tạo mục tiêu cho tháng 11/2026").
- Dark mode: the tonal segment selection (`B/goal-form-390x844-dark.png`) is low-contrast against the surface; the
  themed `secondaryContainer` with a check icon will fix it.

## Questions to Consider

- Should a new goal default to "Lặp lại hằng tháng" = on (today `true`, `:69`)? It is right for rent, wrong for a one-off.
- What if the form opened with the amount focused and the type preselected from a suggestion chip?

## What Must Change to Meet DESIGN.md

- [ ] Order: type → name → amount → category → month → repeat → "Thêm tuỳ chọn" (opening spent); a sticky full-width
  filled save button (`goal_save`).
- [ ] Short segmented labels with a vertical fallback; a 64 dp `moneyInput` field with "VD: 3.000.000".
- [ ] A disabled-field loading state and an `error` helper with "Thử lại" for categories.
- [ ] Switch themed with a `secondary` track; outlined 56 dp fields (no `isDense`).
- [ ] Delete dialog: two or three actions depending on `repeatMonthly`, destructive filled `error`, title capped at two
  lines.
- [ ] Optional: a client-side impact line marked "ước tính", and suggestion chips.

Trend: first run for this target, so there is no trend yet. The snapshot lives in this file.

Questions skipped: non-interactive workflow subagent with no question tool; the owner's decisions came with the task
(5 priority issues listed).
