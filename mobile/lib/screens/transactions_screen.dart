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

/// Điều khiển tab Giao dịch từ bên ngoài (vd. chip "chưa phân loại" ở Tổng quan) mà không phải dựng lại màn hình.
class TransactionsController extends ChangeNotifier {
  bool _uncategorizedRequested = false;

  /// Mở danh sách "Chưa phân loại" của tháng hiện tại.
  void showUncategorized() {
    _uncategorizedRequested = true;
    notifyListeners();
  }

  /// Lấy và xoá yêu cầu đang chờ (màn hình có thể chưa được dựng khi có yêu cầu).
  bool takeUncategorizedRequest() {
    final requested = _uncategorizedRequested;
    _uncategorizedRequested = false;
    return requested;
  }
}

/// Màn "Giao dịch": lọc theo tháng / chưa phân loại, chạm để phân loại.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, this.initialUncategorized = false, this.controller, this.active = true});

  final bool initialUncategorized;
  final TransactionsController? controller;

  /// Tab đang hiện; chuyển từ ẩn sang hiện thì tải lại (giữ tháng và bộ lọc).
  final bool active;

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

  /// (tháng, bộ lọc) của [_items]; khác bộ lọc đang chọn thì không hiện các dòng cũ.
  String? _loadedKey;

  String get _key => '$_month|$_uncategorized';

  @override
  void initState() {
    super.initState();
    _currentMonth = _resolveCurrentMonth();
    _month = _currentMonth;
    widget.controller?.addListener(_onControllerRequest);
    _uncategorized = widget.initialUncategorized || (widget.controller?.takeUncategorizedRequest() ?? false);
    _load();
    _loadCategories();
  }

  @override
  void didUpdateWidget(TransactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerRequest);
      widget.controller?.addListener(_onControllerRequest);
    }
    if (widget.active && !oldWidget.active) {
      _currentMonth = _resolveCurrentMonth();
      _load();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerRequest);
    super.dispose();
  }

  String _resolveCurrentMonth() {
    final state = context.read<AppState>();
    final month = state.summary?.month;
    return month != null && parseMonth(month) != null ? month : currentMonthIct(state.now());
  }

  void _onControllerRequest() {
    if (!(widget.controller?.takeUncategorizedRequest() ?? false)) return;
    setState(() {
      _currentMonth = _resolveCurrentMonth();
      _month = _currentMonth;
      _uncategorized = true;
    });
    // Tab đang ẩn thì tải khi được hiện (didUpdateWidget).
    if (widget.active) _load();
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
    final key = _key;
    setState(() {
      _loading = true;
      _error = null;
      if (key != _loadedKey && false) {
        // Đổi tháng / bộ lọc: bỏ danh sách cũ để không lẫn với tháng mới khi đang tải hoặc lỗi.
        _items = const [];
        _total = 0;
        _loadedKey = null;
      }
    });
    try {
      final page = await client.listTransactions(month: _month, uncategorized: _uncategorized, limit: _pageSize);
      if (!mounted || id != _requestId) return;
      setState(() {
        _items = page.items;
        _total = page.total;
        _loadedKey = key;
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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                  ],
                ),
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
          // Tải lại lỗi khi vẫn còn danh sách cũ (cùng tháng/bộ lọc): báo lỗi thay vì im lặng.
          if (_error != null && _items.isNotEmpty) _ReloadErrorBanner(message: _error!, onRetry: _load),
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
                          : OutlinedButton(onPressed: _loadMore, child: Text('Tải thêm (${_total - _items.length})')),
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

class _ReloadErrorBanner extends StatelessWidget {
  const _ReloadErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('tx_reload_error'),
      color: scheme.errorContainer,
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 20, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Không tải lại được: $message', style: TextStyle(color: scheme.onErrorContainer)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
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

    final categoryLabel = tx.categoryName == null ? null : '${tx.categoryIcon ?? ''} ${tx.categoryName}'.trim();

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        child: Text(
          tx.categoryIcon?.isNotEmpty == true ? tx.categoryIcon! : (tx.isOut ? '↑' : '↓'),
          style: const TextStyle(fontSize: 18),
        ),
      ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              tx.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tx.isExcluded ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatSignedVnd(tx.amount, outgoing: tx.isOut),
            style: theme.textTheme.titleSmall?.copyWith(color: amountColor, fontWeight: FontWeight.w700),
          ),
        ],
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
              if (tx.goalName != null)
                StatusBadge(
                  tx.goalMonth != null && tx.goalMonth != tx.month
                      ? '🎯 ${tx.goalName} · ${shortMonthLabel(tx.goalMonth!)}'
                      : '🎯 ${tx.goalName}',
                  color: scheme.tertiary,
                ),
              if (tx.isPending) StatusBadge('Đang chờ khớp', color: Colors.amber.shade800, icon: Icons.hourglass_top),
              if (tx.isExcluded) StatusBadge('Đã loại trừ', color: scheme.outline, icon: Icons.block),
              if (tx.isPossibleDuplicate)
                StatusBadge('Có thể trùng', color: Colors.deepOrange, icon: Icons.content_copy),
              if (tx.isManual) StatusBadge('Nhập tay', color: scheme.outline, icon: Icons.edit),
            ],
          ),
        ],
      ),
    );
  }
}
