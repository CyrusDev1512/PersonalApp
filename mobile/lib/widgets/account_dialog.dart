import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../models/account.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../utils/currency.dart';
import '../utils/dates.dart';
import 'form_parts.dart';
import 'money_text.dart';

/// Lựa chọn ngân hàng trong form (giá trị gửi lên API).
const Map<String, String> bankChoices = {'VCB': 'Vietcombank (VCB)', 'MB': 'MB Bank', 'OTHER': 'Khác'};

Future<T?> _showFormSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  constraints: AppLayout.sheetConstraints(context),
  builder: builder,
);

/// Mở bảng thêm (account == null) hoặc sửa tài khoản (surfaces/account-sheet/brief.md). Trả về TK sau khi lưu,
/// hoặc `null` nếu đóng; [AccountFormResult.deleted] khi đã xoá. Lưu xong thì hiện SnackBar ở màn bên dưới.
Future<AccountFormResult?> showAccountForm(BuildContext context, {required ApiClient client, Account? account}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final result = await _showFormSheet<AccountFormResult>(
    context,
    (_) => AccountFormSheet(client: client, account: account),
  );
  if (result != null && messenger != null) {
    final saved = result.account;
    final message = result.deleted
        ? 'Đã xoá tài khoản'
        : account == null && saved != null
        ? 'Đã thêm tài khoản "${saved.name.isEmpty ? saved.bankLabel : saved.name}"'
        : 'Đã lưu tài khoản';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
  return result;
}

class AccountFormResult {
  const AccountFormResult({this.account, this.deleted = false});

  final Account? account;
  final bool deleted;
}

/// Bảng thêm / sửa tài khoản: ngân hàng, số TK, tên gợi nhớ, số dư hiện tại, "Tính vào tổng số dư" (và "Đây là
/// tài khoản của tôi" cho TK tự phát hiện); "Xoá tài khoản" ở cuối khi sửa; nút chính dính ở đáy.
class AccountFormSheet extends StatefulWidget {
  const AccountFormSheet({super.key, required this.client, this.account});

  final ApiClient client;
  final Account? account;

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _name;
  late final TextEditingController _balance;
  final _numberFocus = FocusNode();
  final _nameFocus = FocusNode();
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
    _numberFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  static String? _validateNumber(String? v) {
    final s = v?.trim() ?? '';
    if (s.isNotEmpty && s.length < 4) return 'Số tài khoản cần ít nhất 4 chữ số';
    return null;
  }

  static String? _validateName(String? v) => (v == null || v.trim().isEmpty) ? 'Nhập tên tài khoản' : null;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (_validateNumber(_number.text) != null && !(widget.account?.isCash ?? false)) {
        _numberFocus.requestFocus();
      } else if (_validateName(_name.text) != null) {
        _nameFocus.requestFocus();
      }
      return;
    }
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
          _error = e.isNetwork ? 'Không kết nối được máy chủ. Tài khoản chưa được lưu.' : e.message;
        });
      }
    }
  }

  Future<void> _delete() async {
    final a = widget.account;
    if (a == null) return;
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá tài khoản?'),
        content: Text('Xoá "${a.displayName}". Chỉ xoá được tài khoản chưa có giao dịch.'),
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
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(Space.s5, 0, Space.s5, Space.s4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        _editing ? 'Sửa tài khoản' : 'Thêm tài khoản',
                        style: theme.textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
                      ),
                    ),
                    const SizedBox(height: Space.s5),
                    if (_editing)
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Ngân hàng', enabled: false),
                        child: Text(bankLabelOf(a!.bank), style: theme.textTheme.bodyLarge),
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
                    if (!(a?.isCash ?? false)) ...[
                      const SizedBox(height: Space.s4),
                      TextFormField(
                        controller: _number,
                        focusNode: _numberFocus,
                        enabled: !_saving,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Số tài khoản',
                          hintText: _bank == 'OTHER' ? 'Tuỳ chọn' : null,
                          helperText: 'Dùng để nhận diện biến động từ webhook/email',
                        ),
                        validator: _validateNumber,
                      ),
                    ],
                    const SizedBox(height: Space.s4),
                    TextFormField(
                      controller: _name,
                      focusNode: _nameFocus,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Tên gợi nhớ', hintText: 'VD: VCB chính'),
                      validator: _validateName,
                    ),
                    const SizedBox(height: Space.s4),
                    MoneyField(
                      controller: _balance,
                      enabled: !_saving,
                      label: 'Số dư hiện tại',
                      hint: 'VD: 6.200.000',
                      helper: _editing
                          ? 'Để trống nếu không đổi. Hiện tại: ${a!.balance == null ? 'chưa có' : MoneyParts.of(a.balance!).text}'
                          : 'Có thể để trống và nhập sau',
                    ),
                    const SizedBox(height: Space.s2),
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
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Đây là tài khoản của tôi'),
                        subtitle: const Text('TK này được tự phát hiện từ biến động'),
                        value: _confirmed,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() {
                                _confirmed = v;
                                // TK chưa xác nhận thì không tính vào tổng.
                                if (!_confirmed) _includeInTotal = false;
                              }),
                      ),
                    if (_editing && !(a?.isCash ?? false)) ...[
                      const SizedBox(height: Space.s6),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          style: AppButtonStyles.destructiveText(scheme),
                          onPressed: _saving ? null : _delete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Xoá tài khoản'),
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
                key: const Key('account_save'),
                onPressed: _saving ? null : _save,
                icon: _saving ? const BusyIcon() : null,
                label: Text(_editing ? 'Lưu tài khoản' : 'Thêm tài khoản'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mở bảng "Nhập số dư" cho một tài khoản (đặt số dư hiện tại làm mốc). Lưu xong thì hiện SnackBar
/// "Đã cập nhật số dư …" ở màn bên dưới.
Future<Account?> showBalanceDialog(BuildContext context, {required ApiClient client, required Account account}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final saved = await _showFormSheet<Account>(context, (_) => BalanceSheet(client: client, account: account));
  if (saved != null && saved.balance != null) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Đã cập nhật số dư ${account.displayName}: ${MoneyParts.of(saved.balance!).text}')),
      );
  }
  return saved;
}

/// Bảng "Nhập số dư": tài khoản (là thông tin, không phải ô nhập), một câu hướng dẫn, ô số dư (chọn sẵn số cũ
/// để gõ là thay), nút "Lưu số dư" dính ở đáy.
class BalanceSheet extends StatefulWidget {
  const BalanceSheet({super.key, required this.client, required this.account});

  final ApiClient client;
  final Account account;

  @override
  State<BalanceSheet> createState() => _BalanceSheetState();
}

class _BalanceSheetState extends State<BalanceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _balance;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final b = widget.account.balance;
    final text = b == null ? '' : formatGrouped(b);
    // Số cũ được chọn sẵn: gõ số mới là thay, không nối vào sau số cũ.
    _balance = TextEditingController.fromValue(
      TextEditingValue(
        text: text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
      ),
    );
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
          _error = e.isNetwork ? 'Không kết nối được máy chủ. Số dư chưa được lưu.' : e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final a = widget.account;
    final asOf = a.balanceAsOf;
    final small = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(Space.s5, 0, Space.s5, Space.s4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Nhập số dư',
                        style: theme.textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
                      ),
                    ),
                    const SizedBox(height: Space.s4),
                    Text(a.displayName, style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurface)),
                    if (a.balance == null)
                      Text('Chưa có số dư', style: small)
                    else
                      MoneySentence([
                        'Số dư hiện tại: ',
                        a.balance!,
                        if (asOf != null) ' · cập nhật ${formatTimeOrDateIct(asOf, DateTime.now())}',
                      ], style: small),
                    const SizedBox(height: Space.s3),
                    Text(
                      'Mở app ngân hàng và nhập đúng số dư hiện tại. Các biến động sau đó sẽ được cộng/trừ từ mốc này.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: Space.s4),
                    MoneyField(
                      controller: _balance,
                      autofocus: true,
                      enabled: !_saving,
                      label: 'Số dư hiện tại',
                      hint: 'VD: 6.200.000',
                      textInputAction: TextInputAction.done,
                      validator: (v) => parseVnd(v) == null ? 'Nhập số dư (có thể là 0)' : null,
                      onFieldSubmitted: (_) => _save(),
                    ),
                  ],
                ),
              ),
            ),
            StickyActionBar(
              horizontalPadding: Space.s5,
              error: _error,
              primary: FilledButton.icon(
                key: const Key('balance_save'),
                onPressed: _saving ? null : _save,
                icon: _saving ? const BusyIcon() : null,
                label: const Text('Lưu số dư'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tên cũ (trước khi chuyển sang bảng trượt), giữ cho mã gọi cũ.
typedef AccountFormDialog = AccountFormSheet;
typedef BalanceDialog = BalanceSheet;
