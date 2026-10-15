# Critique (after redesign): Kết nối máy chủ (connect / first run)

**DEGRADED: single-context** (impeccable `critique` done by hand in one verifier subagent. No sub-agent tool, and the
engine/detector is out of bounds. The AGENTS.md native source checks replace Assessment B.)

- **Target:** `mobile/lib/screens/connect_screen.dart`. Working tree on HEAD `c7fe25b`.
- **Evidence:** Flutter **web demo** in Chromium only. The connect screen appears only after "Ngắt kết nối", so the
  harness has no "before" shot of it.
  - `X/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/demo_web/after/extra/`
    (`connect-390-light.png`, `connect-390-dark.png`, idle state only).
  - The checking, failed-step, http:// and "from Cài đặt" states were reviewed in code only
    (`connect_screen.dart:138-267`).

## Design Health Score (before → after)

| # | Heuristic | Before | After | Key issue now |
|---|-----------|-------:|------:|---------------|
| 1 | Visibility of System Status | 3 | 4 | Two-step checklist with pending / running / done / failed per step, with spoken states (code) |
| 2 | Match System / Real World | 3 | 3 | Precise technical copy for a self-hoster |
| 3 | User Control and Freedom | 3 | 3 | Fields kept after failure; Back from Cài đặt |
| 4 | Consistency and Standards | 2 | 3 | Wordmark on first run, inline notes instead of tinted boxes, StatusColors |
| 5 | Error Prevention | 3 | 3 | URL validation, http:// note, obscured token |
| 6 | Recognition Rather Than Recall | 3 | 3 | Example URL; the token's location named |
| 7 | Flexibility and Efficiency | 2 | 2 | No paste button for a long token (open in the brief) |
| 8 | Aesthetic and Minimalist Design | 3 | 4 | Wordmark, one sentence, two fields, one button; nothing extra |
| 9 | Error Recovery | 3 | 3 | Failed step marked and an inline error with the fix. The error sits under the checklist, not at the step |
| 10 | Help and Documentation | 3 | 3 | Instruction sentence plus helper "Nên dùng https:// qua Cloudflare Tunnel" |
| **Total** | | **28/40** | **31/40** | **Good → Good** |

## Design Specificity Verdict

**Assessment (unanchored):** the first screen of the product finally says what it is. The cobalt "Chi tiêu" wordmark
in `displaySmall` (`connect_screen.dart:148`) and the line "Theo dõi số dư Vietcombank, MB và giữ tiền cho mục tiêu
tháng này." sit above a "Kết nối máy chủ" heading, two outlined fields with leading icons, and one full-width cobalt
"Kiểm tra & kết nối" (`X/connect-390-light.png`). Dark mode keeps the hierarchy (`X/connect-390-dark.png`). The amber
bordered box and the `errorContainer` box are gone in code (`InlineNote` at `:184`, `InlineError` at `:227`).

**Native source checks:** the token visibility `IconButton` has the tooltips "Hiện token" / "Ẩn token" (`:205-206`).
The warning icon uses `StatusColors.warning.foreground` (`:186`). There are no hard-coded colours. The `ListView(` at
`:142` is a short form.

## What improved

- First run has no app bar. A wordmark header replaces the "sub-page with no back".
- The single progress text became a two-step checklist (`_StepLine`, `:237-267`) whose rows are one semantics node
  each ("Máy chủ phản hồi (/health): lỗi").
- The http:// warning is an inline note, not a coloured container.

## Priority Issues (what still fails)

1. **[P3] The error is not at the step that failed.**
   - *Evidence:* `InlineError` is added after both steps (`connect_screen.dart:223-227`). On a `/health` failure the
     message sits below "Token hợp lệ (/api/summary)", the step that never ran.
   - *Rule:* the brief says "the cause is shown at the step where it failed".
   - *Fix:* render the message directly under the failed `_StepLine`, indented to the label.
2. **[P3] No paste affordance for the token.** This is still open in the brief: on a phone, a 32+ character APP_TOKEN
   from a password manager is the slowest part of setup.

## Persona Red Flags

- **Chủ tài khoản pairing a new phone:** the flow is clear, and the copy names `/health`, APP_TOKEN and `.env`
  precisely. The checking states were not observed in a screenshot run (code only).

## Minor Observations

- The heading "Kết nối máy chủ" (`titleLarge`) is not in the brief's first-run anatomy. It helps when the wordmark is
  the only other heading, so keep it.
- In the web demo the strip button reads "Kết nối lại bản dùng thử" here, a second way to reconnect beside the form.
  This is demo only.

Trend: before 28/40 → after 31/40.

Questions skipped: fewer than 3 priority issues listed (2).
