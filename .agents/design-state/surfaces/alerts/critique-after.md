# Critique (after redesign): Cảnh báo (alert history + alert-detail sheet)

**DEGRADED: single-context** (impeccable `critique` done by hand in one verifier subagent. No sub-agent tool, and the
engine/detector is out of bounds. The AGENTS.md native source checks replace Assessment B.)

- **Target:** `mobile/lib/screens/alerts_screen.dart`, `widgets/alert_row.dart`, `widgets/alert_detail_sheet.dart`,
  `push/push_navigator.dart`, `utils/text.dart`. Working tree on HEAD `c7fe25b`.
- **Evidence:** Flutter **web demo** in Chromium only.
  - `B/` = `…/scratchpad/demo_web/before/`
  - `A/` = `…/scratchpad/demo_web/after/`
  - `X/` = `…/scratchpad/demo_web/after/extra/`
  - `V/` = `…/scratchpad/redesign_verify/critique/`
  - `…` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8`

## Design Health Score (before → after)

| # | Heuristic | Before | After | Key issue now |
|---|-----------|-------:|------:|---------------|
| 1 | Visibility of System Status | 2 | 3 | The time never truncates; unread dot plus 700/500 title weight; "Đọc hết" disables when nothing is unread |
| 2 | Match System / Real World | 2 | 3 | Emoji stripped from titles, but bodies keep "✅ …", and the detail shows the Telegram-only "gõ /uncat" |
| 3 | User Control and Freedom | 3 | 3 | The sheet closes on scrim or Back; filters are reversible |
| 4 | Consistency and Standards | 2 | 3 | Sheet like the rest of the app, StatusColors discs, INFO in secondary. "Đọc hết" overhangs the column at 1280 |
| 5 | Error Prevention | 3 | 3 | Little to prevent; a mark-read failure keeps the row unread |
| 6 | Recognition Rather Than Recall | 2 | 3 | Day groups and a jump to the transaction or goal from the sheet |
| 7 | Flexibility and Efficiency | 2 | 3 | "Chưa đọc · N" filter (`?unread=true`), "Xem giao dịch" / "Xem mục tiêu" |
| 8 | Aesthetic and Minimalist Design | 1 | 3 | Two-line rows in day groups; server emoji survive in message bodies |
| 9 | Error Recovery | 3 | 3 | ErrorView with "Thử lại"; snackbar on mark-read failure |
| 10 | Help and Documentation | 2 | 3 | The empty and empty-unread states say what will appear and when (code; not in a shot) |
| **Total** | | **22/40** | **30/40** | **Acceptable → Good** |

## Design Specificity Verdict

**Assessment (unanchored):** the history now reads as part of the app rather than a Telegram log. Each row has a
level disc (butter `warning.container` for "Sắp chạm mức mục tiêu"; secondary discs with kind icons for the digest,
the transaction notice and the test push). Titles use weight to show unread, and the time is trailing and never
truncated. There is an 8 dp cobalt unread dot, and rows sit in day groups ("Hôm nay", "Hôm qua", "Thứ Sáu, 02/10")
(`A/alerts-390x844-light.png` vs `B/alerts-390x844-light.png`). The badge is cobalt, not red. The detail is a bottom
sheet with "08:00, Thứ Năm 15/10/2026" (`X/alert-detail-390-light.png`).

**Native source checks:** no hard-coded colours or font sizes. The `ListView(` at `alerts_screen.dart:178,189` holds a
skeleton or an empty state. Leading-emoji stripping is in one helper (`utils/text.dart:13-15`) shared with the push
SnackBar.

## What improved

- The 4-line text dumps with two icons per row are gone. Each row is one disc, a title, 2 lines of message and the time.
- The dialog became the shared detail sheet, also used by push, with a contextual filled button.
- Unread filter with a count, and a calm empty-unread state.
- The red badge became `primary` (Calm Badge Rule).

## Priority Issues (what still fails)

1. **[P2] Server emoji and Telegram-only instructions leak into the app.**
   - *Evidence in rows:* the digest row starts its message with "✅ An toàn — Còn 4.000.000đ…"
     (`A/alerts-390x844-light.png`, `-1280x800-dark.png`).
   - *Evidence in the detail sheet:* it prints "🏠", "🍜", "📈", "🏷️", and the last line is "2 giao dịch chưa phân
     loại — gõ /uncat để phân loại." (`X/alert-detail-390-light.png`). That instruction is for the Telegram bot and
     means nothing in the app.
   - *Rules:* DESIGN.md › Components: no emoji as UI icons (only user category emoji). PRODUCT.md voice: "no
     app-authored emoji".
   - *Fix:*
     - Apply `stripLeadingEmoji` per line of the message, not only to the title.
     - Drop or replace lines that reference bot commands ("/uncat"). The backend is out of scope, so do this client side.
     - In the sheet, turn the uncategorised hint into the contextual button.
   - *Command:* /impeccable clarify.
2. **[P3] The detail button always says "Xem giao dịch".**
   - *Evidence:* `alert_detail_sheet.dart:128` uses "Xem giao dịch" even when the transaction is uncategorised.
   - *Rule:* the brief wants "Phân loại giao dịch" there, which names what the owner will do. The builder listed this
     gap.
3. **[P3] "Đọc hết" overhangs the content column at ≥ 840 dp.**
   - *Evidence:* the text spans x = 998–1078 px while the list groups end at x = 1068 (`A/alerts-1280x800-light.png`,
     measured). The app-bar title is gutter-aligned (`titleSpacing: gutter`, `alerts_screen.dart:132`), but the actions
     have no matching end padding.
   - *Fix:* add a trailing `SizedBox(width: gutter - 12)` after the actions (the text button keeps 12 dp of padding).

## Persona Red Flags

- **Chủ tài khoản opening the ATM alert from Telegram:** the WARNING row is unmistakable and opens a sheet with "Xem
  giao dịch". Good. But the digest still talks in Telegram's voice ("gõ /uncat").
- **Sam (TalkBack):** the unread dot carries the semantics "Chưa đọc" (`alert_row.dart:112-113`), merged into the row. Day headings are plain text. Not
  re-tested here.

## Minor Observations

- The transaction notice repeats its own time in the message ("−3.500.000đ · VCB chính · 17:38 15/10" beside "17:38").
  This is server text; a client could drop the trailing time when it equals the row time.
- The INFO "Chi 200.000đ" uses a receipt disc. The before shot showed a green "OK" check for the same notice. Neutral is
  better.
- `X/alert-detail-390-light.png`: the sheet title "Bản tin tài chính 15/10" is `headlineSmall` 24 sp/700 beside a
  40 dp disc. That is DESIGN-compliant but heavier than the message it introduces.

## Questions to Consider

- Should the detail sheet render the digest as structured lines (balance, floor, goals) instead of the Telegram text?

Trend: before 22/40 → after 30/40.

Questions skipped: non-interactive verifier subagent with no question tool (3 priority issues listed).
