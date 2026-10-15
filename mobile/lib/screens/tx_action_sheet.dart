import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/status_colors.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import '../utils/dates.dart';
import '../widgets/category_icon.dart';
import '../widgets/common.dart';
import '../widgets/form_parts.dart';
import '../widgets/money_text.dart';

/// Kết quả bảng thao tác: giao dịch sau khi sửa, hoặc đã xoá.
class TxSheetResult {
  const TxSheetResult({this.transaction, this.deleted = false});

  final Tx? transaction;
  final bool deleted;
}

/// Mở bảng phân loại một giao dịch. [onUndone]: gọi sau khi người dùng bấm "Hoàn tác" trên SnackBar và máy chủ
/// đã trả giao dịch về như cũ (vd. để danh sách tải lại).
Future<TxSheetResult?> showTxActionSheet(
  BuildContext context, {
  required ApiClient client,
  required Tx tx,
  List<Category> categories = const [],
  ValueChanged<Tx>? onUndone,
}) {
  return showModalBottomSheet<TxSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    // Chừa một khoảng phía trên để chạm ra ngoài là đóng được; màn rộng không kéo giãn quá 640 dp.
    constraints: AppLayout.sheetConstraints(context),
    builder: (_) => TxActionSheet(client: client, tx: tx, categories: categories, onUndone: onUndone),
  );
}

/// Bảng phân loại một giao dịch (surfaces/transactions/brief.md): chọn danh mục (+ nhớ luật), gán mục tiêu,
/// "Tính cho tháng sau", loại trừ; mọi lựa chọn là một form, lưu một lần bằng nút dính ở đáy ("Lưu danh mục").
/// Xoá (chỉ giao dịch nhập tay) là nút chữ màu `error` kèm hộp thoại xác nhận.
class TxActionSheet extends StatefulWidget {
  const TxActionSheet({super.key, required this.client, required this.tx, this.categories = const [], this.onUndone});

  final ApiClient client;
  final Tx tx;
  final List<Category> categories;
  final ValueChanged<Tx>? onUndone;

  @override
  State<TxActionSheet> createState() => _TxActionSheetState();
}

class _TxActionSheetState extends State<TxActionSheet> {
  late List<Category> _categories;
  String? _categoriesError;
  int? _categoryId;
  bool _remember = false;
  late final TextEditingController _pattern;
  String? _patternError;
  int? _goalId;
  bool _forNextMonth = false;
  late bool _excluded;
  bool _busy = false;
  String? _error;

  /// Tháng của giao dịch (giờ VN): chỉ gán được vào mục tiêu của tháng này.
  late final String _txMonth;

  /// Mục tiêu của [_txMonth]; `null` = đang tải.
  List<GoalView>? _goals;
  String? _goalsError;

  Tx get tx => widget.tx;

  @override
  void initState() {
    super.initState();
    _categories = widget.categories;
    _categoryId = tx.categoryId;
    _goalId = tx.goalId;
    _excluded = tx.isExcluded;
    // Cụm từ server gợi ý luôn khớp mô tả giao dịch; không có thì để người dùng tự nhập.
    _pattern = TextEditingController(text: tx.suggestedRule ?? '');
    final state = context.read<AppState>();
    _txMonth = tx.month ?? state.summary?.month ?? currentMonthIct(state.now());
    if (_categories.isEmpty) _loadCategories();
    if (!tx.isInternalTransfer) _loadGoals();
  }

  @override
  void dispose() {
    _pattern.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesError = null);
    try {
      final list = await widget.client.listCategories();
      if (mounted) setState(() => _categories = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _categoriesError = e.message);
    }
  }

  Future<void> _loadGoals() async {
    try {
      final list = await widget.client.listGoals(month: _txMonth);
      if (mounted) setState(() => _goals = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _goalsError = e.message);
    }
  }

  List<Category> get _choices =>
      tx.isOut ? _categories.where((c) => c.isExpense || c.isTransfer).toList() : [..._categories];

  /// "Tiền trọ (11/2026)": mục tiêu giao dịch đang được gán.
  String get _assignedGoalLabel {
    final name = tx.goalName ?? 'Mục tiêu #${tx.goalId}';
    return tx.goalMonth == null ? name : '$name (${shortMonthLabel(tx.goalMonth!)})';
  }

  bool get _categoryChanged => _categoryId != tx.categoryId;

  /// Có thể "Tính cho tháng sau" (khoản chi đang tính, chưa tính cho tháng sau).
  bool get _canCountLater => tx.isOut && !tx.isExcluded && !tx.countedForLaterMonth;

  /// Phần thay đổi gửi PATCH (tập con của body trong docs/api.md).
  JsonMap get _changes {
    final remember = _remember && _categoryId != null;
    return {
      if (_categoryChanged || remember) 'category_id': _categoryId,
      if (remember) ...{'remember_rule': true, 'rule_pattern': _pattern.text.trim()},
      if (_goalId != tx.goalId) 'goal_id': _goalId,
      if (_forNextMonth && _canCountLater) 'for_next_month': true,
      if (_excluded != tx.isExcluded) 'excluded': _excluded,
    };
  }

  String get _saveLabel {
    if (_categoryChanged && _categoryId == null) return 'Bỏ phân loại';
    final changes = _changes;
    if (_categoryChanged || _remember || changes.isEmpty) return 'Lưu danh mục';
    return 'Lưu thay đổi';
  }

  String _doneMessage(JsonMap changes) {
    if (changes['remember_rule'] == true) return 'Đã phân loại và nhớ luật "${changes['rule_pattern']}"';
    if (changes.containsKey('category_id')) return _categoryId == null ? 'Đã bỏ phân loại' : 'Đã phân loại';
    if (changes.containsKey('excluded')) return _excluded ? 'Đã loại trừ giao dịch' : 'Đã bỏ loại trừ';
    if (changes.containsKey('for_next_month')) return 'Đã tính cho mục tiêu tháng sau';
    if (changes.containsKey('goal_id')) return _goalId == null ? 'Đã bỏ gán mục tiêu' : 'Đã gán mục tiêu';
    return 'Đã lưu';
  }

  /// Thao tác hoàn tác được (gửi lại giá trị cũ): đổi danh mục (không nhớ luật) hoặc loại trừ, khi chỉ đổi đúng
  /// một thứ đó.
  JsonMap? _undoFor(JsonMap changes) {
    if (changes.length != 1) return null;
    if (changes.containsKey('category_id')) return {'category_id': tx.categoryId};
    if (changes.containsKey('excluded')) return {'excluded': tx.isExcluded};
    return null;
  }

  Future<void> _save() async {
    final changes = _changes;
    if (changes['remember_rule'] == true && (changes['rule_pattern'] as String).length < 2) {
      setState(() => _patternError = 'Nhập cụm từ (ít nhất 2 ký tự) để nhớ luật');
      return;
    }
    if (changes.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _patternError = null;
    });
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final client = widget.client;
    final onUndone = widget.onUndone;
    try {
      final result = await client.patchTransaction(tx.id, changes);
      final summary = result.summary;
      if (summary != null) {
        state.applySummary(summary);
      } else {
        await state.load();
      }
      if (!mounted) return;
      final undo = _undoFor(changes);
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_doneMessage(changes)),
            duration: Duration(seconds: undo == null ? 4 : 6),
            persist: false,
            action: undo == null
                ? null
                : SnackBarAction(
                    label: 'Hoàn tác',
                    onPressed: () async {
                      try {
                        final back = await client.patchTransaction(tx.id, undo);
                        if (back.summary != null) state.applySummary(back.summary!);
                        onUndone?.call(back.transaction);
                      } on ApiException catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('Không hoàn tác được: ${e.message}')));
                      }
                    },
                  ),
          ),
        );
      Navigator.of(context).pop(TxSheetResult(transaction: result.transaction));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _delete() async {
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá giao dịch nhập tay?'),
        content: Text(
          '${MoneyParts.of(tx.amount, sign: tx.isOut ? MoneySign.outgoing : MoneySign.incoming).text} · ${tx.title}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: AppButtonStyles.destructiveFilled(scheme),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await widget.client.deleteTransaction(tx.id);
      await state.load();
      if (!mounted) return;
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Đã xoá giao dịch nhập tay')));
      Navigator.of(context).pop(const TxSheetResult(deleted: true));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final changes = _changes;
    final canSave = !_busy && changes.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Space.s5, 0, Space.s5, Space.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ..._header(theme),
                  const SizedBox(height: Space.s6),
                  Text('Danh mục', style: text.titleSmall),
                  const SizedBox(height: Space.s2),
                  _categoryChips(theme),
                  const SizedBox(height: Space.s2),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Nhớ luật cho giao dịch tương tự'),
                    subtitle: const Text('Giao dịch sau có mô tả giống vậy sẽ tự vào danh mục này'),
                    value: _remember,
                    onChanged: _busy || _categoryId == null
                        ? null
                        : (v) => setState(() {
                            _remember = v;
                            _patternError = null;
                          }),
                  ),
                  if (_remember) ...[
                    const SizedBox(height: Space.s2),
                    TextField(
                      controller: _pattern,
                      enabled: !_busy,
                      onChanged: (_) => setState(() => _patternError = null),
                      decoration: InputDecoration(
                        labelText: 'Cụm từ nhận diện',
                        hintText: 'VD: tên cửa hàng trong mô tả',
                        helperText: 'Giao dịch sau có mô tả chứa cụm từ này sẽ tự vào danh mục đã chọn',
                        errorText: _patternError,
                      ),
                    ),
                  ],
                  ..._goalSection(theme),
                  const SizedBox(height: Space.s2),
                  if (tx.isOut && !tx.isExcluded && tx.countedForLaterMonth)
                    ListTile(
                      key: const Key('tx_counted_later'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_available),
                      title: Text('Đã tính cho ${monthLabel(tx.goalMonth!).toLowerCase()}'),
                      subtitle: Text('Mục tiêu: $_assignedGoalLabel'),
                    )
                  else if (_canCountLater)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tính cho tháng sau'),
                      subtitle: const Text('VD: trả tiền trọ tháng sau từ cuối tháng này'),
                      value: _forNextMonth,
                      onChanged: _busy ? null : (v) => setState(() => _forNextMonth = v),
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Loại trừ'),
                    subtitle: const Text('Không tính giao dịch này vào chi tiêu và mục tiêu'),
                    value: _excluded,
                    onChanged: _busy ? null : (v) => setState(() => _excluded = v),
                  ),
                  if (tx.isManual) ...[
                    const SizedBox(height: Space.s4),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        style: AppButtonStyles.destructiveText(scheme),
                        onPressed: _busy ? null : _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Xoá giao dịch nhập tay'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          StickyActionBar(
            horizontalPadding: Space.s5,
            error: _error,
            primary: FilledButton.icon(
              key: const Key('tx_save'),
              onPressed: canSave ? _save : null,
              icon: _busy ? const BusyIcon() : null,
              label: Text(_saveLabel),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _header(ThemeData theme) {
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);
    final small = text.bodySmall!.copyWith(color: scheme.onSurfaceVariant);
    final metaParts = [
      if (tx.accountName != null && tx.accountName!.isNotEmpty) tx.accountName!,
      if (tx.bankTime != null) formatDateTimeIct(tx.bankTime!),
    ];
    final balanceAfter = tx.balanceAfter;
    return [
      MoneyText(
        tx.amount,
        style: MoneyStyle.large,
        sign: tx.isOut ? MoneySign.outgoing : MoneySign.incoming,
        tone: tx.isExcluded
            ? MoneyTone.excluded
            : tx.isInternalTransfer || tx.isPending
            ? MoneyTone.transfer
            : tx.isOut
            ? MoneyTone.outgoing
            : MoneyTone.incoming,
      ),
      const SizedBox(height: Space.s1),
      Text(tx.title, style: text.titleMedium?.copyWith(color: scheme.onSurface)),
      if (metaParts.isNotEmpty || balanceAfter != null)
        MoneySentence([
          metaParts.join(' · '),
          if (balanceAfter != null) ...[metaParts.isEmpty ? 'Số dư sau: ' : ' · Số dư sau: ', balanceAfter],
        ], style: small),
      if (tx.isPossibleDuplicate) ...[
        const SizedBox(height: Space.s3),
        InlineNote(
          icon: Icons.content_copy,
          iconColor: status.warning.foreground,
          textColor: scheme.onSurface,
          text: 'Có thể trùng với giao dịch #${tx.possibleDuplicateOf}. Nếu đúng là trùng, hãy bật "Loại trừ" cho một bản.',
        ),
      ],
      if (tx.isPending) ...[
        const SizedBox(height: Space.s3),
        InlineNote(
          icon: Icons.hourglass_top,
          textColor: scheme.onSurface,
          text: 'Giao dịch từ email đang chờ webhook khớp, tạm chưa tính.',
        ),
      ],
    ];
  }

  Widget _categoryChips(ThemeData theme) {
    if (_categories.isEmpty) {
      final error = _categoriesError;
      if (error == null) {
        return Text(
          'Đang tải danh mục…',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        );
      }
      return Row(
        children: [
          Expanded(
            child: Text(
              'Không tải được danh mục.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
            ),
          ),
          TextButton(onPressed: _loadCategories, child: const Text('Thử lại')),
        ],
      );
    }
    return Wrap(
      spacing: Space.s2,
      runSpacing: Space.s2,
      children: [
        for (final c in _choices)
          Builder(
            builder: (context) {
              final visual = CategoryVisual.of(c);
              return ChoiceChip(
                avatar: visual.chipAvatar(),
                label: Text(visual.label(c.name)),
                selected: _categoryId == c.id,
                onSelected: _busy
                    ? null
                    : (sel) => setState(() {
                        _categoryId = sel ? c.id : null;
                        // Không có danh mục thì không có luật để nhớ.
                        if (_categoryId == null) _remember = false;
                      }),
              );
            },
          ),
      ],
    );
  }

  List<Widget> _goalSection(ThemeData theme) {
    if (tx.isInternalTransfer) return const [];
    final goals = _goals;
    final helper = 'Mục tiêu ${monthLabel(_txMonth).toLowerCase()} · mặc định tự khớp theo danh mục';
    if (goals == null && _goalsError == null) {
      return [
        const SizedBox(height: Space.s4),
        DropdownButtonFormField<int?>(
          items: const [],
          onChanged: null,
          decoration: const InputDecoration(labelText: 'Gán vào mục tiêu', helperText: 'Đang tải mục tiêu…'),
        ),
      ];
    }
    if (goals == null) {
      return [
        const SizedBox(height: Space.s4),
        Text(
          'Không tải được mục tiêu ${monthLabel(_txMonth).toLowerCase()}: $_goalsError',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
        ),
      ];
    }
    // Giao dịch đang gán vào mục tiêu của tháng khác (vd. "Tính cho tháng sau"): vẫn hiện để không lầm là
    // "Tự động" và không bị bỏ gán khi chọn lại.
    final assignedElsewhere = tx.goalId != null && !goals.any((g) => g.id == tx.goalId);
    if (goals.isEmpty && !assignedElsewhere) return const [];
    return [
      const SizedBox(height: Space.s4),
      DropdownButtonFormField<int?>(
        key: const Key('tx_goal'),
        initialValue: _goalId,
        isExpanded: true,
        decoration: InputDecoration(labelText: 'Gán vào mục tiêu', helperText: helper),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Tự động theo danh mục', overflow: TextOverflow.ellipsis),
          ),
          for (final g in goals)
            DropdownMenuItem<int?>(
              value: g.id,
              child: Text(
                '${g.name} (${g.typeLabel} · ${shortMonthLabel(g.month.isEmpty ? _txMonth : g.month)})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (assignedElsewhere)
            DropdownMenuItem<int?>(
              value: tx.goalId,
              enabled: false,
              child: Text(_assignedGoalLabel, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _busy ? null : (v) => setState(() => _goalId = v),
      ),
    ];
  }
}
