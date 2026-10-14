"""Sinh lại các email mẫu TỔNG HỢP trong thư mục này (không phải email thật của ngân hàng nào).

Chạy: `.venv/bin/python tests/fixtures/emails/_generate.py` (từ thư mục backend). Boundary MIME là ngẫu nhiên nên
file .eml multipart sẽ khác từng byte, nội dung thì giữ nguyên. Số TK, tên, mã tham chiếu đều là giá trị giả lập.
"""

import email.policy
import sys
from email.message import EmailMessage
from pathlib import Path

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent
OUT.mkdir(parents=True, exist_ok=True)

GOOGLE_VCB = (
    "mx.google.com; dkim=pass header.i=@vietcombank.com.vn header.s=synth1 header.b=SyNtHeTiC;"
    " spf=pass (google.com: domain of noreply@info.vietcombank.com.vn designates 192.0.2.10 as permitted sender)"
    " smtp.mailfrom=noreply@info.vietcombank.com.vn;"
    " dmarc=pass (p=REJECT sp=REJECT dis=NONE) header.from=vietcombank.com.vn"
)
GOOGLE_MB = (
    "mx.google.com; dkim=pass header.d=mbbank.com.vn header.s=synth2 header.b=SyNtHeTiC;"
    " spf=pass (google.com: domain of noreply@mbbank.com.vn designates 192.0.2.20 as permitted sender)"
    " smtp.mailfrom=noreply@mbbank.com.vn"
)
VCB_FROM = "VCB Digibank <noreply@info.vietcombank.com.vn>"
VCB_FROM_ROOT = "Vietcombank <noreply@vietcombank.com.vn>"
MB_FROM = "MB Bank <noreply@mbbank.com.vn>"


def build(
    name,
    *,
    sender,
    subject,
    auth=(GOOGLE_VCB,),
    date="Wed, 14 Oct 2026 10:21:05 +0700",
    message_id=True,
    plain=None,
    html=None,
    plain_cte="8bit",
    html_cte="quoted-printable",
    extra_headers=(),
):
    msg = EmailMessage(policy=email.policy.default)
    msg["Delivered-To"] = "nguoidung.synthetic@example.com"
    msg["Received"] = "by 2002:a05:0000:0000:b0:000:0000:0000 with SMTP id synthetic; Wed, 14 Oct 2026 03:21:06 -0700"
    for value in auth:
        msg["Authentication-Results"] = value
    for key, value in extra_headers:
        msg[key] = value
    msg["From"] = sender
    msg["To"] = "nguoidung.synthetic@example.com"
    msg["Subject"] = subject
    if date:
        msg["Date"] = date
    if message_id:
        msg["Message-ID"] = f"<synthetic-{name}@example.invalid>"
    msg["MIME-Version"] = "1.0"
    if plain is not None:
        msg.set_content(plain, charset="utf-8", cte=plain_cte)
        if html is not None:
            msg.add_alternative(html, subtype="html", charset="utf-8", cte=html_cte)
    elif html is not None:
        msg.set_content(html, subtype="html", charset="utf-8", cte=html_cte)
    (OUT / f"{name}.eml").write_bytes(msg.as_bytes(policy=email.policy.default))


def table(rows, title, footer="Tầng 5, Tòa nhà Ngân hàng Mẫu, Hà Nội. Hotline 1900 0000 (số giả lập)."):
    cells = "".join(f"<tr><td style='padding:4px'>{k}</td><td><b>{v}</b></td></tr>" for k, v in rows)
    return (
        "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Thông báo</title>"
        "<style>td{font-family:Arial}</style></head><body>"
        f"<h3>{title}</h3><p>Kính gửi Quý khách NGUYEN VAN A,</p>"
        f"<table border='1' cellspacing='0'>{cells}</table>"
        f"<p>Trân trọng cảm ơn Quý khách!<br/>{footer}</p>"
        "<script>var x = 'Số tiền: 9.999.999 VND';</script></body></html>"
    )


# 1. VCB "Thông báo giao dịch" — chỉ có HTML, người gửi là domain con.
build(
    "vcb_credit_table_html",
    sender=VCB_FROM,
    subject="Thông báo giao dịch",
    html=table(
        [
            ("Số tài khoản", "0011001234567"),
            ("Thời gian giao dịch", "14/10/2026 10:20:30"),
            ("Loại giao dịch", "Ghi có"),
            ("Số tiền", "1,000,000 VND"),
            ("Số dư cuối", "11,000,000 VND"),
            ("Nội dung", "NGUYEN VAN B chuyen tien an trua"),
            ("Số tham chiếu", "5123ABC987"),
        ],
        "Vietcombank thông báo giao dịch",
    ),
)

# 2. VCB "Biên lai chuyển tiền" — multipart (plain + html), không có số dư, có TK người hưởng.
receipt_rows = [
    ("Ngày, giờ giao dịch", "14/10/2026 09:15"),
    ("Số lệnh giao dịch / Số tham chiếu", "5012ABCD1234"),
    ("Tài khoản nguồn", "0011001234567"),
    ("Tên người chuyển", "NGUYEN VAN A"),
    ("Tài khoản người hưởng", "0123456789"),
    ("Tên người hưởng", "TRAN THI B"),
    ("Tên ngân hàng hưởng", "MB - Ngân hàng TMCP Quân đội"),
    ("Số tiền", "3.000.000 VND"),
    ("Số tiền bằng chữ", "Ba triệu đồng"),
    ("Loại phí", "Phí người chuyển trả"),
    ("Số tiền phí", "0 VND"),
    ("Nội dung chuyển tiền", "NGUYEN VAN A chuyen tien tro thang 10"),
]
build(
    "vcb_receipt_transfer_out",
    sender=VCB_FROM,
    subject="Biên lai chuyển tiền qua tài khoản",
    plain="VCB Digibank - Biên lai chuyển tiền qua tài khoản\n"
    + "\n".join(f"{k}: {v}" for k, v in receipt_rows)
    + "\nCảm ơn Quý khách đã sử dụng dịch vụ.\n",
    html=table(receipt_rows, "Biên lai chuyển tiền qua tài khoản"),
)

# 3. VCB kiểu SMS — TK bị che, nội dung sau "Ref".
build(
    "vcb_sms_style_in",
    sender=VCB_FROM_ROOT,
    subject="Thong bao bien dong so du",
    plain=(
        "Quy khach than men,\n"
        "SD TK 0011004xxxxxx +2,500,000VND luc 14-10-2026 08:05:11. SD 12,500,000VND. "
        "Ref MBVCB.12345678.CT tu 0123456789 NGUYEN VAN B toi 0011004xxxxxx NGUYEN VAN A\n"
        "Tran trong.\n"
    ),
)

# 4. VCB tiền ra, số thập phân ",00", TK che giữa, quoted-printable.
build(
    "vcb_debit_decimals_qp",
    sender=VCB_FROM,
    subject="Thông báo biến động số dư",
    plain=(
        "Kính gửi Quý khách,\n"
        "Tài khoản: 001100xxxx4567\n"
        "Phát sinh: -250.000,00 VND\n"
        "Số dư khả dụng: 9.750.000,00 VND\n"
        "Thời gian: 14/10/2026 12:01:02\n"
        "Nội dung: THANH TOAN HOA DON DIEN EVN\n"
    ),
    plain_cte="quoted-printable",
)

# 5. MB dạng dòng, tiền ra.
build(
    "mb_line_out",
    sender=MB_FROM,
    subject="MB thông báo biến động số dư",
    auth=(GOOGLE_MB,),
    plain="MB thong bao: TK 0xxx1234|GD: -500,000VND 14/10/26 10:20|SD: 6,500,000VND|ND: THANH TOAN QR GRABFOOD\n",
)

# 6. MB dạng dòng, tiền vào, không có số dư.
build(
    "mb_line_in_no_balance",
    sender=MB_FROM,
    subject="MB thông báo biến động số dư",
    auth=(GOOGLE_MB,),
    plain="TK 0xxx1234|GD: +5,000,000VND 14/10/26 09:00|ND: CTY ABC TRA LUONG T10\n",
)

# 7. MB chỉ HTML, base64, dấu chấm phân cách nghìn, có mã giao dịch.
build(
    "mb_html_base64",
    sender=MB_FROM,
    subject="Thông báo biến động số dư",
    auth=(GOOGLE_MB,),
    html=table(
        [
            ("Tài khoản", "0123456789"),
            ("Thời gian", "14/10/2026 11:45:00"),
            ("Số tiền giao dịch", "+1.200.000 VND"),
            ("Số dư", "7.700.000 VND"),
            ("Nội dung", "TRAN THI B hoan tien an trua"),
            ("Mã giao dịch", "FT26287123456"),
        ],
        "MB thông báo biến động số dư",
    ),
    html_cte="base64",
)

# 8. MB nhiều giao dịch trong một email.
build(
    "mb_multi",
    sender=MB_FROM,
    subject="MB thông báo biến động số dư",
    auth=(GOOGLE_MB,),
    plain=(
        "TK 0xxx1234|GD: -45,000VND 14/10/26 07:30|SD: 6,955,000VND|ND: COM TAM SANG\n"
        "TK 0xxx1234|GD: -55,000VND 14/10/26 12:10|SD: 6,900,000VND|ND: BUN BO TRUA\n"
    ),
)

# 9. MB không có dấu +/-: chiều lấy từ "Ghi nợ"; giờ dạng "hh:mm dd/mm/yyyy".
build(
    "mb_keyword_direction",
    sender=MB_FROM,
    subject="Thông báo giao dịch",
    auth=(GOOGLE_MB,),
    plain=(
        "Tài khoản: 0123456789\n"
        "Loại giao dịch: Ghi nợ\n"
        "Số tiền: 150,000 VND\n"
        "Thời gian: 10:20 14/10/2026\n"
        "Nội dung: PHI DICH VU SMS BANKING\n"
    ),
)

# 10. Email quảng cáo của VCB (DKIM hợp lệ) — không có giao dịch.
build(
    "vcb_garbage_promo",
    sender=VCB_FROM,
    subject="Ưu đãi tháng 10 dành cho Quý khách",
    plain=(
        "Hoàn tiền tới 10% khi thanh toán bằng thẻ ghi nợ quốc tế.\n"
        "Giảm giá đến 50% tại các cửa hàng đối tác. Áp dụng từ 01/10/2026 đến 31/10/2026.\n"
        "Liên hệ 1900 0000 (số giả lập).\n"
    ),
)

# 11. Người gửi giả mạo: domain trông giống nhưng không phải domain con.
build(
    "forged_sender_lookalike",
    sender="Vietcombank <noreply@vietcombank.com.vn.secure-login.example>",
    subject="Thông báo giao dịch",
    auth=(
        "mx.google.com; dkim=pass header.d=vietcombank.com.vn.secure-login.example; "
        "dmarc=pass header.from=vietcombank.com.vn.secure-login.example",
    ),
    plain="Số tiền: -9,000,000 VND\nSố dư: 1,000,000 VND\n",
)

# 12. DKIM/DMARC thất bại.
build(
    "vcb_dkim_fail",
    sender=VCB_FROM_ROOT,
    subject="Thông báo giao dịch",
    auth=(
        "mx.google.com; dkim=fail (body hash did not verify) header.d=vietcombank.com.vn header.s=synth1;"
        " spf=softfail smtp.mailfrom=vietcombank.com.vn; dmarc=fail (p=REJECT) header.from=vietcombank.com.vn",
    ),
    plain="Số tiền: +9,000,000 VND\nSố dư: 19,000,000 VND\n",
)

# 13. DKIM pass nhưng của domain khác (không thuộc allowlist).
build(
    "vcb_dkim_other_domain",
    sender=VCB_FROM_ROOT,
    subject="Thông báo giao dịch",
    auth=(
        "mx.google.com; dkim=pass header.d=bulk-mailer.example; spf=pass smtp.mailfrom=bulk-mailer.example;"
        " dmarc=fail (p=NONE) header.from=vietcombank.com.vn",
    ),
    plain="Số tiền: +9,000,000 VND\nSố dư: 19,000,000 VND\n",
)

# 14. Nhiều header Authentication-Results: header trên cùng (Gmail) pass, header dưới của relay nội bộ.
build(
    "mb_multiple_auth_results",
    sender=MB_FROM,
    subject="MB thông báo biến động số dư",
    auth=(
        "mx.google.com; dkim=pass header.i=@mbbank.com.vn header.s=synth2; "
        "dmarc=pass (p=QUARANTINE sp=QUARANTINE dis=NONE) header.from=mbbank.com.vn",
        "relay.internal.mbbank.com.vn; none",
    ),
    plain="TK 0xxx1234|GD: -200,000VND 14/10/26 13:00|SD: 6,300,000VND|ND: DIEN THOAI\n",
)

# 15. Kẻ giả mạo tự chèn header "pass" bên dưới header thật (fail) của Gmail.
build(
    "vcb_forged_auth_results_below",
    sender=VCB_FROM_ROOT,
    subject="Thông báo giao dịch",
    auth=(
        "mx.google.com; dkim=none; spf=fail smtp.mailfrom=vietcombank.com.vn;"
        " dmarc=fail (p=REJECT) header.from=vietcombank.com.vn",
        "mx.google.com; dkim=pass header.d=vietcombank.com.vn; dmarc=pass header.from=vietcombank.com.vn",
    ),
    plain="Số tiền: -9,000,000 VND\nSố dư: 1,000,000 VND\n",
)

# 16. Chỉ DMARC pass (DKIM fail) — vẫn chấp nhận.
build(
    "vcb_dmarc_only",
    sender=VCB_FROM,
    subject="Thông báo giao dịch",
    auth=(
        "mx.google.com; dkim=fail header.d=vietcombank.com.vn; spf=pass smtp.mailfrom=info.vietcombank.com.vn;"
        " dmarc=pass (p=REJECT) header.from=info.vietcombank.com.vn",
    ),
    plain="Số tài khoản: 0011001234567\nSố tiền: -75,000 VND\nThời gian: 14/10/2026 18:30:00\nNội dung: GRAB*RIDE\n",
)

# 17. Không có Message-ID.
build(
    "vcb_missing_message_id",
    sender=VCB_FROM,
    subject="Thông báo giao dịch",
    message_id=False,
    plain="Số tài khoản: 0011001234567\nSố tiền: -30.000 VND\nThời gian: 14/10/2026 07:00\nNội dung: BANH MI\n",
)

# 18. Không có giờ trong nội dung → dùng header Date.
build(
    "mb_date_header_fallback",
    sender=MB_FROM,
    subject="MB thông báo biến động số dư",
    auth=(GOOGLE_MB,),
    date="Wed, 14 Oct 2026 15:30:00 +0700",
    plain="TK 0xxx1234|GD: -120,000VND|SD: 6,380,000VND|ND: GRAB\n",
)

# 19. Không có giờ trong nội dung, không có header Date → dùng thời điểm nhận.
build(
    "mb_no_date_received_fallback",
    sender=MB_FROM,
    subject="MB thông báo biến động số dư",
    auth=(GOOGLE_MB,),
    date=None,
    plain="TK 0xxx1234|GD: -80,000VND|SD: 6,300,000VND|ND: CAFE\n",
)

# 20. Không xác định được chiều giao dịch.
build(
    "vcb_direction_unknown",
    sender=VCB_FROM,
    subject="Thông báo",
    plain="Số tài khoản: 0011001234567\nSố tiền: 100,000 VND\nThời gian: 14/10/2026 10:00\nNội dung: ABC\n",
)

# 21. Người gửi không phải ngân hàng.
build(
    "other_sender",
    sender="Ban be <friend.synthetic@example.com>",
    subject="Chuyển tiền cho bạn",
    auth=("mx.google.com; dkim=pass header.d=example.com; dmarc=pass header.from=example.com",),
    plain="Số tiền: -500,000 VND\n",
)

# 22. Phần text/plain chỉ bảo "xem HTML" → dùng phần HTML.
build(
    "vcb_plain_points_to_html",
    sender=VCB_FROM,
    subject="Thông báo giao dịch",
    plain="Vui lòng xem email này ở định dạng HTML.\n",
    html=table(
        [
            ("Số tài khoản", "0011001234567"),
            ("Thời gian giao dịch", "14/10/2026 20:05:00"),
            ("Số tiền giao dịch", "-3,500,000 VND"),
            ("Số dư cuối", "6,500,000 VND"),
            ("Nội dung", "RUT TIEN ATM"),
        ],
        "Vietcombank thông báo giao dịch",
    ),
)

print(sorted(p.name for p in OUT.iterdir()))
