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
