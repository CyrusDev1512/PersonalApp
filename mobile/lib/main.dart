import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'models/goal.dart';
import 'screens/connect_screen.dart';
import 'screens/goal_form_screen.dart';
import 'screens/home_shell.dart';
import 'screens/manual_tx_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN');
  Intl.defaultLocale = 'vi_VN';
  runApp(const PersonalFinanceApp());
}

/// Theme Material 3, màu chủ đạo teal.
ThemeData buildTheme(Brightness brightness) => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: brightness),
  inputDecorationTheme: const InputDecorationTheme(isDense: true),
);

/// Gốc ứng dụng "Chi tiêu".
///
/// [state] cho phép test truyền sẵn AppState (với ApiClient giả); mặc định app tự tạo
/// AppState đọc URL/token từ shared_preferences.
class PersonalFinanceApp extends StatelessWidget {
  const PersonalFinanceApp({
    super.key,
    this.state,
    this.clientFactory,
    this.refreshInterval = const Duration(seconds: 30),
  });

  final AppState? state;
  final ApiClientFactory? clientFactory;
  final Duration? refreshInterval;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'Chi tiêu',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const RootGate(),
      routes: {HomeShell.routeName: (_) => const HomeShell(), ManualTxScreen.routeName: (_) => const ManualTxScreen()},
      onGenerateRoute: _onGenerateRoute,
    );
    final existing = state;
    if (existing != null) return ChangeNotifierProvider<AppState>.value(value: existing, child: app);
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState(clientFactory: clientFactory, refreshInterval: refreshInterval),
      child: app,
    );
  }

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
          builder: (_) => GoalFormScreen(goal: goal),
        );
      case ConnectScreen.routeName:
        return MaterialPageRoute<bool>(settings: settings, builder: (_) => const ConnectScreen(popOnSuccess: true));
    }
    return null;
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
    if (!connected) return const ConnectScreen();
    return const HomeShell();
  }
}
