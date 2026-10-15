# Giao dịch (transactions, categorise sheet, manual entry): shape brief

Targets: `mobile/lib/screens/transactions_screen.dart` (`TransactionsScreen`, `TxTile`),
`screens/tx_action_sheet.dart` (categorise sheet), `screens/manual_tx_screen.dart` (Nhập tay). Visitor mode:
**operate**. Inherits DESIGN.md. Items marked *(inferred)* need the owner's nod.

## Job and audience

The owner scans this month's money movements, and a few times a week clears the "chưa phân loại" pile quickly
(often right after a Telegram/push alert opened the sheet directly). Occasionally records a cash expense.

## The one primary action

**Categorise a transaction**: tap a row → bottom sheet → choose a category chip → **"Lưu danh mục"** (sticky,
full-width filled). This task lives in the rows and the sheet, not in a button. The screen's one creation action is the
FAB **"Nhập tay"** (`edit_note`): recording a cash expense is the only way cash spending reaches the app, so it earns
the FAB on this screen; it uses `secondaryContainer` so cobalt stays reserved for "Thêm mục tiêu".

## Information order: list

1. Top app bar "Giao dịch".
2. Month row: icon buttons "Tháng trước" / "Tháng sau" (tooltips; next disabled at the current month) around
   "Tháng 10/2026" in `titleSmall` (the `monthLabel` format used everywhere).
3. Filter chips: "Tất cả" / "Chưa phân loại · 3" (`filter_uncategorized`).
4. Day groups, newest first: heading "Hôm nay", "Hôm qua", "Thứ Hai, 12/10" in `titleSmall` `onSurfaceVariant`
   *(inferred: trailing day total of outgoing spend in `moneyInline`)*; rows inside one list group per day.
5. "Tải thêm (23)" outlined button at the end when more pages exist.

**Row anatomy:** leading 40 dp disc with the category emoji (user data) or, when uncategorised, `north_east` (out) /
`south_west` (in) icon; title = `tx.title`, 2 lines max; meta `bodySmall` "Vietcombank · 14:32 · SePay"; trailing signed
amount `moneyList` (out `onSurface` with "−", in `ok.foreground` with "+", internal transfer `onSurfaceVariant` with its
sign, so the celadon "Chuyển nội bộ" pill never sits beside the OK green). Built as a `MoneyRow`: above 125% font
scale the amount moves under the meta, end-aligned (DESIGN.md › Layout). Under the meta, **at most one pill**, by
priority: "Có thể trùng" (warning container) > "Đang chờ khớp" (unknown container) > "Chưa phân loại"
(`primaryContainer`, it is an invitation) > "Chuyển nội bộ" (`tertiaryContainer`). Goal assignment, "Nhập tay" and
"Đã loại trừ" become meta text ("→ Tiền trọ · 11/2026" with `flag_outlined`); excluded rows also strike through the
amount in `onSurfaceVariant`.

## Information order: categorise sheet

1. Header: signed amount `moneyLarge`, title `titleMedium`, meta "Vietcombank · 14:32 14/10/2026 · Số dư sau:
   6.500.000đ" `bodySmall`.
2. Notices (only when true), icon + `bodySmall`, no boxes: "Có thể trùng với giao dịch #123. Nếu đúng là trùng, hãy
   "Loại trừ" một bản."; "Giao dịch từ email đang chờ webhook khớp, tạm chưa tính."
3. **Danh mục**: choice chips "🍜 Ăn uống" … in `sort_order` (outgoing: expense + transfer categories, as today);
   the current category is preselected.
4. "Nhớ luật cho giao dịch tương tự" switch; when on, field "Cụm từ nhận diện" prefilled with the server suggestion.
5. "Gán vào mục tiêu" dropdown (`tx_goal`): "Tự động theo danh mục" + this month's goals.
6. "Tính cho tháng sau" switch tile (`tx_counted_later`), subtitle "VD: trả tiền trọ tháng sau từ cuối tháng này".
7. "Loại trừ" / "Bỏ loại trừ" tile; "Xoá giao dịch nhập tay" (manual only) as `error` text.
8. Sticky bottom bar, stacked: full-width filled "Lưu danh mục" ("Bỏ phân loại" when clearing). *(inferred)* In the
   "Chưa phân loại" filter, and only while another uncategorised transaction exists, a full-width text button "Lưu và
   mở giao dịch tiếp theo" on its own row under it (it needs 233 dp; beside the filled button the pair would need
   386 dp of the 320 dp the sheet has at 360 dp).

## Information order: Nhập tay

App bar "Thêm giao dịch" → segmented "Khoản chi" (`north_east`) / "Khoản thu" (`south_west`) → **Số tiền** money field
→ "Mô tả" (placeholder "VD: Bánh mì, đổ xăng") → "Danh mục" → "Thời gian" tile → "Tài khoản" ("Tiền mặt / ngoài ngân
hàng" first) → switch "Cộng/trừ vào số dư tài khoản này" (subtitle "Chỉ bật nếu ngân hàng sẽ không gửi biến động cho
khoản này"; part of the form, saved with it; shown only when a bank account is chosen) → sticky filled "Lưu giao dịch".

| Nhập tay state | What shows |
|---|---|
| Opened | "Khoản chi" selected, focus in **Số tiền** with the number keyboard, "Thời gian" = now, "Tài khoản" = "Tiền mặt / ngoài ngân hàng". |
| Categories loading | Disabled "Danh mục" field with helper "Đang tải danh mục…" (same as the goal form). |
| Categories failed | Helper in `error` "Không tải được danh mục." + text button "Thử lại"; the entry can still be saved as "Chưa phân loại" (today's first dropdown choice). |
| Validation | Inline: "Nhập số tiền", "Số tiền phải lớn hơn 0"; focus moves to the first invalid field. The date picker already limits "Thời gian" (from a year back to tomorrow). |
| Saving | Fields disabled, button busy (label kept, 18 dp progress icon). |
| Save failed | Form stays filled; message in `error` under the sticky button (e.g. "Không kết nối được máy chủ. Giao dịch chưa được lưu."). |
| Saved | Pop back to Giao dịch; snackbar "Đã thêm khoản chi 50.000đ" / "Đã thêm khoản thu 2.000.000đ"; the new row appears in its day group. Dashboard plays the status-change moment if `free` changed. |

## States and ranges

| State | What shows |
|---|---|
| First page loading | Six skeleton rows; month row and chips stay interactive. |
| Empty month | "Chưa có giao dịch trong tháng 10." + `bodySmall` "Giao dịch từ Vietcombank và MB sẽ tự hiện khi ngân hàng báo biến động." |
| Empty "Chưa phân loại" | "Đã phân loại hết giao dịch tháng 10." (calm, positive; no illustration). |
| Error, no data | `ErrorView`: "Không tải được giao dịch" + message + "Thử lại". |
| Reload failed with data | Neutral strip (`tx_reload_error`), the same treatment as Tổng quan's offline strip: `surfaceContainerHigh`, `sync_problem` icon in `onSurfaceVariant`, text `onSurface` "Không tải lại được: <message>", text button "Thử lại". No red (cached data is still correct to look at). |
| Saving in sheet | Controls disabled, button busy; failure keeps the sheet open with the message in `error` under the button. |
| Saved | Sheet closes; snackbar "Đã phân loại" / "Đã phân loại và nhớ luật "GRAB"" / "Đã bỏ phân loại", with "Hoàn tác" where it can be undone (re-PATCH the previous category). The row updates in place or leaves the filtered list. |
| Opened from push | The same sheet over whatever screen is open (PushNavigator), unchanged behaviour. |
| Large text (> 125%) | Rows stack the amount under the meta; the categorise sheet's chips wrap; the sticky bar keeps its two rows. |

Ranges: 20-300 transactions a month, 50 per page; titles up to ~120 characters (bank descriptions are long and
uppercase; show as received, 2 lines); amounts 1.000đ to 100.000.000đ.

## Remove / merge compared with today

- Up to six bordered `StatusBadge`s per row (category, Chuyển nội bộ, 🎯 goal, Đang chờ khớp, Đã loại trừ, Có thể trùng,
  Nhập tay) → one pill by priority + meta text. Category moves into the leading disc + meta.
- Red/green amount colours (`Colors.red.shade700` / `Colors.green.shade700`) → `onSurface` / `ok.foreground`.
- "↑"/"↓" text glyph avatars → Material icons; "🎯" in the goal badge → `flag_outlined`.
- "Chưa phân loại" badge in `error` colour → `primaryContainer` invitation.
- FAB "Thêm giao dịch" (primary container) → "Nhập tay" in `secondaryContainer`.
- Full-width dividers between every row → inset dividers inside day groups; day headings added.
- `Colors.deepOrange` / `Colors.amber` hints in the sheet → `StatusColors.warning` icon + `onSurface` text.

## Constraints and open decisions

- Keep `TransactionsController` behaviour and `Key`s: `filter_uncategorized`, `tx_reload_error`, `tx_goal`,
  `tx_counted_later`. Keep `ListView.builder`/`separated` (long lists).
- **Open:** day totals in group headings (useful for pace, not requested).
- **Open:** "Lưu và mở giao dịch tiếp theo" batch flow (inferred from "quick categorising").
