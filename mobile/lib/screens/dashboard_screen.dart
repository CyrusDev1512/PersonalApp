import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';
import '../widgets/account_dialog.dart';
import '../widgets/alert_tile.dart';
import '../widgets/common.dart';
import '../widgets/goal_card.dart';
import '../widgets/status_banner.dart';
import 'goal_form_screen.dart';

/// Số dư cũ hơn ngưỡng này thì "cập nhật lúc …" chuyển màu hổ phách.
const Duration staleBalanceAfter = Duration(hours: 48);

/// Màn "Tổng quan".
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onOpenUncategorized, this.onOpenAlerts});

  /// Chạm chip "chưa phân loại" → tab Giao dịch đã lọc.
  final VoidCallback? onOpenUncategorized;
  final VoidCallback? onOpenAlerts;

  static Future<void> openGoalForm(BuildContext context, {GoalView? goal}) async {
    await Navigator.of(context).pushNamed(GoalFormScreen.routeName, arguments: GoalFormArgs(goal: goal));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.summary;

    Widget body;
    if (summary == null) {
      if (state.error != null && !state.loading) {
        body = ErrorView(message: state.errorMessage!, onRetry: state.load);
      } else {
        body = const Center(child: CircularProgressIndicator());
      }
    } else {
      body = RefreshIndicator(
        onRefresh: state.load,
        child: _DashboardBody(
          summary: summary,
          state: state,
          onOpenUncategorized: onOpenUncategorized,
          onOpenAlerts: onOpenAlerts,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: state.loading ? null : state.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isConnected ? () => openGoalForm(context) : null,
        icon: const Icon(Icons.add),
        label: const Text('Thêm mục tiêu'),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.summary,
    required this.state,
    this.onOpenUncategorized,
    this.onOpenAlerts,
  });

  final Summary summary;
  final AppState state;
  final VoidCallback? onOpenUncategorized;
  final VoidCallback? onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final client = state.client;
    final needsBalance = summary.level == Level.unknown || summary.accountsMissingBalance.isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (state.error != null) _OfflineBanner(error: state.error!, lastLoadedAt: state.lastLoadedAt),
        _BalanceCard(summary: summary, now: state.now()),
        const SizedBox(height: 12),
        StatusBanner(level: summary.level, reason: summary.levelReason, waitingIncome: summary.waitingIncome),
        if (needsBalance && client != null) ...[
          const SizedBox(height: 12),
          _UnknownBalanceCard(summary: summary, client: client, onSaved: state.load),
        ],
        if (client != null)
          for (final account in summary.unconfirmedAccounts)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _NewAccountCard(account: account, client: client, onSaved: state.load),
            ),
        if (summary.ingestHealth.hasProblems) ...[
          const SizedBox(height: 12),
          _IngestHealthNote(health: summary.ingestHealth),
        ],
        if (summary.uncategorizedCount > 0) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              key: const Key('uncategorized_chip'),
              avatar: const Icon(Icons.label_off_outlined, size: 18),
              label: Text('${summary.uncategorizedCount} giao dịch chưa phân loại'),
              onPressed: onOpenUncategorized,
            ),
          ),
        ],
        SectionHeader('Mục tiêu ${monthLabel(summary.month).toLowerCase()}'),
        if (summary.goals.isEmpty)
          const _EmptyGoals()
        else
          for (final goal in summary.goals)
            GoalCard(goal: goal, onTap: () => DashboardScreen.openGoalForm(context, goal: goal)),
        SectionHeader(
          'Cảnh báo gần đây',
          trailing: TextButton(onPressed: onOpenAlerts, child: const Text('Xem tất cả')),
        ),
        if (summary.latestAlerts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text('Chưa có cảnh báo nào.'),
          )
        else
          Card(
            child: Column(
              children: [
                for (final alert in summary.latestAlerts.take(5))
                  AlertTile(alert: alert, dense: true, onTap: onOpenAlerts),
              ],
            ),
          ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.error, this.lastLoadedAt});

  final ApiException error;
  final DateTime? lastLoadedAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = error.isNetwork ? 'Đang offline — không kết nối được máy chủ' : error.message;
    final when = lastLoadedAt == null
        ? 'Chưa tải được dữ liệu lần nào.'
        : 'Đang hiện dữ liệu tải lúc ${formatShortDateTime(lastLoadedAt!)}.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        key: const Key('offline_banner'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(error.isNetwork ? Icons.cloud_off : Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w600)),
                  Text(when, style: TextStyle(color: scheme.onErrorContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary, required this.now});

  final Summary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final asOf = summary.balanceAsOf;
    final stale = asOf != null && now.difference(asOf) > staleBalanceAfter;
    final staleColor = Colors.amber.shade800;
    final free = summary.free;
    final freeColor = free == null
        ? null
        : free < 0
            ? Colors.red.shade700
            : levelColor(summary.level == Level.unknown ? Level.ok : summary.level);
    final income = summary.expectedIncome;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Tổng số dư', style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                if (summary.anyBalanceDerived) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Có tài khoản đang dùng số dư tự cộng/trừ từ mốc gần nhất',
                    child: StatusBadge('ước tính', color: scheme.secondary),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              summary.balanceKnown ? formatVndOrDash(summary.balance) : 'Chưa biết',
              key: const Key('total_balance'),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            if (asOf != null)
              Row(
                children: [
                  if (stale) ...[Icon(Icons.schedule, size: 16, color: staleColor), const SizedBox(width: 4)],
                  Flexible(
                    child: Text(
                      'cập nhật lúc ${formatShortDateTime(asOf)}${stale ? ' (đã hơn 48 giờ)' : ''}',
                      key: const Key('balance_as_of'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: stale ? staleColor : scheme.onSurfaceVariant,
                        fontWeight: stale ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              )
            else
              Text('chưa có thông tin số dư', style: theme.textTheme.bodySmall),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Mức sàn',
                    value: formatVnd(summary.floor),
                    hint: 'Tổng tiền còn phải giữ cho mục tiêu',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Metric(
                    label: 'Được tiêu thoải mái',
                    value: formatVndOrDash(free),
                    color: freeColor,
                    hint: summary.buffer > 0 ? 'Cảnh báo khi dưới ${formatVnd(summary.buffer)}' : null,
                  ),
                ),
              ],
            ),
            if (summary.inTransit > 0) ...[
              const SizedBox(height: 8),
              Text('Đang chuyển giữa các TK: ${formatVnd(summary.inTransit)}', style: theme.textTheme.bodySmall),
            ],
            if (income != null && income.pending > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Lương chờ nhận: ${formatVnd(income.pending)}${income.day > 0 ? ' (ngày ${income.day})' : ''}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (summary.daysLeft != null) ...[
              const SizedBox(height: 4),
              Text('Còn ${summary.daysLeft} ngày trong tháng', style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color, this.hint});

  final String label;
  final String value;
  final Color? color;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: color)),
        if (hint != null) Text(hint!, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// UNKNOWN: chưa biết số dư → nút "Nhập số dư".
class _UnknownBalanceCard extends StatelessWidget {
  const _UnknownBalanceCard({required this.summary, required this.client, required this.onSaved});

  final Summary summary;
  final ApiClient client;
  final Future<void> Function() onSaved;

  Future<void> _enter(BuildContext context) async {
    final missing = summary.accountsMissingBalance;
    bool saved;
    if (missing.isNotEmpty) {
      saved = await showBalanceDialog(context, client: client, account: missing.first) != null;
    } else {
      final result = await showAccountForm(context, client: client);
      saved = result?.account != null;
    }
    if (saved) await onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final missing = summary.accountsMissingBalance;
    final text = missing.isEmpty
        ? 'Chưa có tài khoản nào có số dư. Thêm tài khoản và nhập số dư hiện tại để app tính được mức an toàn.'
        : 'Chưa biết số dư của: ${missing.map((a) => a.displayName).join(', ')}. '
            'Nhập số dư hiện tại để app bắt đầu tính.';
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('enter_balance'),
              onPressed: () => _enter(context),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Nhập số dư'),
            ),
          ],
        ),
      ),
    );
  }
}

/// TK lạ tự phát hiện: hỏi 1 lần có tính vào tổng không.
class _NewAccountCard extends StatefulWidget {
  const _NewAccountCard({required this.account, required this.client, required this.onSaved});

  final Account account;
  final ApiClient client;
  final Future<void> Function() onSaved;

  @override
  State<_NewAccountCard> createState() => _NewAccountCardState();
}

class _NewAccountCardState extends State<_NewAccountCard> {
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phát hiện TK mới ${a.bankLabel} …${a.last4 ?? ''} — tính vào tổng số dư?'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(onPressed: _busy ? null : () => _answer(true), child: const Text('Tính vào tổng')),
                OutlinedButton(onPressed: _busy ? null : () => _answer(false), child: const Text('Không tính')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IngestHealthNote extends StatelessWidget {
  const _IngestHealthNote({required this.health});

  final IngestHealth health;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (health.stale) 'Không có dữ liệu mới từ ngân hàng trong 48 giờ — kiểm tra webhook/email.',
      if (health.errorEvents > 0) '${health.errorEvents} biến động xử lý lỗi.',
      if (health.unparsedEvents > 0) '${health.unparsedEvents} email chưa đọc được nội dung.',
      if (health.emailError != null) 'Lỗi email: ${health.emailError}',
    ];
    final color = Colors.amber.shade800;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sync_problem, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(lines.join('\n'))),
        ],
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.flag_outlined, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text('Chưa có mục tiêu', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Đặt mục tiêu để được cảnh báo khi số dư xuống gần mức cần giữ, '
              'vd. tiền trọ 3.000.000đ, tiền ăn 5.000.000đ.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => DashboardScreen.openGoalForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Tạo mục tiêu đầu tiên'),
            ),
          ],
        ),
      ),
    );
  }
}
