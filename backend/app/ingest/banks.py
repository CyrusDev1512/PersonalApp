"""Chuẩn hoá tên ngân hàng từ các nguồn khác nhau về một mã chung."""

from __future__ import annotations

from app.text import normalize_for_match

# alias (đã chuẩn hoá: chữ thường, không dấu, không ký tự đặc biệt) -> mã chuẩn
_ALIASES: dict[str, str] = {}


def _add(code: str, *names: str) -> None:
    for n in names:
        _ALIASES[normalize_for_match(n).replace(" ", "")] = code


_add("VCB", "VCB", "Vietcombank", "Ngân hàng TMCP Ngoại thương Việt Nam", "Ngoai thuong", "VCB Digibank")
_add("MB", "MB", "MBBank", "MB Bank", "Ngân hàng TMCP Quân đội", "Quan doi", "MBB")
_add("TCB", "TCB", "Techcombank", "Ky thuong")
_add("ACB", "ACB", "Á Châu", "A Chau")
_add("BIDV", "BIDV", "Đầu tư và Phát triển")
_add("ICB", "ICB", "VietinBank", "CTG", "Cong thuong")
_add("VBA", "VBA", "Agribank")
_add("TPB", "TPB", "TPBank", "Tien Phong")
_add("VPB", "VPB", "VPBank")
_add("STB", "STB", "Sacombank")
_add("VIB", "VIB")
_add("MSB", "MSB", "Maritime Bank")
_add("OCB", "OCB")
_add("SHB", "SHB")
_add("HDB", "HDB", "HDBank")
_add("TIMO", "Timo")
_add("CAKE", "CAKE", "Cake by VPBank")


def canonical_bank(name: str | None) -> str | None:
    """'Vietcombank' -> 'VCB', 'MBBank' -> 'MB'. Không nhận ra -> trả về tên viết hoa đã rút gọn."""
    if not name:
        return None
    key = normalize_for_match(name).replace(" ", "")
    if not key:
        return None
    if key in _ALIASES:
        return _ALIASES[key]
    return key.upper()[:16]
