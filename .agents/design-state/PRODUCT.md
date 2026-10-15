# Product

<!-- impeccable:product-schema 1 -->

Source of truth: the owner's own words, relayed in Vietnamese through the orchestrating session, plus the repository
(`README.md`, `docs/api.md`, `mobile/lib`, `backend/`). Items marked **(inferred)** were not stated by the owner and
should be confirmed; no live interview was possible in this run.

## Platform

android

(Android-first Flutter app, Material 3; iOS is planned later. The browser demo `mobile/lib/main_demo.dart` renders the
same Flutter UI on the web as a preview surface, not a separate web design.)

## Users

- **One person: the owner.** A single account holder in Vietnam with accounts at **Vietcombank (VCB)** and **MB Bank (MB)**,
  plus cash. There are no other user roles, no sharing, no family mode.
- **Situation:** checks the app right after paying for something, or right after a push / Telegram alert says the balance
  moved; also reads an 08:00 daily digest. Often outdoors in daylight, holding the phone in one hand.
- **Job:** "Can I still spend, and how much, without eating into the money I promised to this month's goals?" and, a few
  times a week, "put these new transactions in the right category quickly."
- **Literacy (inferred):** comfortable with banking apps and with self-hosting a server (they run Docker, Cloudflare Tunnel,
  a Telegram bot), so technical setup copy can be precise; everyday screens should still read in plain Vietnamese.

## Product Purpose

"Chi tiêu" is a personal spending guard. Every balance change at VCB/MB arrives automatically (SePay and Casso webhooks,
bank notification emails over IMAP), is de-duplicated across sources, and is compared with the goals the owner set for
the month in advance. The app and Telegram then say, proactively, whether the owner is still safe to spend.

Owner's own example (October): reserve **3.000.000đ** for rent ("Tiền trọ", type *Quỹ giữ* / `reserve`) and a
**5.000.000đ** food budget ("Tiền ăn", type *Ngân sách chi tiêu* / `budget`); warn when the balance gets close to what
the goals still need.

Success means: the owner is never surprised at month end, gets warned early enough to change behaviour, and is not
nagged when nothing is wrong.

## Positioning

A generic budgeting app tracks what was spent. Chi tiêu protects what must **not** be spent: it turns this month's goals
into a live **floor** under the real bank balance and answers one number, **"được tiêu"** (free to spend) = balance − floor,
from real bank events within seconds of each payment. The pairing of automatic VCB/MB ingestion with goal-floor
arithmetic and Telegram nudges is the mechanism a neighbouring app could not truthfully claim.

## Operating Context

- **Model (confirmed, see README and `docs/api.md`):**
  - floor (*mức sàn*) = Σ remaining needed per goal of the month;
  - free (*được tiêu thoải mái*) = Σ balances of counted accounts − floor;
  - buffer (*vùng đệm*) = max(10% × floor, 500.000đ), editable in settings;
  - levels: **OK** *An toàn* (free ≥ buffer), **WARNING** *Sắp chạm mức mục tiêu* (0 ≤ free < buffer),
    **DANGER** *Đã lấn vào tiền dành cho mục tiêu* (free < 0), **UNKNOWN** *Chưa biết số dư* (no balance yet);
    an extra **INFO** level exists for digest / account / health messages;
  - budget alerts at 80% and 100% of a budget goal;
  - month-end forecast: pace of non-goal spending (14 days, capped outliers), safe daily spend
    (*nên chi tối đa ~120.000đ/ngày*), projected free at month end, floor-hit date; early warning when the floor
    would be hit within 7 days.
- **Rituals:** an alert per balance change (only when the state worsens, with hysteresis); the 08:00 digest;
  categorising new transactions (Telegram inline buttons or the app's categorise sheet); goals created ahead for next
  month; recurring goals regenerated at 00:05 on day 1.
- **Edge cases already handled by the backend:** VCB ↔ MB own transfers are paired and not counted as spending;
  rent paid early can be counted for next month (*Tính cho tháng sau*); expected salary turns an early-month shortfall
  into *đang chờ lương* instead of a daily red alert; balances can be derived (*ước tính*) between bank snapshots;
  email-only events wait for webhook matching (*đang chờ khớp*); possible duplicates are flagged.
- **Channels:** Telegram (primary, always on), in-app alert history, optional Android push via FCM with a
  "Gửi thử" (send test) control.
- **Physical scene:** daylight, outdoors, one-handed, a glance of a few seconds after paying; sometimes evening in bed
  (dark mode). **(inferred from the owner's description)**

## Capabilities and Constraints

- **Surfaces:** Tổng quan (dashboard: status, free-to-spend, forecast, goals, accounts), Thêm/Sửa mục tiêu (goal form;
  **"Thêm mục tiêu" is the primary action of the product**), Giao dịch (list, categorise sheet, manual entry), Cảnh báo
  (alert history), Cài đặt (server connection, accounts, buffer, expected salary, Telegram per-transaction toggle, push
  notifications with "Gửi thử"), Kết nối máy chủ (first run: URL + APP_TOKEN, checks `/health` then `/api/summary`),
  plus a browser-demo banner **"Bản dùng thử · dữ liệu giả"**.
- **Stack:** Flutter 3.47, Material 3 (`useMaterial3`), Android-first, light and dark themes, Provider state,
  REST client to a self-hosted FastAPI + SQLite backend. Auto refresh every 30 s while open.
- **Language:** Vietnamese UI only (`vi_VN`), no English strings in the app.
- **Money:** integer VND; always written exactly with dot thousands separators and a trailing "đ" (`6.500.000đ`);
  signed amounts use "−" (U+2212) / "+" (`formatSignedVnd`). Month strings are `YYYY-MM` in Vietnam time.
- **Terminology (binding, from code and docs):** *mục tiêu*, *Quỹ giữ*, *Ngân sách chi tiêu*, *mức sàn*,
  *được tiêu thoải mái*, *vùng đệm*, *chưa phân loại*, *chuyển nội bộ*, *tính cho tháng sau*, *loại trừ*,
  *nhập tay*, *lương dự kiến*, *đang chờ lương*, *dự báo cuối tháng*.
- **Constraints:** single user; token stored with `shared_preferences` (planned move to `flutter_secure_storage`);
  push only when `google-services.json` is present; no network calls from the web demo at runtime; financial data and
  screenshots must never be sent to external services.
- **Undecided:** iOS delivery date; whether the app should ever show more than one month back on the dashboard;
  tablet support beyond a sensible adaptive layout **(inferred as low priority)**.

## Brand Commitments

- **Name:** "Chi tiêu". No logo or icon asset exists yet; the launcher icon and the Android 12+ splash icon are pending
  assets (no release should ship Flutter's default icon).
- **Direction chosen by the owner (binding):** *"Điềm tĩnh, tin cậy"* (calm, trustworthy: muted palette, generous
  breathing room, warnings clear but never alarming or shaming) **combined with** *"Hiện đại, đậm nét"* (modern, bold:
  large bold numerals, high contrast, one strong accent; like a new digital bank).
- **Voice (inferred from the direction and current copy):** calm, factual, short; states the number and the next step;
  never scolds ("tiêu hoang", "vung tay" are out), no exclamation marks, no app-authored emoji. Telegram copy is
  backend-owned and out of scope here.
- **Brand face proposal (owner-approved direction, delivery pending):** Be Vietnam Pro (OFL), bundled as an app asset.
- **Third-party marks:** Vietcombank and MB Bank are real organisations; the app names them in text only and never
  borrows their logos or brand colours.

## Evidence on Hand

- Real product logic and copy: `README.md`, `docs/api.md`, `mobile/lib/**` (current UI, teal seed theme),
  `backend/scripts/demo_seed.py` (demo scenario: TK 10tr, trọ 3tr, ăn 5tr đã chi 2tr → OK; ATM 3,5tr → WARNING).
- Widget tests with stable `Key`s in `mobile/test/` (dashboard, forecast, screens, push).
- **Absent, must not be fabricated:** real screenshots, real statements or emails in the repo (they must stay in temp
  folders and be anonymised before any commit), testimonials, usage metrics, a logo, an app icon.

## Product Principles

1. **One number first.** Every visit answers "được tiêu bao nhiêu?" before anything else; everything else explains or
   acts on that number.
2. **Calm until it matters.** Normal states stay quiet; a worsening state is unmistakable but never punitive.
   Spending money is not an error.
3. **Exact, not approximate.** Money is shown to the đồng, with its freshness ("cập nhật lúc …") and its source of
   uncertainty (*ước tính*, *đang chờ khớp*) stated plainly.
4. **Goals are the control.** Setting or adjusting a goal ("Thêm mục tiêu") is always one tap away; the rest of the app
   feeds the goals.
5. **Fast hands, short sessions.** Categorising and checking are one-handed, few-tap tasks that fit between other things.

## Accessibility & Inclusion

- WCAG 2.2 AA contrast in both themes (body ≥ 4.5:1, large text and non-text UI ≥ 3:1); the hero numeral should clear
  7:1 for outdoor daylight reading **(inferred target)**.
- State is never carried by colour alone: every level has its own icon and Vietnamese label, and the dashboard's
  status glazes differ in lightness as well as hue, so they stay apart for red-green colour-blind eyes (checked by
  simulation, see DESIGN.md › Appendix: Contrast verification).
- Touch targets ≥ 48 × 48 dp with ≥ 8 dp spacing; primary actions reachable with one thumb.
- Text follows the Android font-size setting (sp units) up to 200% without clipping Vietnamese stacked diacritics.
- TalkBack: money is announced as a number plus "đồng", status changes are announced as a live region.
- Honour "Remove animations" (`MediaQuery.disableAnimations`).
