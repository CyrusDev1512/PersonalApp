import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/status_colors.dart';
import '../theme/tokens.dart';
import '../utils/dates.dart';
import '../widgets/account_dialog.dart';
import '../widgets/account_row.dart';
import '../widgets/adaptive.dart';
import '../widgets/common.dart';
import '../widgets/forecast_card.dart';
import '../widgets/goal_row.dart';
import '../widgets/list_group.dart';
import '../widgets/status_hero.dart';
import 'goal_form_screen.dart';

/// Màn "Tổng quan" (surfaces/dashboard/brief.md): status hero trước tiên (trạng thái, số được tiêu, thước mức
/// sàn), rồi "Cần bạn xem", "Dự báo cuối tháng", mục tiêu của tháng và tài khoản.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onOpenUncategorized});

  /// Chạm hàng "… giao dịch chưa phân loại" → tab Giao dịch đã lọc.
  final VoidCallback? onOpenUncategorized;

  static Future<void> openGoalForm(BuildContext context, {GoalView? goal}) async {
    await Navigator.of(context).pushNamed(GoalFormScreen.routeName, arguments: GoalFormArgs(goal: goal));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.summary;
    // Chưa có số liệu nào vì lỗi tải: "Thử lại" là hành động của màn hình, FAB ẩn (không vô hiệu hoá).
    final noData = summary == null && state.error != null;

    Widget body;
    if (summary == null) {
      body = noData && !state.loading
          ? ErrorView(title: 'Không tải được tổng quan', message: state.errorMessage!, onRetry: state.load)
          : const _DashboardSkeleton();
    } else {
      body = RefreshIndicator(
        onRefresh: state.load,
        child: _DashboardBody(summary: summary, state: state, onOpenUncategorized: onOpenUncategorized),
      );
    }

    // Cửa sổ rộng: FAB nằm ở đầu NavigationRail (HomeShell), không hiện thêm ở đây.
    final showFab = !ShellScope.primaryActionInRailOf(context) && !noData;
    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan')),
      body: body,
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => openGoalForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Thêm mục tiêu'),
            )
          : null,
    );
  }
}

/// Khung xương tĩnh khi tải lần đầu: khối hero và ba hàng (không spinner, không shimmer).
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final gutter = Gutter.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, Space.s2, gutter, AppLayout.fabClearance),
      children: const [
        StatusHeroSkeleton(),
        SizedBox(height: AppLayout.sectionGap),
        ListSkeleton(rows: 3),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.summary, required this.state, this.onOpenUncategorized});

  final Summary summary;
  final AppState state;
  final VoidCallback? onOpenUncategorized;

  /// Hero UNKNOWN / hàng "Chưa biết số dư": mở bảng nhập số dư (TK đầu tiên thiếu số dư) hoặc thêm tài khoản.
  Future<void> _enterBalance(BuildContext context, ApiClient client) async {
    final missing = summary.accountsMissingBalance;
    bool saved;
    if (missing.isNotEmpty) {
      saved = await showBalanceDialog(context, client: client, account: missing.first) != null;
    } else {
      final result = await showAccountForm(context, client: client);
      saved = result?.account != null;
    }
    if (saved) await state.load();
  }

  Future<void> _openAccount(BuildContext context, ApiClient client, Account account) async {
    final saved = await showBalanceDialog(context, client: client, account: account);
    if (saved != null) await state.load();
  }

  BudgetPace? _paceFor(GoalView goal) {
    for (final b in summary.forecast?.budgets ?? const <BudgetPace>[]) {
      if (b.goalId == goal.id) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final client = state.client;
    final now = state.now();
    final gutter = Gutter.of(context);
    final error = state.error;
    final missing = summary.accountsMissingBalance;

    final reviewRows = <Widget>[
      if (summary.uncategorizedCount > 0)
        _UncategorizedRow(count: summary.uncategorizedCount, onTap: onOpenUncategorized),
      if (client != null)
        for (final account in summary.unconfirmedAccounts)
          _NewAccountRow(key: ValueKey('new_account_${account.id}'), account: account, client: client, onSaved: state.load),
      if (client != null && summary.level != Level.unknown && missing.isNotEmpty)
        _MissingBalanceRow(accounts: missing, onEnter: () => _enterBalance(context, client)),
      if (summary.ingestHealth.hasProblems) _IngestHealthRow(health: summary.ingestHealth),
    ];

    final goalsHeading = 'Mục tiêu ${monthShortLabel(summary.month, now).toLowerCase()}';
    final nextGoals = state.nextMonthGoals;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, Space.s2, gutter, AppLayout.fabClearance),
      children: [
        if (error != null) ...[
          OfflineStrip(
            key: const Key('offline_banner'),
            icon: error.isNetwork ? Icons.cloud_off : Icons.sync_problem,
            title: error.isNetwork ? 'Đang offline, không kết nối được máy chủ' : error.message,
            message: state.lastLoadedAt == null
                ? null
                : 'Đang hiện số liệu tải lúc ${formatShortDateTimeIct(state.lastLoadedAt!)}.',
            onRetry: state.loading ? null : state.load,
          ),
          const SizedBox(height: AppLayout.groupGap),
        ],
        StatusHero(
          key: const ValueKey('dashboard_hero'),
          data: StatusHeroData.fromSummary(summary, offline: state.offline, dataLoadedAt: state.lastLoadedAt),
          now: now,
          onUnknownAction: client == null ? null : () => _enterBalance(context, client),
        ),
        if (reviewRows.isNotEmpty) ...[
          const SectionHeader('Cần bạn xem'),
          ListGroup(children: reviewRows),
        ],
        if (ForecastCard.shouldShow(summary.forecast)) ...[
          const SectionHeader('Dự báo cuối tháng'),
          ForecastCard(forecast: summary.forecast, month: summary.month),
        ],
        SectionHeader(goalsHeading),
        if (summary.goals.isEmpty)
          _EmptyGoals(monthLabel: monthShortLabel(summary.month, now).toLowerCase())
        else
          ListGroup(
            children: [
              for (final goal in summary.goals)
                GoalRow(
                  goal: goal,
                  pace: _paceFor(goal),
                  onTap: () => DashboardScreen.openGoalForm(context, goal: goal),
                ),
            ],
          ),
        if (nextGoals.isNotEmpty) ...[
          const SizedBox(height: AppLayout.groupGap),
          _NextMonthGoals(
            key: const Key('next_month_goals'),
            month: state.nextMonth ?? shiftMonth(summary.month, 1),
            goals: nextGoals,
            now: now,
          ),
        ],
        if (summary.accounts.isNotEmpty) ...[
          const SectionHeader('Tài khoản'),
          ListGroup(
            children: [
              for (final account in summary.accounts)
                AccountRow(
                  account: account,
                  now: now,
                  onTap: client == null ? null : () => _openAccount(context, client, account),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Hàng "3 giao dịch chưa phân loại" → tab Giao dịch đã lọc. Là một nút (không phải chip / ô đánh dấu).
class _UncategorizedRow extends StatelessWidget {
  const _UncategorizedRow({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = '$count giao dịch chưa phân loại';
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: ListTile(
          key: const Key('uncategorized_chip'),
          leading: LeadingDisc(
            icon: Icons.label_outline,
            background: scheme.primaryContainer,
            foreground: scheme.onPrimaryContainer,
          ),
          title: Text(title),
          subtitle: const Text('Phân loại để mục tiêu và dự báo tính đúng'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Một hàng có câu hỏi và nút trả lời ngay dưới câu (giữ thẳng hàng với chữ, không bóp chữ khi chữ lớn).
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({super.key, required this.leading, required this.text, required this.actions});

  final Widget leading;
  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.listRowPaddingH, vertical: Space.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: Space.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface)),
                const SizedBox(height: Space.s2),
                Wrap(spacing: Space.s2, runSpacing: Space.s2, children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// TK lạ tự phát hiện: hỏi một lần có tính vào tổng số dư không (trả lời ngay trong hàng).
class _NewAccountRow extends StatefulWidget {
  const _NewAccountRow({super.key, required this.account, required this.client, required this.onSaved});

  final Account account;
  final ApiClient client;
  final Future<void> Function() onSaved;

  @override
  State<_NewAccountRow> createState() => _NewAccountRowState();
}

class _NewAccountRowState extends State<_NewAccountRow> {
  bool _busy = false;

  Future<void> _answer(bool include) async {
    setState(() => _busy = true);
    try {
      await widget.client.updateAccount(widget.account.id, {'confirmed': true, 'include_in_total': include});
      await widget.onSaved();
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.account;
    return _ReviewRow(
      leading: a.isCash ? const LeadingDisc(icon: Icons.payments_outlined) : LeadingDisc(text: a.bankShort),
      text: 'Phát hiện TK mới ${a.displayName}. Tính vào tổng số dư?',
      actions: [
        FilledButton.tonal(onPressed: _busy ? null : () => _answer(true), child: const Text('Tính vào tổng')),
        OutlinedButton(onPressed: _busy ? null : () => _answer(false), child: const Text('Không tính')),
      ],
    );
  }
}

/// Đã biết mức nhưng có TK tính vào tổng chưa có số dư.
class _MissingBalanceRow extends StatelessWidget {
  const _MissingBalanceRow({required this.accounts, required this.onEnter});

  final List<Account> accounts;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return _ReviewRow(
      leading: const LeadingDisc(icon: Icons.account_balance_wallet_outlined),
      text: 'Chưa biết số dư của: ${accounts.map((a) => a.displayName).join(', ')}',
      actions: [
        TextButton(key: const Key('enter_balance'), onPressed: onEnter, child: const Text('Nhập số dư')),
      ],
    );
  }
}

/// Nguồn dữ liệu ngân hàng có vấn đề: hiện nguyên văn cảnh báo máy chủ soạn sẵn.
class _IngestHealthRow extends StatelessWidget {
  const _IngestHealthRow({required this.health});

  final IngestHealth health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warnings = health.warnings;
    final lines = <String>[
      ...warnings,
      if (warnings.isEmpty && health.stale) 'Nguồn dữ liệu ngân hàng đang gặp sự cố, kiểm tra webhook/email.',
      if (health.errorEvents > 0) '${health.errorEvents} biến động xử lý lỗi.',
      if (warnings.isEmpty && health.unparsedEvents > 0) '${health.unparsedEvents} email chưa đọc được nội dung.',
      if (health.emailError != null) 'Lỗi email: ${health.emailError}',
    ];
    return Padding(
      key: const Key('ingest_health_note'),
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.listRowPaddingH, vertical: Space.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LeadingDisc(icon: Icons.sync_problem, foreground: StatusColors.of(context).warning.foreground),
          const SizedBox(width: Space.s4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: Space.s2),
              child: Text(
                lines.join('\n'),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mục tiêu đã tạo trước cho tháng sau: một hàng thu gọn "Tháng 11 · 2 mục tiêu đã tạo trước", chạm để mở.
class _NextMonthGoals extends StatefulWidget {
  const _NextMonthGoals({super.key, required this.month, required this.goals, required this.now});

  final String month;
  final List<GoalView> goals;
  final DateTime now;

  @override
  State<_NextMonthGoals> createState() => _NextMonthGoalsState();
}

class _NextMonthGoalsState extends State<_NextMonthGoals> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = '${monthShortLabel(widget.month, widget.now)} · ${widget.goals.length} mục tiêu đã tạo trước';
    final reduce = MediaQuery.disableAnimationsOf(context);
    return ListGroup(
      children: [
        MergeSemantics(
          child: Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppLayout.listRowMinHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppLayout.listRowPaddingH, vertical: Space.s2),
                  child: Row(
                    children: [
                      const LeadingDisc(icon: Icons.event_outlined),
                      const SizedBox(width: Space.s4),
                      Expanded(
                        child: Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: reduce ? Duration.zero : MotionDurations.stateLayer,
                        child: const Icon(Icons.expand_more),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_open)
          for (final goal in widget.goals)
            GoalRow(goal: goal, onTap: () => DashboardScreen.openGoalForm(context, goal: goal)),
      ],
    );
  }
}

/// Chưa có mục tiêu tháng này.
class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.monthLabel});

  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.flag_outlined,
      title: 'Chưa có mục tiêu $monthLabel',
      message:
          'Đặt mục tiêu để được báo khi số dư xuống gần mức cần giữ, vd. tiền trọ 3.000.000đ, '
          'tiền ăn 5.000.000đ.',
      action: TextButton(
        onPressed: () => DashboardScreen.openGoalForm(context),
        child: const Text('Tạo mục tiêu đầu tiên'),
      ),
    );
  }
}
