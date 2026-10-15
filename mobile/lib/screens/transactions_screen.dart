import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../utils/dates.dart';
import '../widgets/category_icon.dart';
import '../widgets/common.dart';
import '../widgets/list_group.dart';
import '../widgets/money_row.dart';
import '../widgets/money_text.dart';
import 'manual_tx_screen.dart';
import 'tx_action_sheet.dart';

/// Điều khiển tab Giao dịch từ bên ngoài (vd. hàng "chưa phân loại" ở Tổng quan) mà không phải dựng lại màn hình.
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

/// Một nhóm ngày trong danh sách giao dịch.
@immutable
class TxDayGroup {
  const TxDayGroup({required this.key, required this.title, required this.items, required this.spent});

  /// "2026-10-14" (ngày giờ Việt Nam) hoặc "" khi không rõ thời gian.
  final String key;

  /// "Hôm nay", "Hôm qua", "Thứ Hai, 12/10".
  final String title;
  final List<Tx> items;

  /// Tổng khoản chi đang tính trong ngày (không gồm chuyển nội bộ, đã loại trừ, đang chờ khớp).
  final int spent;

  /// Khoản chi được cộng vào tổng ngày (kể cả chi tiền mặt nhập tay).
  static bool countsAsSpending(Tx tx) => tx.isOut && tx.status == TxStatus.active && !tx.isInternalTransfer;

  /// Gom [items] (mới nhất trước, như máy chủ trả) thành nhóm theo ngày giờ Việt Nam, giữ thứ tự.
  static List<TxDayGroup> group(List<Tx> items, DateTime now) {
    final order = <String>[];
    final byDay = <String, List<Tx>>{};
    for (final tx in items) {
      final key = tx.bankTime == null ? '' : dayKeyIct(tx.bankTime!);
      final list = byDay[key];
      if (list == null) {
        order.add(key);
        byDay[key] = [tx];
      } else {
        list.add(tx);
      }
    }
    // Giao dịch không rõ thời gian để cuối.
    if (order.remove('')) order.add('');
    return [
      for (final key in order)
        TxDayGroup(
          key: key,
          title: key.isEmpty ? 'Không rõ thời gian' : dayHeadingIct(byDay[key]!.first.bankTime!, now),
          items: byDay[key]!,
          spent: byDay[key]!.where(countsAsSpending).fold(0, (sum, tx) => sum + tx.amount),
        ),
    ];
  }
}

/// Màn "Giao dịch": lọc theo tháng / chưa phân loại, nhóm theo ngày, chạm để phân loại; "Nhập tay" là FAB.
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
      if (key != _loadedKey) {
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

  void _setFilter(bool uncategorized) {
    if (uncategorized == _uncategorized) return;
    setState(() => _uncategorized = uncategorized);
    _load();
  }

  Future<void> _openTx(Tx tx) async {
    final client = _client;
    if (client == null) return;
    final result = await showTxActionSheet(
      context,
      client: client,
      tx: tx,
      categories: _categories,
      onUndone: (_) {
        if (mounted) _load();
      },
    );
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gutter = Gutter.of(context);
    final canGoNext = shiftMonth(_month, 1).compareTo(_currentMonth) <= 0;
    final summaryMonth = context.select<AppState, String?>((s) => s.summary?.month);
    final pending = context.select<AppState, int>((s) => s.summary?.uncategorizedCount ?? 0);
    final count = summaryMonth == _month ? pending : 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Giao dịch')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addManual,
        backgroundColor: AppButtonStyles.secondaryFabBackground(scheme),
        foregroundColor: AppButtonStyles.secondaryFabForeground(scheme),
        icon: const Icon(Icons.edit_note),
        label: const Text('Nhập tay'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter - Space.s2, 0, gutter, Space.s2),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Space.s2,
              runSpacing: Space.s1,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Tháng trước',
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(monthLabel(_month), style: theme.textTheme.titleSmall),
                    IconButton(
                      tooltip: 'Tháng sau',
                      onPressed: canGoNext ? () => _changeMonth(1) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: Space.s2),
                  child: Wrap(
                    spacing: Space.s2,
                    children: [
                      FilterChip(
                        key: const Key('filter_all'),
                        label: const Text('Tất cả'),
                        selected: !_uncategorized,
                        onSelected: (_) => _setFilter(false),
                      ),
                      FilterChip(
                        key: const Key('filter_uncategorized'),
                        label: Text(count > 0 ? 'Chưa phân loại · $count' : 'Chưa phân loại'),
                        selected: _uncategorized,
                        onSelected: _setFilter,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tải lại lỗi khi vẫn còn danh sách cũ (cùng tháng/bộ lọc): dải trung tính, số liệu cũ vẫn xem được.
          if (_error != null && _items.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, Space.s2),
              child: OfflineStrip(
                key: const Key('tx_reload_error'),
                icon: Icons.sync_problem,
                title: 'Không tải lại được: $_error',
                onRetry: _load,
              ),
            ),
          Expanded(child: _buildList(gutter)),
        ],
      ),
    );
  }

  Category? _categoryOf(Tx tx) {
    final id = tx.categoryId;
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Widget _buildList(double gutter) {
    if (_loading && _items.isEmpty) {
      return ListView(
        padding: EdgeInsets.symmetric(horizontal: gutter, vertical: Space.s2),
        children: const [ListSkeleton(rows: 6)],
      );
    }
    if (_error != null && _items.isEmpty) {
      return ErrorView(title: 'Không tải được giao dịch', message: _error!, onRetry: _load);
    }
    final monthText = monthShortLabel(_month, context.read<AppState>().now()).toLowerCase();
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: gutter, vertical: Space.s8),
          children: [
            if (_uncategorized)
              EmptyState(icon: Icons.done_all, title: 'Đã phân loại hết giao dịch $monthText.')
            else
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Chưa có giao dịch trong $monthText.',
                message: 'Giao dịch từ Vietcombank và MB sẽ tự hiện khi ngân hàng báo biến động.',
              ),
          ],
        ),
      );
    }

    final now = context.read<AppState>().now();
    final groups = TxDayGroup.group(_items, now);
    final entries = <_Entry>[];
    for (var g = 0; g < groups.length; g++) {
      final group = groups[g];
      entries.add(_HeaderEntry(group, first: g == 0));
      for (var i = 0; i < group.items.length; i++) {
        entries.add(_RowEntry(group.items[i], first: i == 0, last: i == group.items.length - 1));
      }
    }
    final hasMore = _items.length < _total;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, AppLayout.fabClearance),
        itemCount: entries.length + (hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= entries.length) {
            return Padding(
              padding: const EdgeInsets.only(top: Space.s4),
              child: Center(
                child: _loadingMore
                    ? const SizedBox.square(dimension: 32, child: CircularProgressIndicator())
                    : OutlinedButton(onPressed: _loadMore, child: Text('Tải thêm (${_total - _items.length})')),
              ),
            );
          }
          return switch (entries[i]) {
            _HeaderEntry(:final group, :final first) => _DayHeader(group: group, first: first),
            _RowEntry(:final tx, :final first, :final last) => _GroupPiece(
              key: ValueKey('tx_${tx.id}'),
              first: first,
              last: last,
              child: TxTile(tx: tx, category: _categoryOf(tx), onTap: () => _openTx(tx)),
            ),
          };
        },
      ),
    );
  }
}

sealed class _Entry {
  const _Entry();
}

class _HeaderEntry extends _Entry {
  const _HeaderEntry(this.group, {required this.first});

  final TxDayGroup group;
  final bool first;
}

class _RowEntry extends _Entry {
  const _RowEntry(this.tx, {required this.first, required this.last});

  final Tx tx;
  final bool first;
  final bool last;
}

/// Tiêu đề nhóm ngày: "Hôm nay" … và tổng chi trong ngày ở cuối hàng.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.group, required this.first});

  final TxDayGroup group;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.only(top: first ? Space.s2 : Space.s6, bottom: Space.s2),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Space.s3,
        children: [
          Semantics(
            header: true,
            child: Text(group.title, style: theme.textTheme.titleSmall?.copyWith(color: muted)),
          ),
          if (group.spent > 0)
            MoneySentence(
              ['Đã chi ', group.spent],
              key: ValueKey('day_total_${group.key}'),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
        ],
      ),
    );
  }
}

/// Một hàng trong nhóm ngày: nền và bo góc của list group (góc trên ở hàng đầu, góc dưới ở hàng cuối), đường
/// kẻ thụt 72 dp giữa các hàng. Dựng từng hàng để danh sách dài vẫn dùng `ListView.builder`.
class _GroupPiece extends StatelessWidget {
  const _GroupPiece({super.key, required this.first, required this.last, required this.child});

  final bool first;
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(Radii.lg);
    final radius = BorderRadius.vertical(top: first ? r : Radius.zero, bottom: last ? r : Radius.zero);
    return ClipRRect(
      borderRadius: radius,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: EdgeInsets.only(top: first ? Space.s1 : 0, bottom: last ? Space.s1 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!first) const ExcludeSemantics(child: Divider(indent: ListGroup.dividerIndent)),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Tên nguồn dữ liệu hiển thị.
String txSourceLabel(String source) => switch (source.toLowerCase()) {
  'sepay' => 'SePay',
  'casso' => 'Casso',
  'email' => 'Email',
  'manual' => 'Nhập tay',
  _ => source,
};

/// Một dòng giao dịch (DESIGN.md › Lists › Row anatomy, surfaces/transactions/brief.md): đĩa danh mục (hoặc
/// chiều tiền khi chưa phân loại), mô tả, dòng phụ "Thuê trọ · VCB chính · 14:32 · SePay" (giờ Việt Nam),
/// số tiền có dấu ở cuối, tối đa một pill theo thứ tự ưu tiên.
class TxTile extends StatelessWidget {
  const TxTile({super.key, required this.tx, this.category, this.onTap});

  final Tx tx;

  /// Danh mục đầy đủ (có `system_key` để chọn icon); `null` thì dùng emoji trong giao dịch.
  final Category? category;
  final VoidCallback? onTap;

  /// Dòng phụ dạng chữ thuần.
  static String metaFor(Tx tx) {
    final sources = tx.isManual ? 'Nhập tay' : tx.sources.map(txSourceLabel).join(', ');
    return [
      if (tx.categoryName != null && !tx.isInternalTransfer) tx.categoryName!,
      if (tx.accountName != null && tx.accountName!.isNotEmpty) tx.accountName!,
      if (tx.bankTime != null) formatTimeIct(tx.bankTime!),
      if (sources.isNotEmpty) sources,
      if (tx.isExcluded) 'Đã loại trừ',
    ].join(' · ');
  }

  /// Pill duy nhất của hàng: Có thể trùng > Đang chờ khớp > Chưa phân loại > Chuyển nội bộ.
  static Pill? pillFor(Tx tx) {
    if (tx.isPossibleDuplicate) return const Pill('Có thể trùng', tone: PillTone.warning, icon: Icons.content_copy);
    if (tx.isPending) return const Pill('Đang chờ khớp', tone: PillTone.unknown, icon: Icons.hourglass_top);
    if (tx.isUncategorized) return const Pill('Chưa phân loại', tone: PillTone.invitation, icon: Icons.label_outline);
    if (tx.isInternalTransfer) return const Pill('Chuyển nội bộ', tone: PillTone.transfer, icon: Icons.swap_horiz);
    return null;
  }

  static MoneyTone toneFor(Tx tx) {
    if (tx.isExcluded) return MoneyTone.excluded;
    if (tx.isPending) return MoneyTone.pending;
    if (tx.isInternalTransfer) return MoneyTone.transfer;
    return tx.isOut ? MoneyTone.outgoing : MoneyTone.incoming;
  }

  Widget _leading() {
    if (tx.isInternalTransfer) return const LeadingDisc(icon: Icons.swap_horiz);
    final visual = CategoryVisual.resolve(systemKey: category?.systemKey, emoji: category?.icon ?? tx.categoryIcon);
    if (tx.categoryId != null && !visual.isEmpty) return CategoryAvatar(visual: visual);
    return LeadingDisc(icon: tx.isOut ? Icons.north_east : Icons.south_west);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final meta = metaFor(tx);
    final goal = tx.goalName ?? (tx.goalId == null ? null : 'Mục tiêu #${tx.goalId}');
    final goalText = goal == null
        ? null
        : (tx.goalMonth != null && tx.goalMonth != tx.month ? '$goal · ${shortMonthLabel(tx.goalMonth!)}' : goal);
    final pill = pillFor(tx);
    return MoneyRow(
      leading: _leading(),
      title: Text(tx.title),
      meta: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (meta.isNotEmpty) Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (goalText != null)
            Row(
              children: [
                Icon(Icons.flag_outlined, size: 16, color: muted),
                const SizedBox(width: Space.s1),
                Flexible(child: Text(goalText, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
        ],
      ),
      amount: MoneyText(
        tx.amount,
        style: MoneyStyle.list,
        sign: tx.isOut ? MoneySign.outgoing : MoneySign.incoming,
        tone: toneFor(tx),
      ),
      below: pill == null ? null : Align(alignment: AlignmentDirectional.centerStart, child: pill),
      onTap: onTap,
    );
  }
}
