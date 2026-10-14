import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../models/account.dart';
import '../utils/currency.dart';

/// Lựa chọn ngân hàng trong form (giá trị gửi lên API).
const Map<String, String> bankChoices = {'VCB': 'Vietcombank (VCB)', 'MB': 'MB Bank', 'OTHER': 'Khác'};

/// Mở form thêm (account == null) hoặc sửa tài khoản. Trả về TK sau khi lưu,
/// hoặc `null` nếu huỷ / đã xoá ([AccountFormResult.deleted]).
Future<AccountFormResult?> showAccountForm(BuildContext context, {required ApiClient client, Account? account}) {
  return showDialog<AccountFormResult>(
    context: context,
    builder: (_) => AccountFormDialog(client: client, account: account),
  );
}

class AccountFormResult {
  const AccountFormResult({this.account, this.deleted = false});

  final Account? account;
  final bool deleted;
}

class AccountFormDialog extends StatefulWidget {
  const AccountFormDialog({super.key, required this.client, this.account});

  final ApiClient client;
  final Account? account;

  @override
  State<AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<AccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late String _bank;
  late bool _includeInTotal;
  late bool _confirmed;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _number = TextEditingController(text: a?.accountNumber ?? '');
    _name = TextEditingController(text: a?.name ?? '');
    _balance = TextEditingController();
    final bank = a?.bank.toUpperCase() ?? 'VCB';
    _bank = bankChoices.containsKey(bank) ? bank : 'OTHER';
    _confirmed = a?.confirmed ?? true;
    // TK chưa xác nhận không được tính vào tổng dù cờ đang bật → hiện đúng trạng thái thực tế.
    _includeInTotal = (a?.includeInTotal ?? true) && _confirmed;
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final balance = parseVnd(_balance.text);
    final number = _number.text.replaceAll(RegExp(r'\s'), '');
    try {
      final Account saved;
      final a = widget.account;
      if (a == null) {
        saved = await widget.client.createAccount(
          bank: _bank,
          name: _name.text.trim(),
          accountNumber: number.isEmpty ? null : number,
          includeInTotal: _includeInTotal,
          balance: balance,
        );
      } else {
        saved = await widget.client.updateAccount(a.id, {
          'name': _name.text.trim(),
          if (!a.isCash) 'account_number': number.isEmpty ? null : number,
          'include_in_total': _includeInTotal,
          if (!a.confirmed && _confirmed) 'confirmed': true,
          'balance': ?balance,
        });
      }
      if (mounted) Navigator.of(context).pop(AccountFormResult(account: saved));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _delete() async {
    final a = widget.account;
    if (a == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá tài khoản?'),
        content: Text('Xoá "${a.displayName}". Chỉ xoá được tài khoản chưa có giao dịch.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.client.deleteAccount(a.id);
      if (mounted) Navigator.of(context).pop(const AccountFormResult(deleted: true));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.account;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_editing ? 'Sửa tài khoản' : 'Thêm tài khoản'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_editing)
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Ngân hàng'),
                  child: Text(bankLabelOf(a!.bank)),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _bank,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Ngân hàng'),
                  items: [
                    for (final e in bankChoices.entries)
                      DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _bank = v ?? 'VCB'),
                ),
              if (!(a?.isCash ?? false))
                TextFormField(
                  controller: _number,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Số tài khoản',
                    helperText: 'Dùng để nhận diện biến động từ webhook/email',
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isNotEmpty && s.length < 4) return 'Số tài khoản cần ít nhất 4 chữ số';
                    return null;
                  },
                ),
              TextFormField(
                controller: _name,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Tên gợi nhớ', hintText: 'VD: VCB chính'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên tài khoản' : null,
              ),
              TextFormField(
                controller: _balance,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: const [VndInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Số dư hiện tại',
                  suffixText: 'đ',
                  helperText: _editing
                      ? 'Để trống nếu không đổi. Hiện tại: ${formatVndOrDash(a!.balance)}'
                      : 'Có thể để trống và nhập sau',
                  helperMaxLines: 2,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tính vào tổng số dư'),
                subtitle: const Text('Tắt cho TK tiết kiệm riêng'),
                value: _includeInTotal,
                onChanged: _saving
                    ? null
                    : (v) => setState(() {
                        _includeInTotal = v;
                        // Tính vào tổng nghĩa là TK của mình: server cũng xác nhận luôn TK.
                        if (v) _confirmed = true;
                      }),
              ),
              if (a != null && !a.confirmed)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Xác nhận TK mới'),
                  subtitle: const Text('TK này được tự phát hiện từ biến động — xác nhận là của bạn'),
                  value: _confirmed,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() {
                          _confirmed = v ?? false;
                          // TK chưa xác nhận thì không tính vào tổng.
                          if (!_confirmed) _includeInTotal = false;
                        }),
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_editing && !(a?.isCash ?? false))
          TextButton(
            onPressed: _saving ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Xoá'),
          ),
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Huỷ')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Đang lưu…' : 'Lưu')),
      ],
    );
  }
}

/// Hộp thoại "Nhập số dư" cho một tài khoản (đặt số dư hiện tại làm mốc).
Future<Account?> showBalanceDialog(BuildContext context, {required ApiClient client, required Account account}) {
  return showDialog<Account>(
    context: context,
    builder: (_) => BalanceDialog(client: client, account: account),
  );
}

class BalanceDialog extends StatefulWidget {
  const BalanceDialog({super.key, required this.client, required this.account});

  final ApiClient client;
  final Account account;

  @override
  State<BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends State<BalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _balance;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final b = widget.account.balance;
    _balance = TextEditingController(text: b == null ? '' : formatGrouped(b));
  }

  @override
  void dispose() {
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.client.setAccountBalance(widget.account.id, parseVnd(_balance.text)!);
      if (mounted) Navigator.of(context).pop(saved);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhập số dư'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.account.displayName, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            const Text(
              'Mở app ngân hàng và nhập đúng số dư hiện tại. Các biến động sau đó sẽ được cộng/trừ từ mốc này.',
            ),
            TextFormField(
              controller: _balance,
              autofocus: true,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: const [VndInputFormatter()],
              decoration: const InputDecoration(labelText: 'Số dư hiện tại', suffixText: 'đ'),
              validator: (v) => parseVnd(v) == null ? 'Nhập số dư (có thể là 0)' : null,
              onFieldSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Huỷ')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Đang lưu…' : 'Lưu số dư')),
      ],
    );
  }
}
