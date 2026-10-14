import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Định dạng nhóm nghìn kiểu Việt Nam: 6500000 -> "6.500.000".
final NumberFormat _grouping = NumberFormat('#,##0', 'vi_VN');

/// Số chữ số tối đa khi gõ (đủ cho 100 tỷ, tránh tràn int).
const int _maxDigits = 13;

/// Chỉ phần số, không kèm "đ": 6500000 -> "6.500.000".
String formatGrouped(int amount) {
  final text = _grouping.format(amount.abs());
  return amount < 0 ? '-$text' : text;
}

/// 6500000 -> "6.500.000đ"; -500000 -> "-500.000đ".
String formatVnd(int amount) => '${formatGrouped(amount)}đ';

/// Số tiền có dấu theo chiều giao dịch: chi "−3.500.000đ", thu "+3.500.000đ".
String formatSignedVnd(int amount, {required bool outgoing}) => '${outgoing ? '−' : '+'}${formatVnd(amount.abs())}';

/// `null` -> "—" (chưa biết), còn lại như [formatVnd].
String formatVndOrDash(int? amount) => amount == null ? '—' : formatVnd(amount);

final RegExp _decimalTail = RegExp(r',\d{1,2}$');
final RegExp _nonDigit = RegExp(r'\D');
final RegExp _digit = RegExp(r'\d');

/// Đọc lại số tiền người dùng nhập: "6.500.000đ", "6500000", "1.000.000,00",
/// "1,000,000" -> int. Chuỗi rỗng / không có chữ số -> `null`.
int? parseVnd(String? input) {
  if (input == null) return null;
  var text = input.trim();
  if (text.isEmpty) return null;
  final negative = text.startsWith('-') || text.startsWith('−');
  text = text.replaceFirst(_decimalTail, '');
  final digits = text.replaceAll(_nonDigit, '');
  if (digits.isEmpty) return null;
  final value = int.tryParse(digits);
  if (value == null) return null;
  return negative ? -value : value;
}

/// Định dạng số tiền ngay khi gõ: "1234567" -> "1.234.567", giữ vị trí con trỏ
/// theo số chữ số đứng sau nó.
class VndInputFormatter extends TextInputFormatter {
  const VndInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var raw = newValue.text;
    var cursor = newValue.selection.isValid ? newValue.selection.end.clamp(0, raw.length) : raw.length;
    if (oldValue.selection.isValid &&
        oldValue.selection.isCollapsed &&
        raw.length < oldValue.text.length &&
        raw.replaceAll(_nonDigit, '') == oldValue.text.replaceAll(_nonDigit, '')) {
      // Chỉ xoá mỗi dấu chấm nhóm nghìn (định dạng lại sẽ thêm nó về): xoá luôn chữ số cạnh nó,
      // nếu không phím xoá sẽ "không làm gì".
      final backspace = cursor < oldValue.selection.end;
      final index = backspace ? raw.substring(0, cursor).lastIndexOf(_digit) : raw.indexOf(_digit, cursor);
      if (index >= 0) {
        raw = raw.substring(0, index) + raw.substring(index + 1);
        cursor = index;
      }
    }
    var digits = raw.replaceAll(_nonDigit, '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.length > _maxDigits) {
      // Gõ quá dài: giữ nguyên giá trị cũ.
      return oldValue;
    }
    final formatted = formatGrouped(int.parse(digits));

    var digitsAfterCursor = raw.substring(cursor).replaceAll(_nonDigit, '').length;
    if (digitsAfterCursor > digits.length) digitsAfterCursor = digits.length;

    var pos = formatted.length;
    var seen = 0;
    while (pos > 0 && seen < digitsAfterCursor) {
      pos--;
      final code = formatted.codeUnitAt(pos);
      if (code >= 0x30 && code <= 0x39) seen++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: pos),
    );
  }
}
