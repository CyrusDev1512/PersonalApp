import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';

/// Tham số route của form mục tiêu: `goal == null` là thêm mới.
class GoalFormArgs {
  const GoalFormArgs({this.goal});

  final GoalView? goal;
}

/// Cách xoá mục tiêu lặp lại.
enum _DeleteChoice { thisMonth, stopSeries }

/// Form "Thêm mục tiêu" / "Sửa mục tiêu".
class GoalFormScreen extends StatefulWidget {
  const GoalFormScreen({super.key, this.goal});

  static const routeName = '/goal';

  final GoalView? goal;

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _openingSpent;
  late String _type;
  int? _categoryId;
  late String _thisMonth;
  late String _month;
  late bool _repeat;

  List<Category>? _categories;
  String? _categoriesError;
  bool _saving = false;

  bool get _editing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    final state = context.read<AppState>();
    _thisMonth = state.summary?.month ?? currentMonthIct(state.now());
    if (parseMonth(_thisMonth) == null) _thisMonth = currentMonthIct(state.now());
    _name = TextEditingController(text: g?.name ?? '');
    _amount = TextEditingController(text: g == null ? '' : formatGrouped(g.amount));
    _openingSpent = TextEditingController(
      text: (g == null || g.openingSpent == 0) ? '' : formatGrouped(g.openingSpent),
    );
    _type = g?.type ?? GoalType.reserve;
    _categoryId = g?.categoryId;
    _month = g?.month ?? _thisMonth;
    _repeat = g?.repeatMonthly ?? true;
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _openingSpent.dispose();
    super.dispose();
  }

  ApiClient? get _client => context.read<AppState>().client;

  Future<void> _loadCategories() async {
    final client = _client;
    if (client == null) return;
    setState(() => _categoriesError = null);
    try {
      final all = await client.listCategories();
      if (!mounted) return;
      setState(() => _categories = all.where((c) => c.isExpense).toList());
    } on ApiException catch (e) {
      if (mounted) setState(() => _categoriesError = e.message);
    }
  }

  String? _validateCategory(int? value) {
    if (_type == GoalType.budget && value == null) return 'Ngân sách chi tiêu cần chọn danh mục';
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final client = _client;
    if (client == null) return;
    final input = GoalInput(
      name: _name.text.trim(),
      type: _type,
      amount: parseVnd(_amount.text)!,
      categoryId: _categoryId,
      month: _month,
      repeatMonthly: _repeat,
      openingSpent: parseVnd(_openingSpent.text) ?? 0,
    );
    setState(() => _saving = true);
    final state = context.read<AppState>();
    try {
      if (_editing) {
        await client.updateGoal(widget.goal!.id, input.toJson(includeMonth: false));
      } else {
        await client.createGoal(input);
      }
      await state.load();
      if (!mounted) return;
      showInfo(context, _editing ? 'Đã lưu mục tiêu' : 'Đã thêm mục tiêu "${input.name}"');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showError(context, e);
    }
  }

  Future<void> _delete() async {
    final goal = widget.goal;
    final client = _client;
    if (goal == null || client == null) return;
    final choice = await showDialog<_DeleteChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xoá "${goal.name}"?'),
        content: Text(
          goal.repeatMonthly
              ? 'Mục tiêu này lặp lại hằng tháng. Bạn muốn xoá thế nào?'
              : 'Mục tiêu ${shortMonthLabel(goal.month)} sẽ bị xoá.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _DeleteChoice.thisMonth),
            child: const Text('Chỉ xoá tháng này'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _DeleteChoice.stopSeries),
            child: const Text('Xoá và dừng lặp lại'),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    try {
      await client.deleteGoal(goal.id, stopSeries: choice == _DeleteChoice.stopSeries);
      await state.load();
      if (!mounted) return;
      showInfo(context, 'Đã xoá mục tiêu');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextMonth = shiftMonth(_thisMonth, 1);
    final helper = _type == GoalType.budget
        ? 'Hạn mức chi trong tháng, vd. tiền ăn 5.000.000đ. Mỗi khoản chi thuộc danh mục sẽ trừ dần; '
              'phần chưa chi vẫn được giữ trong mức sàn.'
        : 'Số tiền phải giữ lại trong tài khoản, vd. tiền trọ 3.000.000đ. Khi khoản chi thuộc danh mục '
              'phát sinh (trả trọ), quỹ giảm tương ứng.';

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Sửa mục tiêu' : 'Thêm mục tiêu'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Xoá mục tiêu',
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              TextFormField(
                key: const Key('goal_name'),
                controller: _name,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tên mục tiêu',
                  hintText: 'VD: Tiền trọ, Tiền ăn',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return 'Nhập tên mục tiêu';
                  if (s.length > 80) return 'Tên tối đa 80 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Loại mục tiêu', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: GoalType.reserve, label: Text('Quỹ giữ'), icon: Icon(Icons.savings_outlined)),
                  ButtonSegment(
                    value: GoalType.budget,
                    label: Text('Ngân sách chi tiêu'),
                    icon: Icon(Icons.shopping_basket_outlined),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: _saving
                    ? null
                    : (s) => setState(() {
                        _type = s.first;
                      }),
              ),
              const SizedBox(height: 6),
              Text(helper, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('goal_amount'),
                controller: _amount,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: const [VndInputFormatter()],
                decoration: const InputDecoration(labelText: 'Số tiền', suffixText: 'đ', border: OutlineInputBorder()),
                validator: (v) {
                  final amount = parseVnd(v);
                  if (amount == null) return 'Nhập số tiền';
                  if (amount <= 0) return 'Số tiền phải lớn hơn 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildCategoryField(),
              const SizedBox(height: 16),
              Text('Tháng', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              if (_editing)
                Text(monthLabel(_month), style: theme.textTheme.bodyLarge)
              else
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: _thisMonth, label: Text('Tháng này (${shortMonthLabel(_thisMonth)})')),
                    ButtonSegment(value: nextMonth, label: Text('Tháng sau (${shortMonthLabel(nextMonth)})')),
                  ],
                  selected: {_month},
                  onSelectionChanged: _saving ? null : (s) => setState(() => _month = s.first),
                ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lặp lại hằng tháng'),
                subtitle: Text(
                  _editing
                      ? 'Thay đổi áp dụng cho tháng này và các tháng sau'
                      : 'Tự tạo lại mục tiêu này vào đầu mỗi tháng',
                ),
                value: _repeat,
                onChanged: _saving ? null : (v) => setState(() => _repeat = v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('goal_opening_spent'),
                controller: _openingSpent,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: const [VndInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Đã chi trước khi dùng app (tuỳ chọn)',
                  helperText:
                      'Số đã chi cho mục tiêu này trong tháng trước khi bắt đầu dùng app; '
                      'chỉ tính cho tháng đầu tiên.',
                  helperMaxLines: 3,
                  suffixText: 'đ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final spent = parseVnd(v);
                  if (spent != null && spent < 0) return 'Số tiền không được âm';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('goal_save'),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(_editing ? 'Lưu thay đổi' : 'Tạo mục tiêu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    final categories = _categories;
    if (categories == null) {
      if (_categoriesError != null) {
        return Row(
          children: [
            Expanded(child: Text('Không tải được danh mục: $_categoriesError')),
            TextButton(onPressed: _loadCategories, child: const Text('Thử lại')),
          ],
        );
      }
      return const LinearProgressIndicator();
    }
    final allowNone = _type == GoalType.reserve;
    // Danh mục hiện tại có thể không còn trong danh sách (đã đổi kind…) → vẫn giữ để không lỗi Dropdown.
    final known = categories.any((c) => c.id == _categoryId);
    final value = (_categoryId == null && allowNone) || known ? _categoryId : null;
    return DropdownButtonFormField<int?>(
      key: ValueKey('goal_category_$_type'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Danh mục',
        helperText: allowNone
            ? 'Để "Tiết kiệm thuần" nếu chỉ muốn giữ tiền, không gắn khoản chi nào'
            : 'Khoản chi thuộc danh mục này sẽ trừ vào ngân sách',
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
      ),
      items: [
        if (allowNone)
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Tiết kiệm thuần (không gắn danh mục)', overflow: TextOverflow.ellipsis),
          ),
        for (final c in categories)
          DropdownMenuItem<int?>(
            value: c.id,
            child: Text(c.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      validator: _validateCategory,
      onChanged: _saving ? null : (v) => setState(() => _categoryId = v),
    );
  }
}
