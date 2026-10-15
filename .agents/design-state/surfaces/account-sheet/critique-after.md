# Critique (after redesign): Tài khoản và số dư (account sheet + balance sheet)

**DEGRADED: single-context** (impeccable `critique` done by hand in one verifier subagent. No sub-agent tool, and the
engine/detector is out of bounds. The AGENTS.md native source checks replace Assessment B.)

- **Target:** `mobile/lib/widgets/account_dialog.dart` (`showAccountForm`, `showBalanceDialog`),
  `widgets/account_row.dart`. Working tree on HEAD `c7fe25b`.
- **Evidence:** Flutter **web demo** in Chromium only. The harness has no "before" shots of these sheets; the before
  state is described in `critique-before.md`.
  - `X/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/demo_web/after/extra/`
    (`account-sheet-390-{light,dark}.png` in edit mode, `balance-sheet-390-{light,dark}.png`).
  - The add mode, the delete dialog, the 400 error and the unconfirmed-account switch were reviewed in code only.

## Design Health Score (before → after)

| # | Heuristic | Before | After | Key issue now |
|---|-----------|-------:|------:|---------------|
| 1 | Visibility of System Status | 2 | 3 | A snackbar after each save ("Đã cập nhật số dư VCB chính ··6789: …"). It is lost if the sheet closes mid-save (builder's note) |
| 2 | Match System / Real World | 3 | 3 | "Mở app ngân hàng và nhập đúng số dư hiện tại…" matches the moment |
| 3 | User Control and Freedom | 3 | 3 | Back or swipe closes; nothing is saved without the button |
| 4 | Consistency and Standards | 2 | 3 | Bottom sheets with sticky buttons, outlined fields, switches, named buttons. The bank shows as a disabled field |
| 5 | Error Prevention | 2 | 4 | The known balance is pre-selected, so typing replaces it. Delete asks with a red confirm |
| 6 | Recognition Rather Than Recall | 3 | 3 | "Số dư hiện tại: 9.420.000đ · cập nhật 20:45 14/10" above the field |
| 7 | Flexibility and Efficiency | 2 | 2 | No "Thêm tài khoản khác" after the first account (open in the brief) |
| 8 | Aesthetic and Minimalist Design | 3 | 3 | Clean sheet. In edit mode the title block repeats nothing, but the disabled bank field adds noise |
| 9 | Error Recovery | 2 | 3 | Errors show above the sticky button (code) |
| 10 | Help and Documentation | 3 | 3 | Helpers for account number and balance |
| **Total** | | **25/40** | **30/40** | **Acceptable → Good** |

## Design Specificity Verdict

**Assessment (unanchored):** the balance sheet is the best small surface in the app.
- **Layout:** the account is stated as a fact ("VCB chính ··6789", "Số dư hiện tại: **9.420.000đ** · cập nhật 20:45
  14/10"), then one instruction sentence. The 64 dp money field is focused with the old value selected (2 dp cobalt
  focus border, `moneyInput` digits), and "Lưu số dư" is the sticky button (`X/balance-sheet-390-light.png`).
- **Account sheet:** it is a proper M3 bottom sheet with switches and a red "Xoá tài khoản" text button
  (`X/account-sheet-390-light.png`).

**Native source checks:** no hard-coded colours or font sizes. The destructive styles come from `AppButtonStyles`
(`account_dialog.dart:171, 313`). The balance is pre-selected at `:383` and the field autofocuses at `:460`.

## What improved

- `AlertDialog` forms became bottom sheets with sticky primary buttons that name their action ("Lưu số dư", "Lưu tài
  khoản", "Thêm tài khoản").
- The checkbox became the switch "Đây là tài khoản của tôi". The delete confirm is filled `error`.
- Success snackbars for balance, add, edit and delete (`:36-42`, `:349-350`).
- Account names use the `displayName` form "VCB chính ··6789" everywhere.

## Priority Issues (what still fails)

1. **[P3] In edit mode the bank is a disabled field, not read-only text.**
   - *Evidence:* "Ngân hàng / MB Bank" renders as a greyed, outlined, disabled `InputDecoration(enabled: false)`
     (`account_dialog.dart:226`; `X/account-sheet-390-light.png`). The brief asks for read-only text, because the bank
     cannot change.
   - *Why it matters:* a disabled control reads as "temporarily unavailable" and takes a 56 dp field slot.
   - *Fix:* show "MB Bank" as `titleMedium` text with a `bodySmall` label, like the balance sheet's account fact.
2. **[P3] A result is lost when the sheet closes mid-save.** This is the builder's own gap. The brief wants the
   result as a snackbar on the screen underneath. Not observed in a shot.

## Persona Red Flags

- **Chủ tài khoản with the bank app in the other hand:** open → type over the selected value → "Lưu số dư". Three
  steps, and the keyboard does not hide the button (sticky bar). Good.
- **First run:** after the first account is added there is no shortcut to add the next one (MB, cash).

## Minor Observations

- In edit mode the "Số dư hiện tại" placeholder is "VD: 6.200.000" while the helper says "Hiện tại: 580.000đ"
  (`X/account-sheet-390-light.png`). The example number competes with the real one. Consider leaving the placeholder
  empty in edit mode.
- The gap between the last switch and "Xoá tài khoản" is about 24 dp, as specified. The red text button sits alone at
  the end. Good.

Trend: before 25/40 → after 30/40.

Questions skipped: fewer than 3 priority issues listed (2).
