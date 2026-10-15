# Critique (before redesign): Cài đặt (settings)

**DEGRADED: single-context** (impeccable `critique` run by hand inside one workflow subagent: no sub-agent tool is
exposed, and the engine/detector is out of bounds under the Runtime boundary. Native source checks replace Assessment B
and were run after the design review.)

- **Target:** `mobile/lib/screens/settings_screen.dart` (account rows open `widgets/account_dialog.dart`, critiqued
  under `account-sheet`). Line numbers refer to HEAD `10ba63c` (the before state; the working tree is being redesigned in parallel; at HEAD the file had not changed since 2026-10-14).
- **Evidence:** Flutter **web demo** in Chromium via Playwright, not a device or emulator.
  - `B/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/demo_web/before/`
    (`settings-390x844-light.png`, `-dark`, `settings-1280x800-light.png`, `-dark`; first viewport only).
  - `V/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/demo_web/verify_shots/`
    (an earlier **debug** web build from 07:18 with the same `settings_screen.dart`; emoji fonts not yet bundled):
    `dbg_390-light_29_settings_scroll3.png` shows the lower half (salary, Telegram switch, push).

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | `LinearProgressIndicator`s between headings; the Telegram switch looks applied but is not saved |
| 2 | Match System / Real World | 2 | The buffer is explained as a formula, "vùng đệm = max(% × mức sàn, số tiền tối thiểu)" |
| 3 | User Control and Freedom | 3 | Disconnect asks first; "Đổi máy chủ / token" returns with a SnackBar |
| 4 | Consistency and Standards | 2 | Server first; cards under headers; an emoji avatar next to text avatars; a chevron or a badge as the trailing item |
| 5 | Error Prevention | 2 | Leaving after toggling the switch loses the change silently; destructive confirms use the primary fill |
| 6 | Recognition Rather Than Recall | 3 | Current values prefilled; token masked with its last four characters |
| 7 | Flexibility and Efficiency | 2 | Pull-to-refresh; nothing else |
| 8 | Aesthetic and Minimalist Design | 2 | "Lương dự kiến" nested inside the "Cảnh báo" card; buttons flush to the card edge |
| 9 | Error Recovery | 3 | Specific validation ("Chỉ từ 0 đến 100", "Ngày 1–31"); a load error offers "Thử lại" |
| 10 | Help and Documentation | 3 | Push-state help sentences; the salary explanation |
| **Total** | | **24/40** | **Acceptable** |

## Design Specificity Verdict

**LLM assessment:** a default preferences page: section headers over elevated cards, in the order the code was written
(server first). The setting with the most consequence for the product, the buffer that decides when the owner is warned,
is presented as a formula with two bare number fields. The owner never sees the resulting amount ("báo khi được tiêu
dưới 600.000đ") here, although Tổng quan shows it.

**Deterministic scan (native checks, this surface):** `Colors.*`: 4 lines (`settings_screen.dart:207, 280, 467, 469`;
amber and green) · `Color(0x`: 0 · literal `fontSize:`: 0 · `IconButton`: none · hit targets: fine · `ListView(` at
`:192` holds a short, fixed set of sections (fine) · emoji as UI icon: **1**, the "💵" cash avatar (`:267`). The scan
finds the emoji and the colours; the save-model problem is only visible in the code.

## Overall Impression

Everything settable is here and validated, but the screen is organised for the developer (server, accounts, form, push),
not for the owner's rare, deliberate visits (accounts, the warning rule, salary, notifications, then the server). The
biggest opportunity: lead with the accounts as shared account rows, and turn the buffer into a sentence with the live
amount.

## What's Working

- **Validation and state handling are thorough:** per-field messages, salary day validated only when an amount is set
  (`:373-379`), the busy label "Đang lưu…", and quiet account reloads when the tab returns (`:46-56, 87-97`).
- **Push status is honest:** distinct states with a help sentence each and "Thử lại" where a retry helps
  (`:436-449, 475-487`).
- **The token is masked** ("••••••••a1b2") and the http:// warning appears only when it applies (`:205-210`).

## Priority Issues

1. **[P1] The order serves the developer, not the owner.**
   *Why:* "Máy chủ" is first and takes most of the first viewport, the accounts second, and "Lương dự kiến" is a sub-block
   inside the "Cảnh báo" card (`:196-243, 337-383`; `B/settings-390x844-light.png`).
   *Fix:* Tài khoản → Cảnh báo → Lương dự kiến → Thông báo đẩy → Máy chủ, each a flat list group with a `titleLarge`
   heading, 32 dp between sections.
   *Command:* /impeccable layout.
2. **[P1] The Telegram switch is silently part of "Lưu cài đặt".**
   *Why:* toggling "Báo Telegram mỗi giao dịch" only changes local state (`:385-391`); it is sent with the number fields
   when "Lưu cài đặt" is pressed (`:120`). If the owner toggles it and leaves, the change is lost with no hint. Android
   preferences apply switches at once.
   *Fix:* `PUT /api/settings {"notify_every_tx": …}` (the endpoint takes a subset; no backend change), the switch
   disabled during the call, a SnackBar "Đã bật / Đã tắt báo Telegram mỗi giao dịch", and a revert with the API message on
   failure. "Lưu cài đặt" stays for the number fields only, enabled when they changed.
   *Command:* /impeccable harden.
3. **[P1] Destructive actions look like ordinary ones.**
   *Why:* "Ngắt kết nối" is a `primary` text button (`:220`; teal in `B/settings-390x844-light.png`) and its confirm is a
   primary `FilledButton` (`:161`), while the third earned use of red (destructive confirmation) goes unused.
   *Fix:* an `error` text button that opens the dialog; the dialog's confirm a filled `error` "Ngắt kết nối"; body copy
   kept ("App sẽ quên địa chỉ máy chủ và token trên máy này. Dữ liệu trên máy chủ không bị xoá.").
   *Command:* /impeccable colorize.
4. **[P2] Account rows are not the shared account row.**
   *Why:* `CircleAvatar` with the default `primaryContainer` (bright teal discs "VCB", "MB"), a "💵" emoji for cash
   (`:267`), the balance buried in the subtitle string ("Vietcombank · 5.920.000đ", `:269-277`), a chevron or an amber
   "Chưa xác nhận" badge as the trailing item (`:278-280`), and "Thêm tài khoản" as a header action (`:229-236`).
   *Fix:* DESIGN.md › Account row: a neutral 40 dp disc with the bank short name or `payments_outlined`, the title
   "Vietcombank ··1234", the meta "cập nhật 14:32" (+ "ước tính", "không tính vào tổng"), a trailing `moneyList`
   balance, a warning-container pill under the meta, no chevron; "Thêm tài khoản" as the group's last row.
   *Command:* /impeccable distill.
5. **[P2] The buffer is a formula.**
   *Why:* "Cảnh báo khi phần "Được tiêu thoải mái" nhỏ hơn vùng đệm = max(% × mức sàn, số tiền tối thiểu)." (`:300`).
   *Fix:* a live sentence: "Đang báo khi được tiêu dưới 600.000đ (số lớn hơn giữa 10% mức sàn và 500.000đ).",
   recomputed as the fields change (floor from the cached summary); the two fields side by side at ≥ 400 dp.
   *Command:* /impeccable clarify.

## Further Issues (ranked)

6. **[P2] Loading and errors.** Bare `LinearProgressIndicator`s between headings (`:251, 289`); a load error renders a
   full-page `ErrorView` inside the list (`:228`). The brief: skeleton rows per group; an inline "Không tải được cài
   đặt." + "Thử lại" in the affected group.
7. **[P2] Buttons are flush to the card edge.** The `OverflowBar`s have no end padding (`:216-223, 475-487`): "Đổi máy
   chủ / token" touches the card's right edge (`B/settings-390x844-light.png`), and so does "Gửi thử"
   (`V/dbg_390-light_29_settings_scroll3.png`).
8. **[P2] Hard-coded status colours.** The http warning icon and the "Chưa xác nhận" badge use `Colors.amber.shade800`
   (`:207, 280`); the push icon uses green or amber (`:466-470`). Use `StatusColors.ok/warning.foreground` and
   `onSurfaceVariant`.
9. **[P3] No licence or version row.** Be Vietnam Pro's OFL must ship somewhere; a "Giới thiệu" row with
   `showLicensePage` and the font licence registered through `LicenseRegistry` covers it (open, inferred).
10. **[P3] The save button has a `save_outlined` icon and sits inside the card;** it is enabled even when nothing changed.

## Persona Red Flags

- **Chủ tài khoản on a new phone (project persona):** scrolls past the server block to reach push; turns off "Báo Telegram
  mỗi giao dịch", goes back to Tổng quan, and keeps receiving every transaction on Telegram.
- **Sam (TalkBack):** the account rows read as one long string with the balance in the middle; the teal disc letters
  are read out as "V C B".
- **Riley:** enters 100% and 0đ; nothing shows the resulting warning amount before saving.

## Minor Observations

- "Token" shows "••••" for short tokens; fine.
- Push status uses filled-tonal "Gửi thử" with "Đang gửi…": matches the brief; keep it.
- The salary fields sit side by side (3:2) and work at 390 dp; check them at 200% text.

## Questions to Consider

- Should the buffer fields also autosave? (Not recommended in the brief: the buffer change has consequences.)
- Is "Máy chủ" needed as a section at all, or as one row "Máy chủ: demo.local" that opens Kết nối?

## What Must Change to Meet DESIGN.md

- [ ] Section order and flat list groups (no cards, no nested boxes), `titleLarge` headings, 32 dp section rhythm.
- [ ] Shared account rows (also on Tổng quan), "Thêm tài khoản" as the group's last row, no emoji.
- [ ] A live buffer sentence; switches that apply at once with a SnackBar; "Lưu cài đặt" for the number fields only.
- [ ] `error` styling for "Ngắt kết nối" and its confirm; `StatusColors` for the http and push icons.
- [ ] Skeletons and inline per-group errors; padded button bars; optional "Giới thiệu" / licences row.

Trend: first run for this target, so there is no trend yet. The snapshot lives in this file.

Questions skipped: non-interactive workflow subagent with no question tool; the owner's decisions came with the task
(5 priority issues listed).
