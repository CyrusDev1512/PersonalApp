# Cảnh báo (alert history): shape brief

Target: `mobile/lib/screens/alerts_screen.dart`, `widgets/alert_tile.dart`, and the push-opened alert in
`push/push_navigator.dart`. Visitor mode: **operate**. Inherits DESIGN.md.

## Job and audience

The owner checks why the app or Telegram warned them, catches up on unread items, and jumps to the cause (a
transaction to categorise, a goal over budget).

## The one primary action

**Open an alert** → alert-detail bottom sheet, whose filled button is the contextual next step:
"Phân loại giao dịch" / "Xem giao dịch" (has `transaction_id`), "Xem mục tiêu" (has `goal_id`), otherwise no button.
App-bar text button **"Đọc hết"** (`done_all`) marks everything read (enabled only when something is unread).

## Information order

1. Top app bar "Cảnh báo" + "Đọc hết".
2. *(inferred)* Filter chips "Tất cả" / "Chưa đọc · 2".
3. Day groups ("Hôm nay", "Hôm qua", "Thứ Hai, 12/10"), each one list group of alert rows (DESIGN.md › Alert row):
   level disc, title (700 when unread), 2-line message, time "14:32" / "08:00", unread dot.

**Detail sheet:** level disc + title in `headlineSmall`; "14:32, Thứ Ba 14/10/2026" `bodySmall`; message as
`SelectableText` `bodyLarge`; contextual filled button at the bottom. Opening marks it read and refreshes the badge.

## States and ranges

| State | What shows |
|---|---|
| Loading | Six skeleton rows. |
| Empty | "Chưa có cảnh báo nào." + `bodySmall` "Khi số dư xuống gần mức cần giữ, app sẽ báo ở đây và qua Telegram." |
| Empty unread filter | "Không còn cảnh báo chưa đọc." |
| Error, no data | `ErrorView` "Không tải được cảnh báo" + "Thử lại". |
| Mark read failed | Snackbar with the API message; the row stays unread. |
| Đọc hết done | Snackbar "Đã đánh dấu 5 cảnh báo là đã đọc" / "Không còn cảnh báo chưa đọc". |
| Push in foreground | Snackbar (`push_snackbar`) "Có cảnh báo mới" + action "Xem" (unchanged). |

Ranges: up to 100 alerts loaded; kinds `tx`, `floor`, `safe`, `budget`, `forecast`, `digest`, `account`, `health`,
`info`; levels OK/WARNING/DANGER/UNKNOWN/INFO; messages 1-6 lines of server Vietnamese.

## Copy (Vietnamese)

"Cảnh báo" · "Đọc hết" · "Tất cả" · "Chưa đọc" · "Hôm nay" · "Hôm qua" · "Phân loại giao dịch" · "Xem giao dịch" ·
"Xem mục tiêu" · semantics "Chưa đọc".

## Remove / merge compared with today

- `AlertDialog` on tap → bottom sheet with a contextual action; the push-opened alert (`push_alert_dialog`) uses the same
  sheet component.
- `levelColor()` hard-coded `Colors.*` → `StatusColors`; INFO → secondary roles with a kind icon.
- Flat list with full-width dividers → day groups with inset dividers.
- The `dense` variant used by the dashboard's "Cảnh báo gần đây" goes away with that section.

## Constraints and open decisions

- Keep `Key('push_alert_dialog')` on the new sheet (or update `push_test.dart`), and `push_snackbar`.
- The "Chưa đọc" chip maps to the existing `GET /api/alerts?unread=true` (`ApiClient.listAlerts(unread: true)`).
- **Open:** whether the filter chips are wanted at all (inferred; with the nav badge and "Đọc hết" the plain list may
  be enough).
