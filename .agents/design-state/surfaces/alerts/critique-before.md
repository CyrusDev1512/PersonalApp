# Critique (before redesign): Cảnh báo (alert history)

**DEGRADED: single-context** (impeccable `critique` run by hand inside one workflow subagent: no sub-agent tool is
exposed, and the engine/detector is out of bounds under the Runtime boundary. Native source checks replace Assessment B
and were run after the design review.)

- **Targets:** `mobile/lib/screens/alerts_screen.dart`, `widgets/alert_tile.dart`, `widgets/status_banner.dart`
  (`levelColor`, `levelIcon`), `push/push_navigator.dart` (foreground SnackBar, push-opened dialog), the badge in
  `screens/home_shell.dart`. Line numbers refer to HEAD `10ba63c` (the before state; the working tree is being redesigned in parallel).
- **Evidence:** Flutter **web demo** in Chromium via Playwright, not a device or emulator.
  - `B/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/demo_web/before/`
    (`alerts-*`, `dashboard-after-atm-*` for the push SnackBar; TZ Asia/Ho_Chi_Minh).
  - `X/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/redesign/critique_extra/`
    (`alerts-390-london.png`: browser TZ Europe/London; `dash-scroll3-390-light.png`: "Cảnh báo gần đây").
  - The detail dialog is reviewed from code (it is not in the before set).

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | Unread dot and bold title work, but the time is cut off on 3 of 4 rows; opening waits for the mark-read call |
| 2 | Match System / Real World | 2 | Rows print the raw Telegram message ("Nội dung: … Danh mục: … Số dư: …"); a spending notice carries a green success check |
| 3 | User Control and Freedom | 3 | Dialogs close; "Đọc hết" is low-risk |
| 4 | Consistency and Standards | 2 | Dialog where the system uses sheets; a red badge; hard-coded level colours; two icons per row |
| 5 | Error Prevention | 3 | Little to prevent; mark-read failure keeps the row unread |
| 6 | Recognition Rather Than Recall | 2 | No day grouping, the time hidden, no link to the cause, so the owner must remember which transaction to open in Giao dịch |
| 7 | Flexibility and Efficiency | 2 | "Đọc hết" exists; no "Chưa đọc" filter and no jump to the transaction or goal |
| 8 | Aesthetic and Minimalist Design | 1 | Four-line text dumps with server emoji plus a level icon; full-width dividers; no rhythm |
| 9 | Error Recovery | 3 | ErrorView with "Thử lại"; a mark-read failure shows the API message |
| 10 | Help and Documentation | 2 | The empty state "Chưa có cảnh báo nào." does not say what will appear here or when |
| **Total** | | **22/40** | **Acceptable** |

## Design Specificity Verdict

**LLM assessment:** this is a log viewer. The screen shows Telegram's message format verbatim inside a `ListTile`,
emoji headers included, so the in-app history looks like a pasted chat transcript rather than part of the app. The
level icon on the left and the server emoji in the title ("⚠️ Sắp chạm mức mục tiêu") say the same thing twice. Nothing
connects an alert to its cause: tapping opens an `AlertDialog` whose only action is "Đóng".

**Deterministic scan (native checks, this surface):** `Colors.*` via `levelColor` / `levelIcon`, 5 lines
(`status_banner.dart:7-11`) · `Color(0x`: 0 · literal `fontSize:`: 0 · `IconButton`: none (the app bar uses a
`TextButton.icon` "Đọc hết") · hit targets: fine (the 10 dp unread dot is not a target) · long lists:
`ListView.separated` (`alerts_screen.dart:137`), which is right · emoji as UI icons: none authored, but the server emoji
in titles and bodies render beside the level icon (`alert_tile.dart:25-35`). The badge is M3's default `error` red
(`home_shell.dart:113-122`); the scan cannot see that.

## Overall Impression

The plumbing is right: unread state, mark-all, the push deep links and badge refresh all work. The presentation is a
transcript. The biggest opportunity is to make each alert a short row (level disc, a title without the emoji, two lines
of message, an ICT time) that opens a bottom sheet with the contextual next step ("Phân loại giao dịch", "Xem mục tiêu").

## What's Working

- **Read state is visible and correct:** a bold title with a dot that carries the semantics "Chưa đọc"
  (`alert_tile.dart:38-45`); "Đọc hết" is disabled when nothing is unread and reports a count ("Đã đánh dấu 5 cảnh
  báo là đã đọc", `alerts_screen.dart:101-116`).
- **The full message is selectable** (`SelectableText`) in the detail view, which is useful for copying amounts.
- **Push deep links** open the transaction sheet directly when the alert has a `transaction_id`
  (`push_navigator.dart:48-69`).

## Priority Issues

1. **[P1] Rows are Telegram dumps, and the time is cut off.**
   *Why:* the subtitle is `message + '\n' + time` with `maxLines: 4` (`alert_tile.dart:31-35`). Server messages are four or
   more lines, so the time is truncated away on three of the four rows in `B/alerts-390x844-light.png`, and only "Thử
   thông báo" shows "09:25 02/10". Titles start with server emoji (⚠️ ☀️ 💸 🔔) next to the level icon.
   *Fix:* the alert row from DESIGN.md › Alert row: a 40 dp level disc, the title in `titleMedium` (700 unread, 500 read)
   with a leading emoji stripped on the client (the disc carries the level), the message in `bodyMedium` capped at 2
   lines, the time "14:32" as its own `bodySmall` line, and the 8 dp `primary` unread dot.
   *Command:* /impeccable distill.
2. **[P1] Meaning by colour, wrong colour, low contrast.**
   *Why:* `levelColor` maps OK to green, so a spending notice ("💸 Chi 200.000đ") and the digest get a green success
   check, and INFO to teal (`status_banner.dart:6-20`). The WARNING icon in `Colors.orange.shade800` is 2.93:1 on the
   light surface, under the 3:1 non-text minimum (pixel-sampled, `B/alerts-390x844-light.png`). The badge is
   `error` red (`home_shell.dart:113-122`), against The Calm Badge Rule.
   *Fix:* `StatusColors.<level>.container` discs with `foreground` icons; INFO in `secondaryContainer` with a kind icon
   (`summarize_outlined`, `account_balance_outlined`, `sync_problem`); `badgeTheme` set to `primary` / `onPrimary`.
   *Command:* /impeccable colorize.
3. **[P1] A dead-end dialog instead of a detail sheet.**
   *Why:* tap → `AlertDialog` with "Đóng" only (`alerts_screen.dart:80-98`; the same dialog for push,
   `push_navigator.dart:88-107`). The owner reads "Danh mục: (chưa phân loại)" and then has to find the transaction in
   another tab. Opening also awaits `markAlertRead` before showing anything (`alerts_screen.dart:68-78`), so a slow
   server delays the tap.
   *Fix:* a modal bottom sheet: level disc and title in `headlineSmall`, the time "14:32, Thứ Ba 14/10/2026", the message
   as `SelectableText` `bodyLarge`, and one contextual filled button ("Phân loại giao dịch" / "Xem giao dịch" /
   "Xem mục tiêu"); mark read optimistically. Keep `Key('push_alert_dialog')` on the sheet or update `push_test.dart`.
   *Command:* /impeccable shape.
4. **[P1] The foreground push SnackBar dumps the whole body.**
   *Why:* `[title, body].join('\n')` for 8 s in a fixed SnackBar (`push_navigator.dart:33-44`): 11 lines over the
   dashboard in `B/dashboard-after-atm-390x844-light.png`.
   *Fix:* floating; the title plus one short line (the first body line, ellipsized to one line); the action "Xem";
   6 s; keep `Key('push_snackbar')`.
   *Command:* /impeccable clarify.
5. **[P2] Two clocks on one row.**
   *Why:* the row time uses `formatShortDateTime`, which calls `toLocal()` (`alert_tile.dart:19`; `utils/dates.dart:48`),
   while the server text inside the row is always ICT. In Europe/London, "Thử thông báo" shows "03:25 02/10" and the
   "Chi 200.000đ" body still says "20:45 14/10" (`X/alerts-390-london.png`).
   *Fix:* ICT everywhere via `lib/utils/dates.dart`; group by ICT day.
   *Command:* /impeccable harden.

## Further Issues (ranked)

6. **[P2] No day groups;** full-width dividers between rows (`alerts_screen.dart:137-142`). The brief wants "Hôm nay",
   "Hôm qua", "Thứ Hai, 12/10" list groups with inset dividers.
7. **[P2] No "Chưa đọc" filter.** It is optional in the brief; it maps to the existing `listAlerts(unread: true)`.
8. **[P3] Loading and empty states.** A bare spinner (`:122-123`); the empty text gives no explanation. The brief:
   "Chưa có cảnh báo nào." + "Khi số dư xuống gần mức cần giữ, app sẽ báo ở đây và qua Telegram."
9. **[P3] The `dense` variant on Tổng quan** ("Cảnh báo gần đây", `X/dash-scroll3-390-light.png`) truncates to 2 lines with
   no time; it goes away with that section.
10. **[P3] Unread dot is 10 dp** (`alert_tile.dart:41-42`); DESIGN.md says 8 dp.

## Persona Red Flags

- **Casey (opened from a push):** taps "Xem", reads a dialog that repeats the Telegram text, closes it, and has to
  navigate to Giao dịch to categorise. That is three screens for one job.
- **Sam (TalkBack):** each row is announced as one long button label, emoji names included ("biển cảnh báo", "mặt
  trời"); the level is conveyed by icon colour plus emoji only.
- **Riley:** a six-line server message pushes the time out of every row; changing the phone's time zone shifts row times
  against the message text.

## Minor Observations

- "Đọc hết" with `done_all` in the app bar is right; keep it.
- The detail dialog title is the raw server title with its emoji; strip the emoji in the sheet title too.
- The INFO icon is filled `Icons.info` in teal; DESIGN.md wants the outlined kind icons on a `secondaryContainer` disc.

## Questions to Consider

- Should the in-app history store or show a shorter server `title`/`message` pair, rather than the Telegram body? (That
  needs a backend change, which is out of scope; client-side trimming is the cheap path.)
- With a primary-coloured badge, push and "Đọc hết", are filter chips needed at all?

## What Must Change to Meet DESIGN.md

- [ ] Alert rows: `StatusColors` level disc, emoji-free title, 2-line message, separate ICT time, 8 dp `primary` dot with
  semantics "Chưa đọc".
- [ ] Day groups in list groups; skeleton rows; worded empty states.
- [ ] A detail bottom sheet with a contextual filled action, shared by the tab and push (`push_alert_dialog` key kept or
  the tests updated); optimistic mark-read.
- [ ] Floating push SnackBar: title and one line, "Xem", 6 s.
- [ ] `badgeTheme` set to `primary` / `onPrimary`, "99+" cap.

Trend: first run for this target, so there is no trend yet. The snapshot lives in this file.

Questions skipped: non-interactive workflow subagent with no question tool; the owner's decisions came with the task
(5 priority issues listed).
