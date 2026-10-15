import 'package:flutter/foundation.dart';

/// Chỉ số các tab của HomeShell.
abstract final class HomeTab {
  static const dashboard = 0;
  static const transactions = 1;
  static const alerts = 2;
  static const settings = 3;
}

/// Yêu cầu chuyển tab từ ngoài cây widget (vd. bấm thông báo đẩy → tab Cảnh báo).
///
/// HomeShell lắng nghe và lấy yêu cầu bằng [take]; yêu cầu đến trước khi HomeShell được dựng
/// (app vừa mở từ thông báo) được giữ lại tới khi HomeShell lấy.
class HomeTabRequests extends ChangeNotifier {
  int? _pending;
  bool _uncategorized = false;

  int? get pending => _pending;

  /// [uncategorized]: mở tab Giao dịch với bộ lọc "Chưa phân loại" (vd. từ bản tin "3 giao dịch chưa phân loại").
  void request(int index, {bool uncategorized = false}) {
    _pending = index;
    _uncategorized = uncategorized && index == HomeTab.transactions;
    notifyListeners();
  }

  /// Lấy (và xoá) yêu cầu đang chờ.
  int? take() {
    final index = _pending;
    _pending = null;
    return index;
  }

  /// Yêu cầu vừa lấy có kèm bộ lọc "Chưa phân loại" không (lấy và xoá).
  bool takeUncategorized() {
    final value = _uncategorized;
    _uncategorized = false;
    return value;
  }
}
