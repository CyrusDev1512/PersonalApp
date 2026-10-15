# Critique (after redesign): Cài đặt (settings)

**DEGRADED: single-context** (impeccable `critique` done by hand in one verifier subagent. No sub-agent tool, and the
engine/detector is out of bounds. The AGENTS.md native source checks replace Assessment B.)

- **Target:** `mobile/lib/screens/settings_screen.dart`, `widgets/account_row.dart`, `widgets/money_row.dart`,
  `widgets/form_parts.dart`. Working tree on HEAD `c7fe25b`.
- **Evidence:** Flutter **web demo** in Chromium only.
  - `B/` = `…/scratchpad/demo_web/before/`
  - `A/` = `…/scratchpad/demo_web/after/`
  - `X/` = `…/scratchpad/demo_web/after/extra/`
  - `V/` = `…/scratchpad/redesign_verify/critique/shots360/`
  - `…` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8`

## Design Health Score (before → after)

| # | Heuristic | Before | After | Key issue now |
|---|-----------|-------:|------:|---------------|
| 1 | Visibility of System Status | 2 | 3 | The Telegram switch saves at once with a snackbar and reverts on failure; "Lưu cài đặt" is enabled only on change |
| 2 | Match System / Real World | 2 | 3 | Live sentence "Đang báo khi được tiêu dưới 600.000đ (số lớn hơn giữa 10% mức sàn và 500.000đ)." |
| 3 | User Control and Freedom | 3 | 3 | Disconnect confirms with a red button |
| 4 | Consistency and Standards | 2 | 3 | Shared account rows and the brief's order. A percent and a day number use the money style |
| 5 | Error Prevention | 2 | 3 | The switch no longer looks saved when it is not; red destructive confirm |
| 6 | Recognition Rather Than Recall | 3 | 3 | Values prefilled; masked token |
| 7 | Flexibility and Efficiency | 2 | 2 | Unchanged |
| 8 | Aesthetic and Minimalist Design | 2 | 3 | Flat groups, no cards. But four display-size numerals, and account meta wraps |
| 9 | Error Recovery | 3 | 3 | Specific validation; inline load errors per group (code) |
| 10 | Help and Documentation | 3 | 3 | Push help, salary explanation, "Giới thiệu" with licences |
| **Total** | | **24/40** | **29/40** | **Acceptable → Good** |

## Design Specificity Verdict

**Assessment (unanchored):**
- **Order:** the screen follows the brief: Tài khoản → Cảnh báo → Lương dự kiến → Thông báo đẩy → Máy chủ → Giới
  thiệu (`A/settings-390x844-light.png`, `X/settings-bottom-390-light.png`).
- **Accounts:** they use the same row as Tổng quan ("VCB chính ··6789", neutral "VCB"/"MB" discs, no chevron), with
  "Thêm tài khoản" as the last row.
- **Buffer:** the formula became a sentence with the computed amount.
- **Red:** "Ngắt kết nối" is the only red text, and its dialog confirms with a filled `error` button
  (`X/disconnect-dialog-390-dark.png`).
- **Wide windows:** at 1280 the buffer fields sit side by side (`A/settings-1280x800-light.png`).

**Native source checks:** no hard-coded colours or font sizes (the StatusColors hits are false positives). The
`ListView(` at `settings_screen.dart:265` is a fixed-length preferences page (fine).

## What improved

- The server block moved last. The emoji avatar and the amber colour are gone. Cards under headers became list groups.
- The Telegram switch commits at once (`ApiClient.updateSettingsFields`, PUT subset) and is tested for revert
  (`test/redesign_test.dart:302`).
- "Lưu cài đặt" is the only filled button and stays disabled until a number changes (`X/settings-bottom-390-light.png`).

## Priority Issues (what still fails)

1. **[P2] Account rows wrap their meta and even their title on phones.**
   - *Evidence:* "Vietcombank · cập / nhật 17:38" and "MB Bank · cập nhật 08:40 / 12/10" wrap at 390
     (`A/settings-390x844-light.png`). At 360 the title splits too: "VCB chính / ··6789" (`V/settings-360x780-light.png`).
   - *Cause:* the shared `MoneyRow` puts the balance beside the whole text column (`money_row.dart:108-120`). The meta
     also adds the bank name, while DESIGN.md › Lists specifies "cập nhật 14:32" only.
   - *Fix:* the same layout fix as Giao dịch (meta under the amount, at full width). Alternatively, drop the bank name
     from the meta when the disc already shows "VCB"/"MB".
   - *Command:* /impeccable layout.
2. **[P3] Non-money numbers use the money input style.**
   - *Evidence:* "Vùng đệm theo % mức sàn" shows "10" and "Ngày nhận" shows "25" in `moneyInput` (28 sp/800). Settings
     shows four display-size numerals ("10", "500.000", "15.000.000", "25"; `A/settings-1280x800-light.png`). This is
     deliberate, to match field heights (`settings_screen.dart:508`).
   - *Why it matters:* DESIGN.md reserves the money styles for amounts. A day of the month in an 800 weight competes
     with the money on a quiet preferences screen.
   - *Fix:* keep the 64 dp height and use `bodyLarge` / `titleMedium` for the percent and day digits.
3. **[P3] The push status row's icon floats mid-row.**
   - *Evidence:* `notifications_active_outlined` sits at the vertical centre of a three-line row while its text starts
     at the top (`X/settings-bottom-390-light.png`). Money rows were fixed to top-align their leading disc
     (`money_row.dart:131-133`), but this `ListTile` (`settings_screen.dart:610-611`) was not.
   - *Fix:* `ListTile(titleAlignment: ListTileTitleAlignment.top)` for multi-line status rows.

## Persona Red Flags

- **Chủ tài khoản tuning the buffer:** the live sentence shows the consequence before saving. Good. The save button is
  two sections below the buffer fields, after the salary block. This is by design (one form), but it is far away on a
  phone.
- **Sam (TalkBack):** the switch tiles have subtitles; the token row is masked.

## Minor Observations

- The app-bar title "Cài đặt" and the first section heading "Tài khoản" are both `titleLarge` 22 sp/700, stacked about
  50 dp apart (`A/settings-390x844-light.png`). This is DESIGN-compliant but reads as a doubled heading.
- In edit mode the bank shows as a disabled outlined field, not as read-only text (see the account-sheet critique).
- The "Gửi thử" and "Đổi máy chủ / token" tonal buttons sit outside their groups, left-aligned. That is consistent,
  but the tonal 48 dp pill is heavier than the rows it acts on.

## Questions to Consider

- Should "Lưu cài đặt" sit directly under the buffer fields, with the salary block saved by its own button?

Trend: before 24/40 → after 29/40.

Questions skipped: non-interactive verifier subagent with no question tool (3 priority issues listed).
