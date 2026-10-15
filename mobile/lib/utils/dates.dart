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

/// "2026-10" -> "Tháng 10" (cùng năm với [now] theo giờ Việt Nam) hoặc "Tháng 1/2027" (khác năm).
String monthShortLabel(String month, [DateTime? now]) {
  final parsed = parseMonth(month);
  if (parsed == null) return month;
  final (year, mon) = parsed;
  final current = parseMonth(currentMonthIct(now));
  return current != null && current.$1 == year ? 'Tháng $mon' : 'Tháng $mon/$year';
}

/// Giờ của máy dạng "09:59 14/10/2026" (chỉ dùng cho giờ người dùng tự chọn trên máy, vd. ô "Thời gian"
/// khi nhập tay). Giờ từ máy chủ luôn hiện theo giờ Việt Nam: [formatDateTimeIct].
String formatDateTime(DateTime dt) => DateFormat('HH:mm dd/MM/yyyy', 'vi_VN').format(dt.toLocal());

/// Thời điểm [dt] đọc theo giờ Việt Nam (ICT): kết quả là DateTime UTC đã cộng 7 giờ, chỉ dùng để lấy
/// ngày/giờ hiển thị, không dùng để so sánh thời điểm.
DateTime toIct(DateTime dt) => dt.toUtc().add(ictOffset);

/// Giờ Việt Nam dạng "14:32", không phụ thuộc múi giờ của máy.
String formatTimeIct(DateTime dt) => DateFormat('HH:mm', 'vi_VN').format(toIct(dt));

/// Giờ Việt Nam dạng "14:32 14/10".
String formatShortDateTimeIct(DateTime dt) => DateFormat('HH:mm dd/MM', 'vi_VN').format(toIct(dt));

/// Giờ Việt Nam dạng "14:32 14/10/2026".
String formatDateTimeIct(DateTime dt) => DateFormat('HH:mm dd/MM/yyyy', 'vi_VN').format(toIct(dt));

/// "14:32" nếu [dt] cùng ngày (giờ Việt Nam) với [now], ngược lại "14:32 14/10".
String formatTimeOrDateIct(DateTime dt, DateTime now) {
  final a = toIct(dt);
  final b = toIct(now);
  final sameDay = a.year == b.year && a.month == b.month && a.day == b.day;
  return sameDay ? formatTimeIct(dt) : formatShortDateTimeIct(dt);
}

/// Tên thứ trong tuần (DateTime.weekday 1 = Thứ Hai … 7 = Chủ nhật).
const List<String> _weekdays = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ nhật'];

/// Ngày (giờ Việt Nam) của [dt] dạng khoá "YYYY-MM-DD" để gom nhóm theo ngày.
String dayKeyIct(DateTime dt) {
  final d = toIct(dt);
  return '${d.year}-${_two(d.month)}-${_two(d.day)}';
}

/// Tiêu đề nhóm ngày theo giờ Việt Nam: "Hôm nay", "Hôm qua", "Thứ Hai, 12/10" (thêm năm khi khác năm).
String dayHeadingIct(DateTime dt, DateTime now) {
  final d = toIct(dt);
  final n = toIct(now);
  final day = DateTime.utc(d.year, d.month, d.day);
  final today = DateTime.utc(n.year, n.month, n.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hôm nay';
  if (diff == 1) return 'Hôm qua';
  final date = d.year == n.year ? '${_two(d.day)}/${_two(d.month)}' : '${_two(d.day)}/${_two(d.month)}/${d.year}';
  return '${_weekdays[d.weekday - 1]}, $date';
}

/// "14:32, Thứ Ba 14/10/2026" theo giờ Việt Nam (chi tiết cảnh báo).
String formatLongDateTimeIct(DateTime dt) {
  final d = toIct(dt);
  return '${formatTimeIct(dt)}, ${_weekdays[d.weekday - 1]} ${_two(d.day)}/${_two(d.month)}/${d.year}';
}
