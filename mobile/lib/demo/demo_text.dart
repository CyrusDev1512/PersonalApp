/// Bản Dart của `backend/app/text.py`, `money.py`, `engine/categorize.py` và luật mặc định trong `seed.py`
/// (chỉ dùng cho bản dùng thử chạy trong trình duyệt, không có máy chủ).
library;

// ------------------------------------------------------------------ tiền

/// `format_vnd`: 6500000 -> "6.500.000đ", -500000 -> "-500.000đ", null -> "?".
String vnd(int? amount) {
  if (amount == null) return '?';
  final digits = amount.abs().toString();
  final out = StringBuffer(amount < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  out.write('đ');
  return out.toString();
}

/// `round()` của Python (làm tròn nửa về số chẵn).
int pyRound(num x) {
  final f = x.floor();
  final diff = x - f;
  if (diff > 0.5) return f + 1;
  if (diff < 0.5) return f;
  return f.isEven ? f : f + 1;
}

/// `round(x, 1)` của Python.
double pyRound1(num x) => pyRound(x * 10) / 10;

/// `f"{x:.0f}"` của Python.
String fmt0(num x) => '${pyRound(x)}';

// ------------------------------------------------------------- văn bản

const Map<String, String> _accentGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
  'A': 'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ',
  'E': 'ÈÉẸẺẼÊỀẾỆỂỄ',
  'I': 'ÌÍỊỈĨ',
  'O': 'ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ',
  'U': 'ÙÚỤỦŨƯỪỨỰỬỮ',
  'Y': 'ỲÝỴỶỸ',
  'D': 'Đ',
};

final Map<int, String> _accentMap = {
  for (final e in _accentGroups.entries)
    for (final rune in e.value.runes) rune: e.key,
};

/// `strip_accents`: bỏ dấu tiếng Việt (kể cả dấu tổ hợp U+0300–U+036F), đ -> d.
String stripAccents(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0x300 && rune <= 0x36F) continue;
    out.write(_accentMap[rune] ?? String.fromCharCode(rune));
  }
  return out.toString();
}

final RegExp _domain = RegExp(r'\S+\.(?:com|vn|net|org|io|app)(?:\.vn)?\S*', caseSensitive: false);
final RegExp _cityTokens = RegExp(
  r'\b(?:thanh pho|tp\.? ?hcm|tp\.? ?ho chi minh|ho chi minh|ha noi|tp\.? ?hn|da nang)\b',
);
final RegExp _nonAlnum = RegExp(r'[^a-z0-9]+');
final RegExp _spaces = RegExp(r'\s+');

String _squash(String s) => s.trim().split(_spaces).where((t) => t.isNotEmpty).join(' ');

/// `normalize_for_match`: chữ thường, bỏ dấu, bỏ domain và tên thành phố, chỉ còn chữ/số.
String normalizeForMatch(String? text) {
  if (text == null || text.isEmpty) return '';
  var s = stripAccents(text).toLowerCase();
  s = s.replaceAll(_domain, ' ');
  s = s.replaceAll(_nonAlnum, ' ');
  s = s.replaceAll(_cityTokens, ' ');
  return _squash(s);
}

/// `normalize_pattern`.
String normalizePattern(String pattern) => _squash(stripAccents(pattern).toLowerCase().replaceAll(_nonAlnum, ' '));

/// `contains_phrase`: khớp cả cụm từ theo ranh giới token.
bool containsPhrase(String haystackNorm, String phraseNorm) =>
    phraseNorm.isNotEmpty && ' $haystackNorm '.contains(' $phraseNorm ');

/// `digits_only`.
String digitsOnly(String? text) => (text ?? '').replaceAll(RegExp(r'\D'), '');

// ------------------------------------------------------------ phân loại

/// Luật phân loại (`CategoryRule`).
class DemoRule {
  DemoRule({
    required this.id,
    required this.categoryId,
    required this.pattern,
    this.direction = 'out',
    this.priority = 100,
    this.origin = 'seed',
  });

  final int id;
  int categoryId;
  final String pattern;
  final String direction;
  int priority;
  String origin;
}

/// `match_rule` + `categorize`: (category_id, rule_id). Khoản vào không khớp luật -> mặc định Thu nhập.
(int?, int?) categorize(String description, String direction, List<DemoRule> rules, int? defaultIncomeCategoryId) {
  final norm = normalizeForMatch(description);
  if (norm.isNotEmpty) {
    final hits = [
      for (final r in rules)
        if ((r.direction == direction || r.direction == 'any') && containsPhrase(norm, r.pattern)) r,
    ];
    if (hits.isNotEmpty) {
      hits.sort((a, b) {
        var c = a.priority.compareTo(b.priority);
        if (c != 0) return c;
        c = (a.origin == 'user' ? 0 : 1).compareTo(b.origin == 'user' ? 0 : 1);
        if (c != 0) return c;
        c = b.pattern.length.compareTo(a.pattern.length);
        if (c != 0) return c;
        return a.id.compareTo(b.id);
      });
      return (hits.first.categoryId, hits.first.id);
    }
  }
  if (direction == 'in') return (defaultIncomeCategoryId, null);
  return (null, null);
}

const Set<String> _genericTokens = {
  'chuyen', 'tien', 'khoan', 'thanh', 'toan', 'ck', 'ct', 'tt', 'tu', 'toi', 'den', 'nap', 'rut', 'ibft', 'ft', //
  'mbvcb', 'qr', 'gd', 'nd', 'so', 'tk', 'tai', 'cho', 'va', 'qua', 'napas', 'trace', 'ref', 'vcb', 'mb', 'mbbank',
  'vietcombank', 'ngan', 'hang', 'ma', 'giao', 'dich', 'noi', 'dung',
};

final RegExp _digit = RegExp(r'\d');

/// `suggest_rule`: cụm từ gợi ý để "nhớ luật" (lấy từ chính nội dung nên chắc chắn khớp lại).
String? suggestRule(String? description) {
  final norm = normalizeForMatch(description);
  final runs = <List<String>>[];
  var cur = <String>[];
  for (final tok in norm.split(' ')) {
    if (tok.isEmpty) continue;
    if (tok.contains(_digit) || _genericTokens.contains(tok)) {
      if (cur.isNotEmpty) runs.add(cur);
      cur = <String>[];
    } else {
      cur.add(tok);
    }
  }
  if (cur.isNotEmpty) runs.add(cur);
  final kept = runs.where((r) => r.join(' ').length >= 3).toList();
  if (kept.isEmpty) return null;
  var best = kept.first;
  for (final r in kept) {
    if (r.length > best.length) best = r;
  }
  final phrase = best.take(3).join(' ');
  return containsPhrase(norm, phrase) ? phrase : null;
}

// ------------------------------------------------------- dữ liệu mặc định

/// `seed.CATEGORIES`: (system_key, tên, kind, icon, thứ tự).
const List<(String, String, String, String, int)> defaultCategories = [
  ('food', 'Ăn uống', 'expense', '🍜', 10),
  ('rent', 'Thuê trọ', 'expense', '🏠', 20),
  ('transport', 'Đi lại', 'expense', '🛵', 30),
  ('shopping', 'Mua sắm', 'expense', '🛒', 40),
  ('bills', 'Hoá đơn', 'expense', '🧾', 50),
  ('savings', 'Tiết kiệm', 'expense', '🐷', 60),
  ('other', 'Khác', 'expense', '📦', 90),
  ('income', 'Thu nhập', 'income', '💰', 100),
  ('refund', 'Hoàn tiền', 'income', '↩️', 110),
  ('transfer', 'Chuyển nội bộ', 'transfer', '↔️', 120),
];

/// `seed.RULES`: system_key -> (cụm từ, chiều, ưu tiên).
const Map<String, (List<String>, String, int)> defaultRules = {
  'food': (
    [
      'grabfood', 'grab food', 'shopeefood', 'shopee food', 'baemin', 'befood', 'be food', 'gofood', //
      'highlands', 'highland coffee', 'phuc long', 'the coffee house', 'katinat', 'starbucks', 'cong caphe',
      'trung nguyen', 'kfc', 'lotteria', 'jollibee', 'mcdonald', 'pizza hut', 'domino', 'texas chicken',
      'com tam', 'com ga', 'com van phong', 'com trua', 'com chay', 'pho bo', 'pho ga', 'bun bo', 'bun cha',
      'bun dau', 'bun rieu', 'banh mi', 'hu tieu', 'tra sua', 'an trua', 'an toi', 'an sang', 'tien an',
      'an uong', 'nha hang', 'quan an', 'quan lau', 'lau nuong', 'mixue', 'gong cha', 'bach hoa xanh',
      'winmart', 'coopmart',
    ],
    'out',
    50,
  ),
  'rent': (
    [
      'tien tro', 'tien nha', 'tien phong', 'phong tro', 'thue phong', 'thue nha', 'tien thue nha', //
      'tien thue phong', 'nha tro',
    ],
    'out',
    40,
  ),
  'transport': (
    [
      'grab bike', 'grabbike', 'grab car', 'grabcar', 'xanh sm', 'be bike', 'gojek', 'xang', 'petrolimex', //
      'gui xe', 'vetc', 'epass',
    ],
    'out',
    60,
  ),
  'bills': (
    [
      'tien dien', 'tien nuoc', 'evn', 'internet', 'fpt telecom', 'viettel', 'vnpt', 'mobifone', 'vinaphone', //
      'nap tien dien thoai', 'netflix', 'spotify', 'youtube premium', 'icloud',
    ],
    'out',
    60,
  ),
  'shopping': (
    [
      'shopee', 'lazada', 'tiki', 'tiktok shop', 'uniqlo', 'dien may xanh', 'the gioi di dong', 'cellphones', //
    ],
    'out',
    70,
  ),
  'income': (['luong', 'tra luong', 'tien thuong', 'salary', 'payroll', 'bonus'], 'in', 50),
  'refund': (['hoan tien', 'refund', 'hoan tra'], 'in', 40),
};
