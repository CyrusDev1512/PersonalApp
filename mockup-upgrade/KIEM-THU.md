# Kiểm tra mockup — 19/10/2026

Đã thử trực tiếp bằng trình duyệt tại http://127.0.0.1:8793/.

- Bản nháp giữ riêng khi đổi tài khoản, đóng/mở soạn thảo; xem trước và lưu hoạt động.
- Bốn panel lỗi hiển thị phạm vi, giai đoạn, dữ kiện và phần chưa xác nhận; Escape đóng panel.
- Lịch sử lọc kết hợp tài khoản/kết quả, tìm kiếm, trạng thái rỗng và xóa bộ lọc hoạt động.
- Tạo backup mẫu, xem chi tiết, hủy khôi phục giữ nội dung mới; xác nhận khôi phục trả đúng bản nháp đã lưu.
- Tải lại đặt lại backup và bản nháp. Hướng dẫn mở rộng hoạt động. Kiểm tra kết nối chỉ mô phỏng.
- Desktop 1280px và cửa sổ hẹp 360px: không tràn ngang; kiểm tra màn hình soạn thảo, lịch sử, cài đặt và panel lỗi.
- JavaScript syntax check đạt; trình duyệt không ghi nhận console warning/error trong lượt kiểm tra.
- Chạy một lượt detector Impeccable: có khuyến nghị về thang màu/cỡ chữ/bo góc của thiết kế app thật. Mockup giữ biến thể nhỏ riêng; bóng đã đổi sang màu trung tính.

Một lượt chỉnh cuối: giữ xuống dòng trong xem trước, đổi tiêu đề panel chung thành “Chi tiết”, bóng trung tính.

Không kiểm thử backend hoặc Facebook: bản này không có tích hợp đó. Không sửa app thật, EXE hoặc ZIP.

## Kiểm tra cập nhật panel nhóm

- Thêm Hoàng Nam: tiến độ bắt đầu; chuyển sang Lịch sử thấy 40%, sang Minh An gắn link thấy tiến độ tài khoản cũ tăng 55%; quay lại Hoàng Nam thấy 95% và nội dung đã gõ còn nguyên. Đồng bộ hoàn tất 12 nhóm mẫu.
- Nhập một link nhóm, bản trùng có tham số, và một dòng sai: thêm đúng một nguồn, nhận diện bản trùng và báo lỗi dòng 3.
- Danh sách nguồn của Minh An và Hoàng Nam riêng biệt; có tìm kiếm và chọn nguồn cho bản nháp.
- Tạm dừng có trạng thái riêng; Tiếp tục giữ tiến độ hiện tại. Cập nhật tiến độ không render lại textarea.
- Desktop và 360px không tràn ngang. Layout detector không có finding; JS syntax check đạt.
- Không kiểm tra API đồng bộ thật; các con số tiến độ là dữ liệu mô phỏng.
