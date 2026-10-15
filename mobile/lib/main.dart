import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'models/goal.dart';
import 'push/firebase_push_service.dart';
import 'push/push_navigator.dart';
import 'push/push_service.dart';
import 'screens/connect_screen.dart';
import 'screens/goal_form_screen.dart';
import 'screens/home_shell.dart';
import 'screens/manual_tx_screen.dart';
import 'state/app_state.dart';
import 'state/home_tabs.dart';
import 'state/push_controller.dart';
import 'theme/app_theme.dart';
import 'theme/font_licenses.dart';
import 'widgets/adaptive.dart';

export 'theme/app_theme.dart' show buildTheme;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    // Vẽ dưới thanh trạng thái / thanh điều hướng (thanh trong suốt: theme/app_theme.dart).
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  await initializeDateFormatting('vi_VN');
  Intl.defaultLocale = 'vi_VN';
  // Firebase chỉ được khởi tạo sau khi kết nối máy chủ; thiếu google-services.json thì push tự tắt.
  runApp(PersonalFinanceApp(push: FirebasePushService()));
}

/// Bọc nội dung app ngay dưới MaterialApp (quanh Navigator); [navigatorKey] là Navigator gốc của app.
typedef AppShellBuilder = Widget Function(BuildContext context, Widget child, GlobalKey<NavigatorState> navigatorKey);

/// Gốc ứng dụng "Chi tiêu".
///
/// [state] cho phép test truyền sẵn AppState (với ApiClient giả); mặc định app tự tạo
/// AppState đọc URL/token từ shared_preferences.
/// [push]: dịch vụ thông báo đẩy (main() dùng Firebase); mặc định [NoopPushService] (không có push).
/// [shellBuilder]: bọc thêm quanh Navigator (bản dùng thử trên web thêm thanh "Bản dùng thử");
/// mặc định `null` = không bọc gì.
class PersonalFinanceApp extends StatefulWidget {
  const PersonalFinanceApp({
    super.key,
    this.state,
    this.clientFactory,
    this.refreshInterval = const Duration(seconds: 30),
    this.push,
    this.shellBuilder,
  });

  final AppState? state;
  final ApiClientFactory? clientFactory;
  final Duration? refreshInterval;
  final PushService? push;
  final AppShellBuilder? shellBuilder;

  @override
  State<PersonalFinanceApp> createState() => _PersonalFinanceAppState();

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case GoalFormScreen.routeName:
        final args = settings.arguments;
        final GoalView? goal = switch (args) {
          GoalFormArgs(:final goal) => goal,
          GoalView g => g,
          _ => null,
        };
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => ContentColumn(child: GoalFormScreen(goal: goal)),
        );
      case ConnectScreen.routeName:
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => const ContentColumn(child: ConnectScreen(popOnSuccess: true)),
        );
    }
    return null;
  }
}

class _PersonalFinanceAppState extends State<PersonalFinanceApp> {
  /// Dùng để mở bảng giao dịch / hộp thoại và hiện SnackBar khi có thông báo đẩy.
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _tabs = HomeTabRequests();

  late final AppState _state;
  late final bool _ownsState;
  late final PushController _push;
  late final PushNavigator _pushNavigator;
  final List<StreamSubscription<PushMessage>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    final provided = widget.state;
    _ownsState = provided == null;
    _state = provided ?? AppState(clientFactory: widget.clientFactory, refreshInterval: widget.refreshInterval);
    _pushNavigator = PushNavigator(
      state: _state,
      tabs: _tabs,
      navigatorKey: _navigatorKey,
      messengerKey: _messengerKey,
    );
    _push = PushController(service: widget.push ?? const NoopPushService());
    _subscriptions
      ..add(_push.foregroundMessages.listen(_pushNavigator.handleForeground))
      ..add(_push.openedMessages.listen((m) => unawaited(_pushNavigator.handleOpened(m))));
    _push.attach(_state);
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    _push.dispose();
    _tabs.dispose();
    if (_ownsState) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shellBuilder;
    final app = MaterialApp(
      navigatorKey: _navigatorKey,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        // Thanh hệ thống trong suốt, icon theo theme, cả ở màn không có app bar (Kết nối, thanh demo).
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemOverlayStyleFor(Theme.of(context).brightness),
          child: shell == null ? content : shell(context, content, _navigatorKey),
        );
      },
      scaffoldMessengerKey: _messengerKey,
      title: 'Chi tiêu',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const RootGate(),
      routes: {
        HomeShell.routeName: (_) => const HomeShell(),
        ManualTxScreen.routeName: (_) => const ContentColumn(child: ManualTxScreen()),
      },
      onGenerateRoute: PersonalFinanceApp._onGenerateRoute,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: _state),
        ChangeNotifierProvider<PushController>.value(value: _push),
        ChangeNotifierProvider<HomeTabRequests>.value(value: _tabs),
      ],
      child: app,
    );
  }
}

/// Cổng lần đầu chạy: chưa có URL/token → "Kết nối máy chủ", có rồi → trang chính.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialized = context.select<AppState, bool>((s) => s.initialized);
    final connected = context.select<AppState, bool>((s) => s.isConnected);
    if (!initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!connected) return const ContentColumn(child: ConnectScreen());
    return const HomeShell();
  }
}
