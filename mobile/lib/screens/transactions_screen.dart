import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';
import 'manual_tx_screen.dart';
import 'tx_action_sheet.dart';

/// Màn "Giao dịch": lọc theo tháng / chưa phân loại, chạm để phân loại.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, this.initialUncategorized = false});

  final bool initialUncategorized;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const _pageSize = 50;

  late String _month;
  late String _currentMonth;
  late bool _uncategorized;
  List<Tx> _items = const [];
  int _total = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  List<Category> _categories = const [];
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _currentMonth = state.summary?.month ?? currentMonthIct(state.now());
    if (parseMonth(_currentMonth) == null) _currentMonth = currentMonthIct(state.now());
    _month = _currentMonth;
    _uncategorized = widget.initialUncategorized;
    _load();
    _loadCategories();
  }

  ApiClient? get _client => context.read<AppState>().client;

  Future<void> _loadCategories() async {
    final client = _client;
    if (client == null) return;
    try {
      final list = await client.listCategories();
      if (mounted) setState(() => _categories = list);
    } on ApiException {
      // Danh mục sẽ được tải lại khi mở bảng phân loại.
    }
  }

  Future<void> _load() async {
    final client = _client;
    if (client == null) return;
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await client.listTransactions(month: _month, uncategorized: _uncategorized, limit: _pageSize);
      if (!mounted || id != _requestId) return;
      setState(() {
        _items = page.items;
        _total = page.total;
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

  Future<void> _loadMore() async {
    final client = _client;
    if (client == null || _loadingMore) return;
    final id = _requestId;
    setState(() => _loadingMore = true);
    try {
      final page = await client.listTransactions(
        month: _month,
        uncategorized: _uncategorized,
        limit: _pageSize,
        offset: _items.length,
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _items = [..._items, ...page.items];
        _total = page.total;
      });
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _changeMonth(int delta) {
    final next = shiftMonth(_month, delta);
    if (delta > 0 && next.compareTo(_currentMonth) > 0) return;
    setState(() => _month = next);
    _load();
  }

  Future<void> _openTx(Tx tx) async {
    final client = _client;
    if (client == null) return;
    final result = await showTxActionSheet(context, client: client, tx: tx, categories: _categories);
    if (result == null || !mounted) return;
    setState(() {
      final index = _items.indexWhere((t) => t.id == tx.id);
      if (result.deleted || (result.transaction != null && _uncategorized && !result.transaction!.isUncategorized)) {
        if (index >= 0) {
          _items = [..._items]..removeAt(index);
          _total = _total > 0 ? _total - 1 : 0;
        }
      } else if (result.transaction != null && index >= 0) {
        _items = [..._items]..[index] = result.transaction!;
      }
    });
  }

  Future<void> _addManual() async {
    final created = await Navigator.of(context).pushNamed(ManualTxScreen.routeName);
    if (created == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final canGoNext = shiftMonth(_month, 1).compareTo(_currentMonth) <= 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Giao dịch')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addManual,
        icon: const Icon(Icons.edit_note),
        label: const Text('Thêm giao dịch'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Tháng trước',
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(monthLabel(_month), style: Theme.of(context).textTheme.titleSmall),
                IconButton(
                  tooltip: 'Tháng sau',
                  onPressed: canGoNext ? () => _changeMonth(1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
                const Spacer(),
                FilterChip(
                  key: const Key('filter_uncategorized'),
                  label: const Text('Chưa phân loại'),
                  selected: _uncategorized,
                  onSelected: (v) {
                    setState(() => _uncategorized = v);
                    _load();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _items.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _items.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    final hasMore = _items.length < _total;
    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    _uncategorized
                        ? 'Không còn giao dịch chưa phân loại trong ${monthLabel(_month).toLowerCase()}.'
                        : 'Chưa có giao dịch trong ${monthLabel(_month).toLowerCase()}.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: _items.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i >= _items.length) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: _loadingMore
                          ? const CircularProgressIndicator()
                          : OutlinedButton(
                              onPressed: _loadMore,
                              child: Text('Tải thêm (${_total - _items.length})'),
                            ),
                    ),
                  );
                }
                final tx = _items[i];
                return TxTile(tx: tx, onTap: () => _openTx(tx));
              },
            ),
    );
  }
}

/// Một dòng giao dịch: số tiền màu theo chiều, danh mục, nguồn, trạng thái.
class TxTile extends StatelessWidget {
  const TxTile({super.key, required this.tx, this.onTap});

  final Tx tx;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final amountColor = tx.isExcluded
        ? scheme.outline
        : tx.isOut
            ? Colors.red.shade700
            : Colors.green.shade700;
    final meta = [
      if (tx.accountName != null && tx.accountName!.isNotEmpty) tx.accountName!,
      if (tx.bankTime != null) formatShortDateTime(tx.bankTime!),
      if (tx.sources.isNotEmpty) tx.sources.join(', '),
    ].join(' · ');

    final categoryLabel = tx.categoryName == null
        ? null
        : '${tx.categoryIcon ?? ''} ${tx.categoryName}'.trim();

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        child: Text(
          tx.categoryIcon?.isNotEmpty == true ? tx.categoryIcon! : (tx.isOut ? '↑' : '↓'),
          style: const TextStyle(fontSize: 18),
        ),
      ),
      title: Text(
        tx.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: tx.isExcluded ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meta.isNotEmpty) Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (tx.isInternalTransfer)
                StatusBadge('Chuyển nội bộ', color: scheme.secondary, icon: Icons.swap_horiz)
              else if (categoryLabel != null)
                StatusBadge(categoryLabel, color: scheme.primary)
              else if (tx.isOut)
                StatusBadge('Chưa phân loại', color: scheme.error, icon: Icons.label_off_outlined),
              if (tx.goalName != null) StatusBadge('🎯 ${tx.goalName}', color: scheme.tertiary),
              if (tx.isPending) StatusBadge('Đang chờ khớp', color: Colors.amber.shade800, icon: Icons.hourglass_top),
              if (tx.isExcluded) StatusBadge('Đã loại trừ', color: scheme.outline, icon: Icons.block),
              if (tx.isPossibleDuplicate)
                StatusBadge('Có thể trùng', color: Colors.deepOrange, icon: Icons.content_copy),
              if (tx.isManual) StatusBadge('Nhập tay', color: scheme.outline, icon: Icons.edit),
            ],
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Text(
        formatSignedVnd(tx.amount, outgoing: tx.isOut),
        style: theme.textTheme.titleSmall?.copyWith(color: amountColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
