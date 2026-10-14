import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

/// Khung chính với thanh điều hướng: Tổng quan / Giao dịch / Cảnh báo / Cài đặt.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  static const routeName = '/home';

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index;

  /// Tab Giao dịch mở với bộ lọc "Chưa phân loại" (khi đi từ chip ở Tổng quan).
  bool _txUncategorized = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      if (state.summary == null && !state.loading) state.load();
    });
  }

  void _select(int index) {
    setState(() {
      _index = index;
      _txUncategorized = false;
    });
  }

  void _openUncategorized() {
    setState(() {
      _index = 1;
      _txUncategorized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<AppState, int>((s) => s.summary?.unreadAlerts ?? 0);
    final body = switch (_index) {
      0 => DashboardScreen(onOpenUncategorized: _openUncategorized, onOpenAlerts: () => _select(2)),
      1 => TransactionsScreen(
          key: ValueKey('tx_$_txUncategorized'),
          initialUncategorized: _txUncategorized,
        ),
      2 => const AlertsScreen(),
      _ => const SettingsScreen(),
    };
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Giao dịch',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Cảnh báo',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
