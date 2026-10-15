/// Ký tự emoji / ký hiệu hay đứng đầu tiêu đề cảnh báo của máy chủ ("⚠️", "✅", "🔴", "📊", "☀️", "❔"…),
/// kèm bộ chọn biến thể (FE0E/FE0F), ZWJ, keycap và cờ.
final RegExp _leadingEmoji = RegExp(
  r'^(?:[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{2300}-\u{23FF}\u{2190}-\u{21FF}'
  r'\u{2900}-\u{297F}\u{25A0}-\u{25FF}\u{2100}-\u{214F}\u{3030}\u{303D}\u{3297}\u{3299}\u{FE0E}\u{FE0F}'
  r'\u{200D}\u{20E3}\u{E0020}-\u{E007F}]|\s)+',
  unicode: true,
);

/// Bỏ emoji đứng đầu tiêu đề (máy chủ soạn sẵn cho Telegram): app đã có icon theo mức nên không cần emoji làm
/// icon (DESIGN.md › Components). Chỉ bỏ ở đầu chuỗi; emoji trong câu (danh mục do người dùng đặt) giữ nguyên.
/// Tiêu đề chỉ toàn emoji thì giữ nguyên.
String stripLeadingEmoji(String text) {
  final stripped = text.replaceFirst(_leadingEmoji, '').trimLeft();
  return stripped.isEmpty ? text.trim() : stripped;
}

/// Lời nhắc lệnh bot Telegram ở cuối một dòng ("… — gõ /uncat để phân loại.").
final RegExp _botHint = RegExp(r'\s*[—–-]\s*gõ\s+/\w+.*$');

/// Lệnh bot Telegram trong câu ("/status", "/uncat"): vô nghĩa trong app.
final RegExp _botCommand = RegExp(r'(^|\s)/[a-z_]+\b');

/// Ngày giờ của máy chủ ở cuối dòng ("· 17:38" hoặc "· 17:38 15/10").
final RegExp _trailingTime = RegExp(r'\s*·\s*\d{1,2}:\d{2}(\s+\d{1,2}/\d{1,2}(/\d{2,4})?)?\s*$');

/// Nội dung cảnh báo của máy chủ (soạn cho Telegram) để hiện trong app: bỏ emoji đầu mỗi dòng (app đã có icon),
/// bỏ lời nhắc lệnh bot ("— gõ /uncat để phân loại"; dòng nào vẫn còn lệnh bot thì bỏ cả dòng), bỏ dòng trống.
/// Giữ thụt lề đầu dòng (dòng chi tiết con) và emoji giữa câu (danh mục do người dùng đặt).
String cleanAlertMessage(String message) {
  final out = <String>[];
  for (final raw in message.split('\n')) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    final indent = raw.substring(0, raw.length - raw.trimLeft().length);
    var line = stripLeadingEmoji(trimmed);
    final withoutHint = line.replaceFirst(_botHint, '');
    if (withoutHint != line) {
      line = withoutHint.trimRight();
      if (line.isNotEmpty && !RegExp(r'[.!?:…]$').hasMatch(line)) line = '$line.';
    }
    if (line.isEmpty || _botCommand.hasMatch(line)) continue;
    out.add('$indent$line');
  }
  return out.join('\n');
}

/// Một dòng tóm tắt cho SnackBar thông báo đẩy: dòng đầu của nội dung đã làm sạch, bỏ giờ ở cuối (SnackBar đã
/// có nghĩa là "vừa xong"), để không bị cắt giữa giờ.
String alertSnippet(String message) {
  final first = cleanAlertMessage(message).split('\n').first.trim();
  return first.replaceFirst(_trailingTime, '');
}

/// Số giao dịch chưa phân loại mà nội dung cảnh báo nhắc tới (bản tin), hoặc `null`.
int? mentionedUncategorized(String message) {
  final m = RegExp(r'(\d+) giao dịch chưa phân loại').firstMatch(message);
  return m == null ? null : int.tryParse(m.group(1)!);
}

/// Tên mục tiêu không kèm tháng: máy chủ gửi `goal_name` dạng "Tiền ăn (2026-11)"; app tự ghi tháng một lần
/// theo kiểu của app ("11/2026", "Tháng 11"), nên bỏ "(YYYY-MM)" ở cuối để không lặp.
String goalNameWithoutMonth(String name) => name.replaceFirst(RegExp(r'\s*\(\d{4}-\d{2}\)\s*$'), '');
