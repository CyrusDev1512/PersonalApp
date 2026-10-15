import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../state/connection_store.dart';
import 'demo_backend.dart';
import 'demo_controls.dart';
import 'demo_push_service.dart';

/// Địa chỉ / token "máy chủ" của bản dùng thử (không có request mạng thật nào).
const String demoBaseUrl = 'https://demo.local';
const String demoToken = 'demo';

/// [ConnectionStore] chỉ lưu trong bộ nhớ (bản web không đụng tới localStorage).
class MemoryConnectionStore extends ConnectionStore {
  MemoryConnectionStore([this._info]);

  ConnectionInfo? _info;
  CachedSummary? _summary;
  String? _summaryUrl;

  @override
  Future<ConnectionInfo?> load() async => _info;

  @override
  Future<void> save(ConnectionInfo info) async => _info = info;

  @override
  Future<void> clear() async {
    _info = null;
    _summary = null;
    _summaryUrl = null;
  }

  @override
  Future<CachedSummary?> loadSummary(String baseUrl) async => _summaryUrl == baseUrl ? _summary : null;

  @override
  Future<void> saveSummary(String baseUrl, DateTime loadedAt, Map<String, dynamic> json) async {
    _summaryUrl = baseUrl;
    _summary = CachedSummary(loadedAt: loadedAt, json: json);
  }
}

/// App "Chi tiêu" thật, chạy với máy chủ giả [DemoBackend] và thông báo đẩy giả [DemoPushService].
class DemoApp extends StatefulWidget {
  const DemoApp({super.key, this.backend, this.refreshInterval = const Duration(seconds: 30)});

  /// Mặc định tạo [DemoBackend] mới (test truyền vào bản không có độ trễ).
  final DemoBackend? backend;
  final Duration? refreshInterval;

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late final DemoBackend _backend;
  late final bool _ownsBackend;
  late final DemoPushService _push;
  late final AppState _state;

  ApiClient _client(String baseUrl, String token) => ApiClient(baseUrl: baseUrl, token: token, client: _backend);

  @override
  void initState() {
    super.initState();
    _ownsBackend = widget.backend == null;
    _backend = widget.backend ?? DemoBackend();
    _push = DemoPushService(_backend);
    _state = AppState(
      client: _client(demoBaseUrl, demoToken),
      // "Đổi máy chủ / token" với địa chỉ bất kỳ vẫn dùng máy chủ giả.
      clientFactory: _client,
      store: MemoryConnectionStore(const ConnectionInfo(baseUrl: demoBaseUrl, token: demoToken)),
      refreshInterval: widget.refreshInterval,
    );
  }

  @override
  void dispose() {
    _state.dispose();
    _push.dispose();
    if (_ownsBackend) _backend.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PersonalFinanceApp(
      state: _state,
      push: _push,
      shellBuilder: (context, child, navigatorKey) => DemoShell(
        backend: _backend,
        navigatorKey: navigatorKey,
        onReconnect: () => _state.connect(_client(demoBaseUrl, demoToken)),
        child: child,
      ),
    );
  }
}
