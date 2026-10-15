import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';
import '../widgets/category_icon.dart';
import '../widgets/common.dart';
import '../widgets/form_parts.dart';

/// Tham số route của form mục tiêu: `goal == null` là thêm mới.
class GoalFormArgs {
  const GoalFormArgs({this.goal});

  final GoalView? goal;
}

/// Cách xoá mục tiêu.
enum _DeleteChoice { thisMonth, stopSeries }

/// Gợi ý tên cho mục tiêu mới: chạm thì điền tên, loại và danh mục (theo `system_key`) khi rõ ràng.
const List<(String, String, String?)> _suggestions = [
  ('Tiền trọ', GoalType.reserve, 'rent'),
  ('Tiền ăn', GoalType.budget, 'food'),
  ('Tiết kiệm', GoalType.reserve, null),
];

/// Form "Thêm mục tiêu" / "Sửa mục tiêu" (surfaces/goal-form/brief.md): loại mục tiêu trước (nó đổi nghĩa
/// các ô còn lại), tên, số tiền, danh mục, tháng, lặp lại; "Đã chi trước khi dùng app" nằm trong
/// "Thêm tuỳ chọn"; nút lưu dính ở đáy, nằm trên bàn phím.
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
  final _nameFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _categoryFocus = FocusNode();
  final _openingFocus = FocusNode();
  late String _type;
  int? _categoryId;
  late String _thisMonth;
  late String _month;
  late bool _repeat;
  late bool _moreOptions;
  late DateTime _now;

  /// Mục tiêu tháng này (để báo khi mục tiêu tháng sau nhập vào một chuỗi lặp lại sẵn có).
  List<GoalView> _thisMonthGoals = const [];

  List<Category>? _categories;
  String? _categoriesError;
  bool _saving = false;

  bool get _editing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    final state = context.read<AppState>();
    _now = state.now();
    _thisMonth = state.summary?.month ?? currentMonthIct(_now);
    if (parseMonth(_thisMonth) == null) _thisMonth = currentMonthIct(_now);
    _thisMonthGoals = state.summary?.goals ?? const [];
    _name = TextEditingController(text: g?.name ?? '');
    _amount = TextEditingController(text: g == null ? '' : formatGrouped(g.amount));
    _openingSpent = TextEditingController(
      text: (g == null || g.openingSpent == 0) ? '' : formatGrouped(g.openingSpent),
    );
    _moreOptions = (g?.openingSpent ?? 0) > 0;
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
    _nameFocus.dispose();
    _amountFocus.dispose();
    _categoryFocus.dispose();
    _openingFocus.dispose();
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

  static String? _validateName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Nhập tên mục tiêu';
    if (s.length > 80) return 'Tên tối đa 80 ký tự';
    return null;
  }

  static String? _validateAmount(String? v) {
    final amount = parseVnd(v);
    if (amount == null) return 'Nhập số tiền';
    if (amount <= 0) return 'Số tiền phải lớn hơn 0';
    return vndTooLarge(amount);
  }

  static String? _validateOpening(String? v) {
    final spent = parseVnd(v);
    if (spent != null && spent < 0) return 'Số tiền không được âm';
    return vndTooLarge(spent);
  }

  String? _validateCategory(int? value) {
    if (_type == GoalType.budget && value == null) return 'Ngân sách chi tiêu cần chọn danh mục';
    return null;
  }

  void _applySuggestion((String, String, String?) s) {
    final (name, type, systemKey) = s;
    setState(() {
      _name.text = name;
      _type = type;
      if (systemKey == null) {
        if (type == GoalType.reserve) _categoryId = null;
      } else {
        final match = _categories?.where((c) => c.systemKey == systemKey).toList() ?? const [];
        if (match.length == 1) _categoryId = match.single.id;
      }
    });
    _amountFocus.requestFocus();
  }

  /// Đưa con trỏ tới ô sai đầu tiên.
  void _focusFirstInvalid() {
    if (_validateName(_name.text) != null) {
      _nameFocus.requestFocus();
    } else if (_validateAmount(_amount.text) != null) {
      _amountFocus.requestFocus();
    } else if (_validateCategory(_categoryId) != null) {
      _categoryFocus.requestFocus();
    } else if (_moreOptions && _validateOpening(_openingSpent.text) != null) {
      _openingFocus.requestFocus();
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      _focusFirstInvalid();
      return;
    }
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
      final message = _editing
          ? 'Đã lưu mục tiêu'
          : _month != _thisMonth
          ? 'Đã tạo mục tiêu cho ${monthShortLabel(_month, _now).toLowerCase()}'
          : 'Đã thêm mục tiêu "${input.name}"';
      showInfo(context, message);
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showInfo(context, e.isNetwork ? 'Không kết nối được máy chủ. Mục tiêu chưa được lưu.' : e.message);
    }
  }

  Future<void> _delete() async {
    final goal = widget.goal;
    final client = _client;
    if (goal == null || client == null) return;
    final scheme = Theme.of(context).colorScheme;
    final destructive = AppButtonStyles.destructiveFilled(scheme);
    final choice = await showDialog<_DeleteChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        // Chữ lớn (200%): nội dung cuộn được, không bị cắt mất câu cuối.
        scrollable: true,
        title: Text('Xoá "${goal.name}"?', maxLines: 2, overflow: TextOverflow.ellipsis),
        content: Text(
          goal.repeatMonthly
              ? 'Mục tiêu này lặp lại hằng tháng. Bạn muốn xoá thế nào?'
              : 'Mục tiêu ${shortMonthLabel(goal.month)} sẽ bị xoá.',
        ),
        actions: goal.repeatMonthly
            ? [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, _DeleteChoice.thisMonth),
                  child: const Text('Chỉ xoá tháng này'),
                ),
                FilledButton(
                  style: destructive,
                  onPressed: () => Navigator.pop(ctx, _DeleteChoice.stopSeries),
                  child: const Text('Xoá và dừng lặp lại'),
                ),
              ]
            : [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
                FilledButton(
                  style: destructive,
                  onPressed: () => Navigator.pop(ctx, _DeleteChoice.thisMonth),
                  child: const Text('Xoá'),
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
    final scheme = theme.colorScheme;
    final gutter = Gutter.of(context);
    final nextMonth = shiftMonth(_thisMonth, 1);
    final helper = _type == GoalType.budget
        ? 'Ngân sách chi tiêu: hạn mức chi trong tháng, vd. tiền ăn. Mỗi khoản chi thuộc danh mục trừ dần; '
              'phần chưa chi vẫn được giữ.'
        : 'Quỹ giữ: tiền phải giữ lại trong tài khoản, vd. tiền trọ. Khi trả (giao dịch thuộc danh mục), '
              'quỹ giảm tương ứng.';

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Sửa mục tiêu' : 'Thêm mục tiêu'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Xoá mục tiêu',
              color: scheme.error,
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(gutter, Space.s2, gutter, Space.s6),
                children: [
                  const FieldLabel('Loại mục tiêu'),
                  AdaptiveSegmentedButton<String>(
                    choices: const [
                      SegmentChoice(GoalType.reserve, 'Quỹ giữ', icon: Icons.savings_outlined),
                      SegmentChoice(GoalType.budget, 'Ngân sách', icon: Icons.shopping_basket_outlined),
                    ],
                    selected: _type,
                    onChanged: _saving ? null : (v) => setState(() => _type = v),
                  ),
                  const SizedBox(height: Space.s2),
                  SupportingText(helper),
                  const SizedBox(height: Space.s6),
                  TextFormField(
                    key: const Key('goal_name'),
                    controller: _name,
                    focusNode: _nameFocus,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Tên mục tiêu', hintText: 'VD: Tiền trọ, Tiền ăn'),
                    validator: _validateName,
                  ),
                  if (!_editing) ...[
                    const SizedBox(height: Space.s2),
                    Wrap(
                      spacing: Space.s2,
                      children: [
                        for (final s in _suggestions)
                          _SuggestionButton(label: s.$1, onPressed: _saving ? null : () => _applySuggestion(s)),
                      ],
                    ),
                  ],
                  const SizedBox(height: Space.s4),
                  MoneyField(
                    key: const Key('goal_amount'),
                    controller: _amount,
                    focusNode: _amountFocus,
                    enabled: !_saving,
                    label: 'Số tiền',
                    validator: _validateAmount,
                  ),
                  const SizedBox(height: Space.s4),
                  _buildCategoryField(theme),
                  const SizedBox(height: Space.s6),
                  const FieldLabel('Tháng'),
                  if (_editing)
                    Text(monthLabel(_month), style: theme.textTheme.bodyLarge)
                  else
                    AdaptiveSegmentedButton<String>(
                      choices: [
                        SegmentChoice(_thisMonth, monthShortLabel(_thisMonth, _now)),
                        SegmentChoice(nextMonth, monthShortLabel(nextMonth, _now)),
                      ],
                      selected: _month,
                      onChanged: _saving ? null : (v) => setState(() => _month = v),
                    ),
                  if (_seriesForNextMonth case final series?) ...[
                    const SizedBox(height: Space.s2),
                    SupportingText(
                      'Tháng này đã có "${series.name}" lặp lại cùng loại và danh mục, nên mục tiêu '
                      '${shortMonthLabel(_month)} của chuỗi đó sẽ được cập nhật thay vì tạo thêm.',
                      key: const Key('goal_series_hint'),
                    ),
                  ],
                  const SizedBox(height: Space.s2),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lặp lại hằng tháng'),
                    subtitle: Text(
                      _editing ? 'Áp dụng cho tháng này và các tháng sau' : 'Tự tạo lại vào đầu mỗi tháng',
                    ),
                    value: _repeat,
                    onChanged: _saving ? null : (v) => setState(() => _repeat = v),
                  ),
                  const SizedBox(height: Space.s2),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const Key('goal_more_options'),
                      onPressed: () => setState(() => _moreOptions = !_moreOptions),
                      icon: Icon(_moreOptions ? Icons.expand_less : Icons.expand_more),
                      label: Text(_moreOptions ? 'Ẩn tuỳ chọn' : 'Thêm tuỳ chọn'),
                    ),
                  ),
                  if (_moreOptions) ...[
                    const SizedBox(height: Space.s2),
                    MoneyField(
                      key: const Key('goal_opening_spent'),
                      controller: _openingSpent,
                      focusNode: _openingFocus,
                      enabled: !_saving,
                      label: 'Đã chi trước khi dùng app',
                      hint: 'VD: 500.000',
                      helper:
                          'Số đã chi cho mục tiêu này trong tháng trước khi bắt đầu dùng app; chỉ tính cho tháng '
                          'đầu tiên.',
                      validator: _validateOpening,
                    ),
                  ],
                ],
              ),
            ),
            StickyActionBar(
              primary: FilledButton.icon(
                key: const Key('goal_save'),
                onPressed: _saving ? null : _save,
                icon: _saving ? const BusyIcon() : null,
                label: Text(_editing ? 'Lưu thay đổi' : 'Tạo mục tiêu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mục tiêu lặp lại tháng này cùng loại + danh mục với mục tiêu đang tạo cho tháng sau
  /// (server sẽ cập nhật tháng sau của chuỗi đó thay vì tạo chuỗi mới).
  GoalView? get _seriesForNextMonth {
    if (_editing || _month == _thisMonth || _categoryId == null) return null;
    for (final g in _thisMonthGoals) {
      if (g.repeatMonthly && g.type == _type && g.categoryId == _categoryId) return g;
    }
    return null;
  }

  Widget _buildCategoryField(ThemeData theme) {
    final categories = _categories;
    if (categories == null) {
      final failed = _categoriesError != null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int?>(
            // Chữ của ô chọn giống ô nhập (mặc định M3 là titleMedium, to hơn).
            style: Theme.of(context).textTheme.bodyLarge,
            items: const [],
            onChanged: null,
            decoration: InputDecoration(
              labelText: 'Danh mục',
              helperText: failed ? 'Không tải được danh mục.' : 'Đang tải danh mục…',
              helperStyle: failed ? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error) : null,
            ),
          ),
          if (failed)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(onPressed: _loadCategories, child: const Text('Thử lại')),
            ),
        ],
      );
    }
    final allowNone = _type == GoalType.reserve;
    // Danh mục hiện tại có thể không còn trong danh sách (đã đổi kind…) → vẫn giữ để không lỗi Dropdown.
    final known = categories.any((c) => c.id == _categoryId);
    final value = (_categoryId == null && allowNone) || known ? _categoryId : null;
    return DropdownButtonFormField<int?>(
      // Chữ của ô chọn giống ô nhập (mặc định M3 là titleMedium, to hơn).
      style: Theme.of(context).textTheme.bodyLarge,
      key: ValueKey('goal_category_$_type'),
      initialValue: value,
      focusNode: _categoryFocus,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Danh mục',
        helperText: allowNone
            ? 'Để "Tiết kiệm thuần" (không gắn danh mục) nếu chỉ muốn giữ tiền, không gắn khoản chi nào'
            : 'Khoản chi thuộc danh mục này sẽ trừ vào ngân sách',
      ),
      items: [
        if (allowNone)
          const DropdownMenuItem<int?>(value: null, child: Text('Tiết kiệm thuần', overflow: TextOverflow.ellipsis)),
        for (final c in categories) DropdownMenuItem<int?>(value: c.id, child: CategoryOptionLabel(c)),
      ],
      validator: _validateCategory,
      onChanged: _saving ? null : (v) => setState(() => _categoryId = v),
    );
  }
}

/// Gợi ý tên dạng chip (nút thật: đọc màn hình là "nút", không phải ô đánh dấu).
class _SuggestionButton extends StatelessWidget {
  const _SuggestionButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: Space.s3),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text(label),
    );
  }
}
