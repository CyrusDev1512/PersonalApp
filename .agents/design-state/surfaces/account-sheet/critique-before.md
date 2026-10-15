# Critique (before redesign): Tài khoản và số dư (account form + balance entry)

**DEGRADED: single-context** (impeccable `critique` run by hand inside one workflow subagent: no sub-agent tool is
exposed, and the engine/detector is out of bounds under the Runtime boundary. Native source checks replace Assessment B
and were run after the design review.)

- **Target:** `mobile/lib/widgets/account_dialog.dart` (`showAccountForm` / `AccountFormDialog`, `showBalanceDialog` /
  `BalanceDialog`), opened from Cài đặt (`settings_screen.dart:168-177`) and Tổng quan (`dashboard_screen.dart:340-350`).
  Line numbers refer to HEAD `10ba63c` (the before state; the working tree is being redesigned in parallel).
- **Evidence:** **code only.** The screenshot harness never opens these dialogs, and no earlier capture shows them. No
  device or emulator was used.

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | "Đang lưu…" label while saving; no confirmation when a balance is saved from Tổng quan |
| 2 | Match System / Real World | 3 | "Mở app ngân hàng và nhập đúng số dư hiện tại…" is exactly the owner's situation; "TK" is abbreviated |
| 3 | User Control and Freedom | 3 | "Huỷ" and Back close the dialog |
| 4 | Consistency and Standards | 2 | Dialogs where DESIGN.md uses sheets; underline fields here, outlined everywhere else; a checkbox; a generic "Lưu" |
| 5 | Error Prevention | 2 | The prefilled balance is not selected, so typing appends to it; the destructive confirm is a primary fill |
| 6 | Recognition Rather Than Recall | 3 | The current balance appears in the helper "Hiện tại: 6.200.000đ" |
| 7 | Flexibility and Efficiency | 2 | Enter submits the balance; no "Thêm tài khoản khác" after the first account |
| 8 | Aesthetic and Minimalist Design | 3 | Compact |
| 9 | Error Recovery | 2 | API errors print at the end of the dialog content, which can be scrolled off with the keyboard up |
| 10 | Help and Documentation | 3 | Helpers for the account number and balance |
| **Total** | | **25/40** | **Acceptable** |

## Design Specificity Verdict

**LLM assessment:** stock `AlertDialog` forms with underline fields, unlike the outlined fields on every other form in
the app. The balance dialog has the product's best piece of guidance copy, but it is laid out as a generic modal. The
moment that turns Tổng quan from UNKNOWN into a real state (the first saved balance) passes with no feedback at all.

**Deterministic scan (native checks, this surface):** `Colors.*`: 0 · `Color(0x`: 0 · literal `fontSize:`: 0 ·
`IconButton`: none · hit targets: fine · lists: none · emoji: none. Error text is built inline with
`TextStyle(color: colorScheme.error)` (`account_dialog.dart:241, 344`), which is allowed (a theme role) but duplicated.
The scan finds nothing; every issue here is about interaction or form.

## Overall Impression

The data rules are right (coupling between "Tính vào tổng số dư" and the confirmation, the delete restriction). The
form is in the wrong container and has one real data-entry trap. The biggest opportunity is a balance sheet that opens
with the known balance **selected**, so the owner copying a number from the bank app replaces it in one go.

## What's Working

- **Guidance copy:** "Mở app ngân hàng và nhập đúng số dư hiện tại. Các biến động sau đó sẽ được cộng/trừ từ mốc
  này." (`account_dialog.dart:329-331`).
- **State coupling is correct:** turning on "Tính vào tổng số dư" also confirms the account; un-confirming turns
  counting off (`:217-237`); unconfirmed accounts show their real "not counted" state (`:59-61`).
- **Money input:** `VndInputFormatter` with live grouping, the suffix "đ", Enter to submit on the balance field.

## Priority Issues

1. **[P1] The balance entry appends instead of replacing.**
   *Why:* `BalanceDialog` prefills the formatted balance (`:288-289`) and autofocuses the field (`:332-341`) with the
   cursor at the end. When the owner types the number from the bank app, the digits are appended and regrouped
   ("6.200.000.615.000" after six digits), and the 13-digit cap then silently drops the seventh digit
   (`utils/currency.dart:8, 71-74`).
   *Fix:* select the whole text on open (`TextSelection(baseOffset: 0, extentOffset: text.length)`), so typing replaces
   it; show the known balance as a fact line above ("Số dư hiện tại: 6.200.000đ · cập nhật 14:32").
   *Command:* /impeccable harden.
2. **[P1] Forms are dialogs, not bottom sheets.**
   *Why:* `showDialog` + `AlertDialog` for both forms (`:13-18, 147-257, 262-353`). On a 360x640 phone with the keyboard
   up, the content scrolls inside a small modal, the actions sit at the edge, and API errors render at the end of the
   content (`:239-242, 342-345`). DESIGN.md keeps dialogs for destructive confirmations only.
   *Fix:* modal bottom sheets (drag handle, `headlineSmall` title, 640 dp max width, a sticky full-width filled button
   that rides above the keyboard, the inline error line with `error_outline` directly above it). Keep the
   `showAccountForm` / `showBalanceDialog` signatures and `AccountFormResult`.
   *Command:* /impeccable shape.
3. **[P2] The field style differs from every other form.**
   *Why:* `InputDecoration(labelText: …)` with no `OutlineInputBorder` (`:158, 165, 182, 195, 204, 338`) gives underline
   fields, while the goal form, Nhập tay, Cài đặt and Kết nối use outlined fields. The save label is a generic "Lưu"
   (`:255`).
   *Fix:* use the themed outlined fields (from `inputDecorationTheme`, not per call); a 64 dp money field; button labels
   "Thêm tài khoản" / "Lưu tài khoản" / "Lưu số dư".
   *Command:* /impeccable polish.
4. **[P2] A checkbox and an unmarked destructive confirm.**
   *Why:* "Xác nhận TK mới" is a `CheckboxListTile` (`:225-238`; DESIGN.md uses no checkboxes, and the default fill is
   cobalt). The delete confirm is a primary `FilledButton` "Xoá" (`:121`), and the "Xoá" text button sits in the dialog
   actions beside "Huỷ" and "Lưu" (`:248-253`).
   *Fix:* a switch tile "Đây là tài khoản của tôi" (subtitle "TK này được tự phát hiện từ biến động"); in edit mode a
   separate `error` text button "Xoá tài khoản" (`delete_outline`) 24 dp below the fields; the confirm a filled `error`
   / `onError` "Xoá". When the account has transactions (400), show the server message above the sticky button, next to
   the switch it points to.
   *Command:* /impeccable harden.
5. **[P2] Saving gives no feedback.**
   *Why:* from Tổng quan the balance save just reloads (`dashboard_screen.dart:340-350`); from Cài đặt the SnackBar is a
   generic "Đã lưu tài khoản" (`settings_screen.dart:174`).
   *Fix:* "Đã cập nhật số dư Vietcombank ··1234: 6.200.000đ", "Đã thêm tài khoản "VCB chính"", "Đã xoá tài khoản";
   after the first account on first run, optionally offer "Thêm tài khoản khác" as the SnackBar action.
   *Command:* /impeccable clarify.

## Further Issues (ranked)

6. **[P3] In edit mode the bank is an `InputDecorator`** that looks like an editable field (`:156-160`); show it as
   read-only text.
7. **[P3] The balance helper in edit mode** ("Để trống nếu không đổi. Hiện tại: …") is correct but relies on the
   empty-field convention; in the balance sheet, the prefilled-and-selected pattern from issue 1 is clearer.
8. **[P3] No validation focus;** "Nhập tên tài khoản" / "Số tài khoản cần ít nhất 4 chữ số" appear inline but focus stays
   put.

## Persona Red Flags

- **Chủ tài khoản correcting a drifted balance (bank app in the other hand):** pastes or types 6.150.000 into a field
  that already says 6.200.000 and gets "6.200.000.615.000"; with the keyboard up, the dialog's "Lưu số dư"
  is at the edge of a small modal.
- **Sam (TalkBack):** the checkbox announces "Xác nhận TK mới, hộp kiểm"; the dialog's three action buttons do not mark
  which one is destructive.

## Minor Observations

- The bank choices "Vietcombank (VCB)", "MB Bank", "Khác" are fine as a dropdown (a segmented button would not fit at
  360 dp; see the brief).
- The cash account hides the account number and the delete action: correct.

## Questions to Consider

- Should a first-run add flow ask for the balance first, since that is what ends UNKNOWN?

## What Must Change to Meet DESIGN.md

- [ ] Balance sheet and account sheet as modal bottom sheets with sticky filled buttons and inline errors above them.
- [ ] The known balance selected on open; a 64 dp `moneyInput` field with "VD: 6.200.000".
- [ ] Outlined themed fields; switch tiles only (no checkbox); precise button labels.
- [ ] Destructive confirm in filled `error`; specific success SnackBars.

Trend: first run for this target, so there is no trend yet. The snapshot lives in this file.

Questions skipped: non-interactive workflow subagent with no question tool; the owner's decisions came with the task
(5 priority issues listed).
