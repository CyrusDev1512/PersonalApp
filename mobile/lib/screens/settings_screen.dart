import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/currency.dart';
import '../widgets/account_dialog.dart';
import '../widgets/common.dart';
import 'connect_screen.dart';

/// Màn "Cài đặt": máy chủ, tài khoản, ngưỡng cảnh báo, lương dự kiến.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _warningPercent = TextEditingController();
  final _warningMin = TextEditingController();
  final _incomeAmount = TextEditingController();
  final _incomeDay = TextEditingController();
  bool _notifyEveryTx = true;

  List<Account>? _accounts;
  AppSettings? _settings;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _warningPercent.dispose();
    _warningMin.dispose();
    _incomeAmount.dispose();
    _incomeDay.dispose();
    super.dispose();
  }

  ApiClient? get _client => context.read<AppState>().client;

  Future<void> _load() async {
    final client = _client;
    if (client == null) return;
    setState(() => _error = null);
    try {
      final results = await Future.wait([client.listAccounts(), client.getSettings()]);
      if (!mounted) return;
      final settings = results[1] as AppSettings;
      setState(() {
        _accounts = results[0] as List<Account>;
        _applySettings(settings);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _reloadAccounts() async {
    final client = _client;
    if (client == null) return;
    try {
      final list = await client.listAccounts();
      if (mounted) setState(() => _accounts = list);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void _applySettings(AppSettings s) {
    _settings = s;
    _warningPercent.text = '${s.warningPercent}';
    _warningMin.text = formatGrouped(s.warningMinAmount);
    _incomeAmount.text = s.expectedIncomeAmount > 0 ? formatGrouped(s.expectedIncomeAmount) : '';
    _incomeDay.text = s.expectedIncomeDay > 0 ? '${s.expectedIncomeDay}' : '';
    _notifyEveryTx = s.notifyEveryTx;
  }

  Future<void> _saveSettings() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final client = _client;
    final current = _settings;
    if (client == null || current == null) return;
    final incomeAmount = parseVnd(_incomeAmount.text) ?? 0;
    final next = current.copyWith(
      warningPercent: int.parse(_warningPercent.text.trim()),
      warningMinAmount: parseVnd(_warningMin.text) ?? 0,
      expectedIncomeAmount: incomeAmount,
      expectedIncomeDay: incomeAmount > 0 ? int.tryParse(_incomeDay.text.trim()) ?? 0 : 0,
      notifyEveryTx: _notifyEveryTx,
    );
    setState(() => _saving = true);
    final state = context.read<AppState>();
    try {
      final saved = await client.updateSettings(next);
      if (!mounted) return;
      setState(() {
        _applySettings(saved);
        _saving = false;
      });
      showInfo(context, 'Đã lưu cài đặt');
      await state.load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showError(context, e);
    }
  }

  Future<void> _editConnection() async {
    final client = _client;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConnectScreen(
          initialUrl: client?.baseUrl,
          initialToken: client?.token,
          popOnSuccess: true,
        ),
      ),
    );
    if (changed == true && mounted) {
      showInfo(context, 'Đã kết nối lại máy chủ');
      _load();
    }
  }

  Future<void> _disconnect() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ngắt kết nối?'),
        content: const Text('App sẽ quên địa chỉ máy chủ và token trên máy này. Dữ liệu trên máy chủ không bị xoá.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ngắt kết nối')),
        ],
      ),
    );
    if (ok == true && mounted) await context.read<AppState>().disconnect();
  }

  Future<void> _openAccount([Account? account]) async {
    final client = _client;
    if (client == null) return;
    final state = context.read<AppState>();
    final result = await showAccountForm(context, client: client, account: account);
    if (result == null || !mounted) return;
    showInfo(context, result.deleted ? 'Đã xoá tài khoản' : 'Đã lưu tài khoản');
    await _reloadAccounts();
    await state.load();
  }

  String _maskToken(String token) {
    if (token.length <= 4) return '••••';
    return '••••••••${token.substring(token.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final client = context.select<AppState, ApiClient?>((s) => s.client);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const SectionHeader('Máy chủ'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dns_outlined),
                    title: const Text('Địa chỉ máy chủ'),
                    subtitle: Text(client?.baseUrl ?? '—'),
                  ),
                  if (client != null && ApiClient.isInsecureUrl(client.baseUrl))
                    ListTile(
                      leading: Icon(Icons.lock_open, color: Colors.amber.shade800),
                      title: const Text('Kết nối không mã hoá (http://)'),
                      subtitle: const Text('Token được gửi dạng rõ. Chỉ nên dùng trong mạng LAN tin cậy.'),
                    ),
                  ListTile(
                    leading: const Icon(Icons.key_outlined),
                    title: const Text('Token'),
                    subtitle: Text(client == null ? '—' : _maskToken(client.token)),
                  ),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 8,
                    children: [
                      TextButton(onPressed: _disconnect, child: const Text('Ngắt kết nối')),
                      FilledButton.tonal(onPressed: _editConnection, child: const Text('Đổi máy chủ / token')),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              ErrorView(message: _error!, onRetry: _load),
            ],
            SectionHeader(
              'Tài khoản',
              trailing: TextButton.icon(
                onPressed: client == null ? null : () => _openAccount(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm tài khoản'),
              ),
            ),
            _buildAccounts(theme),
            const SectionHeader('Cảnh báo'),
            _buildSettingsForm(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAccounts(ThemeData theme) {
    final accounts = _accounts;
    if (accounts == null) {
      return _error == null ? const LinearProgressIndicator() : const SizedBox.shrink();
    }
    if (accounts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Chưa có tài khoản. Thêm TK ngân hàng và nhập số dư hiện tại để app tính được mức an toàn.'),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final a in accounts)
            ListTile(
              onTap: () => _openAccount(a),
              leading: CircleAvatar(child: Text(a.isCash ? '💵' : a.bank.substring(0, a.bank.length.clamp(0, 3)))),
              title: Text(a.displayName),
              subtitle: Text(
                [
                  a.bankLabel,
                  a.balanceKnown ? '${formatVnd(a.balance!)}${a.balanceDerived ? ' (ước tính)' : ''}' : 'chưa biết số dư',
                  if (!a.includeInTotal) 'không tính vào tổng',
                ].join(' · '),
              ),
              trailing: a.confirmed
                  ? const Icon(Icons.chevron_right)
                  : StatusBadge('Chưa xác nhận', color: Colors.amber.shade800, icon: Icons.new_releases_outlined),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsForm(ThemeData theme) {
    if (_settings == null) {
      return _error == null ? const LinearProgressIndicator() : const SizedBox.shrink();
    }
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cảnh báo khi phần "Được tiêu thoải mái" nhỏ hơn vùng đệm = max(% × mức sàn, số tiền tối thiểu).',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('settings_warning_percent'),
                controller: _warningPercent,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Vùng đệm theo % mức sàn',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'Nhập số phần trăm';
                  if (n < 0 || n > 100) return 'Chỉ từ 0 đến 100';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('settings_warning_min'),
                controller: _warningMin,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: const [VndInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Vùng đệm tối thiểu',
                  suffixText: 'đ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => parseVnd(v) == null ? 'Nhập số tiền (có thể là 0)' : null,
              ),
              const SizedBox(height: 20),
              Text('Lương dự kiến', style: theme.textTheme.titleSmall),
              Text(
                'Tuỳ chọn. Trước ngày lương, nếu chỉ thiếu tạm thời và lương sẽ bù đủ thì app báo '
                '"chờ lương" thay vì báo nguy hiểm mỗi ngày.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      key: const Key('settings_income_amount'),
                      controller: _incomeAmount,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [VndInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Số tiền lương',
                        hintText: 'Để trống = không dùng',
                        suffixText: 'đ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: const Key('settings_income_day'),
                      controller: _incomeDay,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: const InputDecoration(labelText: 'Ngày nhận', border: OutlineInputBorder()),
                      validator: (v) {
                        final amount = parseVnd(_incomeAmount.text) ?? 0;
                        if (amount <= 0) return null;
                        final day = int.tryParse(v?.trim() ?? '');
                        if (day == null || day < 1 || day > 31) return 'Ngày 1–31';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Báo Telegram mỗi giao dịch'),
                subtitle: const Text('Tắt thì chỉ báo khi chạm ngưỡng mức sàn hoặc ngân sách'),
                value: _notifyEveryTx,
                onChanged: _saving ? null : (v) => setState(() => _notifyEveryTx = v),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('settings_save'),
                onPressed: _saving ? null : _saveSettings,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Đang lưu…' : 'Lưu cài đặt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
