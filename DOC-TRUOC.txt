COMMENTLAB 2026.10.19.4 — WINDOWS x64

MỞ APP
1. Giải nén toàn bộ ZIP ra một thư mục.
2. Mở CommentLab.exe, giữ nguyên thư mục _internal bên cạnh.
Không cần Python, venv, repo, Docker hoặc VPS. Cần Microsoft Edge.
Không mở EXE trực tiếp bên trong ZIP hoặc chỉ chép riêng EXE sang máy khác.
Mở EXE lần nữa dùng lại cửa sổ đang chạy. Không cần giữ cửa sổ điều khiển.
Không dùng bookmark cổng local cũ; EXE tự chọn cổng trống.

CÁCH DÙNG
- Thêm tài khoản bằng tên, c_user và xs hoặc nhập JSON. Để trống xs khi sửa để giữ phiên.
- Nhóm đồng bộ ở nền; vẫn soạn và xem lịch sử được. Đồng bộ đọc qua các trang,
  chỉ báo đầy đủ khi xác minh trang cuối; lỗi giữa chừng báo một phần.
- Chọn nhóm hoặc dán link từng dòng, nhập nội dung. Xem trước là tùy chọn.
- Tối đa 10/20/50 bài tổng cộng mỗi lượt, tùy số bài thực tế đọc được.
- Hướng dẫn trong app có cách lấy phiên và dùng các chức năng.
- Đóng app dừng lượt; mở lại không tự tiếp tục gửi.

LẦN GỬI CHƯA RÕ KẾT QUẢ
Lịch sử → Chi tiết → Bài cần kiểm tra. Tự mở đúng bài để kiểm tra trước.
Bấm “Đã kiểm tra — bỏ qua bài này”, rồi “Xác nhận bỏ qua”.
Bài vẫn bị chặn gửi lại; kết quả vẫn là chưa rõ, có ghi nhận đã kiểm tra.
Tài khoản dùng tiếp khi không còn lần chưa xử lý hoặc lỗi phiên/hạn chế khác.
Không tự gửi tiếp hàng đợi cũ. Nếu còn lần chưa rõ khác, xử lý từng lần.
Nút này không gỡ yêu cầu xác minh/hạn chế Facebook; kiểm tra đọc không chứng minh
kết quả bình luận trước hoặc khả năng gửi hiện tại.

DỮ LIỆU
ZIP không chứa tài khoản, cookie hoặc lịch sử thật.
Bản ZIP lưu tại %LOCALAPPDATA%/CommentLab. Máy mới cần nhập phiên riêng.
Ngoại lệ: EXE đặt trong repo đã có scripts/lab_server.py và private/accounts.sqlite3
sẽ dùng nguyên dữ liệu đó, không di chuyển hoặc hợp nhất với AppData.
Cookie mã hóa DPAPI gắn với người dùng Windows. Không chuyển database cookie
 giữa các máy; không dùng nhiều kho khác nhau để né chống trùng.
Nhật ký .probe/attempts.sqlite3 được giữ khi xóa tài khoản. Chưa có backup thật.

KIỂM THỬ PHÁT HÀNH
Quy trình kiểm tra chính ZIP giải nén ngoài repo, đường dẫn có dấu/khoảng trắng,
thư mục chạy trống, không có biến/PATH Python hoặc venv trong tiến trình app.
Kiểm tra runtime đóng gói, API, một cửa sổ, để chờ và đóng/mở giữ dữ liệu giả.
Chưa nghiệm thu trên máy vật lý/VM Windows sạch khác; không bảo đảm mọi máy.
EXE chưa ký số. Nền fbkit MIT; xem LICENSE và THIRD-PARTY-LICENSES.txt.
