## Cập nhật 2026.10.19.4 — xác nhận bỏ qua bài chưa rõ kết quả

- Trong Lịch sử → Chi tiết, mở link Bài cần kiểm tra. Sau khi tự kiểm tra, bấm **Đã kiểm tra — bỏ qua bài này** rồi xác nhận.
- Giữ nguyên kết quả chưa rõ và khóa chống gửi trùng bài trên mọi tài khoản trong kho. Ghi nhận riêng hành động kiểm tra; không tự đánh dấu thành công/thất bại và không tự gửi tiếp lượt cũ.
- Chỉ gỡ app hold tương ứng khi mọi lần gửi chưa rõ của tài khoản đã được xử lý và không có lỗi phiên, xác minh hoặc hạn chế khác. Không bỏ khóa tài khoản do Facebook yêu cầu xác minh/hạn chế.
- Ghi nhận kiểm tra và gỡ app hold trong cùng transaction SQLite; lỗi ghi giữ nguyên trạng thái. Kiểm tra đúng account, revision phiên, operation và post; không cho thao tác khi request khác đang chạy.
- Kiểm tra phiên chỉ xác nhận khả năng đọc, không xác minh kết quả bình luận trước.
- ZIP có Python và thư viện đóng gói trong _internal. Không cần repo hoặc venv; cần Windows x64 và Microsoft Edge. Giải nén toàn bộ trước khi mở EXE.
- Máy/người dùng Windows mới tự lưu dữ liệu riêng. Không sao chép kho cookie DPAPI để chuyển tài khoản sang máy khác; nhập phiên lại trên máy đó. Chưa có backup thật.
- Cổng phát hành mới kiểm tra chính ZIP giải nén ngoài repo, từ thư mục chạy trống, xóa biến Python/venv và PATH Python của tiến trình app. Đây không thay thế nghiệm thu trên máy vật lý/VM Windows sạch khác.

## Cập nhật 2026.10.19.3 — đọc đầy đủ nhóm

- Sửa nguyên nhân chỉ lấy trang đầu: dùng cursor của all_joined_groups.tab_groups_list, tiếp tục đến has_next_page=false. Truy vấn chỉ đọc được xác minh từ public JS của chính trang hiện tại, không hardcode docID, không lấy nhóm gợi ý/chờ duyệt.
- Đã kiểm chứng thật bằng thao tác chỉ đọc: tài khoản đang chọn trả 371 nhóm duy nhất qua 19 trang, stop_reason=exhausted, complete=true. Không đăng bình luận, không ghi cookie hoặc raw phản hồi vào tài liệu.
- Đồng bộ vẫn chạy nền; cập nhật số nhóm/số trang sau mỗi trang; có Dừng giữa các request. Kiểm tra revision và jobID trước khi công bố kết quả. Lỗi giữa chừng giữ danh sách đã lưu trước đó.
- Không giả phần trăm khi chưa biết tổng. Cursor lặp, không nhận diện query hoặc giới hạn bảo vệ 500 trang luôn báo chưa đầy đủ, không coi là thành công toàn bộ.
- Lỗi đọc/parser dừng lượt hiện tại nhưng không tạo app hold lâu dài. Dấu hiệu phiên/xác minh/hạn chế vẫn dừng và được lưu riêng. Không tự xóa hold cũ thiếu bằng chứng.
- Thông báo app hold có nút Xem lịch sử; Kiểm tra khả năng đọc không được trình bày là xác nhận kết quả gửi trước hoặc mở khóa gửi. Bản lịch sử cũ thiếu diagnostic không thể suy ra chính xác phản hồi Facebook.
- Không thay cơ chế gửi, chống trùng, không retry và khóa kết quả chưa rõ sau POST. Không có backup thật.
- Sau khi cài bản mới, bấm Đồng bộ lại để cập nhật danh sách cũ; không cần nhập lại cookie chỉ để kích hoạt đồng bộ.

## Bản 2026.10.19.2 — giao diện và đồng bộ nền

- Giao diện app thật có panel tài khoản, panel nhóm/nhập link riêng và vùng soạn thảo. Hướng dẫn, lịch sử và chi tiết kết quả vẫn có; không thêm backup thật.
- Lưu tài khoản mới hoặc thay cookie tự xếp lịch đồng bộ nhóm. Đổi tên không gây đồng bộ lại. Có Dừng và Đồng bộ lại; không chạy lại công việc dở khi mở app.
- Đồng bộ chạy nền: tiếp tục soạn, xem lịch sử, thêm/chuyển tài khoản. Thao tác mạng được xếp tuần tự; gửi/lấy bài chờ đồng bộ đang chạy để không chồng request. Khi chưa biết tổng nhóm, thanh tiến độ không hiển thị phần trăm giả.
- Kết quả gắn tài khoản, revision phiên và mã công việc; sửa phiên/xóa tài khoản khiến kết quả cũ không được ghi trở lại. Lỗi đồng bộ không xóa nhóm đã lưu.
- Bộ đọc joined groups hiện chỉ xác minh trang đầu; có trang sau thì báo một phần. Chưa khẳng định đọc đủ danh sách và chưa kiểm chứng Facebook thật trong lượt nghiệm thu này.
- Bản nháp, link và lựa chọn nhóm giữ riêng theo tài khoản trong phiên trang hiện tại; thu gọn/mở lại vẫn giữ. Tải lại trang không phải lưu bản nháp lâu dài.
- Lỗi bài/nguồn, dấu hiệu phiên và app tạm dừng được trình bày riêng. Bài được xác nhận không có quyền bình luận trước POST được bỏ qua. Lỗi chuẩn bị trước POST là chưa gửi; không tự báo tài khoản bị khóa.
- Sau POST mà chưa biết kết quả: dừng lượt, giữ khóa bài và app hold; không retry, không bỏ khóa khi sửa cookie. Chỉ bằng chứng hết phiên/xác minh/hạn chế mới được lưu là session issue. HTTP 200 không đủ xác nhận thành công.
- Lịch sử giữ tên tài khoản/nhóm tại thời điểm xử lý; có tìm kiếm và lọc trong trang lịch sử, mở panel chi tiết. Không ghi cookie/raw response vào chẩn đoán.
- Mỗi kho chỉ có một lượt gửi; chống trùng xuyên tài khoản và khởi động lại giữ nguyên.

## Cách mở bản mới sau sửa lỗi phiên bản — 19/10/2026

Mở CommentLab.exe hoặc MO-COMMENT-LAB.cmd trong C:\Tools\FacebookCommentLab.
EXE tự mở đúng cổng local; không dùng lại bookmark 8790. Giữ _internal cạnh EXE.
Bản EXE trong source tiếp tục dùng kho tài khoản hiện có tại đó; không cần nhập lại.
Bản ZIP giải nén độc lập dùng AppData như trước; không tự hợp nhất hai kho.
Nếu cửa sổ cũ báo khác phiên bản, đóng cửa sổ đó và dùng cửa sổ EXE mới.

# Sử dụng CommentLab

## Gửi bình luận

1. Chọn tài khoản bên trái.
2. Dán mỗi dòng một link nhóm hoặc bài trong nhóm. Có thể chọn thêm nhóm đã lưu.
3. Chọn giới hạn 10, 20 hoặc 50 bài **tổng cộng** và nhập nội dung.
4. Bấm **Gửi bình luận**. App tự đọc bài, bỏ qua bài đã xử lý và gửi tuần tự.

**Xem trước là tùy chọn**: dùng khi muốn đọc trích đoạn, bỏ chọn bài hoặc sửa nội dung riêng. Bấm **Gửi các bài đã chọn** để gửi; không cần đánh dấu duyệt. Thay nhóm, số bài hoặc nội dung chung làm bản xem trước cũ mất hiệu lực. Bản xem trước ở server có hạn 10 phút.

Số đã chọn là mức tối đa, không bảo đảm Facebook trả đủ bài. Bản mới đọc tiếp qua các trang; kiểm tra chỉ đọc ngày 19/10/2026 đã lấy đủ50 bài riêng biệt qua8 trang. Nếu nhóm có ít bài truy cập được hoặc không đọc tiếp được, app báo số thực tế; không bịa hoặc lặp bài.

Nếu báo “giao diện và chương trình khác phiên bản”, đóng bản cũ rồi mở EXE mới và tải lại trang. Link dạng facebook.com/TenPage không phải link nhóm; bản này chưa hỗ trợ Page.

## Tài khoản và lấy phiên

Bấm **Hướng dẫn** ở đầu app; cách lấy phiên cũng nằm trong form thêm/sửa tài khoản.

Trên Chrome đăng nhập Facebook của bạn, mở F12 hoặc Ctrl+Shift+I → Application → Cookies → https://www.facebook.com. Tìm giá trị `c_user` và `xs`, nhập vào app trên máy của bạn. Không gửi xs qua chat, chụp ảnh hoặc chia sẻ. App không tự đọc cookie Chrome. Cookie bổ sung datr/fr/sb không bắt buộc; có thể nhập JSON dạng danh sách cookie.

**Sửa**: để trống xs giữ phiên cũ. Nhập ID khác tạo tài khoản mới, không chuyển nhóm/lịch sử. **Xóa** yêu cầu xác nhận trong app; xóa phiên/nhóm, giữ lịch sử và khóa chống trùng. Đang đọc/gửi không chuyển hoặc sửa tài khoản. Lưu phiên chưa có nghĩa đã xác thực Facebook.

## Nhóm và link

**Kiểm tra & lưu nhóm** hiển thị lỗi từng dòng. Hỗ trợ link HTTPS facebook.com/groups/… và bài /posts/ID hoặc /permalink/ID. Page, share và pfbid chưa hỗ trợ. Bài cụ thể phải đọc được trong danh sách mới nhất; bài cũ ngoài danh sách chưa có bộ đọc độc lập.

**Đồng bộ nhóm** đọc tiếp theo cursor đến trang cuối đã xác minh. Nếu lỗi giữa chừng, báo kết quả một phần; không lấy nhóm gợi ý làm nhóm đã tham gia. Lỗi không xóa danh sách cũ. Có thể bổ sung link thủ công.

## Lịch sử, dừng và chống trùng

Lịch sử ghi **tên tài khoản, ID, tên nhóm, link bài, thời gian, trạng thái**. Tên được lưu trước khi gửi nên vẫn còn khi đổi tên hoặc xóa tài khoản. Bản cũ thiếu metadata ghi rõ chưa lưu tên; tên tài khoản được tra hiện tại có nhãn “tên hiện tại”. Dùng **Mới hơn / Cũ hơn** để xem từng trang 50 bản ghi.

Bài đã xử lý, đang gửi hoặc chưa rõ kết quả bị khóa trên mọi tài khoản của kho, kể cả đổi nội dung. Có thể dùng cùng nội dung cho các bài khác nhau; chống trùng ở đây ngăn gửi lại cùng bài.

**Dừng** chờ request đang chạy rồi bỏ phần còn lại. Lỗi/timeout/xác minh/hạn chế dừng lượt, không tự retry hoặc đổi tài khoản. Không tự tiếp tục sau khởi động lại. Khi chưa rõ kết quả, kiểm tra trên Facebook trước; app không có nút bỏ qua khóa để gửi lại.

## Dữ liệu

EXE lưu tại `%LOCALAPPDATA%\CommentLab`. Cookie mã hóa Windows DPAPI. Bản nguồn và desktop có kho riêng; không dùng hai kho để gửi trùng. Không xóa nhật ký để né chống trùng. Đổi máy/người dùng Windows cần nhập lại phiên. Giữ `_internal` cạnh EXE.

Kiểm tra phiên chỉ đọc lại nhóm. Chỉ khóa hết phiên được gỡ khi đọc thành công; khóa hạn chế/xác minh/chưa rõ kết quả tiếp tục giữ. Đọc thành công không chứng minh được phép gửi trở lại.
