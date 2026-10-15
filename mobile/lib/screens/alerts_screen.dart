import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../utils/dates.dart';
import '../widgets/adaptive.dart';
import '../widgets/alert_detail_sheet.dart';
import '../widgets/alert_row.dart';
import '../widgets/common.dart';
import '../widgets/list_group.dart';

/// Màn "Cảnh báo" (surfaces/alerts/brief.md): bộ lọc Tất cả / Chưa đọc, nhóm theo ngày, chạm để mở bảng chi
/// tiết (đánh dấu đã đọc); "Đọc hết" trên thanh tiêu đề.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, this.active = true});

  /// Tab đang hiện; chuyển từ ẩn sang hiện thì tải lại.
  final bool active;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert> _alerts = const [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

  /// Bộ lọc "Chưa đọc" (`GET /api/alerts?unread=true`).
  bool _unreadOnly = false;

  /// Bộ lọc của [_alerts] (khác bộ lọc đang chọn thì không hiện danh sách cũ).
  bool? _loadedUnread;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AlertsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _load();
  }

  ApiClient? get _client => context.read<AppState>().client;

  Future<void> _load() async {
    final client = _client;
    if (client == null) return;
    final id = ++_requestId;
    final unread = _unreadOnly;
    setState(() {
      _loading = true;
      _error = null;
      if (_loadedUnread != unread) _alerts = const [];
    });
    try {
      final list = await client.listAlerts(unread: unread, limit: 100);
      if (!mounted || id != _requestId) return;
      setState(() {
        _alerts = list;
        _loadedUnread = unread;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  void _setFilter(bool unreadOnly) {
    if (unreadOnly == _unreadOnly) return;
    setState(() => _unreadOnly = unreadOnly);
    _load();
  }

  Future<void> _open(Alert alert) async {
    final client = _client;
    if (client == null) return;
    var shown = alert;
    if (!alert.read) {
      try {
        final updated = await client.markAlertRead(alert.id);
        shown = updated;
        if (!mounted) return;
        // Bộ lọc "Chưa đọc": cảnh báo vừa đọc vẫn ở lại cho tới lần tải sau (khỏi nhảy dòng dưới tay).
        setState(() => _alerts = [for (final a in _alerts) a.id == alert.id ? updated : a]);
        // Cập nhật số chưa đọc trên thanh điều hướng.
        context.read<AppState>().load();
      } on ApiException catch (e) {
        if (mounted) showError(context, e);
      }
    }
    if (!mounted) return;
    await showAlertDetail(context, client: client, alert: shown);
  }

  Future<void> _readAll() async {
    final client = _client;
    if (client == null) return;
    setState(() => _busy = true);
    try {
      final count = await client.markAllAlertsRead();
      if (!mounted) return;
      setState(() => _alerts = [for (final a in _alerts) a.copyWith(read: true)]);
      showInfo(context, count > 0 ? 'Đã đánh dấu $count cảnh báo là đã đọc' : 'Không còn cảnh báo chưa đọc');
      context.read<AppState>().load();
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = Gutter.of(context);
    final unreadCount = context.select<AppState, int>((s) => s.summary?.unreadAlerts ?? 0);
    final hasUnread = unreadCount > 0 || _alerts.any((a) => !a.read);
    return Scaffold(
      // Chữ "Đọc hết" thẳng mép phải với nội dung (ContentAppBar chừa đệm cuối = lề − đệm trong của nút).
      appBar: ContentAppBar(
        title: const Text('Cảnh báo'),
        actions: [
          TextButton.icon(
            onPressed: hasUnread && !_busy ? _readAll : null,
            icon: const Icon(Icons.done_all),
            label: const Text('Đọc hết'),
          ),
        ],
      ),
      body: ContentColumn(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, Space.s2),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: Space.s2,
                  children: [
                    FilterChip(
                      key: const Key('alerts_filter_all'),
                      label: const Text('Tất cả'),
                      selected: !_unreadOnly,
                      onSelected: (_) => _setFilter(false),
                    ),
                    FilterChip(
                      key: const Key('alerts_filter_unread'),
                      label: Text(unreadCount > 0 ? 'Chưa đọc · $unreadCount' : 'Chưa đọc'),
                      selected: _unreadOnly,
                      onSelected: _setFilter,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildList(gutter)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(double gutter) {
    final alerts = _loadedUnread == _unreadOnly ? _alerts : const <Alert>[];
    if (_loading && alerts.isEmpty) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: gutter, vertical: Space.s2),
        children: const [ListSkeleton(rows: 6)],
      );
    }
    if (_error != null && alerts.isEmpty) {
      return ErrorView(title: 'Không tải được cảnh báo', message: _error!, onRetry: _load);
    }
    if (alerts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: gutter, vertical: Space.s8),
          children: [
            if (_unreadOnly)
              const EmptyState(icon: Icons.done_all, title: 'Không còn cảnh báo chưa đọc.')
            else
              const EmptyState(
                icon: Icons.notifications_none,
                title: 'Chưa có cảnh báo nào.',
                message: 'Khi số dư xuống gần mức cần giữ, app sẽ báo ở đây và qua Telegram.',
              ),
          ],
        ),
      );
    }

    final now = context.read<AppState>().now();
    // Nhóm theo ngày (giờ Việt Nam), giữ thứ tự mới nhất trước của máy chủ.
    final entries = <Object>[];
    String? lastDay;
    for (var i = 0; i < alerts.length; i++) {
      final a = alerts[i];
      final day = a.createdAt == null ? '' : dayKeyIct(a.createdAt!);
      final first = day != lastDay;
      if (first) {
        entries.add(a.createdAt == null ? 'Không rõ thời gian' : dayHeadingIct(a.createdAt!, now));
        lastDay = day;
      }
      final nextDay = i + 1 < alerts.length
          ? (alerts[i + 1].createdAt == null ? '' : dayKeyIct(alerts[i + 1].createdAt!))
          : null;
      entries.add((alert: a, first: first, last: nextDay != day));
    }
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, Space.s8),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          if (e is String) {
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? Space.s2 : Space.s6, bottom: Space.s2),
              child: Semantics(
                header: true,
                child: Text(e, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
            );
          }
          final (:alert, :first, :last) = e as ({Alert alert, bool first, bool last});
          const r = Radius.circular(Radii.lg);
          return ClipRRect(
            key: ValueKey('alert_${alert.id}'),
            borderRadius: BorderRadius.vertical(top: first ? r : Radius.zero, bottom: last ? r : Radius.zero),
            child: Material(
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: EdgeInsets.only(top: first ? Space.s1 : 0, bottom: last ? Space.s1 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!first) const ExcludeSemantics(child: Divider(indent: ListGroup.dividerIndent)),
                    AlertRow(alert: alert, onTap: () => _open(alert)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
