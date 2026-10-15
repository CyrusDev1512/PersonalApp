# Tài khoản và số dư (account sheet + balance sheet): shape brief

Target: `mobile/lib/widgets/account_dialog.dart` (`showAccountForm` / `AccountFormDialog`, `showBalanceDialog` /
`BalanceDialog`). Both are `AlertDialog`s today; DESIGN.md › Bottom sheets moves them into bottom sheets (dialogs stay
only for destructive confirmations). Visitor mode: **operate** (setup and correction). Inherits DESIGN.md. Items marked
*(inferred)* need the owner's nod.

## Job and audience

The owner tells the app which accounts count and what their balance is right now. Two moments:

- **First run:** Kết nối máy chủ → Tổng quan in UNKNOWN → "Thêm tài khoản" → add Vietcombank, enter today's balance →
  back on Tổng quan the hero leaves UNKNOWN (the status-change moment plays). Then the same for MB and cash.
- **Correction:** a balance drifted or was never set ("Chưa biết số dư của: MB ··5678"), an auto-discovered account
  needs confirming, a savings account should stop counting. The owner has the bank app open in the other hand and
  copies a number across.

## Entry points

| From | Opens |
|---|---|
| Tổng quan, UNKNOWN hero "Thêm tài khoản" (no accounts) | Account sheet, add mode |
| Tổng quan, UNKNOWN hero "Nhập số dư" (`enter_balance`) | Balance sheet for the first account without a balance |
| Tổng quan, "Cần bạn xem" row "Chưa biết số dư của: MB ··5678" → "Nhập số dư" | Balance sheet for that account |
| Tổng quan, account row tap | Balance sheet for that account (the common correction) |
| Cài đặt, account row tap | Account sheet, edit mode (all fields, balance included) |
| Cài đặt, "Thêm tài khoản" row | Account sheet, add mode |

The "Phát hiện TK mới … Tính vào tổng số dư?" row on Tổng quan keeps its inline answer (tonal "Tính vào tổng" /
outlined "Không tính", `PATCH {"confirmed": true, "include_in_total": …}`) and does not open a sheet.

## The one primary action

**Balance sheet:** **"Lưu số dư"**. **Account sheet:** **"Thêm tài khoản"** (add) / **"Lưu tài khoản"** (edit). Each is the
sheet's full-width filled `primary` button in the sticky bottom bar that rides above the keyboard; busy state keeps the
label and shows an 18 dp progress icon.

## Balance sheet: information order

1. Drag handle; title "Nhập số dư" (`headlineSmall`).
2. The account as a fact, not a field: "Vietcombank ··1234" in `titleMedium`; meta `bodySmall` "Số dư hiện tại:
   6.200.000đ · cập nhật 14:32" or "Chưa có số dư".
3. One sentence, `bodyMedium`: "Mở app ngân hàng và nhập đúng số dư hiện tại. Các biến động sau đó sẽ được cộng/trừ từ
   mốc này."
4. Money field "Số dư hiện tại" (`moneyInput`, 64 dp, suffix "đ", live grouping, `autofocus`, prefilled with the known
   balance, placeholder "VD: 6.200.000").
5. Sticky "Lưu số dư".

## Account sheet: information order

1. Drag handle; title "Thêm tài khoản" / "Sửa tài khoản" (`headlineSmall`, 1.42; in edit mode the account name is not
   quoted in the title).
2. **Ngân hàng**: add mode the existing dropdown field ("Vietcombank (VCB)", "MB Bank", "Khác"); a segmented button
   was considered, but "Vietcombank" needs 145 dp with the check icon against 109 dp per segment at 360 dp. Edit mode:
   read-only text (the bank cannot change).
3. **Số tài khoản** (number keyboard), helper "Dùng để nhận diện biến động từ webhook/email", optional for "Khác".
4. **Tên gợi nhớ**, placeholder "VD: VCB chính".
5. **Số dư hiện tại** (money field as above); helper in add mode "Có thể để trống và nhập sau"; in edit mode "Để trống
   nếu không đổi. Hiện tại: 6.200.000đ".
6. Switch tile **"Tính vào tổng số dư"**, subtitle "Tắt cho TK tiết kiệm riêng". Part of the form (saved with the
   button), themed `secondary` track.
7. Auto-discovered, unconfirmed accounts only: switch tile **"Đây là tài khoản của tôi"**, subtitle "TK này được tự phát
   hiện từ biến động". Replaces today's `CheckboxListTile` (checkboxes are not used; their default fill is cobalt).
   Keeps today's coupling: turning "Tính vào tổng số dư" on also turns this on (the server confirms an account that is
   counted); turning this off turns "Tính vào tổng số dư" off.
8. Edit mode only, last, after 24 dp: `error` text button **"Xoá tài khoản"** (`delete_outline`).
9. Sticky primary button.

## Delete confirmation

Dialog (destructive): title "Xoá tài khoản?"; body "Xoá "VCB chính · …1234". Chỉ xoá được tài khoản chưa có giao dịch.";
actions text "Huỷ" + **filled `error` / `onError` "Xoá"** (today it is a plain cobalt `FilledButton`). On success the
sheet closes with snackbar "Đã xoá tài khoản"; on `400` (the account has transactions) the dialog closes, the sheet stays
open and shows the server message in `error` above the sticky button (today: "Tài khoản đã có giao dịch — hãy tắt
"Tính vào tổng" thay vì xoá"), next to the switch it points to.

## States and ranges

| State | What shows |
|---|---|
| Opened (balance) | Keyboard up, field focused, the known balance selected so typing replaces it. |
| Validation | Inline under the field: "Nhập số dư (có thể là 0)" (balance sheet), "Nhập tên tài khoản", "Số tài khoản cần ít nhất 4 chữ số". Focus moves to the first invalid field. |
| Saving | Fields and switches disabled, sticky button busy. Back and swipe-down still close the sheet; the request is not cancelled, and its result shows as a snackbar on the screen underneath. |
| Save failed | Sheet stays open, fields kept; the API message in `error` (`bodyMedium`, with an `error_outline` icon) directly above the sticky button. Offline: "Không kết nối được máy chủ. Số dư chưa được lưu." |
| Saved (balance) | Sheet closes; snackbar "Đã cập nhật số dư Vietcombank ··1234: 6.200.000đ". Tổng quan refreshes; if `free` or the level changed the hero plays the status-change moment (UNKNOWN → a level on first run). |
| Saved (account) | Sheet closes; snackbar "Đã thêm tài khoản "VCB chính"" / "Đã lưu tài khoản". |
| Unsaved changes + Back | *(inferred)* No discard dialog: the sheet closes and nothing is saved (the forms are short; a confirmation would cost more than retyping). |
| Large text | Fields stack as they already do; the money field grows with the text (no fixed height above 64 dp). |

Ranges: 1-5 accounts; balances 0 to 13 digits (negative balances are not entered here); names 1-60 characters and
account numbers up to 32 characters (server limits), at least 4 digits when given.

## Remove / merge compared with today

- `AlertDialog` forms → modal bottom sheets with a sticky primary button (DESIGN.md › Bottom sheets).
- `CheckboxListTile` "Xác nhận TK mới" → switch tile with plain wording.
- Error text `TextStyle(color: colorScheme.error)` built inline → the shared inline-error line above the sticky button.
- Delete confirmation `FilledButton` (cobalt) → filled `error`.
- Button label "Lưu" → "Thêm tài khoản" / "Lưu tài khoản" (controls name their action).

## Constraints and open decisions

- Keep `showAccountForm` / `showBalanceDialog` signatures and `AccountFormResult` (callers in Tổng quan and Cài đặt), or
  rename deliberately with the tests; keep `Key('enter_balance')` on the hero / "Cần bạn xem" button that opens it.
- API unchanged: `POST /api/accounts`, `PATCH /api/accounts/{id}` (`balance` sets today's anchor; turning
  `include_in_total` on also confirms), `DELETE /api/accounts/{id}` (`400` when it has transactions).
- **Open (inferred):** after adding the first account on first run, offer "Thêm tài khoản khác" as a snackbar action.
