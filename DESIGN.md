---
name: CommentLab
description: "Bàn thao tác nhiều tài khoản, gửi trực tiếp với xem trước tùy chọn."
colors:
  bg: "#f3f6f4"
  surface: "#ffffff"
  sidebar: "#edf3ef"
  ink: "#163c37"
  muted: "#536d63"
  line: "#d3dfd9"
  accent: "#176b5b"
  active-account: "#dcebe2"
  selection: "#c5dfce"
  button-ink: "#164c40"
  button-border: "#bed0ca"
  button-hover: "#e8f1ec"
  input-ink: "#173c32"
  input-border: "#b7cac0"
  focus: "#b58128"
  badge-bg: "#e5eee8"
  badge-ink: "#345c4a"
  notice-bg: "#e6efe9"
  warning: "#795019"
  warning-bg: "#fff0d3"
  danger: "#913c2d"
  danger-bg: "#fbe8e3"
  table-head: "#eef3ef"
  table-head-ink: "#526b62"
  table-line: "#e2e9e5"
  status-bg: "#edf2ef"
  excerpt-bg: "#f1f5f2"
  excerpt-ink: "#4e665c"
typography:
  brand:
    fontFamily: "Segoe UI, sans-serif"
    fontSize: "22px"
    fontWeight: 700
    letterSpacing: "-.6px"
  brand-mobile:
    fontFamily: "Segoe UI, sans-serif"
    fontSize: "20px"
    fontWeight: 700
    letterSpacing: "-.6px"
  headline:
    fontFamily: "Segoe UI, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    letterSpacing: "-.5px"
  title:
    fontFamily: "Segoe UI, sans-serif"
    fontSize: "16px"
    fontWeight: 700
  body:
    fontFamily: "Segoe UI, sans-serif"
    fontSize: "14px"
    fontWeight: 400
  label:
    fontFamily: "Segoe UI, sans-serif"
    fontSize: "12px"
rounded:
  panel: "10px"
  control: "7px"
  badge: "5px"
  excerpt: "6px"
spacing:
  compact: "8px"
  toolbar: "10px"
  field: "11px"
  small: "12px"
  mobile: "16px"
  panel: "18px"
  review: "20px"
  main: "32px"
components:
  button-primary:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.surface}"
    rounded: "{rounded.control}"
    padding: "10px 14px"
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.button-ink}"
    rounded: "{rounded.control}"
    padding: "10px 14px"
  button-danger:
    backgroundColor: "{colors.danger-bg}"
    textColor: "{colors.danger}"
    rounded: "{rounded.control}"
    padding: "10px 14px"
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.input-ink}"
    rounded: "{rounded.control}"
    padding: "11px"
  tab-active:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.surface}"
    rounded: "{rounded.control}"
    padding: "10px 14px"
  account-active:
    backgroundColor: "{colors.active-account}"
    textColor: "{colors.button-ink}"
    rounded: "{rounded.control}"
    padding: "14px"
  badge:
    backgroundColor: "{colors.badge-bg}"
    textColor: "{colors.badge-ink}"
    rounded: "{rounded.badge}"
    padding: "5px 9px"
  review:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.panel}"
    padding: "20px"
---

# Design System: CommentLab

## Overview

**Creative North Star: "Bàn thao tác gọn, rõ tài khoản"**

Nền xanh xám nhạt, mặt trắng, chữ xanh mực và hành động teal. Font hệ thống, đường phân vùng mảnh và nội dung ngắn giúp người vận hành biết đang dùng tài khoản nào, chọn nguồn nào và gửi nội dung nào.

Nguồn thiết kế là mockup tương tác gọn đã được người dùng duyệt, sau đó chuyển vào ứng dụng nhiều tài khoản. Tài liệu trích xuất từ `ui/app.css`, `ui/index.html`, `ui/app.js`, theo `PRODUCT.md` và `.impeccable/direction.md` hiện hành. Các ảnh runtime `desktop-direct.png`, `mobile-direct.png`, `help-direct.png` và `history-viewport-direct.png` trong `.impeccable/review/` đối chiếu màn gửi trực tiếp, Hướng dẫn và lịch sử. Kết luận ship áp dụng cho đợt tinh chỉnh UI này; ảnh dùng dữ liệu thử và không chứng minh gửi Facebook thật.

**Key Characteristics:**

- Sidebar tài khoản và một vùng làm việc chính.
- Mặt phẳng, viền mảnh, không bóng đổ hoặc ảnh trang trí.
- Gửi trực tiếp là hành động chính; xem trước để chọn bài và sửa nội dung riêng khi cần.
- Trạng thái luôn có chữ, màu chỉ hỗ trợ nhận biết.

## Colors

### Primary

`accent` dùng cho nút chính, tab hiện tại, liên kết và checkbox. Tài khoản đang chọn dùng nền `active-account` cùng viền accent. `focus` là màu vàng nâu riêng cho outline bàn phím.

`selection` là nền xanh nhạt khi người dùng bôi chọn văn bản, khác với nền tài khoản đang chọn.

### Neutral

`bg`, `surface` và `sidebar` chia ba lớp nền. `ink` là chữ chính; `muted` dành cho thông tin phụ. Các token button/input giữ viền và chữ theo source. Bảng có nền đầu bảng và đường chia riêng; trích đoạn bài có nền dịu để tách khỏi nội dung trả lời.

`notice-bg` dành cho phản hồi thông thường. Các cặp warning/danger dùng cho cảnh báo và lỗi, luôn kèm thông điệp. Nhãn “Đã lưu phiên” không khẳng định Facebook đã xác thực phiên.

**The Status Label Rule.** Mọi trạng thái cần nhãn chữ; màu không chứng minh bình luận đã hiển thị trên Facebook.

## Typography

Toàn giao diện dùng Segoe UI rồi sans-serif, không tải font ngoài. Body theo token `body`; đoạn văn có line-height (1.55), notice (1.5). Tiêu đề trang dùng `headline`; h2 và tiêu đề bài dùng `title`. Chữ thương hiệu dùng `brand` và `brand-mobile`, cùng độ đậm (700) trên cả tên CommentLab. Inline font-weight (400) trong HTML bị CSP chặn, không phải giá trị runtime. Nhãn nhỏ, đầu bảng, badge và trạng thái dùng cỡ (12px). Không có font monospace riêng trong giao diện hiện hành.

## Layout

Header cao (70px), padding ngang (28px), có Hướng dẫn và Làm mới. Desktop gồm sidebar (260px) và vùng làm việc co giãn; main rộng tối đa (1250px), padding (32px), căn giữa trong phần còn lại. Sidebar padding (25px 18px). Ba tab chuyển nội dung Gửi bình luận, Xem trước và Lịch sử trong cùng vùng chính.

Tại viewport tối đa (760px), các vùng xếp một cột; header tự tăng chiều cao và có thể xuống hàng, ẩn badge vị trí. Sidebar padding (16px), tài khoản xếp ngang và cuộn nội bộ với mỗi mục rộng tối thiểu (170px). Main padding (22px 16px); tab, tiêu đề và hàng hành động cho phép xuống hàng. Bảng nhóm dùng fixed layout, ô và link dài được ngắt dòng. Hàng lịch sử đổi từ ba cột sang một cột. Không áp dụng bố cục phiên/soạn/biên nhận ba cột của phiên bản trước.

## Elevation & Depth

Không có box-shadow, animation hoặc transition trong stylesheet hiện hành. Chiều sâu đến từ nền dịu, mặt trắng và viền (1px); không có lớp biên nhận nổi. Outline focus (3px), offset (2px) dành cho button, input, textarea và select.

## Shapes

Panel nhập link, editor tài khoản, review và empty state bo theo `panel`. Nút và trường nhập theo `control`, badge/trạng thái theo `badge`, trích đoạn theo `excerpt`. Empty state dùng viền nét đứt; panel thường dùng viền liền. Không có icon library hay ảnh raster trong shell hiện hành.

Không chuẩn hóa thành token mới: stylesheet còn quy tắc toast bo (8px), nhưng UI hiện hành không tạo phần tử toast. Các inline style bị CSP `style-src 'self'` chặn cũng không được coi là hình thức đã triển khai.

## Components

### Buttons / Navigation

Nút thường trắng, viền xanh xám, hover nền dịu. Nút chính và tab active giữ teal kể cả hover theo cascade hiện hành; không có token accent-hover riêng. Nút xóa xác nhận dùng màu danger. Disabled giảm opacity (.5) và đổi con trỏ. Tabs là các button trong nav có nhãn “Các bước”, không phải một ARIA tab widget đầy đủ.

### Account selector / Editor

Mỗi nút tài khoản hiển thị tên, ID và trạng thái bằng chữ; mục active có nền/viền riêng. Thêm, Sửa, Xóa nằm dưới danh sách. Editor rộng tối đa (650px), có nhãn trường, xs được che mặc định và nút Hiện/Ẩn. Cookie bổ sung và nhập JSON nằm trong details. Xóa có màn xác nhận trước thao tác.

### Inputs / Groups

Input, select và textarea cùng nền trắng, viền mảnh, padding theo `field`. Nhập link có textarea cao tối thiểu (120px), mỗi dòng một link; kết quả kiểm tra ghi theo dòng. Select chọn mức tối đa (10/20/50) bài toàn lượt đi cạnh thao tác kiểm tra. Nhóm đã lưu nằm trong details, bảng có checkbox (18px), nguồn và trạng thái bằng chữ.

Nội dung bình luận chung nằm dưới nguồn, có nhãn đậm (600) và textarea bốn dòng. Dòng giới hạn tổng lượt đi cùng hai hành động: Xem trước là nút phụ, Gửi bình luận là nút teal chính. Trên mobile hàng nút xuống dòng và căn phải; không dùng thanh cố định che nội dung.

### Optional preview

Mỗi bài là một panel trắng có tên nhóm, link bài, trích đoạn và textarea riêng cao tối thiểu (88px), kéo cao theo chiều dọc. Checkbox “Chọn bài này” cho phép bỏ bài khỏi lượt gửi; không có bước đánh dấu duyệt bắt buộc. Số bài thực tế và nút Gửi các bài đã chọn nằm đầu danh sách, nút bị vô hiệu khi không có bài được chọn. Thay nguồn hoặc nội dung chung làm mất hiệu lực bản xem trước. Khi đang xử lý, giao diện hiện tiến độ và Dừng; Dừng chờ request hiện tại.

### Help

Hướng dẫn mở từ header, giữ sidebar và navigation. Nội dung rộng tối đa (760px), bắt đầu bằng danh sách ba bước và phần giải thích xem trước tùy chọn; chi tiết dùng details/summary native với tiêu đề đậm (600), viền dưới mảnh và padding dọc (12px). Danh sách thụt trái (24px), khoảng cách mục (8px); phần chữ kế thừa line-height (1.65), đoạn văn dùng quy tắc p (1.55).

### Feedback / History

Banner có role status; lỗi và cảnh báo giữ nội dung mô tả. Kết quả từng bài hiển thị trạng thái chữ. Lịch sử là các hàng phẳng chia bằng viền: tên tài khoản/ID, tên nhóm/link bài, thời gian/trạng thái/ghi chú. Desktop dùng tỷ lệ cột (1fr 1.3fr 1.6fr), gap và padding dọc (18px); mobile một cột, gap (12px). Tên chưa có được ghi rõ, không thêm tên suy đoán. Mỗi trang có tối đa (50) bản ghi, hàng điều hướng Mới hơn / Cũ hơn cùng khoảng bản ghi nằm dưới danh sách; khi rỗng chỉ có thông điệp ngắn. Các nhãn “Chưa rõ kết quả” và “Đã xác nhận phản hồi” phản ánh mức bằng chứng, không cam kết bài đã hiển thị thật.

## Do's and Don'ts

### Do:

- Do giữ tài khoản hiện tại và trạng thái bằng chữ dễ nhận biết.
- Do giữ outline bàn phím rõ và nhãn cho trường nhập.
- Do giữ bố cục một cột trên mobile và cuộn riêng danh sách tài khoản.
- Do giữ bản nháp khi thao tác thất bại và vô hiệu bản xem trước khi nguồn hoặc nội dung chung thay đổi.

### Don't:

- Don't mô tả phiên đã lưu là phiên đã được Facebook xác thực.
- Don't dùng màu xanh để khẳng định bình luận đã hiển thị thật.
- Don't khôi phục bố cục phiên/soạn/biên nhận ba cột từ bản cũ.
- Don't thêm font ngoài, ảnh trang trí hoặc bóng đổ vào hệ hiện hành khi chưa có quyết định thiết kế mới.
