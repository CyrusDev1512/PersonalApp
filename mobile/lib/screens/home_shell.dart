import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/home_tabs.dart';
import '../widgets/adaptive.dart';
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

  /// Các tab đã mở ít nhất một lần; tab chưa mở thì chưa dựng (khỏi tải dữ liệu thừa).
  final Set<int> _opened = {};

  /// Mở tab Giao dịch với bộ lọc "Chưa phân loại" (khi đi từ chip ở Tổng quan).
  final _transactions = TransactionsController();

  /// Yêu cầu chuyển tab từ ngoài (bấm thông báo đẩy); có thể không có (test dựng HomeShell riêng).
  HomeTabRequests? _tabRequests;

  @override
  void initState() {
    super.initState();
    _tabRequests = Provider.of<HomeTabRequests?>(context, listen: false);
    _tabRequests?.addListener(_onTabRequest);
    _index = _validIndex(_tabRequests?.take()) ?? widget.initialIndex;
    _opened.add(_index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      if (state.summary == null && !state.loading) state.load();
    });
  }

  @override
  void dispose() {
    _tabRequests?.removeListener(_onTabRequest);
    _transactions.dispose();
    super.dispose();
  }

  static int? _validIndex(int? index) => index != null && index >= 0 && index <= HomeTab.settings ? index : null;

  void _onTabRequest() {
    final index = _validIndex(_tabRequests?.take());
    if (index != null && mounted) _select(index);
  }

  void _select(int index) {
    setState(() {
      _index = index;
      _opened.add(index);
    });
  }

  void _openUncategorized() {
    _transactions.showUncategorized();
    _select(HomeTab.transactions);
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<AppState, int>((s) => s.summary?.unreadAlerts ?? 0);
    // Cửa sổ rộng (≥ 840 dp): NavigationRail bên trái, FAB "Thêm mục tiêu" ở đầu rail.
    final useRail = WindowClass.of(context).usesRail;
    // Giữ trạng thái các tab (tháng, bộ lọc, vị trí cuộn, chữ đang gõ) khi chuyển tab; tab tự tải lại khi hiện lại.
    final tabs = <Widget>[
      DashboardScreen(onOpenUncategorized: _openUncategorized),
      TransactionsScreen(controller: _transactions, active: _index == HomeTab.transactions),
      AlertsScreen(active: _index == HomeTab.alerts),
      SettingsScreen(active: _index == HomeTab.settings),
    ];
    final body = ShellScope(
      primaryActionInRail: useRail,
      child: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < tabs.length; i++)
            // Tab ẩn: tắt Hero (các FAB trùng tag mặc định) và animation.
            HeroMode(
              enabled: i == _index,
              child: TickerMode(
                enabled: i == _index,
                // Màn hình rộng: một cột nội dung tối đa 720 dp ở giữa, không kéo giãn bố cục điện thoại.
                child: _opened.contains(i) ? ContentColumn(child: tabs[i]) : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
    final alertsBadge = unread > 99 ? '99+' : '$unread';
    if (useRail) {
      // Không bọc Scaffold: Scaffold của từng tab là gốc, nên SnackBar nổi trong cột nội dung, trên FAB của tab.
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              leading: const _RailPrimaryAction(),
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Tổng quan'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text('Giao dịch'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text(alertsBadge),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text(alertsBadge),
                    child: const Icon(Icons.notifications),
                  ),
                  label: const Text('Cảnh báo'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Cài đặt'),
                ),
              ],
            ),
            Expanded(child: body),
          ],
        ),
      );
    }
    // Không bọc Scaffold: Scaffold của từng tab là gốc, nên SnackBar nổi phía trên FAB của tab (không đè lên
    // "Thêm mục tiêu"). Thanh điều hướng tự chừa vùng cử chỉ; phần nội dung bỏ phần đệm dưới đó đi. Bàn phím đang
    // mở: thanh điều hướng nằm dưới bàn phím nên ẩn đi, để Scaffold của tab tự tránh bàn phím cho đúng (cấu trúc
    // cây giữ nguyên để không mất trạng thái các tab).
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(context: context, removeBottom: !keyboard, child: body),
          ),
          if (keyboard) const SizedBox.shrink() else _bottomBar(unread, alertsBadge),
        ],
      ),
    );
  }

  Widget _bottomBar(int unread, String alertsBadge) {
    return NavigationBar(
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
              label: Text(alertsBadge),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text(alertsBadge),
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
    );
  }
}

/// FAB "Thêm mục tiêu" ở đầu NavigationRail (cửa sổ rộng). Ẩn (không vô hiệu hoá) khi chưa có dữ liệu nào
/// vì lỗi tải: lúc đó "Thử lại" là hành động của màn hình.
class _RailPrimaryAction extends StatelessWidget {
  const _RailPrimaryAction();

  @override
  Widget build(BuildContext context) {
    final noData = context.select<AppState, bool>((s) => s.summary == null && s.error != null);
    if (noData) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FloatingActionButton.extended(
        key: const Key('rail_add_goal'),
        // Không dùng Hero: tab Giao dịch có FAB riêng với tag mặc định.
        heroTag: null,
        onPressed: () => DashboardScreen.openGoalForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm mục tiêu'),
      ),
    );
  }
}
