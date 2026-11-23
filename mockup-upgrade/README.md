# CommentLab — mockup độc lập

Mở index.html trực tiếp hoặc chạy static server chỉ tại thư mục này:

`python -m http.server 8793 --bind 127.0.0.1 --directory C:\Tools\FacebookCommentLab\mockup-upgrade`

Không import module app thật, không dùng API, cookie, localStorage hoặc IndexedDB.
CSP chặn kết nối bằng `connect-src 'none'`. Mọi tài khoản, kết quả, bản nháp và
backup là dữ liệu mẫu trong bộ nhớ. Reload đặt lại bản thử.

Luồng thử: sửa bản nháp → đổi tài khoản → quay lại → đóng/mở soạn thảo;
mở bốn kết quả lỗi; tìm/lọc lịch sử; tạo backup → đổi bản nháp → khôi phục;
Hủy/Escape/backdrop phải đóng panel hoặc hộp xác nhận mà không thay dữ liệu.

Không sửa app, dữ liệu người dùng hoặc EXE/ZIP. Không có nút gửi Facebook.

## Bố cục nhóm và đồng bộ nền

- Chọn tài khoản → chọn nhóm trong panel riêng hoặc chuyển sang Gắn link → soạn nội dung.
- Thêm tài khoản chỉ nhập tên mẫu; không có bước nhập cookie thật. Lưu tự bắt đầu tiến độ đồng bộ giả lập 12 nhóm, khoảng 28 giây khi tab hoạt động.
- Có thể đổi tài khoản, xem lịch sử hoặc soạn thảo trong lúc chạy; tiến độ vẫn hiển thị dưới tài khoản. Có Tạm dừng/Tiếp tục và Đồng bộ lại.
- Nhóm, lựa chọn, link nháp và nội dung được giữ riêng từng tài khoản trong bộ nhớ trang. Link được kiểm tra định dạng và trùng ngay trên máy; không tải nội dung link.
- Giữ nguyên dữ liệu giả và CSP connect-src none. Không kết nối Facebook, đọc tài khoản thật hoặc sửa app thật.
