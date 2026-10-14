import 'package:intl/intl.dart';

/// Múi giờ Việt Nam (ICT, UTC+7, không có giờ mùa hè). Tháng của backend tính theo ICT.
const Duration ictOffset = Duration(hours: 7);

String _two(int v) => v.toString().padLeft(2, '0');

/// Tháng hiện tại theo giờ Việt Nam, dạng "YYYY-MM".
String currentMonthIct([DateTime? now]) {
  final ict = (now ?? DateTime.now()).toUtc().add(ictOffset);
  return '${ict.year}-${_two(ict.month)}';
}

/// Tháng ("YYYY-MM") của thời điểm [dt] theo giờ Việt Nam.
String monthOfIct(DateTime dt) => currentMonthIct(dt);

/// (năm, tháng) từ "YYYY-MM"; chuỗi sai định dạng -> `null`.
(int, int)? parseMonth(String month) {
  final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(month);
  if (m == null) return null;
  final year = int.parse(m.group(1)!);
  final mon = int.parse(m.group(2)!);
  if (mon < 1 || mon > 12) return null;
  return (year, mon);
}

/// Cộng/trừ [delta] tháng: shiftMonth("2026-12", 1) -> "2027-01".
String shiftMonth(String month, int delta) {
  final parsed = parseMonth(month);
  if (parsed == null) return month;
  final (year, mon) = parsed;
  final index = year * 12 + (mon - 1) + delta;
  return '${index ~/ 12}-${_two(index % 12 + 1)}';
}

/// "2026-10" -> "10/2026".
String shortMonthLabel(String month) {
  final parsed = parseMonth(month);
  if (parsed == null) return month;
  final (year, mon) = parsed;
  return '${_two(mon)}/$year';
}

/// "2026-10" -> "Tháng 10/2026".
String monthLabel(String month) => 'Tháng ${shortMonthLabel(month)}';

/// Giờ địa phương dạng "09:59 14/10".
String formatShortDateTime(DateTime dt) => DateFormat('HH:mm dd/MM', 'vi_VN').format(dt.toLocal());

/// Giờ địa phương dạng "09:59 14/10/2026".
String formatDateTime(DateTime dt) => DateFormat('HH:mm dd/MM/yyyy', 'vi_VN').format(dt.toLocal());

/// Ngày địa phương dạng "14/10/2026".
String formatDate(DateTime dt) => DateFormat('dd/MM/yyyy', 'vi_VN').format(dt.toLocal());
