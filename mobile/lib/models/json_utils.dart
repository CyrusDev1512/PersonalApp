/// Hàm đọc JSON "dễ tính": chấp nhận null, số thực thay cho số nguyên, chuỗi số…
/// để app không crash khi backend đổi nhẹ định dạng.
library;

typedef JsonMap = Map<String, dynamic>;

JsonMap asMap(Object? v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((key, value) => MapEntry(key.toString(), value));
  return <String, dynamic>{};
}

int? asIntOrNull(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.isFinite ? v.round() : null;
  if (v is bool) return v ? 1 : 0;
  if (v is String) return int.tryParse(v.trim()) ?? double.tryParse(v.trim())?.round();
  return null;
}

int asInt(Object? v, [int fallback = 0]) => asIntOrNull(v) ?? fallback;

double asDouble(Object? v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim()) ?? fallback;
  return fallback;
}

bool asBool(Object? v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return fallback;
}

String? asStringOrNull(Object? v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

String asString(Object? v, [String fallback = '']) => asStringOrNull(v) ?? fallback;

final RegExp _hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$', caseSensitive: false);

/// Chuỗi ISO-8601 (UTC, hậu tố `Z`) -> DateTime giờ máy (`.toLocal()`).
/// Chuỗi có giờ nhưng thiếu múi giờ được coi là UTC (đúng hợp đồng API).
DateTime? asDateTime(Object? v) {
  if (v is! String) return null;
  var s = v.trim();
  if (s.isEmpty) return null;
  if (s.contains('T') && !_hasZone.hasMatch(s)) s = '${s}Z';
  return DateTime.tryParse(s)?.toLocal();
}

List<T> asList<T>(Object? v, T Function(JsonMap json) parse) {
  if (v is! List) return <T>[];
  return [
    for (final item in v)
      if (item is Map) parse(asMap(item)),
  ];
}

List<String> asStringList(Object? v) {
  if (v is! List) return const <String>[];
  return [for (final item in v) if (item != null) item.toString()];
}
