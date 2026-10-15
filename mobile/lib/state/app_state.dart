import 'dart:async';

import 'package:flutter/widgets.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../utils/dates.dart';
import 'connection_store.dart';

typedef ApiClientFactory = ApiClient Function(String baseUrl, String token);

ApiClient _defaultFactory(String baseUrl, String token) => ApiClient(baseUrl: baseUrl, token: token);

/// Trạng thái chung của app: kết nối máy chủ + tổng quan mới nhất.
///
/// Tự tải lại mỗi [refreshInterval] khi app đang mở (foreground);
/// `refreshInterval = null` (dùng trong test) thì không có timer.
class AppState extends ChangeNotifier with WidgetsBindingObserver {
  AppState({
    ApiClient? client,
    ApiClientFactory? clientFactory,
    this.store = const ConnectionStore(),
    this.refreshInterval = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _client = client,
       _initialized = client != null,
       _factory = clientFactory ?? _defaultFactory,
       now = clock ?? DateTime.now {
    if (refreshInterval != null) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
      _restartTimer();
    }
  }

  final Duration? refreshInterval;

  /// Đồng hồ (inject được để test "cũ hơn 48 giờ").
  final DateTime Function() now;

  final ApiClientFactory _factory;

  /// Nơi lưu URL/token (shared_preferences).
  final ConnectionStore store;

  ApiClient? _client;
  bool _initialized;

  /// Đã tải được dữ liệu từ máy chủ ít nhất một lần với [_client] hiện tại.
  bool _confirmed = false;
  Summary? _summary;
  List<GoalView> _nextMonthGoals = const [];
  String? _nextMonth;
  int _goalsRequest = 0;
  bool _loading = false;
  ApiException? _error;
  DateTime? _lastLoadedAt;
  Future<void>? _inFlight;
  int _generation = 0;
  Timer? _timer;
  bool _foreground = true;
  bool _observing = false;
  bool _disposed = false;

  ApiClient? get client => _client;
  bool get isConnected => _client != null;

  /// [client] khi kết nối đã được xác nhận (tải tổng quan từ máy chủ thành công ít nhất một lần);
  /// `null` khi chưa kết nối hoặc mới chỉ có bản lưu offline.
  ApiClient? get confirmedClient => _confirmed ? _client : null;

  /// Đã đọc xong thông tin kết nối đã lưu.
  bool get initialized => _initialized;
  Summary? get summary => _summary;

  /// Mục tiêu của tháng sau (`GET /api/goals?month=<tháng sau>`) để xem/sửa trước; rỗng nếu chưa có.
  List<GoalView> get nextMonthGoals => _nextMonthGoals;

  /// Tháng ("YYYY-MM") của [nextMonthGoals].
  String? get nextMonth => _nextMonth;
  bool get loading => _loading;
  ApiException? get error => _error;
  String? get errorMessage => _error?.message;

  /// Lần tải tổng quan thành công gần nhất.
  DateTime? get lastLoadedAt => _lastLoadedAt;

  /// Lần tải gần nhất thất bại vì không tới được máy chủ.
  bool get offline => _error?.isNetwork ?? false;

  /// Tạo client cho một URL/token (màn kết nối dùng để kiểm tra trước khi lưu).
  ApiClient createClient(String baseUrl, String token) => _factory(baseUrl, token);

  /// Đọc URL/token đã lưu; có thì tạo client và tải tổng quan.
  Future<void> init() async {
    if (_initialized) {
      if (_client != null && _summary == null) unawaited(load());
      return;
    }
    ConnectionInfo? info;
    try {
      info = await store.load();
    } catch (_) {
      info = null;
    }
    if (info != null) {
      try {
        _client = _factory(info.baseUrl, info.token);
      } on ApiException {
        _client = null;
      }
    }
    final client = _client;
    if (client != null) {
      // Hiện ngay bản tổng quan gần nhất (dùng được cả khi offline), rồi tải mới.
      try {
        final cached = await store.loadSummary(client.baseUrl);
        if (cached != null) {
          _summary = Summary.fromJson(cached.json);
          _lastLoadedAt = cached.loadedAt;
        }
      } catch (_) {
        // Cache hỏng: bỏ qua.
      }
    }
    _initialized = true;
    _notify();
    if (_client != null) {
      _restartTimer();
      unawaited(load());
    }
  }

  /// Lưu kết nối đã kiểm tra và chuyển sang dùng [client].
  /// [summaryJson]: tổng quan vừa tải khi kiểm tra (tránh gọi lại).
  Future<void> connect(ApiClient client, {JsonMap? summaryJson}) async {
    await store.save(ConnectionInfo(baseUrl: client.baseUrl, token: client.token));
    _setClient(client);
    if (summaryJson != null) {
      final s = Summary.fromJson(summaryJson);
      _applyLoaded(s);
      unawaited(_saveCache(client.baseUrl, summaryJson));
      unawaited(_loadNextMonthGoals(client, _generation, s.month));
    } else {
      unawaited(load());
    }
  }

  /// Xoá kết nối đã lưu (quay về màn "Kết nối máy chủ").
  Future<void> disconnect() async {
    await store.clear();
    _setClient(null);
  }

  void _setClient(ApiClient? client) {
    _generation++;
    _client = client;
    _confirmed = false;
    _initialized = true;
    _summary = null;
    _nextMonthGoals = const [];
    _nextMonth = null;
    _error = null;
    _lastLoadedAt = null;
    _loading = false;
    _inFlight = null;
    _restartTimer();
    _notify();
  }

  /// Tải lại GET /api/summary. Gọi trùng khi đang tải thì dùng chung một request.
  Future<void> load() {
    final client = _client;
    if (client == null) return Future.value();
    return _inFlight ??= _load(client, _generation);
  }

  Future<void> _load(ApiClient client, int generation) async {
    _loading = true;
    _notify();
    try {
      final raw = await client.getSummaryJson();
      final s = Summary.fromJson(raw);
      if (generation != _generation) return;
      _applyLoaded(s);
      unawaited(_saveCache(client.baseUrl, raw));
      await _loadNextMonthGoals(client, generation, s.month);
    } on ApiException catch (e) {
      if (generation != _generation) return;
      _error = e;
    } catch (_) {
      if (generation != _generation) return;
      _error = const ApiException(null, ApiMessages.badResponse);
    } finally {
      if (generation == _generation) {
        _loading = false;
        _inFlight = null;
        _notify();
      }
    }
  }

  void _applyLoaded(Summary s) {
    _confirmed = _client != null;
    _summary = s;
    _error = null;
    _lastLoadedAt = now();
    _notify();
  }

  Future<void> _saveCache(String baseUrl, JsonMap raw) async {
    try {
      await store.saveSummary(baseUrl, _lastLoadedAt ?? now(), raw);
    } catch (_) {
      // Không lưu được cache thì thôi, không ảnh hưởng app.
    }
  }

  /// Tải mục tiêu tháng sau tháng [month] của tổng quan. Lỗi thì bỏ qua (giữ danh sách cũ nếu cùng tháng).
  Future<void> _loadNextMonthGoals(ApiClient client, int generation, String month) async {
    final next = shiftMonth(parseMonth(month) == null ? currentMonthIct(now()) : month, 1);
    final id = ++_goalsRequest;
    List<GoalView>? goals;
    try {
      goals = await client.listGoals(month: next);
    } catch (_) {
      goals = null;
    }
    if (generation != _generation || id != _goalsRequest) return;
    if (goals == null && _nextMonth == next) return;
    _nextMonth = next;
    _nextMonthGoals = goals ?? const [];
    _notify();
  }

  /// Dùng tổng quan server trả kèm (vd. sau PATCH giao dịch) thay vì tải lại.
  void applySummary(Summary s) {
    _applyLoaded(s);
    final client = _client;
    // Thao tác có thể đổi mục tiêu tháng sau (vd. "Tính cho tháng sau").
    if (client != null) unawaited(_loadNextMonthGoals(client, _generation, s.month));
  }

  // ------------------------------------------------------------ tự làm mới

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    final interval = refreshInterval;
    if (interval == null || _client == null || !_foreground || _disposed) return;
    _timer = Timer.periodic(interval, (_) => load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        _restartTimer();
        unawaited(load());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _foreground = false;
        _restartTimer();
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
