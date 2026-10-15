import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'demo/demo_app.dart';
import 'demo/demo_controls.dart';

/// Font đi kèm bản web (scripts/build_web_demo.sh chép vào build/web/fonts/): nạp trước runApp để engine
/// không phải tải font dự phòng (emoji, ký hiệu) từ fonts.gstatic.com. Roboto Regular đầy đủ đã được
/// `flutter build web --no-web-resources-cdn` đóng gói sẵn (assets/fonts/fallback/, khai báo trong FontManifest),
/// ở đây chỉ thêm các độ đậm Medium/Bold dùng cho tiêu đề, nút, số tiền.
const List<(String, String)> demoFonts = [
  ('Roboto', 'fonts/Roboto-Medium.ttf'),
  ('Roboto', 'fonts/Roboto-Bold.ttf'),
  (demoEmojiFontFamily, 'fonts/NotoColorEmoji.ttf'),
  (demoSymbolsFontFamily, 'fonts/DejaVuSans-Symbols.ttf'),
];

/// Bản dùng thử chạy trong trình duyệt: app thật + máy chủ giả trong app (không cần server, không gọi mạng).
///
/// Build: `scripts/build_web_demo.sh` (flutter build web -t lib/main_demo.dart).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN');
  Intl.defaultLocale = 'vi_VN';
  if (kIsWeb) {
    await loadDemoFonts();
    // Luôn bật semantics trên web (trình đọc màn hình, và để test tự động tìm widget theo nhãn).
    SemanticsBinding.instance.ensureSemantics();
  }
  runApp(const DemoApp());
}

/// Nạp các font trong [demoFonts] từ URL tương đối (cạnh index.html). Lỗi thì bỏ qua font đó.
Future<void> loadDemoFonts() async {
  final client = http.Client();
  try {
    await Future.wait([for (final (family, path) in demoFonts) _loadFont(client, family, path)]);
  } finally {
    client.close();
  }
}

Future<void> _loadFont(http.Client client, String family, String path) async {
  try {
    final resp = await client.get(Uri.base.resolve(path));
    if (resp.statusCode != 200) {
      debugPrint('Không nạp được font $path (HTTP ${resp.statusCode})');
      return;
    }
    await ui.loadFontFromList(resp.bodyBytes, fontFamily: family);
  } catch (e) {
    debugPrint('Không nạp được font $path: $e');
  }
}
