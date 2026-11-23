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

# Product

## Yêu cầu tương thích desktop — đã chốt 19/10/2026

Mở app phải dùng giao diện và backend tương thích. App chặn thao tác ngay khi
phát hiện lệch phiên bản; không đợi người dùng thao tác rồi mới báo API không tồn tại.
Server giữ bộ file giao diện lúc khởi động. Launcher CMD mở cùng EXE.
Bản EXE nằm trong checkout có kho tài khoản hiện hữu tiếp tục dùng kho đó,
không chuyển hoặc hợp nhất dữ liệu; bản ZIP độc lập tiếp tục dùng AppData.

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Python + requests, HTTP server thư viện chuẩn, HTML/CSS/JavaScript thuần. Windows desktop x64: PyInstaller onedir, một cửa sổ Edge app. SQLite và DPAPI qua thư viện chuẩn; không thêm dependency production ở đợt này.

## Users

Người vận hành nhiều tài khoản Facebook cá nhân của mình, chọn nhóm/bài và gửi nội dung; xem trước tùy chọn.

## Product Purpose

Tài khoản → Nhóm/nhập link và bình luận → Gửi → Lịch sử; Xem trước tùy chọn. Hướng dẫn luôn có ở đầu trang. Một lượt gửi trên mỗi kho dữ liệu tại một thời điểm; đồng bộ có hàng chờ nền riêng và dùng khóa mạng chung; không đổi tài khoản để tiếp tục khi bị hạn chế. Giao diện gọn theo mockup đã được người dùng chấp thuận.

## Operating Context

Dự án riêng C:\Tools\FacebookCommentLab. Không sửa ASSETCONTROL/Kanban. Windows chạy cục bộ, không Docker/VPS. EXE đi cùng _internal, cần Edge. Đóng cửa sổ dừng hàng đợi và chờ request đang chạy. Mở lần hai dùng lại cửa sổ. Dữ liệu desktop tại %LOCALAPPDATA%\CommentLab; bản nguồn có kho riêng, không tự trộn lịch sử.

## Capabilities and Constraints

- Tạo, sửa, chọn, xóa tài khoản; c_user duy nhất. xs để trống khi sửa giữ phiên cũ. Thay ID tạo danh tính mới. Nhập JSON và cookie bổ sung được giữ.
- Cookie mã hóa DPAPI theo người dùng Windows. API metadata không trả cookie. Lần đầu chuyển session.json cũ và chỉ xóa bản rõ sau khi đọc lại dữ liệu mã hóa thành công. Xóa tài khoản giữ nhật ký và trạng thái khóa.
- Mỗi tài khoản có nhóm riêng; đồng bộ joined groups với actorID và viewer_join_state MEMBER được xác minh; đọc tiếp theo cursor đến has_next_page=false. Lỗi hoặc giới hạn đọc báo một phần. Lỗi không xóa danh sách cũ.
- Mỗi dòng một link HTTPS nhóm/bài; không hỗ trợ Page/share/pfbid. Kiểm tra từng dòng, chuẩn hóa posts/permalink và loại trùng bài. Chọn tối đa 10/20/50 bài toàn lượt, không nhân theo số nhóm. Nguồn có thể trả ít hơn; hiển thị số thực tế, không tuyên bố đủ 50.
- Link bài cụ thể được đối chiếu trong 10/20/50 bài mới nhất của nhóm. Nếu không có nội dung ở đó, báo lỗi và chưa đưa vào gửi; chưa có bộ đọc mọi bài cũ độc lập.
- Gửi trực tiếp bằng nội dung chung; không bắt buộc duyệt. Xem trước tùy chọn để bỏ chọn bài hoặc sửa nội dung riêng. Backend vẫn đóng băng tài khoản, revision phiên, bài và nội dung, hạn 10 phút khi xem trước. Thay nguồn/nội dung chung hủy bản xem trước cũ. Không tạo nội dung giả, không tự tạo nội dung bằng AI.
- Chặn bài đã được xử lý/đang gửi/chưa rõ kết quả trên mọi tài khoản của kho; thay nội dung không bỏ khóa. Có thể dùng cùng nội dung cho các bài khác nhau; khóa trùng áp dụng theo bài xuyên tài khoản, không cấm nội dung chung đã được người dùng yêu cầu. Nhật ký cũ thiếu content_hash vẫn giữ khóa bài nhưng không tái dựng được nội dung cũ.
- Ghi reservation trước POST, không retry, không coi HTTP 200 là thành công. Checkpoint/hạn chế lưu session issue; unknown lưu app hold qua khởi động lại; đổi cookie không xóa khóa. Kiểm tra đọc chỉ gỡ session_expired, không chứng minh hết hạn chế gửi.
- Lịch sử lưu snapshot tên tài khoản và nhóm trước POST; phân trang 50 bản ghi. Bản cũ thiếu metadata ghi rõ, không đoán tên.
- Nút Dừng chờ request hiện tại; mở lại không tự tiếp tục. Không cam kết khoảng chờ giúp tránh khóa Facebook.
- Không gửi bình luận Facebook thật trong đợt nghiệm thu; request thực chỉ đọc. Nền fbkit dùng request nội bộ Facebook, không phải API Meta công khai.
- Feed đọc tiếp bằng cursor và query phân trang lấy từ asset JS hiện tại; không hardcode docID, không thực thi JS tải về. Loại trùng ID, chỉ lấy feed đúng group ID, giữ CHRONOLOGICAL; dừng khi đủ số, hết bài, lỗi, lặp cursor hoặc giới hạn10 trang. Metadata báo số trang và lý do dừng. Joined groups vẫn chỉ trang đầu.

## Evidence on Hand

Kết quả chạy mới nhất ghi ở KET-QUA-KIEM-THU-UI.md và dist/desktop-smoke.json, dist/desktop-acceptance.json. Không dùng số test lịch sử thay cho chạy lại. Joined groups đã được khảo sát chỉ đọc: trang đầu 20 MEMBER, có trang sau; không tuyên bố đồng bộ đủ.

## Product Principles

Người vận hành biết rõ tài khoản, bài và nội dung; trạng thái có bằng chứng; bí mật giữ trên máy; kết quả chưa rõ không tự gửi lại; giao diện ít chữ và không che giấu giới hạn.

## Phân biệt thông báo tạm dừng — đã triển khai trong nguồn

App phải phân biệt phạm vi bài/nguồn, phiên/tài khoản và chưa xác định. Không trình bày hold nội bộ như bằng chứng tài khoản bị Facebook khóa. Nhận diện không chắc chắn vẫn dừng và giữ kết quả chưa rõ; không tự xóa hold lịch sử. Diagnostic không chứa bí mật hoặc raw response.
