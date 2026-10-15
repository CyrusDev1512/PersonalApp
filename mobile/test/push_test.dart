import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance/api/api_client.dart';
import 'package:personal_finance/main.dart';
import 'package:personal_finance/push/push_service.dart';
import 'package:personal_finance/screens/connect_screen.dart';
import 'package:personal_finance/screens/tx_action_sheet.dart';
import 'package:personal_finance/state/app_state.dart';
import 'package:personal_finance/state/push_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

const _token = 'fcm:token-1';
final _encodedToken = Uri.encodeComponent(_token);

Map<String, dynamic> _alertJson({int id = 10, bool read = false, int? txId = 55, String kind = 'tx'}) => {
  'id': id,
  'created_at': '2026-10-14T02:59:05Z',
  'kind': kind,
  'level': kind == 'tx' ? 'WARNING' : 'OK',
  'title': kind == 'tx' ? '⚠️ Sắp chạm mức mục tiêu' : '📈 Dự báo cuối tháng',
  'message': kind == 'tx' ? '−3.500.000đ · VCB ...' : 'Chi như hiện tại thì khoảng ngày 25/10 sẽ chạm mức sàn',
  'read': read,
  'transaction_id': txId,
  'goal_id': null,
};

Map<String, dynamic> _txJson() => {
  'id': 55,
  'account_id': 1,
  'account_name': 'VCB chính',
  'bank': 'VCB',
  'direction': 'out',
  'amount': 3500000,
  'bank_time': '2026-10-14T02:59:00Z',
  'time_precision': 'second',
  'description': 'RUT TIEN ATM',
  'reference_code': 'FT26287',
  'balance_after': 6500000,
  'category_id': null,
  'goal_id': null,
  'suggested_rule': 'rut tien atm',
  'categorized_by': 'none',
  'status': 'active',
  'is_manual': false,
  'affects_balance': true,
  'pair_id': null,
  'sources': ['sepay'],
  'possible_duplicate_of': null,
};

FakeServer _server({bool pushEnabled = true, Map<String, Object? Function(RecordedRequest req)> extra = const {}}) =>
    FakeServer({
      'GET /health': (_) => {'status': 'ok', 'time': '2026-10-14T03:00:00Z', 'version': '0.1.0'},
      'GET /api/summary': (_) => warningSummaryJson(),
      'GET /api/goals': (_) => <Object>[],
      'GET /api/categories': (_) => categoriesJson(),
      'GET /api/accounts': (_) => [accountJson()],
      'GET /api/settings': (_) => {
        'warning_percent': 10,
        'warning_min_amount': 500000,
        'expected_income_amount': 0,
        'expected_income_day': 0,
        'notify_every_tx': true,
      },
      'GET /api/transactions': (_) => {'items': <Object>[], 'total': 0},
      'GET /api/transactions/55': (_) => _txJson(),
      'GET /api/alerts': (_) => [_alertJson(), _alertJson(id: 9, read: true, txId: null, kind: 'forecast')],
      'GET /api/alerts/10': (_) => _alertJson(),
      'GET /api/alerts/9': (_) => _alertJson(id: 9, txId: null, kind: 'forecast'),
      'POST /api/alerts/10/read': (_) => _alertJson(read: true),
      'POST /api/alerts/9/read': (_) => _alertJson(id: 9, read: true, txId: null, kind: 'forecast'),
      'POST /api/devices': (req) => jsonResponse({
        'id': 3,
        'platform': (req.json as Map)['platform'],
        'app_version': (req.json as Map)['app_version'],
        'last_seen_at': '2026-10-14T03:00:00Z',
        'push_enabled': pushEnabled,
      }, 201),
      'GET /api/devices': (_) => {
        'push_enabled': pushEnabled,
        'error': pushEnabled ? null : 'Chưa đặt FCM_SERVICE_ACCOUNT_FILE',
        'devices': [
          {
            'id': 3,
            'platform': 'android',
            'app_version': '1.0.0',
            'created_at': '2026-10-14T03:00:00Z',
            'last_seen_at': '2026-10-14T03:00:00Z',
            'last_error': null,
          },
        ],
      },
      'DELETE /api/devices/$_encodedToken': (_) => http.Response('', 204),
      'POST /api/devices/test': (_) => jsonResponse({'queued': true, 'push_enabled': pushEnabled}, 202),
      ...extra,
    });

/// `POST /api/devices` trả lần lượt các mã [statuses] (≥ 300 là lỗi), hết danh sách thì 201.
Object? Function(RecordedRequest req) _flakyRegister(List<int> statuses) {
  var calls = 0;
  return (req) {
    final code = calls < statuses.length ? statuses[calls] : 201;
    calls++;
    if (code >= 300) return jsonResponse({'detail': 'Service Unavailable'}, code);
    return jsonResponse({
      'id': 3,
      'platform': 'android',
      'app_version': '1.0.0',
      'last_seen_at': '2026-10-14T03:00:00Z',
      'push_enabled': true,
    }, code);
  };
}

void _useTallScreen(WidgetTester tester) {
  // Bố cục điện thoại / máy tính bảng dọc (< 840 dp: NavigationBar); cao để không phải cuộn.
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// App đã kết nối sẵn máy chủ giả, dùng [push].
Future<AppState> _pumpConnected(
  WidgetTester tester,
  FakeServer server,
  PushService push, {
  DateTime Function()? clock,
}) async {
  _useTallScreen(tester);
  final state = AppState(
    client: ApiClient(baseUrl: 'https://finance.example.com', token: 'tok', client: server.client),
    refreshInterval: null,
    clock: clock,
  );
  addTearDown(state.dispose);
  await tester.pumpWidget(PersonalFinanceApp(state: state, refreshInterval: null, push: push));
  await tester.pumpAndSettle();
  return state;
}

FakePushService _fakePush() {
  final push = FakePushService();
  addTearDown(push.close);
  return push;
}

Future<void> _goTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

PushController _controller(WidgetTester tester) =>
    Provider.of<PushController>(tester.element(find.byType(NavigationBar)), listen: false);

Future<void> _disconnectFromSettings(WidgetTester tester) async {
  await _goTab(tester, 'Cài đặt');
  await tester.tap(find.widgetWithText(TextButton, 'Ngắt kết nối'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Ngắt kết nối'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('PushMessage.fromData: mọi giá trị thành chuỗi, chuỗi rỗng coi như không có', () {
    final m = PushMessage.fromData(
      {'alert_id': '10', 'kind': 'tx', 'level': 'WARNING', 'transaction_id': 55, 'goal_id': '', 'month': '2026-10'},
      title: ' ⚠️ Sắp chạm mức ',
      body: '',
    );
    expect(m.title, '⚠️ Sắp chạm mức');
    expect(m.body, isNull);
    expect(m.alertId, '10');
    expect(m.alertIdValue, 10);
    expect(m.kind, 'tx');
    expect(m.level, 'WARNING');
    expect(m.transactionId, '55');
    expect(m.transactionIdValue, 55);
    expect(m.goalId, isNull);
    expect(m.month, '2026-10');
    expect(const PushMessage().transactionIdValue, isNull);
  });

  testWidgets('kết nối máy chủ xong thì đăng ký thiết bị (POST /api/devices)', (tester) async {
    final server = _server();
    final push = _fakePush();
    _useTallScreen(tester);
    await tester.pumpWidget(
      PersonalFinanceApp(
        refreshInterval: null,
        push: push,
        clientFactory: (url, t) => ApiClient(baseUrl: url, token: t, client: server.client),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ConnectScreen), findsOneWidget);
    // Chưa kết nối: chưa đụng tới Firebase.
    expect(push.initCalls, 0);
    expect(server.where('POST', '/api/devices'), isEmpty);

    await tester.enterText(find.byKey(const Key('connect_url')), 'https://finance.example.com');
    await tester.enterText(find.byKey(const Key('connect_token')), 'tok');
    await tester.tap(find.byKey(const Key('connect_submit')));
    await tester.pumpAndSettle();

    expect(find.byType(ConnectScreen), findsNothing);
    expect(push.initCalls, 1);
    expect(push.permissionCalls, 1);
    final post = server.where('POST', '/api/devices').single;
    expect(post.json, {'token': _token, 'platform': 'android', 'app_version': '1.0.0'});
    expect(post.headers['Authorization'], 'Bearer tok');
    // POST báo push_enabled=true: không cần hỏi thêm GET /api/devices.
    expect(server.where('GET', '/api/devices'), isEmpty);
  });

  testWidgets('token FCM đổi thì đăng ký lại', (tester) async {
    final server = _server();
    final push = _fakePush();
    await _pumpConnected(tester, server, push);
    expect(server.where('POST', '/api/devices'), hasLength(1));

    push.tokenRefresh.add('fcm:token-2');
    await tester.pumpAndSettle();

    final posts = server.where('POST', '/api/devices').toList();
    expect(posts, hasLength(2));
    expect((posts.last.json as Map)['token'], 'fcm:token-2');
    // Trùng token đang đăng ký thì không gửi lại.
    push.tokenRefresh.add('fcm:token-2');
    await tester.pumpAndSettle();
    expect(server.where('POST', '/api/devices'), hasLength(2));
  });

  testWidgets('bấm thông báo có transaction_id: tải giao dịch và mở bảng thao tác', (tester) async {
    final server = _server();
    final push = _fakePush();
    await _pumpConnected(tester, server, push);

    push.opened.add(
      PushMessage.fromData(
        {'alert_id': '10', 'kind': 'tx', 'level': 'WARNING', 'transaction_id': '55', 'goal_id': '', 'month': '2026-10'},
        title: '⚠️ Sắp chạm mức mục tiêu',
        body: '−3.500.000đ · VCB',
      ),
    );
    await tester.pumpAndSettle();

    expect(server.where('GET', '/api/transactions/55'), hasLength(1));
    expect(find.byType(TxActionSheet), findsOneWidget);
    expect(find.descendant(of: find.byType(TxActionSheet), matching: find.text('RUT TIEN ATM')), findsOneWidget);
    expect(find.text('Tính cho tháng sau'), findsOneWidget);
    // Đã mở thông báo thì cảnh báo được đánh dấu đã đọc.
    expect(server.where('POST', '/api/alerts/10/read'), hasLength(1));
  });

  testWidgets('bấm thông báo không có giao dịch: sang tab Cảnh báo và mở cảnh báo', (tester) async {
    final server = _server();
    final push = _fakePush();
    await _pumpConnected(tester, server, push);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);

    push.opened.add(
      PushMessage.fromData({
        'alert_id': '9',
        'kind': 'forecast',
        'level': 'WARNING',
        'transaction_id': '',
        'goal_id': '',
        'month': '2026-10',
      }),
    );
    await tester.pumpAndSettle();

    expect(server.where('GET', '/api/transactions/55'), isEmpty);
    expect(server.where('GET', '/api/alerts/9'), hasLength(1));
    expect(server.where('POST', '/api/alerts/9/read'), hasLength(1));
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 2);
    expect(find.byKey(const Key('push_alert_dialog')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('push_alert_dialog')),
        matching: find.text('Chi như hiện tại thì khoảng ngày 25/10 sẽ chạm mức sàn'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('push_alert_dialog')), findsNothing);
    // Tab Cảnh báo đã mở và tải danh sách.
    expect(server.where('GET', '/api/alerts'), isNotEmpty);
  });

  testWidgets('thông báo khi app đang mở: SnackBar + tải lại tổng quan; "Xem" mở giao dịch', (tester) async {
    final server = _server();
    final push = _fakePush();
    await _pumpConnected(tester, server, push);
    final summaryLoads = server.where('GET', '/api/summary').length;

    push.foreground.add(
      PushMessage.fromData(
        {'alert_id': '10', 'kind': 'tx', 'level': 'WARNING', 'transaction_id': '55'},
        title: '⚠️ Sắp chạm mức mục tiêu',
        body: '−3.500.000đ · VCB',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('push_snackbar')), findsOneWidget);
    // Gọn: tiêu đề + dòng đầu của nội dung.
    final snackbar = find.byKey(const Key('push_snackbar'));
    expect(find.descendant(of: snackbar, matching: find.text('⚠️ Sắp chạm mức mục tiêu')), findsOneWidget);
    expect(find.descendant(of: snackbar, matching: find.text('−3.500.000đ · VCB')), findsOneWidget);
    expect(server.where('GET', '/api/summary').length, summaryLoads + 1);
    expect(find.byType(TxActionSheet), findsNothing);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Xem'));
    await tester.pumpAndSettle();
    expect(server.where('GET', '/api/transactions/55'), hasLength(1));
    expect(find.byType(TxActionSheet), findsOneWidget);
  });

  testWidgets('ngắt kết nối: DELETE /api/devices/{token} rồi xoá token trên máy', (tester) async {
    final server = _server();
    final push = _fakePush();
    int? requestsWhenTokenDeleted;
    push.onDeleteToken = () => requestsWhenTokenDeleted = server.requests.length;
    await _pumpConnected(tester, server, push);

    await _goTab(tester, 'Cài đặt');
    await tester.tap(find.widgetWithText(TextButton, 'Ngắt kết nối'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ngắt kết nối'));
    await tester.pumpAndSettle();

    expect(find.byType(ConnectScreen), findsOneWidget);
    final delete = server.where('DELETE', '/api/devices/$_encodedToken').single;
    expect(delete.url.toString(), 'https://finance.example.com/api/devices/fcm%3Atoken-1');
    expect(delete.headers['Authorization'], 'Bearer tok');
    expect(push.deleteTokenCalls, 1);
    // DELETE gửi trước khi xoá token.
    expect(requestsWhenTokenDeleted, server.requests.indexOf(delete) + 1);
  });

  testWidgets('Cài đặt với NoopPushService: "chưa cấu hình" + hướng dẫn, không gửi thử được', (tester) async {
    final server = _server();
    await _pumpConnected(tester, server, const NoopPushService());
    await _goTab(tester, 'Cài đặt');

    final status = find.byKey(const Key('push_status'));
    await tester.ensureVisible(status);
    await tester.pumpAndSettle();
    expect(find.text('Thông báo đẩy'), findsOneWidget);
    expect(find.descendant(of: status, matching: find.textContaining('chưa cấu hình')), findsOneWidget);
    expect(find.textContaining('Bản build này chưa có Firebase — xem README'), findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(find.byKey(const Key('push_test')));
    expect(button.onPressed, isNull);
    expect(server.requests.where((r) => r.url.path.startsWith('/api/devices')), isEmpty);
  });

  testWidgets('Cài đặt: push đang bật thì "Gửi thử" gọi POST /api/devices/test', (tester) async {
    final server = _server();
    final push = _fakePush();
    await _pumpConnected(tester, server, push);
    await _goTab(tester, 'Cài đặt');

    final status = find.byKey(const Key('push_status'));
    await tester.ensureVisible(status);
    await tester.pumpAndSettle();
    expect(find.descendant(of: status, matching: find.text('Đang bật')), findsOneWidget);
    // Mở Cài đặt thì đọc lại trạng thái máy chủ.
    expect(server.where('GET', '/api/devices'), hasLength(1));

    await tester.tap(find.byKey(const Key('push_test')));
    await tester.pumpAndSettle();
    expect(server.where('POST', '/api/devices/test'), hasLength(1));
    expect(find.text('Đã gửi thông báo thử, chờ vài giây.'), findsOneWidget);
  });

  testWidgets('máy chủ chưa cấu hình Firebase: trạng thái server_not_configured kèm lỗi', (tester) async {
    final server = _server(pushEnabled: false);
    final push = _fakePush();
    await _pumpConnected(tester, server, push);
    // POST báo push_enabled=false → hỏi GET /api/devices để lấy lý do.
    expect(server.where('POST', '/api/devices'), hasLength(1));
    expect(server.where('GET', '/api/devices'), hasLength(1));

    await _goTab(tester, 'Cài đặt');
    final status = find.byKey(const Key('push_status'));
    await tester.ensureVisible(status);
    await tester.pumpAndSettle();
    expect(find.descendant(of: status, matching: find.text('Máy chủ chưa cấu hình Firebase')), findsOneWidget);
    expect(find.descendant(of: status, matching: find.textContaining('FCM_SERVICE_ACCOUNT_FILE')), findsOneWidget);
  });

  testWidgets('không được cấp quyền thông báo: không đăng ký, hiện hướng dẫn và "Thử lại"', (tester) async {
    final server = _server();
    final push = _fakePush()..permission = PushPermission.denied;
    await _pumpConnected(tester, server, push);
    expect(server.where('POST', '/api/devices'), isEmpty);

    await _goTab(tester, 'Cài đặt');
    final status = find.byKey(const Key('push_status'));
    await tester.ensureVisible(status);
    await tester.pumpAndSettle();
    expect(find.descendant(of: status, matching: find.text('Chưa được cấp quyền thông báo')), findsOneWidget);

    // Người dùng bật quyền trong cài đặt máy rồi bấm "Thử lại".
    push.permission = PushPermission.granted;
    await tester.tap(find.widgetWithText(TextButton, 'Thử lại'));
    await tester.pumpAndSettle();
    expect(server.where('POST', '/api/devices'), hasLength(1));
    expect(find.descendant(of: status, matching: find.text('Đang bật')), findsOneWidget);
  });

  testWidgets('bản build không có Firebase (init lỗi): app vẫn chạy, không gọi API thiết bị', (tester) async {
    final server = _server();
    final push = _fakePush()..initOk = false;
    await _pumpConnected(tester, server, push);
    expect(push.initCalls, 1);
    expect(push.permissionCalls, 0);
    expect(find.text('Sắp chạm mức mục tiêu'), findsOneWidget);
    expect(server.requests.where((r) => r.url.path.startsWith('/api/devices')), isEmpty);
  });

  testWidgets('ngắt kết nối khi chưa tải được tổng quan (máy chủ không tới được): vẫn huỷ token cũ', (tester) async {
    // Phiên trước đã đăng ký thiết bị ở máy chủ này; giờ mở app với kết nối đã lưu nhưng không tới được máy chủ.
    SharedPreferences.setMockInitialValues({'server_url': 'https://finance.example.com', 'app_token': 'tok'});
    final server = _server(
      extra: {
        'GET /api/summary': (_) => throw http.ClientException('no route'),
        'DELETE /api/devices/$_encodedToken': (_) => throw http.ClientException('no route'),
      },
    );
    final push = _fakePush();
    _useTallScreen(tester);
    await tester.pumpWidget(
      PersonalFinanceApp(
        refreshInterval: null,
        push: push,
        clientFactory: (url, t) => ApiClient(baseUrl: url, token: t, client: server.client),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ConnectScreen), findsNothing);
    expect(server.where('POST', '/api/devices'), isEmpty);

    await _disconnectFromSettings(tester);

    expect(find.byType(ConnectScreen), findsOneWidget);
    // Thử DELETE token Firebase hiện có ở máy chủ cũ...
    final delete = server.where('DELETE', '/api/devices/$_encodedToken').single;
    expect(delete.headers['Authorization'], 'Bearer tok');
    // ...lỗi cũng vẫn xoá token trên máy để máy chủ cũ chỉ còn token hết hiệu lực.
    expect(push.initCalls, 1);
    expect(push.deleteTokenCalls, 1);
    expect(push.token, isNull);
  });

  testWidgets('đổi máy chủ khi máy chủ cũ chưa tải được: huỷ ở máy chủ cũ, đổi token, đăng ký ở máy chủ mới', (
    tester,
  ) async {
    final old = _server(extra: {'GET /api/summary': (_) => throw http.ClientException('no route')});
    final next = _server();
    final push = _fakePush()..tokenAfterDelete = 'fcm:token-2';
    var tokenDeletedAfterDelete = false;
    push.onDeleteToken = () => tokenDeletedAfterDelete = old.where('DELETE', '/api/devices/$_encodedToken').isNotEmpty;
    final state = await _pumpConnected(tester, old, push);
    expect(old.where('POST', '/api/devices'), isEmpty);

    await state.connect(ApiClient(baseUrl: 'https://new.example.com', token: 'tok-2', client: next.client));
    await tester.pumpAndSettle();

    final delete = old.where('DELETE', '/api/devices/$_encodedToken').single;
    expect(delete.headers['Authorization'], 'Bearer tok');
    expect(push.deleteTokenCalls, 1);
    expect(tokenDeletedAfterDelete, isTrue);
    final post = next.where('POST', '/api/devices').single;
    expect((post.json as Map)['token'], 'fcm:token-2');
    expect(post.headers['Authorization'], 'Bearer tok-2');
    expect(next.requests.where((r) => r.method == 'DELETE'), isEmpty);
    expect(_controller(tester).status, PushStatus.enabled);
    expect(_controller(tester).registeredToken, 'fcm:token-2');
  });

  testWidgets('ngắt kết nối với NoopPushService: không gọi API thiết bị, không lỗi', (tester) async {
    final server = _server();
    await _pumpConnected(tester, server, const NoopPushService());

    await _disconnectFromSettings(tester);

    expect(find.byType(ConnectScreen), findsOneWidget);
    expect(server.requests.where((r) => r.url.path.startsWith('/api/devices')), isEmpty);
  });

  testWidgets('đăng ký lỗi (503): lần tải tổng quan thành công sau ≥ 2 phút thì đăng ký lại', (tester) async {
    var now = DateTime(2026, 10, 14, 10);
    final server = _server(
      extra: {
        'POST /api/devices': _flakyRegister([503]),
      },
    );
    final push = _fakePush();
    final state = await _pumpConnected(tester, server, push, clock: () => now);
    final controller = _controller(tester);
    expect(controller.status, PushStatus.error);
    expect(server.where('POST', '/api/devices'), hasLength(1));

    // Chưa đủ 2 phút: chưa thử lại.
    now = now.add(const Duration(seconds: 30));
    await state.load();
    await tester.pumpAndSettle();
    expect(server.where('POST', '/api/devices'), hasLength(1));
    expect(controller.status, PushStatus.error);

    // Mở lại app sau 2 phút → tải tổng quan → đăng ký lại.
    now = now.add(const Duration(minutes: 2));
    state.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(server.where('POST', '/api/devices'), hasLength(2));
    expect(controller.status, PushStatus.enabled);
    expect(controller.registeredToken, _token);

    // Đã bật: không gửi thêm.
    now = now.add(const Duration(minutes: 5));
    await state.load();
    await tester.pumpAndSettle();
    expect(server.where('POST', '/api/devices'), hasLength(2));
  });

  testWidgets('token mới gửi lỗi: giữ lại và gửi lại ở lần tải tổng quan sau ≥ 2 phút', (tester) async {
    var now = DateTime(2026, 10, 14, 10);
    final server = _server(
      extra: {
        'POST /api/devices': _flakyRegister([201, 503]),
      },
    );
    final push = _fakePush();
    final state = await _pumpConnected(tester, server, push, clock: () => now);
    final controller = _controller(tester);
    expect(controller.status, PushStatus.enabled);

    push.tokenRefresh.add('fcm:token-2');
    await tester.pumpAndSettle();
    expect(controller.status, PushStatus.error);
    expect(controller.registeredToken, _token);

    now = now.add(const Duration(minutes: 1));
    await state.load();
    await tester.pumpAndSettle();
    expect(server.where('POST', '/api/devices'), hasLength(2));

    now = now.add(const Duration(minutes: 2));
    await state.load();
    await tester.pumpAndSettle();
    final tokens = server.where('POST', '/api/devices').map((r) => (r.json as Map)['token']).toList();
    expect(tokens, [_token, 'fcm:token-2', 'fcm:token-2']);
    expect(controller.registeredToken, 'fcm:token-2');
    expect(controller.status, PushStatus.enabled);
  });
}
