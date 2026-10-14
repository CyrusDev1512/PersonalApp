import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';

/// Form "Thêm giao dịch" nhập tay (chi tiền mặt, chi trước khi dùng app…).
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
  String _direction = 'out';
  int? _categoryId;
  int? _accountId;
  bool _affectsBalance = false;
  late DateTime _time;
  List<Category> _categories = const [];
  List<Account> _accounts = const [];
  bool _saving = false;

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
    super.dispose();
  }

  ApiClient? get _client => context.read<AppState>().client;

  Future<void> _loadLists() async {
    final client = _client;
    if (client == null) return;
    try {
      final results = await Future.wait([client.listCategories(), client.listAccounts()]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<Category>;
        _accounts = (results[1] as List<Account>).where((a) => !a.isCash).toList();
      });
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    }
  }

  List<Category> get _categoryChoices => _direction == 'out'
      ? _categories.where((c) => c.isExpense).toList()
      : _categories.where((c) => c.isIncome || c.isExpense).toList();

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

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final client = _client;
    if (client == null) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    try {
      await client.createTransaction(
        direction: _direction,
        amount: parseVnd(_amount.text)!,
        description: _description.text.trim(),
        categoryId: _categoryId,
        bankTime: _time,
        accountId: _accountId,
        affectsBalance: _accountId != null && _affectsBalance,
      );
      await state.load();
      if (!mounted) return;
      showInfo(context, 'Đã thêm giao dịch');
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
    final choices = _categoryChoices;
    final categoryValue = choices.any((c) => c.id == _categoryId) ? _categoryId : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm giao dịch')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Chỉ nhập các khoản không có biến động ngân hàng (chi tiền mặt, chi trước khi dùng app…). '
                  'Đã phân loại khoản rút ATM thì không nhập lại các khoản tiêu bằng tiền mặt đó.',
                  style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'out', label: Text('Khoản chi'), icon: Icon(Icons.north_east)),
                  ButtonSegment(value: 'in', label: Text('Khoản thu'), icon: Icon(Icons.south_west)),
                ],
                selected: {_direction},
                onSelectionChanged: _saving
                    ? null
                    : (s) => setState(() {
                          _direction = s.first;
                          if (!_categoryChoices.any((c) => c.id == _categoryId)) _categoryId = null;
                        }),
              ),
              const SizedBox(height: 16),
              TextFormField(
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
              TextFormField(
                controller: _description,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'VD: Bánh mì, đổ xăng',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                key: ValueKey('manual_category_$_direction'),
                initialValue: categoryValue,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Chưa phân loại')),
                  for (final c in choices) DropdownMenuItem<int?>(value: c.id, child: Text(c.label)),
                ],
                onChanged: _saving ? null : (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('Thời gian'),
                subtitle: Text(formatDateTime(_time)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _saving ? null : _pickTime,
              ),
              DropdownButtonFormField<int?>(
                initialValue: _accounts.any((a) => a.id == _accountId) ? _accountId : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tài khoản', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Tiền mặt / ngoài ngân hàng')),
                  for (final a in _accounts) DropdownMenuItem<int?>(value: a.id, child: Text(a.displayName)),
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
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Lưu giao dịch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
