import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';

/// Kết quả bảng thao tác: giao dịch sau khi sửa, hoặc đã xoá.
class TxSheetResult {
  const TxSheetResult({this.transaction, this.deleted = false});

  final Tx? transaction;
  final bool deleted;
}

Future<TxSheetResult?> showTxActionSheet(
  BuildContext context, {
  required ApiClient client,
  required Tx tx,
  List<Category> categories = const [],
}) {
  return showModalBottomSheet<TxSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => TxActionSheet(client: client, tx: tx, categories: categories),
  );
}

/// Gợi ý cụm từ để "nhớ luật" từ mô tả giao dịch: bỏ mã số dài, lấy vài từ đầu.
String suggestRulePattern(String description) {
  final words = description
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length >= 2)
      .take(4)
      .toList();
  return words.join(' ');
}

/// Bảng thao tác một giao dịch: chọn danh mục (+ nhớ luật), gán mục tiêu,
/// "Tính cho tháng sau", loại trừ, xoá (nhập tay).
class TxActionSheet extends StatefulWidget {
  const TxActionSheet({super.key, required this.client, required this.tx, this.categories = const []});

  final ApiClient client;
  final Tx tx;
  final List<Category> categories;

  @override
  State<TxActionSheet> createState() => _TxActionSheetState();
}

class _TxActionSheetState extends State<TxActionSheet> {
  late List<Category> _categories;
  int? _categoryId;
  bool _remember = false;
  late final TextEditingController _pattern;
  bool _busy = false;
  String? _error;

  Tx get tx => widget.tx;

  @override
  void initState() {
    super.initState();
    _categories = widget.categories;
    _categoryId = tx.categoryId;
    _pattern = TextEditingController(text: suggestRulePattern(tx.description));
    if (_categories.isEmpty) _loadCategories();
  }

  @override
  void dispose() {
    _pattern.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await widget.client.listCategories();
      if (mounted) setState(() => _categories = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  List<Category> get _choices {
    final list = tx.isOut ? _categories.where((c) => c.isExpense || c.isTransfer).toList() : [..._categories];
    return list;
  }

  Future<void> _patch(JsonMap changes, {String? done}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final state = context.read<AppState>();
    try {
      final result = await widget.client.patchTransaction(tx.id, changes);
      final summary = result.summary;
      if (summary != null) {
        state.applySummary(summary);
      } else {
        await state.load();
      }
      if (!mounted) return;
      if (done != null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(done)));
      }
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

  void _saveCategory() {
    final pattern = _pattern.text.trim();
    if (_remember && pattern.length < 2) {
      setState(() => _error = 'Nhập cụm từ (ít nhất 2 ký tự) để nhớ luật');
      return;
    }
    _patch({
      'category_id': _categoryId,
      if (_remember && _categoryId != null) ...{'remember_rule': true, 'rule_pattern': pattern},
    }, done: _remember ? 'Đã phân loại và nhớ luật "$pattern"' : 'Đã phân loại');
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá giao dịch nhập tay?'),
        content: Text('${formatSignedVnd(tx.amount, outgoing: tx.isOut)} · ${tx.title}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final state = context.read<AppState>();
    try {
      await widget.client.deleteTransaction(tx.id);
      await state.load();
      if (mounted) Navigator.of(context).pop(const TxSheetResult(deleted: true));
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
    final goals = context.select<AppState, List<GoalView>>((s) => s.summary?.goals ?? const []);
    final goalIds = goals.map((g) => g.id).toSet();
    final changedCategory = _categoryId != tx.categoryId;
    final meta = [
      if (tx.accountName != null) tx.accountName!,
      if (tx.bankTime != null) formatDateTime(tx.bankTime!),
      if (tx.balanceAfter != null) 'Số dư sau: ${formatVnd(tx.balanceAfter!)}',
    ].join(' · ');

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatSignedVnd(tx.amount, outgoing: tx.isOut),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: tx.isOut ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
            Text(tx.title, style: theme.textTheme.titleMedium),
            if (meta.isNotEmpty) Text(meta, style: theme.textTheme.bodySmall),
            if (tx.isPossibleDuplicate)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Có thể trùng với giao dịch #${tx.possibleDuplicateOf}. Nếu đúng là trùng, hãy "Loại trừ" một bản.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.deepOrange),
                ),
              ),
            if (tx.isPending)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Giao dịch từ email đang chờ webhook khớp, tạm chưa tính.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 16),
            Text('Danh mục', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_categories.isEmpty && _error == null)
              const LinearProgressIndicator()
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in _choices)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: _categoryId == c.id,
                      onSelected: _busy ? null : (sel) => setState(() => _categoryId = sel ? c.id : null),
                    ),
                ],
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Nhớ luật cho giao dịch tương tự'),
              value: _remember,
              onChanged: _busy || _categoryId == null ? null : (v) => setState(() => _remember = v ?? false),
            ),
            if (_remember)
              TextField(
                controller: _pattern,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Cụm từ nhận diện',
                  helperText: 'Giao dịch sau có mô tả chứa cụm từ này sẽ tự vào danh mục đã chọn',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _busy || (!changedCategory && !_remember) ? null : _saveCategory,
                    child: Text(_categoryId == null ? 'Bỏ phân loại' : 'Lưu danh mục'),
                  ),
                ),
              ],
            ),
            if (goals.isNotEmpty && !tx.isInternalTransfer) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: goalIds.contains(tx.goalId) ? tx.goalId : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Gán vào mục tiêu',
                  helperText: 'Mặc định tự khớp theo danh mục',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Tự động theo danh mục')),
                  for (final g in goals) DropdownMenuItem<int?>(value: g.id, child: Text('${g.name} (${g.typeLabel})')),
                ],
                onChanged: _busy
                    ? null
                    : (v) {
                        if (v != tx.goalId) _patch({'goal_id': v}, done: 'Đã gán mục tiêu');
                      },
              ),
            ],
            const SizedBox(height: 8),
            const Divider(),
            if (tx.isOut && !tx.isExcluded)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_repeat),
                title: const Text('Tính cho tháng sau'),
                subtitle: const Text('VD: trả tiền trọ tháng sau từ cuối tháng này'),
                enabled: !_busy,
                onTap: () => _patch({
                  'for_next_month': true,
                  if (changedCategory && _categoryId != null) 'category_id': _categoryId,
                }, done: 'Đã tính cho mục tiêu tháng sau'),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(tx.isExcluded ? Icons.undo : Icons.block),
              title: Text(tx.isExcluded ? 'Bỏ loại trừ' : 'Loại trừ'),
              subtitle: Text(
                tx.isExcluded ? 'Tính lại giao dịch này' : 'Không tính giao dịch này vào chi tiêu và mục tiêu',
              ),
              enabled: !_busy,
              onTap: () => _patch(
                {'excluded': !tx.isExcluded},
                done: tx.isExcluded ? 'Đã bỏ loại trừ' : 'Đã loại trừ giao dịch',
              ),
            ),
            if (tx.isManual)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline, color: scheme.error),
                title: Text('Xoá giao dịch nhập tay', style: TextStyle(color: scheme.error)),
                enabled: !_busy,
                onTap: _delete,
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
