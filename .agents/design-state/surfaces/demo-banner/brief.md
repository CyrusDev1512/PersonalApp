# Demo banner "Bản dùng thử · dữ liệu giả": shape brief

Target: the browser demo (`mobile/lib/main_demo.dart`, `mobile/lib/demo/demo_controls.dart`: `DemoShell`,
`DemoBanner`), being built in parallel by another agent; this brief was aligned with its in-progress code. Visitor mode:
**operate** preview. Inherits DESIGN.md.

## Job and audience

Anyone shown the web demo (the owner, or someone they share it with) must never mistake its balances, accounts and
alerts for real money, and needs one obvious way to make something happen without a bank: simulate a balance change.

## The one primary action

**"Giả lập biến động số dư"** (`demo_simulate`, `Icons.bolt`): opens the preset sheet; the resulting refresh is
what lets a visitor see the dashboard's status-change moment. After "Ngắt kết nối" it is replaced by
**"Kết nối lại bản dùng thử"** (`demo_reconnect`, `Icons.link`). This is a demo control, not product UI, so it must not
use the cobalt `primary`: style it as a filled **`tertiary` / `onTertiary`** button (celadon on the celadon strip),
keeping The One Cobalt Rule intact for "Thêm mục tiêu".

## Placement and anatomy

- `DemoShell` puts the banner above the whole app (every route, sheets' parents included); its colour extends under
  the status bar and the content respects the top inset (as the current `SafeArea(bottom: false)` does).
- Strip: `tertiaryContainer`, 16 dp start / 12 dp end padding, at least 48 dp tall so the button's touch target is a
  full 48 dp (use `MaterialTapTargetSize.padded`; the current `shrinkWrap` + 36 dp minimum is below the floor).
- Start: `Icons.science_outlined` 18 dp + "Bản dùng thử · dữ liệu giả" in `labelLarge`, `onTertiaryContainer`, one
  line where it fits, wrapping only at very large text.
- The one demo button, `labelLarge`, M3 padding (16 dp start with its icon, 24 dp end), 48 dp target.
- **Narrow widths:** lay label and button out like `OverflowBar`: one row when both fit at natural width (about 480 dp
  and up at 100%: label 202 dp with its icon, button 231 dp, plus padding), otherwise the button moves to a second row,
  end-aligned. At 360 dp that gives a strip of 88 dp (12 + 20 label + 8 + 48 button; 94 dp at 130%). Never ellipsize
  either text: today's 112 dp label cap and ellipsis would render "Giả lập biến động s…" once the button gets
  `labelLarge` and the 48 dp target (≈ 26 dp short at 360 dp). Shorter copy ("Giả lập biến động") was considered and
  rejected: "số dư" is what tells a first-time visitor what the button does.
- No dismiss, no border, no shadow, no watermark or ribbon anywhere else. Semantics: the label is one node,
  "Bản dùng thử, dữ liệu giả"; the button keeps its visible text as its name.
- Celadon is used so the strip is unmistakably "not the app's state": it never resembles the cobalt OK hero, the
  warning butter / umber or the danger iron red.

## Behaviour of the demo around it

- Server- or device-bound actions explain themselves instead of failing silently, e.g. "Gửi thử" → a snackbar that the
  demo push is simulated; results of a simulation that does not change the level say so (the current copy: "… đã được
  ghi nhận. Giao dịch không làm đổi mức cảnh báo nên máy chủ không gửi thông báo đẩy — xem ở tab Cảnh báo.").
- Fake data must be plausible and arithmetically consistent (AGENTS.md); no real account numbers, names or references.
- No network calls at runtime: fonts (Be Vietnam Pro, and the demo's emoji/symbol fallbacks) are bundled.

## States

| State | What shows |
|---|---|
| Connected | Label + "Giả lập biến động số dư" (one row ≥ ~480 dp, two rows below). |
| Busy (simulating) | Button disabled with its label kept; the dashboard then animates the status change. |
| Disconnected | Label + "Kết nối lại bản dùng thử". |

## Remove / merge compared with the in-progress code

- `FilledButton` (cobalt `primary`) → filled `tertiary` button.
- `labelMedium` label → `labelLarge`; 36 dp shrink-wrapped button → 48 dp padded target; the fixed one-row layout with
  a 112 dp label cap and ellipsis → the two-row fallback above.
- Keep `Key`s `demo_simulate`, `demo_reconnect` and the preset sheet as is.

## Constraints and open decisions

- Colours come from the theme like any other component; nothing hard-coded in `demo/`.
- **Open:** whether tapping the label should open a short explanation ("Số liệu chỉ để minh hoạ, không phải tài khoản
  thật."); not needed while the strip is always visible.
