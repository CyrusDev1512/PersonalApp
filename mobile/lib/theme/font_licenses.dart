import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Đường dẫn giấy phép SIL OFL 1.1 của Be Vietnam Pro (khai báo trong pubspec.yaml › assets).
const String beVietnamProLicenseAsset = 'assets/fonts/OFL.txt';

bool _registered = false;

/// Đưa giấy phép font vào LicenseRegistry (trang "Giấy phép" của app). Gọi một lần khi khởi động;
/// gọi lại không đăng ký trùng.
void registerFontLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(beVietnamProLicenseAsset);
    yield LicenseEntryWithLineBreaks(const ['Be Vietnam Pro'], text);
  });
}
