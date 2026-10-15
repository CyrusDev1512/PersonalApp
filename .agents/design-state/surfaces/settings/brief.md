# Cài đặt (settings): shape brief

Target: `mobile/lib/screens/settings_screen.dart` (+ `widgets/account_dialog.dart`). Visitor mode: **operate**.
Inherits DESIGN.md. Items marked *(inferred)* need the owner's nod.

## Job and audience

The owner sets up once (accounts and starting balances, server), then occasionally tunes: buffer rule, expected salary,
Telegram verbosity, push notifications on a new phone. Visits are rare and deliberate; clarity of consequence matters
more than speed.

## The one primary action

**"Lưu cài đặt"** (`settings_save`): the only filled button, at the end of the buffer and salary fields, enabled only
when one of those fields changed; success snackbar "Đã lưu cài đặt". It saves fields that need deliberate commitment
(numbers with consequences). Switches on this screen do not wait for it: they apply at once (Android convention for a
preferences screen). The most consequential setup action, "Thêm tài khoản", is the last row of the accounts group
(leading `add`), not a competing filled button.

## Information order

1. Top app bar "Cài đặt".
2. **Tài khoản** list group: one shared account row per account, the same component as on Tổng quan (DESIGN.md › Lists
   and containers): 40 dp neutral disc with the bank short name in text ("VCB", "MB") or `payments_outlined` for cash;
   title "Vietcombank ··1234"; meta "cập nhật 14:32" (+ "ước tính", "không tính vào tổng"); trailing `moneyList` balance
   or "chưa biết số dư"; the pill "Chưa xác nhận" (warning container) under the meta for auto-discovered accounts; no
   chevron. Last row: "Thêm tài khoản". Tap opens the account sheet in edit mode, "Thêm tài khoản" in add mode
   (`../account-sheet/brief.md`).
3. **Cảnh báo** group (its two buffer fields form one form with item 4):
   - one sentence with the live value: "Đang báo khi được tiêu dưới 600.000đ (số lớn hơn giữa 10% mức sàn và
     500.000đ)." recomputed as the fields change;
   - "Vùng đệm theo % mức sàn" (`settings_warning_percent`, suffix "%") and "Vùng đệm tối thiểu"
     (`settings_warning_min`, money field) side by side at ≥ 400 dp, stacked below;
   - switch "Báo Telegram mỗi giao dịch", subtitle "Tắt thì chỉ báo khi chạm ngưỡng mức sàn hoặc ngân sách". Applies at
     once: `PUT /api/settings {"notify_every_tx": …}` (the endpoint takes a subset), switch disabled while the call
     runs, snackbar "Đã bật báo Telegram mỗi giao dịch" / "Đã tắt báo Telegram mỗi giao dịch"; on failure it flips back
     and the snackbar carries the API message. It is not part of "Lưu cài đặt".
4. **Lương dự kiến**: one line "Tuỳ chọn. Trước ngày lương, nếu chỉ thiếu tạm thời và lương sẽ bù đủ thì app báo
   "chờ lương" thay vì báo nguy hiểm mỗi ngày."; "Số tiền lương" (`settings_income_amount`, placeholder "Để trống = không
   dùng") + "Ngày nhận" (`settings_income_day`); then "Lưu cài đặt".
5. **Thông báo đẩy**: status row (`push_status`) with icon + `PushStatus.label` + the existing help sentence; actions
   tonal "Gửi thử" (`push_test`, busy "Đang gửi…") and text "Thử lại" when retry applies.
6. **Máy chủ** (last: rarely changed): "Địa chỉ máy chủ" row (URL), the http warning row when insecure (warning icon,
   "Kết nối không mã hoá (http://)", "Token được gửi dạng rõ. Chỉ nên dùng trong mạng LAN tin cậy."), "Token" row
   (masked "••••••••a1b2"), then tonal "Đổi máy chủ / token" and `error` text button "Ngắt kết nối" (confirm dialog:
   "Ngắt kết nối?" / "App sẽ quên địa chỉ máy chủ và token trên máy này. Dữ liệu trên máy chủ không bị xoá." /
   "Huỷ" + filled `error` "Ngắt kết nối").

## States and ranges

| State | What shows |
|---|---|
| Loading | Skeleton rows inside each group (no bare `LinearProgressIndicator` between headings). |
| Load error | Inline in the affected group: "Không tải được cài đặt." + text "Thử lại"; other groups still usable. |
| No accounts | Group holds one explanatory row "Chưa có tài khoản. Thêm TK ngân hàng và nhập số dư hiện tại để app tính được mức an toàn." + "Thêm tài khoản". |
| Validation | Inline: "Nhập số phần trăm", "Chỉ từ 0 đến 100", "Nhập số tiền (có thể là 0)", "Ngày 1–31". |
| Saving / saved / failed | Button busy "Đang lưu…" / snackbar "Đã lưu cài đặt" / snackbar with the API message, fields kept. |
| Telegram switch saving / failed | Switch disabled during the call / switch returns to its previous value + snackbar with the API message. |
| Push states | Labels from `PushStatus` ("Đang bật", "Chưa được cấp quyền thông báo", "Máy chủ chưa cấu hình Firebase", …) with icons: enabled `notifications_active_outlined` in `ok.foreground`, problems `notifications_off_outlined` in `warning.foreground`, unavailable `notifications_none` in `onSurfaceVariant`. |
| Gửi thử result | Snackbar "Đã gửi thông báo thử, chờ vài giây." / "Máy chủ chưa cấu hình Firebase nên chưa gửi được thông báo thử." |

Ranges: 1-5 accounts; buffer 0-100%; salary up to 9 digits; day 1-31.

## Remove / merge compared with today

- Reorder: Tài khoản → Cảnh báo → Lương dự kiến → Thông báo đẩy → Máy chủ (today Máy chủ is first).
- Cards under `SectionHeader`s → list groups (no cards, no nested padding boxes); the alert form card becomes plain
  fields on the surface inside one group.
- Replace the formula sentence "vùng đệm = max(% × mức sàn, số tiền tối thiểu)" with a plain sentence and the live
  computed amount.
- "💵" emoji avatar → `payments_outlined`; bank-letter avatar keeps text (no logos); `Colors.amber.shade800` →
  `StatusColors.warning`.
- "Thêm tài khoản" moves from the section-header trailing button into the group's last row.

## Constraints and open decisions

- Keep `Key`s: `settings_warning_percent`, `settings_warning_min`, `settings_income_amount`, `settings_income_day`,
  `settings_save`, `push_status`, `push_test`.
- **Decided:** switches save at once, number fields with "Lưu cài đặt". **Open:** autosave for the number fields too
  (not recommended: the buffer change has consequences the owner should commit to deliberately).
- **Open (inferred):** a "Giới thiệu" row with app version and licences (OFL for Be Vietnam Pro must ship somewhere;
  Flutter's `showLicensePage` with the font's `OFL.txt` registered via `LicenseRegistry` covers it).
