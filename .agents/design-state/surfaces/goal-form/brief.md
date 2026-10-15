# Thêm / Sửa mục tiêu (goal form): shape brief

Target: `mobile/lib/screens/goal_form_screen.dart` (route `/goal`). Visitor mode: **operate**. Inherits the world in
DESIGN.md; no new identity work. Items marked *(inferred)* need the owner's nod.

## Job and audience

The owner sets the month's promises (e.g. "Tiền trọ" 3.000.000đ *Quỹ giữ*, "Tiền ăn" 5.000.000đ *Ngân sách*) at the
start of a month or ahead for next month, and occasionally edits one. They must finish in well under a minute,
one-handed, and understand what the goal does to "được tiêu".

## The one primary action

**"Tạo mục tiêu"** (new) / **"Lưu thay đổi"** (edit): full-width filled `primary` button in a sticky bottom bar that
rides above the keyboard (`goal_save`). Busy: label stays, icon becomes an 18 dp progress indicator.

## Information order

1. Top app bar: "Thêm mục tiêu" / "Sửa mục tiêu"; in edit mode a trailing `delete_outline` icon button with tooltip
   "Xoá mục tiêu".
2. **Loại mục tiêu**: segmented button "Quỹ giữ" (`savings_outlined`) / "Ngân sách" (`shopping_basket_outlined`);
   short labels because each segment gets at most 164 dp at 360 dp ("Ngân sách chi tiêu" needs 180 dp with its icon).
   One `bodySmall` line below that changes with the type and names the full term:
   - "Quỹ giữ: tiền phải giữ lại trong tài khoản, vd. tiền trọ. Khi trả (giao dịch thuộc danh mục), quỹ giảm tương ứng."
   - "Ngân sách chi tiêu: hạn mức chi trong tháng, vd. tiền ăn. Mỗi khoản chi thuộc danh mục trừ dần; phần chưa chi vẫn
     được giữ."
3. **Tên mục tiêu** (`goal_name`), placeholder "VD: Tiền trọ, Tiền ăn". *(inferred)* For a new goal, suggestion chips
   under the field: "Tiền trọ", "Tiền ăn", "Tiết kiệm"; tapping fills the name (and the matching type/category when
   unambiguous).
4. **Số tiền** (`goal_amount`): money field, 64 dp, `moneyInput` (proportional digits), suffix "đ", live grouping.
5. **Danh mục**: dropdown (`goal_category_<type>`); Quỹ giữ allows "Tiết kiệm thuần (không gắn danh mục)"; helper text
   per type as today.
6. **Tháng**: segmented "Tháng 10" / "Tháng 11" for new goals (the year is added only when it differs from the current
   one: "Tháng 12" / "Tháng 1/2027"); read-only "Tháng 10/2026" when editing; series hint (`goal_series_hint`) under it
   when relevant. Both segmented buttons switch to vertical, full-width segments when a label does not fit its half
   (e.g. "Tháng 1/2027" at 130%, any label at 200%; DESIGN.md › Inputs).
7. **Lặp lại hằng tháng**: switch tile (themed `secondary` track, not cobalt); part of the form, saved with "Tạo mục
   tiêu" / "Lưu thay đổi"; subtitle "Tự tạo lại vào đầu mỗi tháng" (new) / "Áp dụng cho tháng này và các tháng sau"
   (edit).
8. **Thêm tuỳ chọn** (collapsed expander): "Đã chi trước khi dùng app (tuỳ chọn)" (`goal_opening_spent`) with its helper.
9. *(inferred, optional)* **Impact line** just above the sticky button, new current-month goals only:
   "Mức sàn tháng 10 tăng 3.000.000đ · được tiêu còn 1.000.000đ", in `bodyMedium`; when the result would be below the
   buffer, append "· sẽ ở mức cảnh báo" in `warning.foreground`. Computed from the cached summary
   (`amount − opening_spent`); hidden when the summary is missing, for next-month goals and when editing.

## States and ranges

| State | What shows |
|---|---|
| Categories loading | Disabled dropdown with label "Danh mục" and helper "Đang tải danh mục…" (no bare progress bar). |
| Categories failed | Helper in `error`: "Không tải được danh mục." + text button "Thử lại". |
| Validation | Inline under the field: "Nhập tên mục tiêu", "Tên tối đa 80 ký tự", "Nhập số tiền", "Số tiền phải lớn hơn 0", "Ngân sách chi tiêu cần chọn danh mục", "Số tiền không được âm". Focus moves to the first invalid field. |
| Saving | All fields disabled, button busy. |
| Save failed (offline / server) | Form stays filled; snackbar with the API message, e.g. "Không kết nối được máy chủ. Mục tiêu chưa được lưu." |
| Saved | Pop back; snackbar "Đã thêm mục tiêu "Tiền trọ"" / "Đã lưu mục tiêu" / "Đã tạo mục tiêu cho tháng 11". The dashboard then plays the status-change moment if `free` changed. |
| Delete | Dialog (destructive, so a dialog is right): title "Xoá "Tiền trọ"?" (`headlineSmall` 1.42; the quoted name capped at two lines with an ellipsis); recurring: "Mục tiêu này lặp lại hằng tháng. Bạn muốn xoá thế nào?" with "Huỷ", "Chỉ xoá tháng này", filled `error` "Xoá và dừng lặp lại"; single: "Mục tiêu 10/2026 sẽ bị xoá." with "Huỷ", filled `error` "Xoá". |

Ranges: names 1-80 characters; amounts 1.000đ to 13 digits; 5-20 expense categories with user emoji.

## Remove / merge compared with today

- Move **Loại mục tiêu** to the top (it changes the meaning of every other field) and keep its explanation to one line.
- Move the save button from the end of the scroll into a sticky bottom bar; drop its check icon.
- Fold "Đã chi trước khi dùng app" behind "Thêm tuỳ chọn" (first-month-only, rarely used).
- Replace the bare `LinearProgressIndicator` for categories with a disabled field state.
- Delete-dialog destructive button becomes `error`-filled. Non-recurring goals get the two-button version ("Huỷ" /
  "Xoá", mapped to delete-this-month); today they are also offered "Xoá và dừng lặp lại", which means nothing for them.

## Constraints and open decisions

- Keep `GoalFormArgs`, route name and all `Key`s listed above (`goal_name`, `goal_amount`, `goal_category_reserve`,
  `goal_opening_spent`, `goal_save`, `goal_series_hint`).
- **Open:** impact line formula for a Quỹ giữ whose category already has spending this month (server knows; client can
  only approximate). Ship it only if the server can return a preview, or label it "ước tính".
- **Open:** suggestion chips (item 3) are an inference from the owner's examples, not a stated request.
