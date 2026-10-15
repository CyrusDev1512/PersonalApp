# Critique (before redesign): Kết nối máy chủ (connect / first run)

**DEGRADED: single-context** (impeccable `critique` run by hand inside one workflow subagent: no sub-agent tool is
exposed, and the engine/detector is out of bounds under the Runtime boundary. Native source checks replace Assessment B
and were run after the design review.)

- **Target:** `mobile/lib/screens/connect_screen.dart` (first run via `RootGate` in `main.dart:159-185`, and `/connect`
  from Cài đặt with `popOnSuccess`). Line numbers refer to HEAD `10ba63c` (the before state; the working tree is being redesigned in parallel; at HEAD the file had not changed since 2026-10-14).
- **Evidence:** this screen is **not in the before set** (the harness starts connected).
  - `V/` = `/tmp/claude-0/-home-user-PersonalApp/1acd5986-5399-596c-aaaf-115f6ff877b8/scratchpad/demo_web/verify_shots/`
    : `dbg_390-light_33_after_disconnect.png` and `dbg_390-light_01_connect.png`, from an earlier **debug** Flutter web
    build (07:18, same `connect_screen.dart`), in Chromium, not a device or emulator.
  - The progress, failure and http:// states are reviewed from code only.

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Step text "Đang kiểm tra máy chủ (/health)…" then the token check; busy spinner in the button. The failed step is not marked |
| 2 | Match System / Real World | 3 | Precise technical copy that fits a self-hosting owner (APP_TOKEN, .env, Cloudflare Tunnel) |
| 3 | User Control and Freedom | 3 | Back from Cài đặt; fields stay filled after a failure |
| 4 | Consistency and Standards | 2 | First run looks like a sub-page (an app bar with no back); an amber bordered box; a red error box; dense fields |
| 5 | Error Prevention | 3 | URL normalised and validated; http:// warned; token obscured |
| 6 | Recognition Rather Than Recall | 3 | Example URL in the hint; the token's location named |
| 7 | Flexibility and Efficiency | 2 | Keyboard submit on the token; no paste affordance for a long token |
| 8 | Aesthetic and Minimalist Design | 3 | Short and focused; lacks identity rather than having clutter |
| 9 | Error Recovery | 3 | 401, 404 and network failures are explained with the fix, but in a box detached from the step that failed |
| 10 | Help and Documentation | 3 | The instruction sentence names APP_TOKEN in .env |
| **Total** | | **28/40** | **Good** |

## Design Specificity Verdict

**LLM assessment:** functional but anonymous. The very first screen of the product is a default `AppBar("Kết nối máy
chủ")` above a paragraph and two fields (`V/dbg_390-light_33_after_disconnect.png`). Nothing names "Chi tiêu" or says
what it does, so the product's first impression is a server form. The copy itself is the strongest on any screen:
specific, honest and actionable.

**Deterministic scan (native checks, this surface):** `Colors.*`: **3** (`connect_screen.dart:155, 157, 162`, amber
box and icon) · `Color(0x`: 0 · literal `fontSize:`: 0 · `IconButton` without tooltip: 0 (the visibility toggle has
"Hiện token" / "Ẩn token", `:186-190`) · hit targets: fine · `ListView(` at `:127` is a short form (fine) · emoji: none.
`RootGate` shows a bare full-screen spinner while initialising (`main.dart:179-181`).

## Overall Impression

It is the best-behaved screen in the app and needs presentation, not logic. The biggest opportunity: a wordmark header
on first run, and a two-step checklist that shows where a connection failed.

## What's Working

- **Errors name the cause and the fix:** "Sai token: máy chủ từ chối (401). Kiểm tra lại APP_TOKEN trong file .env của
  máy chủ." and "Địa chỉ này không phải máy chủ Chi tiêu (không có /health). Kiểm tra lại URL." (`:58-67`).
- **A safe ordering:** `/health` first, then `/api/summary` with the token; the token is obscured by default and never
  echoed into the URL.
- **Keyboard flow:** URL keyboard type, autocorrect off, submit from the token field (`:140-141, 193`).

## Priority Issues

1. **[P2] No identity on first run.**
   *Why:* the generic app bar (`:123`) with no back arrow makes the first screen read like a settings sub-page
   (`V/dbg_390-light_33_after_disconnect.png`).
   *Fix:* on first run, no app bar; a header with the wordmark "Chi tiêu" in `displaySmall` 700 `primary` and one
   `bodyLarge` line "Theo dõi số dư Vietcombank, MB và giữ tiền cho mục tiêu tháng này."; from Cài đặt, a small app
   bar with Back.
   *Command:* /impeccable shape.
2. **[P2] The failure is not tied to its step.**
   *Why:* progress is a single transient line (`_step`, `:204`), and on failure it disappears and an `errorContainer`
   box appears under the button (`:205-215`). The owner cannot see whether the server or the token failed.
   *Fix:* a two-row checklist, "Máy chủ phản hồi (/health)" and "Token hợp lệ (/api/summary)", each pending
   (`radio_button_unchecked`), running (18 dp progress), done (`check_circle` in `ok.foreground`) or failed (`error`);
   one inline error line (icon plus `bodyMedium`) under the failed step, no tinted box.
   *Command:* /impeccable clarify.
3. **[P2] The http:// warning is an amber bordered box.**
   *Why:* `Colors.amber` fill with an amber border (`:152-172`). DESIGN.md forbids container borders and hard-coded
   colours.
   *Fix:* an inline note: `lock_open` in `StatusColors.warning.foreground` plus `bodySmall` "Địa chỉ http:// không mã
   hoá: token sẽ được gửi dạng rõ qua mạng. Chỉ dùng trong mạng LAN tin cậy."
   *Command:* /impeccable colorize.

## Further Issues (ranked)

4. **[P3] Fields are dense** (`main.dart:33`, about 48 dp) where DESIGN.md asks for 56 dp outlined fields. The
   "https://… qua Cloudflare Tunnel" advice sits in the paragraph instead of the URL field's helper.
5. **[P3] No "Dán" (paste) suffix** for the long token (open, inferred in the brief; a cheap client-only change).
6. **[P3] `RootGate` spinner** on cold start (`main.dart:179-181`): use a static `surface` screen or the splash.
7. **[P3] Success from Cài đặt** shows "Đã kết nối lại máy chủ" (`settings_screen.dart:148`); the brief says "Đã kết nối
   máy chủ". This is wording only.

## Persona Red Flags

- **Jordan-like first run (the owner on a fresh install):** the first thing seen is "Kết nối máy chủ" with no product
  name; a failure shows one red paragraph without saying which half failed.
- **Sam (TalkBack):** the step line changes text without a live region, so the progress is not announced.

## Minor Observations

- The submit button keeps its label "Kiểm tra & kết nối" and swaps the icon for a spinner while busy: correct per
  DESIGN.md.
- The prefix icons `dns_outlined` / `key_outlined` are consistent with Cài đặt.

## Questions to Consider

- Should the first-run header also say where to find APP_TOKEN, or is the instruction sentence enough?

## What Must Change to Meet DESIGN.md

- [ ] A wordmark header on first run; a small app bar from Cài đặt.
- [ ] A two-step checklist with state icons and one inline error under the failed step; a live region for the step
  changes.
- [ ] An inline http:// note in `StatusColors.warning`; no tinted or bordered boxes; outlined 56 dp fields.
- [ ] Keep the keys `connect_url`, `connect_token`, `connect_submit` and the existing error copy.

Trend: first run for this target, so there is no trend yet. The snapshot lives in this file.

Questions skipped: non-interactive workflow subagent with no question tool; only 3 priority issues listed, and the
owner's decisions came with the task.
