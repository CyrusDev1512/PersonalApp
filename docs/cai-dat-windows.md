# Cài đặt server Chi tiêu trên máy Windows của bạn

Tài liệu này dành cho người **không phải lập trình viên**. Làm lần lượt từng bước, đánh dấu ô `[ ]` khi xong.
Mỗi bước ghi rõ **Bạn làm** (việc chỉ bạn làm được: tạo tài khoản, bấm nút trên web, nhập mật khẩu) và **Script làm**
(việc máy tự làm khi bạn nháy đúp file `.cmd`).

Làm xong, bạn sẽ có:

- Server Chi tiêu chạy trong **Docker Desktop** trên máy Windows của bạn, tự chạy lại khi máy khởi động lại.
- Một địa chỉ Internet cố định, miễn phí, của **ngrok**, vd. `https://ten-ngau-nhien.ngrok-free.app`.
- **SePay** báo biến động số dư Vietcombank và MB Bank về server ngay khi có giao dịch.
- Cảnh báo qua **Telegram**, chỉ gửi cho tài khoản Telegram của bạn.
- **App Chi tiêu** trên điện thoại Android dùng dữ liệu thật của bạn.

Thời gian: khoảng 1–2 giờ cho lần đầu, phần lớn là tạo tài khoản và chờ tải.
Chi phí: các gói miễn phí là đủ dùng. Có thể mất phí SMS của Vietcombank (xem [bước 7](#7-sepay-liên-kết-vcb--mb-và-thêm-webhook)).

```
 Vietcombank, MB ──► SePay ──webhook HTTPS──► ngrok (tên miền miễn phí) ──► Docker trên máy Windows của bạn
                                                                                │
                              Telegram (cảnh báo) ◄─────────────────────────────┤
                              App Chi tiêu (Android) ◄── qua cùng địa chỉ ngrok ─┘
```

Các file bạn sẽ dùng nằm trong thư mục `scripts\windows\` của code:

| File (nháy đúp) | Dùng để |
|---|---|
| `setup.cmd` | Cài đặt lần đầu, hoặc chạy lại để bật lại server / điền phần còn thiếu (giá trị đã có được giữ nguyên). |
| `doi-cau-hinh.cmd` | **Xem và đổi** cấu hình đã lưu: authtoken / tên miền ngrok, khoá SePay, bot Telegram, Gmail, tạo khoá mới. Hỏi lại từng mục; bấm Enter là giữ nguyên. |
| `status.cmd` | Xem server có đang chạy tốt không; in lỗi và log gần nhất. |
| `test-sepay.cmd` | Gửi một giao dịch **giả** để thử cả đường đi SePay → server → Telegram, không làm đổi số liệu thật. |
| `update.cmd` | Cập nhật lên bản code mới nhất, giữ nguyên dữ liệu và cấu hình. |

---

## 0. Chuẩn bị

**Máy tính** (theo [yêu cầu của Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/)):

- [ ] **Windows 11** bản 23H2 trở lên (khuyên dùng), hoặc **Windows 10 64-bit bản 22H2** (build 19045).
  Windows 10 đã hết hạn hỗ trợ thông thường; các nguồn của Microsoft ghi khác nhau về hạn cập nhật bảo mật mở rộng
  (10/2026 hay 10/2027), và Docker chỉ hỗ trợ các bản Windows còn trong thời hạn của Microsoft → **dùng Windows 11 nếu được**.
- [ ] RAM từ **8 GB**, CPU 64-bit, đã bật **ảo hoá** (Virtualization, Intel VT-x / AMD SVM) trong BIOS/UEFI.
  Kiểm tra nhanh: mở Task Manager → Performance → CPU → dòng "Virtualization: Enabled".
- [ ] Còn trống vài GB trên ổ C.
- [ ] Windows Home: trang của Docker liệt kê bản Pro/Enterprise/Education nhưng cũng ghi bản Home chạy được container Linux
  (đủ cho dự án này). Nếu cài lỗi trên bản Home, xem lại trang yêu cầu của Docker.

**Tài khoản cần có** (đều miễn phí): GitHub (để tải code và file cài app), ngrok, Telegram, SePay.

**Điện thoại**: Android (app chưa có bản iOS).

**Chỗ để code**: `C:\PersonalApp`. Đường dẫn ngắn, không dấu tiếng Việt, không dấu cách (thư mục người dùng kiểu
`C:\Users\Tân` có dấu, Docker Desktop từng lỗi với đường dẫn như vậy), nằm ngoài OneDrive, và tạo được mà không cần quyền
quản trị. **Không** để trong Desktop/Documents nếu các thư mục đó đang được OneDrive đồng bộ: file cấu hình `.env` chứa
khoá bí mật sẽ bị tải lên mây (setup cảnh báo cả hai trường hợp nếu phát hiện).

---

## 1. Cài Docker Desktop

**Bạn làm:**

- [ ] Tải **Docker Desktop for Windows (x86_64)** tại <https://www.docker.com/products/docker-desktop/>.
- [ ] Chạy file cài đặt. Giữ lựa chọn mặc định **cài cho người dùng hiện tại (per-user)**: không cần quyền quản trị.
  Ở trang cấu hình chọn **Use WSL 2**.
- [ ] Nếu được yêu cầu cài/cập nhật WSL: mở PowerShell, chạy `wsl --update` (cần WSL 2.1.5 trở lên, xem bằng
  `wsl --version`). Bật WSL lần đầu cần quyền quản trị và có thể phải khởi động lại máy.
- [ ] Mở **Docker Desktop**, bấm **Accept** điều khoản (Docker Subscription Service Agreement). Docker Desktop miễn phí
  cho mục đích cá nhân. Không bắt buộc đăng nhập tài khoản Docker.
- [ ] Vào **Settings** (bánh răng) → **General** → bật **Start Docker Desktop when you sign in to your computer**
  (mặc định đang tắt). Đây là điều kiện để server tự chạy lại sau khi máy khởi động lại.
- [ ] Đợi góc dưới bên trái của Docker Desktop báo **Engine running**.

**Script làm:** `setup.cmd` tự kiểm tra Docker đã cài và đang chạy; nếu chưa chạy thì tự mở Docker Desktop và chờ.
`setup.cmd` và `status.cmd` cũng nhắc nếu bạn chưa bật tự chạy khi đăng nhập.

---

## 2. Tạo tài khoản ngrok, lấy tên miền miễn phí và authtoken

ngrok cho server một địa chỉ HTTPS trên Internet mà không cần mua tên miền hay mở cổng modem.

**Bạn làm:**

- [ ] Đăng ký tại <https://dashboard.ngrok.com/signup> (gói Free).
- [ ] Mở <https://dashboard.ngrok.com/domains>. Tài khoản miễn phí được ngrok **tự cấp sẵn một tên miền cố định**
  ("dev domain"), dạng `ten-ngau-nhien.ngrok-free.app` hoặc `.ngrok-free.dev`. Tên này không đổi được và gói Free chỉ
  dùng được đúng tên này. Hướng dẫn cũ (2023) bảo bấm "claim a free static domain"; hiện ngrok tự cấp, nhưng nếu trang
  của bạn có nút nhận tên miền miễn phí thì bấm. Ghi lại tên miền (không cần `https://`).
- [ ] Mở <https://dashboard.ngrok.com/get-started/your-authtoken>, bấm **Copy** để chép **authtoken**.
  Authtoken là **bí mật**: ai có nó có thể dùng tài khoản ngrok của bạn.

**Script làm:** `setup.cmd` hỏi authtoken (nhập vào hiện thành dấu `*`) và tên miền (bấm Enter để script tự đọc tên miền
sau khi ngrok chạy), rồi chạy container ngrok bản ghim cố định `ngrok/ngrok:3.39.11-alpine`, đưa
`https://<tên-miền>` về server, và tự thử gọi `https://<tên-miền>/health` từ Internet. Script cũng ghi
`COMPOSE_PROFILES=ngrok` vào `.env`, để cả lệnh `docker compose up -d` gõ tay cũng bật/cập nhật ngrok.
Dán sai authtoken hay tên miền: nháy đúp **`doi-cau-hinh.cmd`** để dán lại (gõ `-` để xoá tên miền, script tự nhận lại).

Giới hạn gói Free (theo [tài liệu ngrok](https://ngrok.com/docs/pricing-limits/free-plan-limits/)): 1 GB dữ liệu ra/tháng,
**20.000 request HTTP/tháng**, 4.000 request/phút, 1 tên miền, tối đa 3 agent. Webhook SePay và app dùng chung hạn mức này.

> Mở địa chỉ ngrok bằng **trình duyệt** sẽ thấy một trang cảnh báo của ngrok (bấm *Visit Site*). Theo tài liệu ngrok,
> trang này chỉ hiện với trình duyệt, không ảnh hưởng SePay hay app.

---

## 3. Tạo bot Telegram

**Bạn làm:**

- [ ] Trong Telegram, mở **@BotFather** → gửi `/newbot` → đặt tên hiển thị → đặt username (phải kết thúc bằng `bot`).
- [ ] BotFather trả về **token** dạng `123456789:AAH...`. Chép lại. Token là **bí mật**.

**Script làm:** `setup.cmd` kiểm tra token với Telegram và cho biết tên bot (`@...`). Sau khi server chạy, script bảo
bạn mở bot và bấm **Start**: bot trả lời "Chat ID của bạn" kèm một dãy số; bạn gõ dãy số đó vào cửa sổ setup. Script tự
lưu, **tự khởi động lại server đúng cách** (`docker compose up -d`; lệnh `docker compose restart` *không* nạp giá trị mới)
và gửi một tin thử. Từ đó bot chỉ trả lời và gửi cảnh báo cho đúng chat riêng của bạn.

Lệnh của bot: `/status` (tình hình hiện tại), `/goals` (mục tiêu tháng), `/uncat` (giao dịch chưa phân loại).

> ⚠️ **Telegram ở Việt Nam:** tháng 5/2025 báo chí đưa tin cơ quan quản lý yêu cầu các nhà mạng chặn Telegram
> ([VnExpress](https://e.vnexpress.net/news/tech/vietnam-innovation/vietnam-orders-telecom-operators-to-block-telegram-4889832.html)).
> Tình trạng chặn hiện tại **chưa kiểm chứng**. Nếu máy chạy server không vào được Telegram, cảnh báo sẽ **không tới**
> điện thoại mà không có lỗi nào hiện ra: `status.cmd` sẽ báo "Không tới được Telegram". Xem [mục 13](#13-xử-lý-sự-cố).

---

## 4. (Tuỳ chọn, nên bỏ qua) Gmail cho email biến động số dư

Server có thể đọc email báo biến động số dư qua Gmail (IMAP) làm **nguồn dự phòng** cho SePay. Tuy nhiên:

- Chưa tìm thấy Vietcombank hay MB Bank gửi **email** biến động số dư cho tài khoản cá nhân. Vietcombank báo miễn phí qua
  app ([VCB Digibank → Cài đặt → Quản lý thông báo](https://www.vietcombank.com.vn/vi-VN/Trang-thong-tin-dien-tu/Migration/Nhan-thong-bao-thay-doi-so-du-hoan-toan-mien-phi-tren-App-VCB-Digibank)),
  MB báo qua app MBBank (Tiện ích → Đăng ký biến động số dư). Thông báo trong app thì server không đọc được.
- Vì vậy nguồn email **có thể không nhận được gì**. Chỉ làm bước này khi bạn đã thấy ngân hàng gửi email biến động vào hộp thư.

**Bạn làm (nếu dùng):**

- [ ] Nên tạo một **Gmail riêng** chỉ để nhận email ngân hàng: mật khẩu ứng dụng cho quyền đọc **toàn bộ** hộp thư.
  Đổi email nhận thông báo tại ngân hàng sang Gmail này, hoặc tạo bộ lọc chuyển tiếp từ hộp thư chính.
- [ ] Bật **Xác minh 2 bước** cho Gmail đó, rồi tạo **Mật khẩu ứng dụng** tại <https://myaccount.google.com/apppasswords>
  (16 chữ cái). Gmail cá nhân luôn bật IMAP từ 1/2025, không cần bật thêm.
- [ ] Khi đổi mật khẩu Google, mọi mật khẩu ứng dụng bị thu hồi: tạo cái mới và nháy đúp `doi-cau-hinh.cmd`.

**Script làm:** `setup.cmd` hỏi Gmail và mật khẩu ứng dụng (ẩn, tự bỏ dấu cách). Lần cài đầu tiên script tự hỏi; các lần
sau muốn thêm thì nháy đúp `doi-cau-hinh.cmd`. Server đọc hộp thư 2 phút/lần, không đánh dấu đã đọc, chỉ nhận email từ domain
ngân hàng khai báo trong `EMAIL_BANK_DOMAINS` và có chữ ký DKIM/DMARC hợp lệ.
*Chưa kiểm chứng:* email **chuyển tiếp** qua bộ lọc Gmail có còn qua được kiểm tra DKIM hay không.

---

## 5. Tải code về máy

> **Quan trọng — chọn đúng nhánh.** Bộ cài đặt Windows này đang nằm ở nhánh **`claude/cool-darwin-edy2qo`** (PR #1).
> Nhánh mặc định `main` hiện **chưa có** gì để chạy (chưa có `docker-compose.yml`, `scripts\windows\`). Cho tới khi PR #1
> được gộp vào `main`, luôn tải nhánh `claude/cool-darwin-edy2qo` như hướng dẫn dưới đây. Gộp xong thì dùng `main`
> (`update.cmd` sẽ tự đề nghị chuyển sang `main` khi nhánh cũ bị xoá).

**Cách A — Git (khuyên dùng: sau này cập nhật bằng một cú nháy đúp `update.cmd`)**

- [ ] Cài **Git for Windows**: <https://git-scm.com/download/win> (giữ mọi lựa chọn mặc định).
- [ ] Mở **PowerShell** (bấm Start, gõ `PowerShell`, Enter) rồi chạy **từng dòng**:

  ```powershell
  cd C:\
  git clone -b claude/cool-darwin-edy2qo https://github.com/CyrusDev1512/PersonalApp.git
  ```

  Code nằm ở `C:\PersonalApp`. Kho code riêng tư thì cửa sổ đăng nhập GitHub sẽ hiện ra: đăng nhập là xong.
  (Sau khi PR #1 đã gộp vào `main`, lệnh thứ hai chỉ cần `git clone https://github.com/CyrusDev1512/PersonalApp.git`.)

**Cách B — tải file ZIP**

- [ ] Đăng nhập GitHub trên trình duyệt (kho riêng tư cần đăng nhập), rồi mở đường dẫn tải ZIP **của đúng nhánh**:
  <https://github.com/CyrusDev1512/PersonalApp/archive/refs/heads/claude/cool-darwin-edy2qo.zip>
  (hoặc trên trang dự án: bấm nút chọn nhánh, ghi `main`, ở góc trái → chọn `claude/cool-darwin-edy2qo` → **Code** →
  **Download ZIP**). Nút **Download ZIP** ở trang chính khi chưa đổi nhánh sẽ tải `main`: **không** dùng được.
- [ ] Chuột phải file ZIP → **Properties** → tick **Unblock** → OK (để Windows không hỏi lại khi chạy file `.cmd`).
- [ ] Chuột phải → **Extract All...** → chọn `C:\`. Mở thư mục vừa giải nén, tìm thư mục con có `docker-compose.yml`
  (tên dạng `PersonalApp-claude-cool-darwin-edy2qo`), chuyển nó ra thành **`C:\PersonalApp`**.

Kiểm tra: `C:\PersonalApp` có **trực tiếp** `docker-compose.yml` và `scripts\windows\setup.cmd`.

---

## 6. Chạy cài đặt

**Bạn làm:**

- [ ] Mở thư mục code → `scripts` → `windows` → **nháy đúp `setup.cmd`**.
  Nếu Windows hiện "Windows protected your PC": bấm **More info** → **Run anyway**.
- [ ] Trả lời các câu hỏi. Khi dán bí mật (authtoken, token bot, mật khẩu ứng dụng): bấm chuột phải hoặc `Ctrl+V`;
  ký tự hiện thành `*`, script **không bao giờ in lại** bí mật ra màn hình.
- [ ] Làm theo bước Telegram (bấm Start với bot, gõ Chat ID).
- [ ] Ở menu cuối: chọn **1** để chép **SePay API key** (dùng ở bước 7; dán xong quay lại bấm Enter để script xoá
  clipboard). Chọn **3** khi tới bước 9.3 (kết nối app trên điện thoại): có thể nháy đúp `setup.cmd` lại lúc đó.

**Script làm:**

1. Kiểm tra Docker Desktop (mở giúp nếu chưa chạy).
2. Tạo `.env` từ `.env.example` nếu chưa có, lưu dạng UTF-8 không BOM (docker compose không đọc được file UTF-16 mà
   Notepad hay PowerShell 5 đôi khi tạo ra; nếu gặp, script tự chuyển lại).
3. Tự sinh `APP_TOKEN` (43 ký tự) và `SEPAY_API_KEY` (40 ký tự) bằng bộ sinh số ngẫu nhiên an toàn của Windows.
4. Hỏi authtoken và tên miền ngrok, token bot Telegram, tên chủ tài khoản (giúp nhận ra tiền chuyển giữa VCB và MB của
   chính bạn), và có dùng Gmail không.
5. Chạy `docker compose --profile ngrok up -d --build`, chờ server trả lời, kiểm tra ngrok và gọi thử từ Internet.
6. Lấy Chat ID Telegram, khởi động lại server để nạp, gửi tin thử.
7. In việc tiếp theo: **URL webhook SePay** `https://<tên-miền>/webhooks/sepay`, **địa chỉ máy chủ (URL)**
   `https://<tên-miền>`, và menu chép API key / APP_TOKEN.

**Chạy lại:** nháy đúp `setup.cmd` bao nhiêu lần cũng được. Giá trị đã có được **giữ nguyên**, script chỉ hỏi phần còn thiếu.
Muốn xem và đổi từng giá trị (vd. dán lại authtoken ngrok, dán API key do SePay cấp, đổi Gmail, tạo khoá mới):
nháy đúp **`scripts\windows\doi-cau-hinh.cmd`**. Script hỏi lại từng mục: bấm **Enter** là giữ nguyên, gõ **`c`** là đổi;
với mục không bắt buộc (vd. tên miền ngrok), gõ **`-`** để xoá.

---

## 7. SePay: liên kết VCB + MB và thêm webhook

> Tên menu và tên ô trên trang SePay có thể khác một chút so với dưới đây (SePay đổi giao diện theo thời gian).
> Những chỗ đánh dấu ⚠️ là **chưa chắc chắn — kiểm tra lại trên trang SePay**.

### 7.1 Đăng ký

- [ ] Đăng ký tại <https://my.sepay.vn>. Gói **FREE**: 0đ, 50 giao dịch **tiền vào** mỗi tháng (vượt thì trả thêm);
  giao dịch tiền ra miễn phí và không tính vào hạn mức; không giới hạn số tài khoản ngân hàng và webhook
  ([bảng giá](https://sepay.vn/bang-gia.html)). ⚠️ Kiểm tra lại bảng giá hiện tại và giá mỗi giao dịch vượt mức.

### 7.2 Liên kết MB Bank (tài khoản cá nhân, qua API)

- [ ] my.sepay.vn → **Ngân hàng** → **Kết nối thêm** → tab **Cá nhân** → **MB**.
- [ ] Nhập số tài khoản, số CCCD và số điện thoại đăng ký với MB → nhập OTP MB gửi về
  ([hướng dẫn](https://docs.sepay.vn/ket-noi-mb-api.html)).
- Chỉ những giao dịch **sau khi liên kết** mới được đồng bộ.

### 7.3 Liên kết Vietcombank (tài khoản cá nhân)

- Hướng dẫn kết nối API Vietcombank của SePay chỉ dành cho **doanh nghiệp / hộ kinh doanh** (cần hợp đồng OneQR với VCB).
  ⚠️ Chưa thấy hướng dẫn API cho tài khoản VCB **cá nhân**, nên nhiều khả năng phải dùng cách **SMS Banking**:
- [ ] Trong SePay chọn liên kết Vietcombank kiểu SMS: SePay đưa cho bạn một **số điện thoại**.
- [ ] Đăng ký số đó với Vietcombank làm **số thứ hai** nhận SMS biến động số dư. **Giữ số của bạn là số chính**, và
  **không** để số của SePay nhận OTP ([FAQ SePay](https://sepay.vn/faq.html)).
- Chi phí và hạn chế (theo báo chí 2023–2024, ⚠️ kiểm tra lại với Vietcombank):
  - Phí SMS khoảng **10.000đ/tháng cho mỗi số điện thoại** (tối đa 20 SMS), sau đó 700đ/SMS, chưa VAT.
  - Từ 1/1/2024 Vietcombank **không nhắn SMS cho giao dịch dưới 50.000đ** → các giao dịch VCB nhỏ hơn 50.000đ
    sẽ **không** về SePay và server không biết.

### 7.4 Tiền ra (rất quan trọng với app này)

App cần biết cả **tiền ra** để trừ ngân sách và cảnh báo. ⚠️ Hai trang chính thức của SePay nói khác nhau về việc MB
qua API có báo tiền ra hay không. Sau khi làm xong bước 8–9:

- [ ] Chi thử một khoản nhỏ từ MB (vd. chuyển 50.000đ sang VCB của chính bạn) và xem bot Telegram có báo tiền ra từ MB không.
- [ ] Nếu không: trên trang tài khoản MB của SePay, chuyển cách kết nối từ **API** sang **SMS** rồi thử lại.

### 7.5 Thêm webhook

- [ ] my.sepay.vn → **Tích hợp WebHooks** → **Thêm webhooks**, điền:

| Ô trên trang SePay | Giá trị |
|---|---|
| Sự kiện (Có tiền vào / Có tiền ra / Cả hai) | **Cả hai** |
| Tài khoản ngân hàng | chọn **cả** VCB và MB |
| Bỏ qua nếu không có Code thanh toán | **Không** (nếu chọn Có, các khoản chuyển cá nhân sẽ bị bỏ qua) |
| Là WebHooks xác thực thanh toán | **Không** |
| Gọi đến URL | `https://<tên-miền-ngrok>/webhooks/sepay` (setup đã in sẵn) |
| Kiểu chứng thực | **API Key** |
| API Key | dán từ menu **1** của `setup.cmd` |
| Request Content type | **application/json** (server chỉ đọc JSON) |
| Tự động gọi lại khi lỗi (nếu có) | **Bật** |

- [ ] ⚠️ Nếu SePay **tự tạo** API key (không cho bạn dán key của mình): chép key SePay đưa, nháy đúp
  `doi-cau-hinh.cmd`, ở mục `SEPAY_API_KEY` gõ `d` rồi dán key đó.
- [ ] Lưu webhook. **Không cần bấm "Gửi thử"** của SePay: bước 8 (`test-sepay.cmd`) thử cả đường đi bằng một tài khoản
  giả, không đụng tài khoản thật. ⚠️ Chưa biết dữ liệu "Gửi thử" của SePay dùng số tài khoản nào: có thể là số VCB/MB
  **thật** của bạn.

**Khi bot hỏi "🆕 Phát hiện tài khoản mới"** (sau khi bật webhook, nếu bạn lỡ bấm "Gửi thử", hoặc có giao dịch thật
trước khi bạn thêm tài khoản trong app ở bước 9.3): **so số tài khoản trong tin** với số VCB/MB của bạn.

- Là số **của bạn** → bấm **✅ Tính vào tổng**. Sau đó ở bước 9.3 **sửa** tài khoản đó (đừng thêm mới) để nhập số dư.
  Nếu tin đến từ "Gửi thử", mở giao dịch thử trong app → bật **Loại trừ**.
- **Không** phải số của bạn (vd. `SEPAYTEST …5013` của bước 8) → bấm **🚫 Bỏ qua**.
- Lỡ bấm **Bỏ qua** cho tài khoản thật: giao dịch sau đó vẫn được ghi nhưng **không có cảnh báo**. Sửa ở bước 9.3:
  mở tài khoản đó trong app → bật **Tính vào tổng số dư**.

Cách SePay xử lý lỗi (theo [tài liệu SePay](https://developer.sepay.vn/en/sepay-webhooks/xu-ly-loi)): khi server không trả
lời được (máy tắt, mất mạng) và đã bật tự gọi lại, SePay gửi lại tối đa 7 lần, cách nhau 1, 1, 2, 3, 5, 8, 13 phút
(khoảng 33 phút). Quá thời gian đó, vào nhật ký webhook trên SePay và bấm **Gọi lại** cho các giao dịch lỗi.
Server tự bỏ qua giao dịch bị gửi trùng, nên gọi lại nhiều lần không sao.

*Test Mode* của SePay (công tắc góc trên bên phải) là môi trường thử riêng: webhook thật **không** nhận giao dịch giả lập
của Test Mode; muốn dùng thì phải tạo lại webhook bên trong Test Mode.

---

## 8. Thử đường đi SePay → server → Telegram

**Bạn làm:**

- [ ] Nháy đúp `scripts\windows\test-sepay.cmd`.
- [ ] Mở Telegram: lần thử **đầu tiên**, bot gửi tin **"🆕 Phát hiện tài khoản mới"** cho tài khoản `SEPAYTEST …5013`.
  Không cần bấm gì (nếu bấm thì chọn **🚫 Bỏ qua**, đừng bấm "Tính vào tổng"). Tài khoản thử luôn có số đuôi `5013`
  và ngân hàng `SEPAYTEST`: không phải tài khoản của bạn.

**Script làm:** gửi một webhook có API key tới **địa chỉ Internet** `https://<tên-miền>/webhooks/sepay`, giống SePay
gửi (cùng URL, cùng kiểu xác thực, cùng dạng JSON), với một **tài khoản giả** (`7391046285013`, ngân hàng `SEPAYTEST`). Server chưa biết tài khoản này nên tạo nó ở trạng
thái **không tính vào tổng** → tổng số dư, mục tiêu và cảnh báo thật **không đổi**. Script kiểm tra server đã ghi nhận,
đặt tên tài khoản thử thành "Thử kết nối SePay (không phải TK thật)" và nói bạn chờ tin Telegram nào.
Id của webhook thử luôn từ 900.000.000.000.000 trở lên nên không bao giờ trùng giao dịch thật.

Các lần chạy sau, bot **không** nhắn gì (tài khoản thử đã có, tránh làm phiền) — script sẽ nói rõ điều đó. Muốn thử
riêng server trong máy (bỏ qua ngrok): `.\scripts\windows\test-sepay.cmd -Local`.

Kết quả cuối của script là **"ĐƯỜNG ĐI WEBHOOK HOẠT ĐỘNG"** (đạt) hoặc **"CHƯA ĐẠT"** (xem các dòng `[X]` phía trên).
Cần biết:

- Tài khoản thử "Thử kết nối SePay (không phải TK thật)" **ở lại** trong danh sách tài khoản của app (server không cho xoá
  tài khoản đã có giao dịch). Nó không tính vào tổng nên không ảnh hưởng gì.
- Mỗi lần chạy `test-sepay.cmd` được tính là "vừa nhận webhook SePay", nên lời nhắc "48 giờ không nhận được webhook SePay"
  trong bản tin 08:00 bị đặt lại từ lúc đó.
- Bài thử gửi **không** kèm header bỏ qua trang cảnh báo của ngrok (giống SePay), nhưng không giả được đúng phần mềm gửi của
  SePay. Bằng chứng cuối cùng là giao dịch thật ở bước 9.4 và **nhật ký webhook** trên my.sepay.vn.

---

## 9. Cài app Android và kết nối

### 9.1 Tải file cài (APK)

- [ ] Trên GitHub của dự án → tab **Actions** → workflow **CI** → chọn lần chạy mới nhất có dấu ✓ xanh của nhánh
  `claude/cool-darwin-edy2qo` (sau khi gộp: nhánh `main`).
  Không có lần chạy nào, hoặc artifact đã hết hạn: mở tab **Pull requests** → PR #1 → tab **Checks** → **Re-run all jobs**.
  (Nút **Run workflow** trong tab Actions chỉ hiện khi file workflow đã có ở nhánh `main`, tức là sau khi gộp PR #1.)
- [ ] Cuộn xuống mục **Artifacts** → tải **`chi-tieu-apk-firebase-none`** (cần đăng nhập GitHub). Đây là bản không có
  thông báo đẩy Firebase — cảnh báo đã có qua Telegram. File tải về là `.zip`; giải nén để lấy **`app-release.apk`**.
  GitHub tự xoá artifact sau một thời gian (mặc định 90 ngày); hết hạn thì chạy lại như trên.
- [ ] Đưa file APK sang điện thoại (cáp USB, Google Drive, Zalo "Cloud của tôi"...), hoặc làm các bước trên bằng trình
  duyệt của điện thoại.

### 9.2 Cài đặt

- [ ] Mở file `app-release.apk` trên điện thoại → cho phép **Cài ứng dụng không rõ nguồn gốc** cho ứng dụng đang mở file
  (Files / Chrome) → **Cài đặt**.
- [ ] Nếu Google Play Protect cảnh báo ứng dụng chưa được xác minh: chọn **Vẫn cài đặt** (app tự build, không qua Play Store).

### 9.3 Kết nối với server của bạn

- [ ] Trên máy tính, nháy đúp `setup.cmd` (hoặc dùng cửa sổ setup còn mở) → ở menu cuối chọn **3**: bot gửi vào Telegram
  của bạn 3 tin: lời dặn, **địa chỉ máy chủ**, **APP_TOKEN**. Mỗi giá trị nằm riêng một tin, ở dạng chữ đơn cách.
- [ ] Mở app **Chi tiêu** → trong Telegram **chạm vào dòng chữ đơn cách** của tin địa chỉ (Telegram báo đã chép) → dán vào ô
  **Địa chỉ máy chủ (URL)** (dạng `https://<tên-miền-ngrok>`, không có `/` ở cuối). Làm tương tự với tin APP_TOKEN → ô
  **Token (APP_TOKEN)** → bấm **Kiểm tra & kết nối**. Nếu dòng gợi ý dưới ô địa chỉ nhắc tới Cloudflare Tunnel thì
  bỏ qua: dùng địa chỉ ngrok.
- [ ] Quay lại cửa sổ setup trên máy tính, bấm **Enter**: script **tự xoá** các tin chứa địa chỉ và APP_TOKEN khỏi Telegram.
- [ ] Vào **Cài đặt → Tài khoản**. Nếu Vietcombank / MB **đã có** trong danh sách (SePay đã gửi giao dịch trước đó):
  **chạm vào tài khoản để sửa** → bật **Tính vào tổng số dư** → nhập **Số dư hiện tại** → **Lưu tài khoản**.
  Đừng thêm mới tài khoản đã có: app sẽ báo **"Số tài khoản đã tồn tại"**.
  Chưa có thì **Thêm tài khoản** Vietcombank và MB với **số tài khoản đầy đủ** và **số dư hiện tại**: số tài khoản phải
  khớp để giao dịch SePay gửi về được gắn đúng tài khoản.
- [ ] Trên màn hình Tổng quan, bấm **Thêm mục tiêu** (vd. Tiền trọ 3.000.000đ, Tiền ăn 5.000.000đ).

### 9.4 Thử bằng giao dịch thật

- [ ] Chuyển **từ 50.000đ trở lên** (dưới 50.000đ Vietcombank không nhắn SMS) từ VCB sang MB của chính bạn.
- [ ] Trong 1–2 phút, Telegram báo biến động; hai nửa của khoản chuyển được ghép thành **chuyển nội bộ** (không tính là
  chi tiêu). Không thấy gì: xem [Xử lý sự cố](#13-xử-lý-sự-cố) và nhật ký webhook trên my.sepay.vn.

### 9.5 Cập nhật app sau này

Tải APK mới như 9.1 và cài đè. Nếu điện thoại báo **"Chưa cài đặt ứng dụng"** / xung đột: các bản APK của CI được ký bằng
khoá debug, có thể khác nhau giữa các lần build → **gỡ app cũ rồi cài lại**, nhập lại địa chỉ server + APP_TOKEN.
Dữ liệu nằm trên server nên không mất gì.

---

## 10. Giữ server luôn chạy

- [ ] Docker Desktop **tự chạy khi đăng nhập Windows** (bước 1). Các container có `restart: unless-stopped` nên tự chạy lại
  khi Docker khởi động.
- [ ] **Settings → System → Power** (Nguồn): **Sleep / Ngủ = Never** khi cắm điện. Laptop: Control Panel → Power Options →
  *Choose what closing the lid does* → **Do nothing** khi cắm điện.
- [ ] Windows Update: đặt **Active hours** (giờ hoạt động) để máy không tự khởi động lại lúc bạn cần.
  Sau khi máy khởi động lại, Docker Desktop **chỉ chạy khi có người đăng nhập Windows** → hãy đăng nhập lại.
  (Chưa tìm thấy cách chính thức để Docker Desktop chạy trước khi đăng nhập. Bật tự đăng nhập Windows thì tiện hơn
  nhưng kém an toàn: ai mở máy cũng vào được.)
- [ ] Mỗi tuần hoặc khi nghi ngờ: nháy đúp **`status.cmd`**. Server cũng tự nhắc trong bản tin 08:00 nếu 48 giờ
  không nhận được webhook SePay nào.
- Lỡ bấm **Stop** container trong Docker Desktop: chúng sẽ không tự chạy lại; nháy đúp `setup.cmd` để bật lại.

---

## 11. Cập nhật lên bản mới

- [ ] Nháy đúp **`scripts\windows\update.cmd`**.

**Script làm:** `git pull` (bản Git), thêm vào `.env` các biến cấu hình mới nếu có, `docker compose up -d --build`, chờ
server trả lời, kiểm tra qua Internet, dọn image cũ. Dữ liệu (volume Docker `personalapp_app-data`) và `.env` giữ nguyên.
Bản ZIP: tải ZIP mới **của đúng nhánh** (đường dẫn ở [bước 5, cách B](#5-tải-code-về-máy); sau khi PR #1 gộp thì tải `main`),
giải nén **đè** lên `C:\PersonalApp` (giữ file `.env`), rồi nháy đúp `update.cmd`.
Bản Git: nếu nhánh `claude/cool-darwin-edy2qo` đã bị xoá sau khi gộp, `update.cmd` sẽ hỏi chuyển sang `main`: chọn **c**.

---

## 12. Sao lưu dữ liệu

Mở PowerShell (Start → gõ `PowerShell`) rồi chạy từng dòng:

```powershell
cd C:\PersonalApp
docker compose exec app python -c "import sqlite3; s=sqlite3.connect('/data/app.db'); d=sqlite3.connect('/data/backup.db'); s.backup(d)"
docker compose cp app:/data/backup.db ".\backup-$(Get-Date -Format yyyy-MM-dd).db"
```

File sao lưu chứa dữ liệu tài chính của bạn: cất ở nơi an toàn (USB riêng), không gửi cho ai.

---

## 13. Xử lý sự cố

Luôn chạy **`status.cmd`** trước: nó in từng phần đang ổn/lỗi và log gần nhất.

| Triệu chứng | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| Script báo **chưa cài Docker** / **Docker chưa chạy**, hoặc lỗi `error during connect` | Docker Desktop chưa mở, WSL cũ, chưa bật ảo hoá | Mở Docker Desktop, đợi "Engine running". Chạy `wsl --update` rồi khởi động lại máy. Bật Virtualization trong BIOS. |
| Nháy đúp `.ps1` không chạy / "running scripts is disabled" | Windows chặn script PowerShell | Dùng các file **`.cmd`** (đã tự bỏ qua chặn cho riêng lần chạy đó). |
| `port is already allocated` khi khởi động | Chương trình khác đang dùng cổng 8000 | Tìm bằng `netstat -ano \| findstr :8000`, tắt chương trình đó, chạy lại `setup.cmd`. Hoặc đổi cổng như dòng dưới. |
| `bind: An attempt was made to access a socket in a way forbidden by its access permissions` | Windows (Hyper-V/WSL) giữ sẵn một dải cổng có chứa 8000 | Xem bằng `netsh int ipv4 show excludedportrange protocol=tcp`. Mở `C:\PersonalApp\.env` bằng Notepad, thêm dòng `HOST_PORT=18000`, lưu, nháy đúp `setup.cmd`. Chỉ đổi cổng trong máy; địa chỉ ngrok, SePay và app giữ nguyên. |
| **ngrok** không kết nối, log có `ERR_NGROK_105` / `ERR_NGROK_107` | Authtoken sai hoặc đã bị đổi | Chép lại authtoken (bước 2), nháy đúp `doi-cau-hinh.cmd`, đổi mục ngrok authtoken. |
| ngrok báo lỗi về **tên miền** / `status.cmd` báo tên miền khác `.env` | `NGROK_DOMAIN` gõ sai hoặc không phải tên miền của tài khoản | Xem lại <https://dashboard.ngrok.com/domains>, nháy đúp `doi-cau-hinh.cmd` và sửa tên miền (hoặc gõ `-` để xoá, script tự nhận lại). |
| Log ngrok báo **agent quá cũ** (vd. `ERR_NGROK_121`), container ngrok khởi động lại liên tục | ngrok ngừng nhận bản agent cũ; bản ngrok được ghim cố định trong `docker-compose.yml` | Báo người bảo trì cập nhật bản ghim, rồi nháy đúp `update.cmd`. Chữa tạm: thêm dòng `NGROK_IMAGE=ngrok/ngrok:alpine` vào `.env`, nháy đúp `setup.cmd`. |
| Gọi địa chỉ ngrok thấy `ERR_NGROK_3200` (offline) | Container ngrok không chạy, hoặc máy/Docker tắt | Nháy đúp `setup.cmd` (bật lại), rồi `status.cmd`. |
| `ERR_NGROK_8012` / HTTP 502 | ngrok chạy nhưng server (container app) không trả lời | `status.cmd` → xem log `app`. |
| ngrok chạy ở máy khác cùng tài khoản | Một tên miền miễn phí chỉ nên chạy ở một nơi | Tắt ngrok ở máy kia. |
| SePay báo webhook lỗi **401** | API key trên SePay khác `SEPAY_API_KEY`, hoặc server chưa nạp `.env` mới | Chép lại key bằng menu 1 của `setup.cmd` và dán vào SePay; hoặc dán key của SePay qua `doi-cau-hinh.cmd`. Chạy `test-sepay.cmd` để thử. |
| SePay báo **404** | Server chưa có `SEPAY_API_KEY` (route webhook tắt), hoặc ngrok offline | Chạy `setup.cmd`; xem `status.cmd`. Kiểm tra URL đúng `/webhooks/sepay`. |
| SePay báo **timeout / 5xx** | Máy tắt, mất mạng, Docker tắt | Bật lại máy/Docker; SePay tự gọi lại tối đa ~33 phút, sau đó bấm **Gọi lại** trong nhật ký webhook. |
| **Không có tin Telegram** | Chưa có Chat ID; token bot bị thu hồi; giao dịch thuộc tài khoản chưa xác nhận / không tính vào tổng (vd. lỡ bấm "Bỏ qua" cho tài khoản thật) | `status.cmd` (phần Telegram). Nhắn `/status` cho bot. Chưa có Chat ID → `setup.cmd`. Tài khoản thật bị "không tính vào tổng" → sửa trong app (bước 9.3). |
| **Telegram bị chặn**: `status.cmd` báo "Không tới được Telegram" dù Internet vẫn chạy | Nhà mạng chặn Telegram (xem ghi chú ở bước 3) | Cảnh báo không tới điện thoại; trong lúc đó mở app Chi tiêu → **Cảnh báo** để xem. Cách chữa: cho **máy chạy server** đi qua VPN/proxy có vào được Telegram, hoặc dùng bản APK có thông báo đẩy Firebase (cần người bảo trì cấu hình Firebase). |
| Bot không trả lời lệnh | Nhắn trong nhóm, hoặc từ tài khoản Telegram khác | Bot chỉ trả lời chat riêng với đúng tài khoản có Chat ID trong `.env`. |
| **App không kết nối được** | Thiếu `https://`, sai tên miền, chép thiếu/thừa ký tự ở ô Token, server/ngrok tắt | Nhập đúng `https://<tên-miền>`; gửi lại bằng menu 3 của `setup.cmd` và **chạm** (không bấm giữ) vào dòng chữ đơn cách để chép; chạy `status.cmd`. App báo **Sai token (401)** = ô Token (APP_TOKEN) sai (hoặc đã tạo token mới). |
| Thêm tài khoản trong app báo **"Số tài khoản đã tồn tại"** | SePay đã gửi giao dịch của tài khoản đó nên server đã tự tạo nó | Không thêm mới: chạm vào tài khoản đó trong **Cài đặt → Tài khoản** để sửa (bước 9.3). |
| Đã sửa `.env` bằng tay nhưng không có tác dụng | `docker compose restart` không nạp `.env` mới | Nháy đúp `setup.cmd` (hoặc `update.cmd`). |
| `.env` sửa bằng Notepad xong Docker báo `unexpected character` | File lưu dạng UTF-16 | Nháy đúp `setup.cmd`: script tự chuyển về UTF-8. Giá trị có `$` hoặc `#` phải đặt trong nháy đơn `'...'`. |
| Chữ tiếng Việt trong cửa sổ đen bị lỗi | Phông chữ của cửa sổ | Chuột phải thanh tiêu đề → Properties → Font → **Consolas**; hoặc dùng Windows Terminal. |
| Gmail báo lỗi đăng nhập | Mật khẩu ứng dụng bị thu hồi (đổi mật khẩu Google) | Tạo mật khẩu ứng dụng mới, nháy đúp `doi-cau-hinh.cmd`. |
| `setup.cmd` báo lỗi build / mount, đường dẫn có dấu tiếng Việt hoặc dấu cách | Docker Desktop lỗi với đường dẫn đó | Chuyển cả thư mục code (cùng file `.env`) sang `C:\PersonalApp`, chạy lại `setup.cmd`. Dữ liệu nằm trong Docker nên không mất. |
| Hết hạn mức ngrok Free (20.000 request/tháng) | App mở liên tục, nhiều thiết bị | Giảm số lần mở app; hạn mức tính lại đầu tháng; hoặc nâng gói ngrok. |

---

## 14. Bảo mật

- **APP_TOKEN** là chìa khoá vào toàn bộ dữ liệu tài chính qua Internet. Không gửi cho ai, không chụp màn hình.
  Tin Telegram chứa APP_TOKEN (menu 3) nằm trên máy chủ của Telegram (chat thường không mã hoá đầu-cuối): sau khi chép
  vào app, bấm Enter trong cửa sổ setup để script **tự xoá**; nếu script báo không xoá được thì tự xoá trong Telegram.
- File **`.env`** chứa mọi khoá (APP_TOKEN, SePay, ngrok, Telegram, Gmail). Không chia sẻ, không đưa lên GitHub
  (`.gitignore` đã chặn), không để trong OneDrive.
- Clipboard của Windows có thể nhớ lịch sử (`Win+V`) và đồng bộ lên mây. Menu 1 và 2 của setup chép khoá theo kiểu
  **không lưu vào lịch sử** và **xoá clipboard** khi bạn bấm Enter sau khi dán. Nếu script báo "Windows có thể đã lưu
  khoá này vào Lịch sử clipboard", mở `Win+V` và xoá mục đó.
- Khoá màn hình Windows bằng mật khẩu khi rời máy; máy chủ chính là máy chứa toàn bộ dữ liệu.
- **Đổi khoá (rotate)** khi lộ màn hình/file, mất máy, hoặc nghi ngờ:

| Khoá | Cách đổi |
|---|---|
| APP_TOKEN | `doi-cau-hinh.cmd` → tạo mới → nhập lại trong app (menu 3) |
| SEPAY_API_KEY | `doi-cau-hinh.cmd` → `m` (tạo mới) → dán key mới vào webhook trên my.sepay.vn (menu 1) |
| Token bot Telegram | @BotFather → `/revoke` → chọn bot → `doi-cau-hinh.cmd` → dán token mới |
| ngrok authtoken | dashboard ngrok → đặt lại authtoken → `doi-cau-hinh.cmd` |
| Mật khẩu ứng dụng Gmail | xoá ở <https://myaccount.google.com/apppasswords>, tạo cái mới → `doi-cau-hinh.cmd` |

- Mọi đường `/api/*` đều đòi APP_TOKEN; webhook SePay đòi API key; trang tài liệu API `/docs` bị tắt.
  (Nâng cao, chưa làm sẵn: chỉ cho phép địa chỉ IP của SePay, danh sách tại
  <https://developer.sepay.vn/en/dia-chi-ip> — IP có thể thay đổi.)

---

## 15. Những điểm chưa chắc chắn — kiểm tra lại

Thông tin dưới đây lấy từ tài liệu công khai (tháng 10/2026) nhưng chưa kiểm chứng trên tài khoản thật:

1. ⚠️ SePay có gửi **tiền ra** của tài khoản MB cá nhân qua API không (hai trang của SePay nói khác nhau) → thử theo 7.4.
2. ⚠️ Vietcombank cá nhân có bắt buộc dùng SMS Banking không, và phí SMS cho số thứ hai của SePay.
3. ⚠️ Tên menu/ô trên trang SePay ("Tích hợp WebHooks", "Bỏ qua nếu không có Code thanh toán", "Gửi thử").
4. ⚠️ SePay cho tự nhập API key hay tự tạo key (setup hỗ trợ cả hai, xem 7.5).
5. ⚠️ Dữ liệu "Gửi thử" của SePay khác giao dịch thật thế nào.
6. ⚠️ Giá mỗi giao dịch vượt 50 giao dịch/tháng của gói FREE, và gói FREE hiện còn 50 giao dịch hay không.
7. Vietcombank và MB có gửi email biến động số dư không (chưa tìm thấy, không phải đã khẳng định là không).
8. Email chuyển tiếp qua Gmail còn qua kiểm tra DKIM không.
9. Hạn cập nhật bảo mật của Windows 10 cho người dùng cá nhân; Docker Desktop trên Windows Home.
10. Docker Desktop có chạy được trước khi đăng nhập Windows không.
11. App và SePay gọi server qua ngrok có bao giờ gặp trang cảnh báo của ngrok không (tài liệu ngrok nói không; chưa thử
    thực tế; `test-sepay.cmd` chỉ giả lập được một phần, xem bước 8).
12. App dùng bao nhiêu trong hạn mức 20.000 request/tháng của ngrok (chưa đo).
13. ⚠️ Telegram hiện có bị nhà mạng Việt Nam chặn không (tin 5/2025, xem bước 3). Bị chặn thì cảnh báo không tới điện thoại.
14. ⚠️ Bản ngrok ghim cố định (3.39.11) còn được ngrok chấp nhận bao lâu (xem mục 13, dòng "agent quá cũ").
15. Docker Desktop với đường dẫn có dấu tiếng Việt / dấu cách (chưa thử; vì vậy khuyên dùng `C:\PersonalApp`).
16. Gói Free của ngrok có nhận `--url=https://<tên-miền-miễn-phí-của-bạn>` không, và khi để trống tên miền thì ngrok có tự
    dùng đúng tên miền miễn phí đó không (chưa chạy với ngrok thật; nếu lỗi, gõ đúng tên miền bằng `doi-cau-hinh.cmd`).

## Nguồn tham khảo

- Docker Desktop trên Windows: <https://docs.docker.com/desktop/setup/install/windows-install/>,
  cài đặt tự chạy: <https://docs.docker.com/desktop/settings-and-maintenance/settings/>
- ngrok: tên miền miễn phí <https://ngrok.com/docs/gateway/domains/>, giới hạn gói Free
  <https://ngrok.com/docs/pricing-limits/free-plan-limits/>, dùng với Docker <https://ngrok.com/docs/using-ngrok-with/docker/>
- SePay: kết nối MB <https://docs.sepay.vn/ket-noi-mb-api.html>, VCB doanh nghiệp
  <https://docs.sepay.vn/ket-noi-vietcombank-doanh-nghiep-ho-kinh-doanh.html>, webhook
  <https://developer.sepay.vn/en/sepay-webhooks/tich-hop-webhook>, xử lý lỗi
  <https://developer.sepay.vn/en/sepay-webhooks/xu-ly-loi>, bảng giá <https://sepay.vn/bang-gia.html>
- Gmail IMAP: <https://support.google.com/mail/answer/7126229>, mật khẩu ứng dụng <https://support.google.com/accounts/answer/185833>
- Telegram bot: <https://core.telegram.org/bots/tutorial>
- Phí SMS Vietcombank: <https://tuoitre.vn/vietcombank-dieu-chinh-phi-bao-bien-dong-so-du-qua-tin-nhan-20231215175417823.htm>
