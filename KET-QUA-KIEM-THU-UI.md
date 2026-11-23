## Nghiệm thu 2026.10.19.4 — đạt

- 177 test Python và 24 test JavaScript đạt; kiểm tra cú pháp JavaScript đạt. Log: `build/release-20261019-4-final.log`.
- 11 ca mới về xác nhận bỏ qua: giữ trạng thái chưa rõ/post lock, chặn trùng xuyên tài khoản và khởi động lại, nhiều lần chưa xử lý, giữ lỗi phiên/hạn chế, sai revision/actor/post, xác nhận lặp, busy và rollback khi lỗi DB. Có ca reserved sau crash trước khi ghi hold.
- UI fixture trên trình duyệt: Lịch sử → Chi tiết đúng bài → xác nhận bỏ qua; lịch sử giữ Chưa rõ kết quả và ghi Đã kiểm tra · bỏ qua bài; về Làm việc không còn banner app hold. Desktop và chiều rộng 390px; dialog không tràn ngang (380px). Ảnh: `build/review-outcome-desktop.png`.
- Frozen smoke đạt, gồm endpoint xác nhận bỏ qua có CSRF, giữ trạng thái/post lock. `sys.path` nằm trong bundle và có Python DLL.
- Chính ZIP cuối đã giải nén ngoài repo trong thư mục có dấu/khoảng trắng, chạy EXE với cwd trống, PATH chỉ System32 và xóa biến Python/venv. Runtime, UI/backend, lưu phiên giả và API hoạt động; Edge thật mở hai lần vẫn một cửa sổ, idle 30 giây backend còn hoạt động, đóng/mở lại giữ dữ liệu.
- Báo cáo archive: `dist/portable-acceptance.json`, có SHA-256 trùng ZIP cuối. Harness điều khiển test có Python; tiến trình EXE dùng runtime đi kèm. Chưa kiểm tra trên máy vật lý/VM sạch khác.
- Gói không có repo, venv, database, cookie, private/profiles hoặc nhật ký thật. Cần Windows x64, Microsoft Edge, giải nén cả `_internal`. EXE chưa ký số.
- Đã thay EXE và toàn bộ `_internal` ở thư mục gốc, so khớp mọi file với bundle phát hành. Không sửa dữ liệu tài khoản thật, không tự xác nhận bài của người dùng, không đăng bình luận thật.
- EXE SHA-256: `f8843a5b123f165af5718c4e11d0b68be9c7724af5d35cd278cd8e6e49116810`
- ZIP SHA-256: `077b30dd3ae422b808501ce276c5ba54a20c6c9f7c17ac0440b81f027c897a9b`

## Nghiệm thu 2026.10.19.3 — đạt

166 Python + 21 JavaScript, syntax check, frozen smoke và desktop acceptance đạt. Bản hướng dẫn cuối đã cập nhật, chạy lại JS và smoke trên gói EXE cuối. Root EXE/UI khớp checksum với dist. Không có cookie hay database thật trong ZIP. Đã kiểm chứng đọc 371 nhóm/19 trang đến has_next_page=false; không gửi bình luận thật. Không xóa hold hoặc nhật ký thật.

## Cập nhật 2026.10.19.3 — đọc đầy đủ nhóm

- Sửa nguyên nhân chỉ lấy trang đầu: dùng cursor của all_joined_groups.tab_groups_list, tiếp tục đến has_next_page=false. Truy vấn chỉ đọc được xác minh từ public JS của chính trang hiện tại, không hardcode docID, không lấy nhóm gợi ý/chờ duyệt.
- Đã kiểm chứng thật bằng thao tác chỉ đọc: tài khoản đang chọn trả 371 nhóm duy nhất qua 19 trang, stop_reason=exhausted, complete=true. Không đăng bình luận, không ghi cookie hoặc raw phản hồi vào tài liệu.
- Đồng bộ vẫn chạy nền; cập nhật số nhóm/số trang sau mỗi trang; có Dừng giữa các request. Kiểm tra revision và jobID trước khi công bố kết quả. Lỗi giữa chừng giữ danh sách đã lưu trước đó.
- Không giả phần trăm khi chưa biết tổng. Cursor lặp, không nhận diện query hoặc giới hạn bảo vệ 500 trang luôn báo chưa đầy đủ, không coi là thành công toàn bộ.
- Lỗi đọc/parser dừng lượt hiện tại nhưng không tạo app hold lâu dài. Dấu hiệu phiên/xác minh/hạn chế vẫn dừng và được lưu riêng. Không tự xóa hold cũ thiếu bằng chứng.
- Thông báo app hold có nút Xem lịch sử; Kiểm tra khả năng đọc không được trình bày là xác nhận kết quả gửi trước hoặc mở khóa gửi. Bản lịch sử cũ thiếu diagnostic không thể suy ra chính xác phản hồi Facebook.
- Không thay cơ chế gửi, chống trùng, không retry và khóa kết quả chưa rõ sau POST. Không có backup thật.
- Sau khi cài bản mới, bấm Đồng bộ lại để cập nhật danh sách cũ; không cần nhập lại cookie chỉ để kích hoạt đồng bộ.

## Nghiệm thu EXE cuối — đạt

- 157/157 test Python; 20/20 test JavaScript; JavaScript syntax hợp lệ.
- Frozen smoke: assets, CSRF, lưu phiên fixture và DPAPI đạt.
- Desktop acceptance trên chính EXE phát hành: protocol UI/backend trùng, API lưu tài khoản/nhập link/lịch sử hoạt động; dữ liệu gửi rỗng bị chặn trước mạng; mở hai lần một cửa sổ; 30 giây chờ backend còn hoạt động; đóng dừng server; mở lại giữ phiên fixture.
- Cấm outbound network trong các phép thử EXE; không có bình luận thật.
- EXE root và UI đã đối chiếu SHA-256 với dist. Gói ZIP không chứa private/profiles/cookie/database.
- EXE SHA-256: 93cb3da18dae39152ac590f08d131ad4282a6971dc4ffa9d46d57890c10378ab
- ZIP SHA-256: 471337f86bdc52cb128fc92ba0d56a3ab7252d8255e036bb9a7634e5dfdbf21d
- Mã nguồn và tài liệu bàn giao cập nhật; không commit/push. Chưa có backup thật, chưa xác minh Facebook thật.
- Bản EXE cũ giữ tại build/previous-desktop-20261019-163921 (chỉ bundle, không dữ liệu tài khoản). Không tự chạy bản cũ trên kho đã được bản mới cập nhật.

# Kiểm thử bản 2026.10.19.2

Nguồn kiểm thử: app thật trên fixture riêng port 8796, cấm toàn bộ request ra Facebook.

Đã kiểm tra bằng trình duyệt:
- Lưu tài khoản mới trả ngay; thanh đồng bộ nền xuất hiện; phần soạn vẫn dùng được.
- Đổi tài khoản rồi quay lại giữ đúng nội dung và link của tài khoản cũ.
- Nhập link bài, gửi giả lập, lịch sử hiển thị đúng tên tài khoản/nhóm và chi tiết.
- Gửi lại bài đã xử lý bị bỏ qua, không có lần gửi mới.
- Timeout giả lập dừng lượt và báo app hold/lỗi kết nối, không kết luận Facebook khóa tài khoản.
- Desktop và 360px: panel xếp đúng, phần soạn truy cập được. Sửa header mobile để nút không tràn chiều cao; bổ sung tên truy cập ô tìm nhóm.
- Sửa panel thành công để không gắn nhãn “chưa xác định phạm vi lỗi”.
- Impeccable detector layout đã chạy; không có kết quả cảnh báo.

Bộ test nguồn cuối: 157 Python + 20 JavaScript đạt; JavaScript syntax check đạt.

Kiểm tra desktop ban đầu phát hiện timeout khi mở EXE lần hai, kèm file metrics của Edge đang bị giữ lúc dọn fixture. Không bỏ qua cổng này: thêm log lifecycle không chứa bí mật, dùng ShowWindowAsync để tránh chờ UI Edge, thêm regression test và cho cleanup fixture bỏ qua file metrics bị Windows giữ. Lượt trước sửa phòng vệ đã chạy lại thành công; bản cuối vẫn phải chạy lại toàn bộ cổng đóng gói.

Kết quả chính xác của EXE cuối xem dist/desktop-smoke.json và dist/desktop-acceptance.json. Không coi việc build thành công là đủ nếu hai report chưa ok=true. Không gửi bình luận thật, không đọc tài khoản thật, không kiểm chứng đồng bộ đủ nhóm trên Facebook trong đợt này.

---
Báo cáo các lượt trước bên dưới chỉ là lịch sử, không thay bằng chứng của bản hiện tại.

# Chẩn đoán hai thông báo tạm dừng — 19/10/2026

## Phát hiện đã kiểm chứng từ code

1. Hai câu “Facebook yêu cầu xác minh. Đã khóa gửi tài khoản.” và “Phản hồi chưa nhận diện được. Đã khóa gửi để kiểm tra.” là chuỗi do ERRORS trong scripts/workspace_lab.py tự tạo, không phải nguyên văn phản hồi Facebook.
2. scripts/remote_status.py bản trước gán verification_required khi Location chứa /checkpoint hoặc /challenge, HOẶC toàn bộ body chứa checkpoint_url (kể cả null). check_graphql quét toàn bộ errors serialize, kể cả trường debug. Đây là ca báo xác minh sai có thể tái hiện bằng fixture.
3. unrecognized_response là nhánh gom lỗi: GraphQL error không nhận ra, redirect lạ, lỗi parser/local; trong _read còn có FeedError. Nó không chứng minh tài khoản Facebook bị khóa.
4. _send_reviewed gọi AccountStore.block cho mọi kết quả chưa xác nhận. Đây là bản ghi blocks trong SQLite local, không phải lệnh khóa tài khoản trên Facebook. _read, _sync và recheck cũng có đường tạo hold. HTTP403 ở _read đã được coi là lỗi nguồn; ở các luồng khác vẫn có thể tạo hold cục bộ.
5. Nhật ký thực tế đọc chỉ metadata: kho source có một hold verification_required và một hold unrecognized_response; một lần gần nhất outcome_unknown có write_attempts=1 nhưng không có diagnostic. Cờ write_attempts được đặt trước _try_comment, không chứng minh POST Facebook thực sự đã tới server. Không có raw response để kết luận phản hồi lịch sử chính xác.

## Thay đổi mã nguồn

- Chuyển dấu checkpoint_url/temporarily blocked nằm bất kỳ trong body sang phản hồi chưa xác định, không khẳng định yêu cầu xác minh/hạn chế. Vẫn dừng để kiểm tra, không tự gửi tiếp.
- Chỉ coi redirect xác minh là dấu hiệu phiên khi đúng đường dẫn gốc, host Facebook/tương đối và mã3xx; chuỗi giống đường dẫn hoặc host khác là không rõ.
- GraphQL đọc trường message thực sự; không diễn giải keyword trong debug/path thành khóa nick. Lỗi vẫn dừng.
- HTTP403 ghi phạm vi request. Thông báo lỗi rõ về bài trong GraphQL thêm diagnostic phạm vi request nhưng không thay đổi cơ chế dừng khi kết quả chưa rõ.
- Thông báo và sidebar ghi App tạm dừng; không đồng nghĩa Facebook khóa tài khoản. Lịch sử/report mới có phạm vi và giai đoạn lỗi.
- Diagnostic chỉ có enum bằng chứng, giai đoạn, phạm vi và HTTPstatus. Không lưu body, cookie, URL redirect hay nội dung exception. Diagnostic ở giai đoạn gửi được ghi vào journal; lỗi đọc/sync hiện có trong trạng thái công việc, không phải lịch sử lâu dài.
- Không tự xóa/đổi hold cũ; không tiếp tục hàng đợi; không tăng quyền hoặc sửa phiên của người dùng.

## Kiểm thử và trạng thái bàn giao

147 Python test +16 Node test đạt, JS syntax đạt. Bổ sung ca config null, từ khóa trong nội dung/debug, redirect sai host/path, HTTP403/429, lỗi GraphQL riêng bài, không lộ dữ liệu exception, diagnostic journal và thông báo UI.
Không gọi Facebook để thử gửi/kiểm tra nick trong đợt này.
Đã sửa mã nguồn. EXE/ZIP và tiến trình đang mở vẫn là bản phát hành trước; chưa build hoặc cập nhật bundle ở đợt chẩn đoán này.

---

# Sửa lỗi “Không có thao tác này” — 19/10/2026

Kết quả mới nhất; các phần dưới là lịch sử nghiệm thu.

## Nguyên nhân và thay đổi

Server Python cũ tại 8790 giữ code backend cũ nhưng đọc UI mới từ ổ đĩa. Những API UI mới gọi chưa có trong tiến trình đó.
- Server mới snapshot HTML/CSS/JS lúc khởi động, tránh trộn phiên bản khi cập nhật file.
- /api/state trả UI_PROTOCOL; UI kiểm tra tương thích trước POST, chặn cửa sổ cũ thay vì đợi API 404.
- MO-COMMENT-LAB.cmd mở CommentLab.exe, không còn khởi động Python server cũ.
- EXE đặt trong source có kho hiện hữu dùng lại kho đó; ZIP độc lập vẫn dùng AppData. Không copy/hợp nhất/xóa tài khoản hay nhật ký.
- Không sửa luồng lấy bài, số lượng bài, gửi bình luận hoặc thêm Page.

## Kiểm chứng

- 136 Python test + 14 Node test đạt; JavaScript syntax đạt.
- Regression: giữ UI cũ khi file trên đĩa đổi; từ chối protocol thiếu/sai trước POST; giữ bản nháp khi lệch phiên bản; chọn đúng kho hiện hữu/standalone.
- Chính EXE phát hành: UI/backend protocol khớp; lưu dữ liệu giả; /api/history có mặt; request gửi không hợp lệ trả 400 trước network, không còn 404; mở hai lần một cửa sổ; để chờ 30 giây vẫn hoạt động; đóng/mở lại giữ fixture.
- Mở EXE root trên máy hiện tại: protocol khớp, hai tài khoản hiện hữu vẫn có, không busy. UI chạy từ chính backend EXE: Lịch sử và Hướng dẫn mở thành công. Chạy CMD lần nữa vẫn cùng launcher/port.
- 1002 file runtime root khớp bản dist; EXE và ZIP đối chiếu SHA-256. Không đăng bình luận Facebook thật, không kiểm thử gửi thật trong đợt này.
- Tiến trình Python cũ tại 8790 không bị dừng trong đợt này. Cửa sổ 8790 khi tải lại sẽ bị khóa thao tác do lệch protocol; dùng EXE đang mở. Không khẳng định tiến trình cũ đã được nâng cấp tại chỗ.

## Bàn giao

- EXE: C:\Tools\FacebookCommentLab\CommentLab.exe; giữ _internal đi kèm.
- ZIP: C:\Users\PC\Desktop\CommentLab-Windows-x64.zip (16036743 bytes).
- EXE SHA-256: eace3fc7d5faeef8f602a4b9b2de5cf326c47598673f6d0737ef6adfa8c8dd94
- ZIP SHA-256: bd6950ffb4199c06175f576fa8b7b78b991e0cd40db16bca3b4c3a636bce4170
- Bản cũ: build/previous-release-20261019-135639. Đóng EXE trước khi hoàn tác bundle; không đổi kho dữ liệu.
- Báo cáo máy: dist/desktop-smoke.json và dist/desktop-acceptance.json.
- EXE chưa ký số; chưa kiểm thử trên máy Windows sạch khác.

---

# Bổ sung phân trang và lỗi lệch phiên bản — 19/10/2026

Phần này cập nhật kết quả bản mới; phần dưới lưu nghiệm thu trước đó.

- Nguyên nhân29/50: root group_feed trả30 edges nhưng chỉ29 Story hợp lệ, page_info.has_next_page=true; code trước không đọc tiếp cursor. Chưa thể kết luận số29 là giới hạn nhóm.
- Bản mới tìm query phân trang từ JS asset hiện tại, lấy cursor, giữ group ID/CHRONOLOGICAL, loại trùng. Không hardcode docID, không execute downloadedJS, không gửi cookie tới CDN. Giới hạn10trang và kích thước/thời gian asset; dừng khi đủ số, hết bài, cursor lặp hoặc lỗi.
- Chỉ đọc thật: **50 ID riêng biệt qua8 trang**, thứ tự thời gian giảm dần;0 comment mutation. Nếu không thể lấy đủ hoặc hết bài, báo số thực tế.
- **132 Python +12 Node đạt** trong build mới; thêm ca phân trang trùng cursor/overlap, thiếu resolver, hết nhóm, nguồn khác group, trang lỗi, hủy, giới hạn trang. Frozen acceptance bổ sung /api/history và /api/send/direct để bảo đảm frontend route có trong EXE; gửi rỗng phải400 trước network.
- Lỗi đỏ trên máy: process Python111320 tại8790 khởi động11:06, vẫn chạy code cũ; static UI đọc file mới. POST /api/send/direct và /api/history đều tái hiện404 “Không có thao tác này.” Không gửi comment trong phép thử. Link PlanetRusi là Page/trang cá nhân, không phải /groups/; luồng nhóm không hỗ trợ.
- Đã đổi lỗi404 frontend thành hướng dẫn khởi động lại app đúng bản. Tự động xét duyệt chặn lệnh dừng/restart process111320; chưa dừng backend cũ. Người dùng cần đóng bản cũ và mở EXE mới. Không đổi hoặc xóa kho tài khoản.

Bản phân trang đã build/smoke/desktop acceptance thành công, các API mới hiện diện trong EXE. Root và Desktop ZIP đã đối chiếu hash. ZIP16035303byte, SHA2568e791a2da71ce8bbc61b9695558b3ff87747579c5bab98ca1332cea69e8a4795. EXE SHA2563f4a3a57f73dd77d5950ea96f59946c1ba3602401d900c9e471e0e7e83f82d18.

---

# Nghiệm thu gửi trực tiếp, hướng dẫn và 50 bài — 19/10/2026

## Kết quả bản phát hành này

- Toàn bộ Python: **119/119 đạt**. Node frontend handler: **11/11 đạt**. JavaScript syntax check đạt. Đây là kết quả build mới, không dùng số từ bản trước.
- PyInstaller thành công; smoke trên EXE đạt (`dist/desktop-smoke.json`).
- EXE với Edge thật và LOCALAPPDATA thử riêng: lưu phiên, kiểm tra link, mở hai lần vẫn một backend/cửa sổ, idle30s vẫn hoạt động, kết thúc cây browser thử dừng backend, mở lại giữ dữ liệu. Đạt (`dist/desktop-acceptance.json`). Đây là API/lifecycle acceptance; không gọi việc kết thúc process là click dấu×.
- SHA256 toàn bộ1002 file `_internal` root trùng bundle dist. EXE root và ZIP Desktop trùng bản build.
- Gói quét không chứa private/profiles/.probe/.env, session/cookie JSON hoặc database tài khoản, nhật ký thật.

## Kiểm thử hành vi

Fixture và unit test chặn network ngoài: gửi trực tiếp50 bài không bản duyệt; cùng nội dung ở các bài khác nhau; nhấn lại/đổi nội dung/đổi tài khoản/xóa thêm lại/restart không bỏ khóa cùng bài; khóa xuyên instance, khóa giữa đọc và gửi; dừng khi đang đọc; lỗi sau hai bài thành công dừng47 bài còn lại; metadata tên ghi vào reservation trướcPOST và không lấy trường bí mật ngoài allowlist; phân trang51 bản ghi; giữ tên snapshot sau đổi/xóa tài khoản. Các regression mã hóa, migration, remote status, CSRF/Host/Origin vẫn đạt.

Browser E2E qua CUA tại fixture8796 (mọi external request bị cấm):
- Nhập nhóm, nội dung, chọn50, bấm Gửi trực tiếp → hoàn tất50/50.
- Bấm lại → bỏ qua50 bài, không gửi thêm.
- Xem trước nhóm khác, sửa một bình luận, bỏ chọn một bài rồi gửi9 mục giả lập. Mục đầu trả yêu cầu xác minh → dừng1/9, tám mục còn lại Chưa gửi, tài khoản giữ khóa.
- Lịch sử hiển thị tên tài khoản, tên nhóm, bài, thời gian và kết quả. Trang đầu50, Cũ hơn hiển thị51–51.
- Mở Hướng dẫn và mở phần c_user/xs. Tạo tài khoản fixture, sửa tên với xs trống, xóa bằng xác nhận inline thành công. Không còn hạn chế kiểm chứng click xóa của lượt trước.
- Desktop1366 và mobile360 có captures mới trong `.impeccable/review/`. Mobile scrollWidth=clientWidth=360, không tràn ngang toàn trang.

Impeccable finish reviewer: **ship trong phạm vi UI refinement được giao**, không thay thế audit backend/desktop. Detector chỉ có advisory token tài liệu cũ. Hình đã chụp đúng server thật; CSP chặn inline style nên không được dùng inline style làm bằng chứng ảnh sai.

## Facebook thật — chỉ đọc

Yêu cầu50 bài ở nhóm đã được người dùng cho phép, nhận29 bài riêng biệt và tên nhóm. Không gửi bình luận thật. Số50 là trần xử lý, không bảo đảm nguồn trả đủ50; chưa triển khai phân trang tiếp theo cho bộ đọc feed. Joined groups vẫn chỉ trang đầu và báo một phần khi còn trang sau.

Bài cũ ngoài danh sách mới nhất chưa có reader độc lập; Page/share/pfbid chưa hỗ trợ. Không coi đọc thành công là quyền gửi đã được phục hồi. EXE chưa ký số và chưa nghiệm thu trên máy sạch khác.

## Bàn giao

- EXE: `C:\Tools\FacebookCommentLab\CommentLab.exe`; giữ `_internal` cạnh EXE.
- ZIP: `C:\Users\PC\Desktop\CommentLab-Windows-x64.zip`,16028144 byte.
- ZIP SHA256: `64b47f61043a7991083e61f117cf02b1c3b9bf9e768595b3c8cc878a1e640614`.
- EXE SHA256: `cb44df6fccd759ecb87c2a90a71148defb81854cff124a3378315e288ac0b270`.
- Bundle cũ được giữ tại `build/previous-release-20261019-113126`.
- Hướng dẫn sử dụng: `HUONG-DAN-GIAO-DIEN.md`, nút Hướng dẫn trong app. Bàn giao kỹ thuật: `HandoffPrompt.md`, PRODUCT.md.

Không sửa ASSETCONTROL/Kanban, không thêm dependency production, không commit/push. Không thay đổi dữ liệu tài khoản thật khi kiểm thử. Source và desktop có kho riêng; khóa chống trùng không tự hợp nhất giữa hai kho.
