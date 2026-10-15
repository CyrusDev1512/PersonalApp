import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';
import '../widgets/form_parts.dart';
import '../widgets/money_text.dart';

/// Form "Thêm giao dịch" nhập tay (chi tiền mặt, chi trước khi dùng app…): surfaces/transactions/brief.md ›
/// Nhập tay. Mở ra là "Khoản chi", con trỏ ở ô số tiền; nút lưu dính ở đáy.
class ManualTxScreen extends StatefulWidget {
  const ManualTxScreen({super.key});

  static const routeName = '/transactions/new';

  @override
  State<ManualTxScreen> createState() => _ManualTxScreenState();
}

class _ManualTxScreenState extends State<ManualTxScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _amountFocus = FocusNode();
  String _direction = 'out';
  int? _categoryId;
  int? _accountId;
  bool _affectsBalance = false;
  late DateTime _time;
  List<Category>? _categories;
  String? _categoriesError;
  List<Account> _accounts = const [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _time = context.read<AppState>().now();
    _loadLists();
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  ApiClient? get _client => context.read<AppState>().client;

  Future<void> _loadLists() async {
    final client = _client;
    if (client == null) return;
    setState(() => _categoriesError = null);
    try {
      final categories = await client.listCategories();
      if (mounted) setState(() => _categories = categories);
    } on ApiException catch (e) {
      if (mounted) setState(() => _categoriesError = e.message);
    }
    try {
      final accounts = await client.listAccounts();
      if (mounted) setState(() => _accounts = accounts.where((a) => !a.isCash).toList());
    } on ApiException {
      // Không tải được tài khoản: vẫn lưu được như tiền mặt.
    }
  }

  List<Category> get _categoryChoices {
    final all = _categories ?? const <Category>[];
    return _direction == 'out'
        ? all.where((c) => c.isExpense).toList()
        : all.where((c) => c.isIncome || c.isExpense).toList();
  }

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _time,
      firstDate: DateTime(_time.year - 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_time));
    if (!mounted) return;
    setState(() {
      _time = DateTime(date.year, date.month, date.day, time?.hour ?? _time.hour, time?.minute ?? _time.minute);
    });
  }

  static String? _validateAmount(String? v) {
    final amount = parseVnd(v);
    if (amount == null) return 'Nhập số tiền';
    if (amount <= 0) return 'Số tiền phải lớn hơn 0';
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      _amountFocus.requestFocus();
      return;
    }
    final client = _client;
    if (client == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final state = context.read<AppState>();
    final amount = parseVnd(_amount.text)!;
    try {
      await client.createTransaction(
        direction: _direction,
        amount: amount,
        description: _description.text.trim(),
        categoryId: _categoryId,
        bankTime: _time,
        accountId: _accountId,
        affectsBalance: _accountId != null && _affectsBalance,
      );
      await state.load();
      if (!mounted) return;
      final kind = _direction == 'out' ? 'khoản chi' : 'khoản thu';
      showInfo(context, 'Đã thêm $kind ${MoneyParts.of(amount).text}');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.isNetwork ? 'Không kết nối được máy chủ. Giao dịch chưa được lưu.' : e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gutter = Gutter.of(context);
    final choices = _categoryChoices;
    final categoryValue = choices.any((c) => c.id == _categoryId) ? _categoryId : null;
    final categoriesFailed = _categories == null && _categoriesError != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm giao dịch')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(gutter, Space.s2, gutter, Space.s6),
                children: [
                  const InlineNote(
                    icon: Icons.info_outline,
                    text:
                        'Chỉ nhập các khoản không có biến động ngân hàng (chi tiền mặt, chi trước khi dùng app…). '
                        'Đã phân loại khoản rút ATM thì không nhập lại các khoản tiêu bằng tiền mặt đó.',
                  ),
                  const SizedBox(height: Space.s4),
                  AdaptiveSegmentedButton<String>(
                    choices: const [
                      SegmentChoice('out', 'Khoản chi', icon: Icons.north_east),
                      SegmentChoice('in', 'Khoản thu', icon: Icons.south_west),
                    ],
                    selected: _direction,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() {
                            _direction = v;
                            if (!_categoryChoices.any((c) => c.id == _categoryId)) _categoryId = null;
                          }),
                  ),
                  const SizedBox(height: Space.s4),
                  MoneyField(
                    controller: _amount,
                    focusNode: _amountFocus,
                    autofocus: true,
                    enabled: !_saving,
                    label: 'Số tiền',
                    hint: 'VD: 50.000',
                    validator: _validateAmount,
                  ),
                  const SizedBox(height: Space.s4),
                  TextFormField(
                    controller: _description,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 300,
                    decoration: const InputDecoration(labelText: 'Mô tả', hintText: 'VD: Bánh mì, đổ xăng'),
                  ),
                  const SizedBox(height: Space.s2),
                  DropdownButtonFormField<int?>(
                    key: ValueKey('manual_category_$_direction${_categories == null ? '_loading' : ''}'),
                    initialValue: categoryValue,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Danh mục',
                      helperText: _categories == null
                          ? (categoriesFailed ? 'Không tải được danh mục.' : 'Đang tải danh mục…')
                          : null,
                      helperStyle: categoriesFailed
                          ? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)
                          : null,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Chưa phân loại', overflow: TextOverflow.ellipsis),
                      ),
                      for (final c in choices)
                        DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.label, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: _saving || _categories == null ? null : (v) => setState(() => _categoryId = v),
                  ),
                  if (categoriesFailed)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(onPressed: _loadLists, child: const Text('Thử lại')),
                    ),
                  const SizedBox(height: Space.s2),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: const Text('Thời gian'),
                    subtitle: Text(formatDateTime(_time)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _saving ? null : _pickTime,
                  ),
                  const SizedBox(height: Space.s2),
                  DropdownButtonFormField<int?>(
                    initialValue: _accounts.any((a) => a.id == _accountId) ? _accountId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Tài khoản'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tiền mặt / ngoài ngân hàng', overflow: TextOverflow.ellipsis),
                      ),
                      for (final a in _accounts)
                        DropdownMenuItem<int?>(
                          value: a.id,
                          child: Text(a.displayName, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _accountId = v),
                  ),
                  if (_accountId != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cộng/trừ vào số dư tài khoản này'),
                      subtitle: const Text('Chỉ bật nếu ngân hàng sẽ không gửi biến động cho khoản này'),
                      value: _affectsBalance,
                      onChanged: _saving ? null : (v) => setState(() => _affectsBalance = v),
                    ),
                ],
              ),
            ),
            StickyActionBar(
              error: _error,
              primary: FilledButton.icon(
                key: const Key('manual_save'),
                onPressed: _saving ? null : _save,
                icon: _saving ? const BusyIcon() : null,
                label: const Text('Lưu giao dịch'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
