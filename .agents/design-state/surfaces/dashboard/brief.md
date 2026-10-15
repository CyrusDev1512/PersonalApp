# Tổng quan (dashboard): shape brief

Target: `mobile/lib/screens/dashboard_screen.dart` (+ `widgets/status_banner.dart`, `forecast_card.dart`,
`goal_card.dart`, `alert_tile.dart`). Visitor mode: **operate**. Status: written from the owner's relayed direction and
the code; not confirmed in a live round. Items marked *(inferred)* need the owner's nod.

## Direction contract

- **THESIS:** One glazed object answers "được tiêu bao nhiêu?"; the page refuses the category default of a balance card
  plus a grid of equal metric tiles. The big number itself is earned, not a template reflex: the owner asked for "large
  bold numerals" and the product's first principle is "one number first". What the craft floor refuses (big number,
  small label, supporting stats, accent) is avoided by what surrounds it: a state heading instead of a kicker, a ruler
  that explains the number instead of stat tiles, and forecast facts written as sentences further down.
- **OWN-WORLD:** Bát men lam: porcelain ground, one cobalt glaze, Be Vietnam Pro 800 numerals, flat tonal groups, no
  borders, no shadows on content.
- **STORY:** The owner sees the state and the free amount, understands how close the floor is from the ruler, and either
  closes the app reassured or acts (categorise, adjust a goal, add a goal).
- **FIRST VIEWPORT (360 × 640 dp):** app bar "Tổng quan"; the status hero full width at the top (heading, 44 sp
  numeral, meaning line, floor ruler, legend); below it the first rows of "Cần bạn xem" or "Dự báo cuối tháng";
  extended FAB "Thêm mục tiêu" bottom-right above the navigation bar.
- **FORM:** Material 3 operate screen with one signature component (status hero + thước mức sàn). No concept roll was run
  (the impeccable engine is out of bounds in this project), so there is no seed key.
- **FINISH:** unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md
  re-run in scan mode, and every screenshot labelled with its source (device, emulator or Flutter web).

## Job and audience

The owner, one-handed, often outdoors, seconds after paying or after a push/Telegram alert, or at the 08:00 digest.
They need: am I OK, how much can I still spend, is anything waiting for me.

## The one primary action

**"Thêm mục tiêu"**: extended FAB, cobalt (`primary`), visible whenever the screen has data (hidden, never disabled,
only in the load-error-without-cache state), opens the goal form. Everything else on the
screen is secondary (row taps, inline buttons in "Cần bạn xem").

## Information order (top to bottom)

1. *(demo build only)* demo banner, see `../demo-banner/brief.md`.
2. Offline strip *(only when the last refresh failed but a cached summary exists)*.
3. **Status hero** (DESIGN.md › Components › Status hero): heading, numeral, meaning line, floor ruler, two-row
   legend, context lines (đang chuyển giữa các TK, lương dự kiến chưa về), freshness line. The server's `level_reason`
   is not printed here (it restates the heading and the numeral).
4. **Cần bạn xem** list group *(only rows that apply; hidden when empty)*:
   - "3 giao dịch chưa phân loại" → Giao dịch with the "Chưa phân loại" filter;
   - "Phát hiện TK mới MB ··5678. Tính vào tổng số dư?" with tonal "Tính vào tổng" + outlined "Không tính";
   - "Chưa biết số dư của: MB ··5678" + text button "Nhập số dư" (when the level is known but an account is missing);
   - ingest health: server warnings verbatim, icon `sync_problem` in `warning.foreground`, text `onSurface`.
5. **Dự báo cuối tháng** (forecast block).
6. **Mục tiêu tháng 10** (goal progress rows), then one collapsed row "Tháng 11 · 2 mục tiêu đã tạo trước" that expands
   to the next-month list.
7. **Tài khoản** *(new on this screen; the owner's surface list names accounts on Tổng quan)*: the shared account row
   (DESIGN.md › Lists and containers), the same component as in Cài đặt: "Vietcombank ··1234", meta "cập nhật 14:32"
   (+ "ước tính", "không tính vào tổng"), trailing `moneyList` balance or "chưa biết số dư". Tap opens the balance
   sheet (`../account-sheet/brief.md`). Cash shows `Icons.payments_outlined`.

Expanded (≥ 1200 dp, optional): left pane 400 dp = items 2-5, right pane = 6-7.

## States and ranges

| State | What shows |
|---|---|
| First load (no cache) | Static skeleton: hero block in `surfaceContainerHigh`, three row skeletons. No spinner, no shimmer. |
| Error, no cache | Centred: `cloud_off` icon, "Không tải được tổng quan", the API message, filled "Thử lại". FAB hidden (a disabled FAB looks enabled); it returns with the data. |
| Offline / error with cache | Neutral strip (`surfaceContainerHigh`, no red): "Đang offline, không kết nối được máy chủ" (network) or the API message / "Đang hiện số liệu tải lúc 14:32." + text "Thử lại"; hero freshness line "Đang offline · số liệu lúc 14:32". |
| Stale balance (> 48 h) | Hero freshness line "Số dư chưa cập nhật 2 ngày" with `schedule` icon; colours unchanged. |
| Derived balance | "ước tính" tag after "Số dư" in the legend and on the account row. |
| UNKNOWN, no accounts | Hero UNKNOWN: heading "Chưa biết số dư" (not repeated) / "Thêm tài khoản và nhập số dư hiện tại để app tính được phần được tiêu." / filled "Thêm tài khoản" (opens the account sheet in add mode). Forecast hidden. |
| UNKNOWN, accounts without balance | Hero UNKNOWN: "Nhập số dư hiện tại của Vietcombank ··1234 để app tính được phần được tiêu." / filled "Nhập số dư" (`enter_balance`, opens the balance sheet for the first missing account). |
| OK | Cobalt glaze; meaning "được tiêu thoải mái · còn 17 ngày"; ruler reserved + free segments, tick inside the free segment with its halo. |
| WARNING | Butter (light) / umber (dark) glaze; meaning "dưới vùng đệm 600.000đ · còn 17 ngày"; the free segment stops short of the tick. |
| DANGER | Iron-red glaze; numeral "−350.000đ"; meaning "thiếu cho mục tiêu · còn 17 ngày"; ruler: reserved [0, balance], outlined missing segment up to the floor, blank stretch, tick. |
| Waiting for salary (WARNING with `waiting_income`) | Meaning "đang chờ lương ngày 5 · lương về sẽ đủ"; ruler as DANGER (balance may be under the floor) but in the WARNING glaze. |
| No goals | Mục tiêu section: `flag_outlined` + "Chưa có mục tiêu tháng 10" + "Đặt mục tiêu để được báo khi số dư xuống gần mức cần giữ, vd. tiền trọ 3.000.000đ, tiền ăn 5.000.000đ." + text button "Tạo mục tiêu đầu tiên". Ruler shows one free segment and no tick. |
| Large text (> 125%) | Goal and account rows stack the amount under the meta (DESIGN.md › Layout); the hero legend rows wrap their amounts at 200%. |
| Forecast insufficient / unavailable | One muted line "Chưa đủ dữ liệu để dự báo cuối tháng." / hidden. |
| Status change while open | The one authored motion (DESIGN.md). Amount-only change: glaze, count and ruler, silently. Level change: also the heading swap and the live-region announcement. |

Ranges: `free` from about −20.000.000đ to 200.000.000đ (up to 12 glyphs, scale-down in the hero); 0-10 goals, names
up to 80 characters (2 lines max in rows); 1-5 accounts; 0-50 uncategorised.

## Copy (Vietnamese)

App bar "Tổng quan" · FAB "Thêm mục tiêu" · hero headings = `Level.label` ("An toàn", "Sắp chạm mức mục tiêu",
"Đã lấn vào tiền dành cho mục tiêu", "Chưa biết số dư") · meaning lines "được tiêu thoải mái · còn 17 ngày",
"dưới vùng đệm 600.000đ · còn 17 ngày", "đang chờ lương ngày 5 · lương về sẽ đủ", "thiếu cho mục tiêu · còn 17 ngày" ·
legend "Giữ cho mục tiêu" / "Số dư" + amounts · "ước tính" · "Cập nhật lúc 14:32" · "Lương dự kiến chưa về: 15.000.000đ
(ngày 5)" · "Cần bạn xem" · "Dự báo cuối tháng" · "Nên chi tối đa ~120.000đ mỗi ngày" · "Cuối tháng dự kiến còn
~2.400.000đ được tiêu" / "Cuối tháng dự kiến thiếu ~350.000đ cho mục tiêu" · "Ước tính sơ bộ" · "Mục tiêu tháng 10" ·
"còn phải giữ" / "còn được chi" · "Đã chi 2.000.000đ / 5.000.000đ · 40%" · "Vượt 350.000đ" · "Đã trả xong" ·
"Tài khoản" · "không tính vào tổng".

## Remove / merge compared with today

- Merge `_BalanceCard`, `StatusBanner` and the `_Metric` pair (Mức sàn / Được tiêu thoải mái) into the status hero; the
  floor and the balance become the ruler legend, the free amount becomes the hero numeral (today it is a 22 sp metric
  beside the floor while the total balance is the biggest number: the hierarchy is inverted).
- Merge `_UnknownBalanceCard` into the hero UNKNOWN state and the "Cần bạn xem" missing-balance row.
- Move `_NewAccountCard`, `_IngestHealthNote` and the uncategorised `ActionChip` into the single "Cần bạn xem" group
  (today they are three different visual treatments, two of them hard-coded amber boxes with borders).
- Remove "Cảnh báo gần đây" (the nav badge and the Cảnh báo tab cover it; push opens the alert directly).
- Remove the app-bar refresh `IconButton` (30 s auto refresh + pull-to-refresh + the freshness line remain).
- Remove the forecast card's coloured border; severity moves to the icon and headline colour. Its two numbers become
  two sentences (DESIGN.md › Forecast block), so the dashboard keeps one big number.
- Move "Còn N ngày trong tháng" into the meaning line and "Lương chờ nhận" into the hero context lines.
- Replace every `Colors.green/orange/red/amber/blueGrey` with `StatusColors`; replace `GoalCard` cards with rows in one
  list group; replace the "🎯" and emoji fallbacks with icons.

## Constraints and open decisions

- Keep widget `Key`s used by tests or update the tests deliberately: `total_balance` (legend "Số dư" amount),
  `balance_as_of` (freshness line), `offline_banner`, `enter_balance`, `uncategorized_chip` (the "Cần bạn xem" row),
  `ingest_health_note`, `forecast_card`, `forecast_headline`, `forecast_free_end`, `next_month_goals`.
- The status-change animation needs the last shown `level`/`free` kept in memory (and optionally `shared_preferences`
  for resume); never animate on first paint.
- **Open:** DANGER numeral shows the signed `free` ("−350.000đ") with the meaning line "thiếu cho mục tiêu · còn 17
  ngày"; the alternative is a positive shortfall ("350.000đ" + the same line). Recommended: signed, for consistency
  across states and with the ruler.
- **Decided:** accounts are on Tổng quan (the owner's surface list: "status, free-to-spend, forecast, goals, accounts")
  and in Cài đặt, as one shared row component.
