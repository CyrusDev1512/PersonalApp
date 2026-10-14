import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/dates.dart';
import '../widgets/alert_tile.dart';
import '../widgets/common.dart';

/// Màn "Cảnh báo": lịch sử, đánh dấu đã đọc.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert> _alerts = const [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  ApiClient? get _client => context.read<AppState>().client;

  Future<void> _load() async {
    final client = _client;
    if (client == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await client.listAlerts(limit: 100);
      if (!mounted) return;
      setState(() {
        _alerts = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _open(Alert alert) async {
    final client = _client;
    if (client == null) return;
    if (!alert.read) {
      try {
        final updated = await client.markAlertRead(alert.id);
        if (!mounted) return;
        setState(() => _alerts = [for (final a in _alerts) a.id == alert.id ? updated : a]);
        // Cập nhật số chưa đọc trên thanh điều hướng.
        context.read<AppState>().load();
      } on ApiException catch (e) {
        if (mounted) showError(context, e);
      }
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(alert.title.isEmpty ? alert.level.label : alert.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alert.createdAt != null)
                Text(formatDateTime(alert.createdAt!), style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 8),
              SelectableText(alert.message),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
      ),
    );
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
    final hasUnread = _alerts.any((a) => !a.read);
    Widget body;
    if (_loading && _alerts.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _alerts.isEmpty) {
      body = ErrorView(message: _error!, onRetry: _load);
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: _alerts.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Chưa có cảnh báo nào.')),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _alerts.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) => AlertTile(alert: _alerts[i], onTap: () => _open(_alerts[i])),
              ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cảnh báo'),
        actions: [
          TextButton.icon(
            onPressed: hasUnread && !_busy ? _readAll : null,
            icon: const Icon(Icons.done_all),
            label: const Text('Đọc hết'),
          ),
        ],
      ),
      body: body,
    );
  }
}
