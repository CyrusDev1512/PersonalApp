## Cổng bổ sung 2026.10.19.4

- `python -m unittest tests.test_review_outcome -v`: 11 ca, có giữ chống trùng qua mở lại, các lần chưa rõ cùng tài khoản, giữ lỗi phiên/hạn chế, xác nhận lặp, sai tài khoản/revision, lỗi ghi rollback và lần reserved sau crash.
- `node --test tests/ui_workspace.test.cjs`: xác nhận riêng đúng bài/account, không gửi request comment, nhấn đúp, lỗi giữ dialog và lịch sử ghi nhận bỏ qua.
- `python -m scripts.build_desktop`: chạy full suite + syntax + build + frozen smoke + ZIP portable acceptance.
- `python -m tests.portable_release dist/CommentLab-Windows-x64.zip dist/portable-acceptance.json`: dùng chính archive, kiểm tra SHA-256, giải nén thư mục ngoài repo có dấu/khoảng trắng; child EXE chạy cwd trống, PATH System32 và không có biến Python/venv. Cha harness dùng Python chỉ để điều khiển test, không phải runtime của app.
- Kiểm tra runtime EXE xác nhận sys.path nằm trong bundle và python312.dll kèm theo. Kiểm tra CSRF và API xác nhận bỏ qua bằng dữ liệu giả trong chính frozen EXE.
- Desktop acceptance dùng Edge thật và dữ liệu tạm riêng, cấm mọi request Facebook. Kiểm tra hai lần mở chỉ một cửa sổ, idle 30 giây, lưu phiên và mở lại.
- Đây là thử môi trường tách biệt trên máy hiện tại, chưa phải máy vật lý hoặc VM Windows sạch khác.

# Bản thử một bình luận qua HTTP trực tiếp

## Trạng thái

- **Đã chốt:** sửa hai lỗi của fbkit, chuẩn bị phép thử đơn lẻ bằng tài khoản cá nhân và bổ sung giao diện local tiếng Việt.
- **Đã thực hiện:** bản làm việc tại `C:\Tools\FacebookCommentLab`, dựa trên [drpwchen/fbkit](https://github.com/drpwchen/fbkit), commit `96627e5c919ab65cb3ae440507d2edeb09d8479c` (v0.11.1). Bản Desktop cũ được giữ; không chạy song song hai bản.
- Giao diện: chạy `MO-COMMENT-LAB.cmd`; xem `HUONG-DAN-GIAO-DIEN.md` để chuẩn bị phiên và xem trước.
- **Chưa kiểm chứng:** đăng bình luận thành công trong nhóm Facebook thật. Không có request Facebook nào được gửi trong quá trình chuẩn bị/kiểm thử.
- Không commit/push, không triển khai VPS, không sửa ASSETCONTROL/MREkanban. Giữ nguyên giấy phép MIT và thông tin tác giả upstream.

## Những gì đã sửa

1. `_create_comment()` chỉ gửi một lần, kể cả khi caller cũ truyền `attempts=3`. Phản hồi thiếu dữ liệu không còn tự động tạo lần gửi mới. Tham số chờ ban đầu của caller cũ vẫn được giữ.
2. `graphql_request()` đọc và ghép toàn bộ phản hồi: JSON đơn, JSON nhiều phần, phần bổ sung theo `path`, `incremental`, danh sách và lỗi xuất hiện ở phần sau. Phản hồi bị cắt không được coi là thành công.
3. Kiểm tra thành công cần ID và nội dung khớp chính xác. Không chấp nhận nội dung rỗng hoặc chỉ khớp một phần.
4. HTTP POST không đi theo redirect để tránh tự gửi lại hoặc đọc nhầm trang đăng nhập.
5. Lệnh thử `scripts.comment_probe` thêm nhật ký SQLite để giữ lần thử qua các lần chạy/khởi động lại. Cùng tài khoản, bài và nội dung đã được ghi nhận sẽ không gửi lại, ngay cả khi đổi mã lần thử.

Không sửa các chức năng khác của fbkit. Hướng dẫn retry ba lần trong tài liệu upstream không áp dụng cho bản thử này; yêu cầu mới nhất là không tự gửi lại khi kết quả chưa rõ.

## Chuẩn bị

Máy hiện tại đã có Python 3.12, `requests` và `python-dotenv`; không cài thêm thư viện. Luồng thử không import hoặc chạy Playwright. Không cần Docker, VPS hay API key AI.

Cần cung cấp riêng:

- Một bài trong nhóm bạn quản lý hoặc được phép thử; tài khoản có quyền bình luận vào bài đó.
- Nội dung duy nhất sẽ dùng cho bình luận thử.
- ID tài khoản cá nhân dự định sử dụng.
- File phiên JSON dạng danh sách cookie, do bạn chủ động cung cấp tại máy. Để trong thư mục `private/` (được Git bỏ qua). **Không dán cookie/token/mật khẩu vào chat hoặc dòng lệnh.** Không tự quét hay lấy phiên từ Chrome.

File phiên chỉ được đọc khi dùng `--send`; phải khớp ID đã chọn. Phiên có dấu hiệu chuyển sang Page bị từ chối. Nếu phiên hết hạn hoặc gặp checkpoint, dừng để người dùng xử lý đăng nhập bình thường; không có cơ chế vượt xác minh.

## Xem trước — không truy cập mạng

Mở PowerShell tại thư mục bản thử. Ví dụ dưới đây dùng ID giả:

```powershell
Set-Location 'C:\Tools\FacebookCommentLab'
python -X utf8 -m scripts.comment_probe --target 'https://www.facebook.com/groups/123/posts/456/' --text 'Nội dung thử đã duyệt'
```

Kết quả phải là `preview_only`, `network_requests: 0`. Có thể dùng `--message-file .\private\noi-dung.txt` thay cho `--text` để nhập văn bản UTF-8 nhiều dòng.

Đầu vào hỗ trợ ID bài dạng số, hoặc URL HTTPS `/groups/<nhóm>/posts/<ID số>/` và `/groups/<nhóm>/permalink/<ID số>/`. Link rút gọn `/share/` và ID `pfbid...` chưa được giải mã. Không đoán ID từ link không hỗ trợ.

## Gửi thật — chỉ sau khi đã duyệt bài, tài khoản và nội dung

Mẫu lệnh dưới đây có giá trị giữ chỗ, chưa chạy:

```powershell
python -X utf8 -m scripts.comment_probe --target '<LINK_BAI_DA_DUYET>' --message-file '.\private\noi-dung.txt' --cookies '.\private\session.json' --expected-user-id '<ID_CA_NHAN_DA_DUYET>' --send
```

- Có GET kiểm tra phiên trước, tối đa một POST bình luận.
- Không tự tham gia nhóm, không quét hàng loạt, không đổi danh tính và không dùng trình duyệt để gửi.
- Nhận URL nhóm chỉ giúp trích ID bài. Payload bình luận giữ ngữ cảnh upstream (`groupID=null`), chưa thêm tham số group bằng phỏng đoán. Cơ chế này còn phải thử với Facebook thật.
- Mã thao tác được dùng làm mã chống trùng trong request và ghi vào nhật ký trước khi gửi. Đây không phải cam kết Facebook luôn đảm bảo exactly-once; bản thử không tự replay để giảm nguy cơ trùng khi mất mạng.

## Đọc kết quả

| Trạng thái | Ý nghĩa và việc cần làm |
|---|---|
| `preview_only` | Chỉ xem trước; chưa đọc phiên hoặc truy cập mạng. |
| `not_sent` | Không vượt qua kiểm tra đầu vào/phiên hoặc đã có lần thử trùng; lần chạy hiện tại không gửi POST mới. |
| `confirmed_by_response` | Facebook trả ID bình luận và đúng nội dung. Cần mở bài để xác nhận tác giả và hiển thị; chưa chứng minh nhóm đã duyệt hoặc người khác nhìn thấy. |
| `unconfirmed` | Phản hồi thiếu dữ liệu, có lỗi hoặc chưa đủ các phần. Có thể đã đăng; không chạy lại. |
| `outcome_unknown` | Timeout/lỗi sau khi bắt đầu gửi. Có thể đã đăng; kiểm tra bài trước. |
| `reserved` trong nhật ký | Đã dành chỗ trước POST nhưng chưa ghi được kết quả, có thể do tiến trình bị ngắt. Không gửi lại. |

Exit code: `0` cho xem trước/đọc báo cáo/xác nhận theo response; `2` khi không gửi; `3` khi kết quả chưa rõ. Không dùng riêng exit code để kết luận đã đăng.

Xem lại báo cáo không truy cập Facebook:

```powershell
python -X utf8 -m scripts.comment_probe --report '<OPERATION_ID_TRONG_KET_QUA>'
```

Nhật ký nằm trong `.probe/attempts.sqlite3`, lưu mã thao tác, ID tài khoản/bài, hash nội dung và trạng thái. Không lưu cookie, token hoặc raw response. Không xóa nhật ký để ép gửi lại. Với kết quả chưa rõ, cần kiểm tra bài thủ công trước khi quyết định phép thử mới.

## Kiểm thử đã chạy

```powershell
python -m unittest discover -s tests -v
python -m compileall -q scripts tests
git diff --check
```

29 ca unittest đạt ngày 17/10/2026. Có kiểm thử luồng HTTP bằng response giả, lỗi nhiều phần, timeout, redirect, kiểm tra danh tính, khóa lần thử trùng và hai kết nối SQLite đồng thời. Các test chặn network; không dùng tài khoản thật. Kiểm tra cú pháp Python và whitespace đạt.

Điều kiện nghiệm thu live còn thiếu: một bình luận xuất hiện đúng bài nhóm, đúng tài khoản cá nhân, đúng nội dung; reload còn tồn tại, xác định trạng thái duyệt; không có bình luận trùng. Chỉ kết luận hỗ trợ group sau khi có kết quả này.
