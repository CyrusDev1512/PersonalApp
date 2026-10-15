import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../state/push_controller.dart';
import '../theme/app_theme.dart';
import '../theme/status_colors.dart';
import '../theme/tokens.dart';
import '../utils/currency.dart';
import '../widgets/adaptive.dart';
import '../widgets/account_dialog.dart';
import '../widgets/account_row.dart';
import '../widgets/common.dart';
import '../widgets/form_parts.dart';
import '../widgets/list_group.dart';
import '../widgets/money_text.dart';
import 'connect_screen.dart';

/// Màn "Cài đặt" (surfaces/settings/brief.md): Tài khoản → Cảnh báo → Lương dự kiến → Thông báo đẩy → Máy chủ.
///
/// Công tắc áp dụng ngay (PUT một trường, báo bằng SnackBar, lỗi thì trả về như cũ); các ô số (vùng đệm, lương)
/// lưu cùng nhau bằng "Lưu cài đặt", chỉ bật khi có thay đổi.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.active = true});

  /// Tab đang hiện; chuyển từ ẩn sang hiện thì tải lại danh sách tài khoản (giữ chữ đang gõ trong form).
  final bool active;

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
  bool _savingTelegram = false;

  List<Account>? _accounts;
  AppSettings? _settings;
  String? _error;
  bool _saving = false;

  /// Chữ trong các ô số ở lần áp dụng cài đặt gần nhất (để biết có thay đổi chưa lưu).
  List<String> _applied = const [];

  List<TextEditingController> get _fields => [_warningPercent, _warningMin, _incomeAmount, _incomeDay];

  bool get _dirty {
    final now = [for (final c in _fields) c.text.trim()];
    for (var i = 0; i < now.length; i++) {
      if (i >= _applied.length || now[i] != _applied[i]) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    for (final c in _fields) {
      c.addListener(_onFieldChanged);
    }
    _load();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      if (_settings == null || _accounts == null) {
        _load();
      } else {
        _reloadAccounts(quiet: true);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  ApiClient? get _client => context.read<AppState>().client;

  Future<void> _load() async {
    final client = _client;
    if (client == null) return;
    unawaited(Provider.of<PushController?>(context, listen: false)?.refreshServerStatus());
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

  /// [quiet]: tự làm mới khi quay lại tab — lỗi thì giữ danh sách cũ, không báo.
  Future<void> _reloadAccounts({bool quiet = false}) async {
    final client = _client;
    if (client == null) return;
    try {
      final list = await client.listAccounts();
      if (mounted) setState(() => _accounts = list);
    } on ApiException catch (e) {
      if (mounted && !quiet) showError(context, e);
    }
  }

  void _applySettings(AppSettings s) {
    _settings = s;
    _warningPercent.text = '${s.warningPercent}';
    _warningMin.text = formatGrouped(s.warningMinAmount);
    _incomeAmount.text = s.expectedIncomeAmount > 0 ? formatGrouped(s.expectedIncomeAmount) : '';
    _incomeDay.text = s.expectedIncomeDay > 0 ? '${s.expectedIncomeDay}' : '';
    _notifyEveryTx = s.notifyEveryTx;
    _applied = [for (final c in _fields) c.text.trim()];
  }

  Future<void> _saveSettings() async {
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || !_fieldsValid) return;
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

  /// "Báo Telegram mỗi giao dịch": lưu ngay một trường; lỗi thì công tắc quay về như cũ.
  Future<void> _toggleTelegram(bool value) async {
    final client = _client;
    final current = _settings;
    if (client == null || current == null) return;
    setState(() {
      _notifyEveryTx = value;
      _savingTelegram = true;
    });
    try {
      final saved = await client.updateSettingsFields({'notify_every_tx': value});
      if (!mounted) return;
      setState(() {
        _settings = (_settings ?? current).copyWith(notifyEveryTx: saved.notifyEveryTx);
        _notifyEveryTx = saved.notifyEveryTx;
        _savingTelegram = false;
      });
      showInfo(
        context,
        saved.notifyEveryTx ? 'Đã bật báo Telegram mỗi giao dịch' : 'Đã tắt báo Telegram mỗi giao dịch',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _notifyEveryTx = !value;
        _savingTelegram = false;
      });
      showError(context, e);
    }
  }

  Future<void> _editConnection() async {
    final client = _client;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ConnectScreen(initialUrl: client?.baseUrl, initialToken: client?.token, popOnSuccess: true),
      ),
    );
    if (changed == true && mounted) {
      showInfo(context, 'Đã kết nối máy chủ');
      _load();
    }
  }

  Future<void> _disconnect() async {
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // Chữ lớn (200%): nội dung cuộn được, không bị cắt mất câu cuối.
        scrollable: true,
        title: const Text('Ngắt kết nối?'),
        content: const Text('App sẽ quên địa chỉ máy chủ và token trên máy này. Dữ liệu trên máy chủ không bị xoá.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: AppButtonStyles.destructiveFilled(scheme),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ngắt kết nối'),
          ),
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
    final gutter = Gutter.of(context);
    return Scaffold(
      appBar: const ContentAppBar(title: Text('Cài đặt')),
      body: ContentColumn(
        child: RefreshIndicator(
          onRefresh: _load,
          // Một Form cho các ô số của "Cảnh báo" và "Lương dự kiến" (một nút "Lưu cài đặt").
          child: Form(
            key: _formKey,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(gutter, Space.s2, gutter, Space.s8),
              children: [
                const SectionHeader('Tài khoản', first: true),
                _buildAccounts(client),
                const SectionHeader('Cảnh báo'),
                ..._buildAlertSettings(theme),
                const SectionHeader('Lương dự kiến'),
                ..._buildIncome(theme),
                const SectionHeader('Thông báo đẩy'),
                const _PushSection(),
                const SectionHeader('Máy chủ'),
                ..._buildServer(theme, client),
                const SectionHeader('Giới thiệu'),
                ListGroup(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Giấy phép mã nguồn mở'),
                      subtitle: const Text('Phông chữ Be Vietnam Pro (SIL OFL 1.1) và các thư viện'),
                      onTap: () => showLicensePage(context: context, applicationName: 'Chi tiêu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Lỗi tải: nằm ngay trong nhóm bị ảnh hưởng, các nhóm khác vẫn dùng được.
  Widget _loadError() => ListGroup(
    children: [
      ListTile(
        leading: const Icon(Icons.cloud_off),
        title: const Text('Không tải được cài đặt.'),
        subtitle: _error == null ? null : Text(_error!),
        trailing: TextButton(onPressed: _load, child: const Text('Thử lại')),
      ),
    ],
  );

  Widget _buildAccounts(ApiClient? client) {
    final accounts = _accounts;
    if (accounts == null) {
      return _error == null ? const ListGroup(children: [ListSkeleton(rows: 2)]) : _loadError();
    }
    final addRow = ListTile(
      key: const Key('settings_add_account'),
      leading: const SizedBox(
        width: AppLayout.listLeadingSize,
        child: Center(child: Icon(Icons.add)),
      ),
      title: const Text('Thêm tài khoản'),
      onTap: client == null ? null : () => _openAccount(),
    );
    final now = context.read<AppState>().now();
    return ListGroup(
      children: [
        if (accounts.isEmpty)
          const ListTile(
            leading: SizedBox(
              width: AppLayout.listLeadingSize,
              child: Center(child: Icon(Icons.account_balance_outlined)),
            ),
            title: Text('Chưa có tài khoản'),
            subtitle: Text('Thêm TK ngân hàng và nhập số dư hiện tại để app tính được mức an toàn.'),
          ),
        for (final a in accounts) AccountRow(account: a, now: now, onTap: () => _openAccount(a)),
        addRow,
      ],
    );
  }

  /// Vùng đệm hiện tại theo các ô đang nhập (cập nhật khi gõ).
  (int, int, int) _bufferPreview(int floor) {
    final s = _settings!;
    final pct = int.tryParse(_warningPercent.text.trim()) ?? s.warningPercent;
    final min = parseVnd(_warningMin.text) ?? s.warningMinAmount;
    final buffer = math.max(floor * pct ~/ 100, min);
    return (buffer, pct, min);
  }

  List<Widget> _buildAlertSettings(ThemeData theme) {
    final settings = _settings;
    if (settings == null) {
      return [
        _error == null ? const ListGroup(children: [ListSkeleton(rows: 2)]) : _loadError(),
      ];
    }
    final floor = context.select<AppState, int>((s) => s.summary?.floor ?? 0);
    final (buffer, pct, min) = _bufferPreview(floor);
    final percentField = TextFormField(
      key: const Key('settings_warning_percent'),
      controller: _warningPercent,
      enabled: !_saving,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
      style: _numberStyle(context),
      decoration: _numberDecoration(context, label: 'Phần trăm mức sàn', suffix: '%'),
      validator: _validatePercent,
    );
    final minField = MoneyField(
      key: const Key('settings_warning_min'),
      controller: _warningMin,
      enabled: !_saving,
      label: 'Vùng đệm tối thiểu',
      hint: 'VD: 500.000',
      validator: _validateMin,
    );
    return [
      MoneySentence(
        ['Đang báo khi được tiêu dưới ', buffer, ' (số lớn hơn giữa $pct% mức sàn và ', min, ').'],
        key: const Key('settings_buffer_sentence'),
        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface),
      ),
      const SizedBox(height: Space.s4),
      _pair(percentField, minField, flex: (1, 1)),
      const SizedBox(height: Space.s4),
      ListGroup(
        children: [
          SwitchListTile(
            key: const Key('settings_notify_every_tx'),
            title: const Text('Báo Telegram mỗi giao dịch'),
            subtitle: const Text('Tắt thì chỉ báo khi chạm ngưỡng mức sàn hoặc ngân sách'),
            value: _notifyEveryTx,
            onChanged: _savingTelegram ? null : _toggleTelegram,
          ),
        ],
      ),
    ];
  }

  String? _validatePercent(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null) return 'Nhập số phần trăm';
    if (n < 0 || n > 100) return 'Chỉ từ 0 đến 100';
    return null;
  }

  String? _validateMin(String? v) {
    final amount = parseVnd(v);
    if (amount == null) return 'Nhập số tiền (có thể là 0)';
    return vndTooLarge(amount, max: _maxBufferAmount);
  }

  /// Vùng đệm tối thiểu lớn nhất máy chủ nhận (backend: `le=1_000_000_000`).
  static const int _maxBufferAmount = 1000000000;

  String? _validateIncome(String? v) => vndTooLarge(parseVnd(v));

  String? _validateDay(String? v) {
    final amount = parseVnd(_incomeAmount.text) ?? 0;
    if (amount <= 0) return null;
    final day = int.tryParse(v?.trim() ?? '');
    if (day == null || day < 1 || day > 31) return 'Ngày 1–31';
    return null;
  }

  /// Kiểm tra cả bốn ô theo chữ đang có (ô cuộn khỏi màn hình có thể chưa dựng nên Form không thấy).
  bool get _fieldsValid =>
      _validatePercent(_warningPercent.text) == null &&
      _validateMin(_warningMin.text) == null &&
      _validateIncome(_incomeAmount.text) == null &&
      _validateDay(_incomeDay.text) == null;

  /// Hai ô của "Lương dự kiến" (cùng Form với vùng đệm: một nút "Lưu cài đặt" cho cả hai nhóm).
  (Widget, Widget) _incomeFieldsPair() => (
    MoneyField(
      key: const Key('settings_income_amount'),
      controller: _incomeAmount,
      enabled: !_saving,
      label: 'Số tiền lương',
      hint: 'Để trống = không dùng',
      validator: _validateIncome,
    ),
    TextFormField(
      key: const Key('settings_income_day'),
      controller: _incomeDay,
      enabled: !_saving,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
      style: _numberStyle(context),
      decoration: _numberDecoration(context, label: 'Ngày nhận', hint: 'VD: 5'),
      validator: _validateDay,
    ),
  );

  List<Widget> _buildIncome(ThemeData theme) {
    if (_settings == null) return const [];
    final (amountField, dayField) = _incomeFieldsPair();
    return [
      Text(
        'Tuỳ chọn. Trước ngày lương, nếu chỉ thiếu tạm thời và lương sẽ bù đủ thì app báo "chờ lương" thay vì '
        'báo nguy hiểm mỗi ngày.',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: Space.s4),
      _pair(amountField, dayField, flex: (3, 2)),
      const SizedBox(height: Space.s4),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: FilledButton.icon(
          key: const Key('settings_save'),
          onPressed: _saving || !_dirty ? null : _saveSettings,
          icon: _saving ? const BusyIcon() : null,
          label: Text(_saving ? 'Đang lưu…' : 'Lưu cài đặt'),
        ),
      ),
    ];
  }

  List<Widget> _buildServer(ThemeData theme, ApiClient? client) {
    final scheme = theme.colorScheme;
    return [
      ListGroup(
        children: [
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Địa chỉ máy chủ'),
            subtitle: Text(client?.baseUrl ?? '—'),
          ),
          if (client != null && ApiClient.isInsecureUrl(client.baseUrl))
            ListTile(
              leading: Icon(Icons.lock_open, color: StatusColors.of(context).warning.foreground),
              title: const Text('Kết nối không mã hoá (http://)'),
              subtitle: const Text('Token được gửi dạng rõ. Chỉ nên dùng trong mạng LAN tin cậy.'),
            ),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('Token'),
            subtitle: Text(client == null ? '—' : _maskToken(client.token)),
          ),
        ],
      ),
      const SizedBox(height: Space.s3),
      Wrap(
        spacing: Space.s2,
        runSpacing: Space.s2,
        children: [
          FilledButton.tonal(onPressed: _editConnection, child: const Text('Đổi máy chủ / token')),
          TextButton(
            style: AppButtonStyles.destructiveText(scheme),
            onPressed: _disconnect,
            child: const Text('Ngắt kết nối'),
          ),
        ],
      ),
    ];
  }
}

/// Ô số không phải tiền (vùng đệm %, ngày nhận lương): chữ `titleMedium` thường (số tiền mới dùng chữ số to
/// `moneyInput`), nhưng cao 64 dp như ô tiền đặt cạnh để hai ô thẳng hàng.
TextStyle _numberStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface);

InputDecoration _numberDecoration(BuildContext context, {required String label, String? suffix, String? hint}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      suffixStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      constraints: const BoxConstraints(minHeight: 64),
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s5),
    );

/// Hai ô cạnh nhau khi đủ rộng (≥ 400 dp), xếp chồng khi hẹp.
Widget _pair(Widget a, Widget b, {required (int, int) flex}) => LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= 400) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: flex.$1, child: a),
          const SizedBox(width: Space.s3),
          Expanded(flex: flex.$2, child: b),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        a,
        const SizedBox(height: Space.s4),
        b,
      ],
    );
  },
);

/// Mục "Thông báo đẩy": trạng thái đăng ký push của máy này + nút "Gửi thử".
class _PushSection extends StatefulWidget {
  const _PushSection();

  @override
  State<_PushSection> createState() => _PushSectionState();
}

class _PushSectionState extends State<_PushSection> {
  bool _sending = false;

  Future<void> _sendTest(PushController push) async {
    setState(() => _sending = true);
    try {
      final result = await push.sendTest();
      if (!mounted) return;
      showInfo(
        context,
        result.pushEnabled
            ? 'Đã gửi thông báo thử, chờ vài giây.'
            : 'Máy chủ chưa cấu hình Firebase nên chưa gửi được thông báo thử.',
      );
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static String _help(PushController push) => switch (push.status) {
    PushStatus.idle => 'Kết nối máy chủ để bật thông báo đẩy.',
    PushStatus.checking => 'Đang đăng ký máy này với máy chủ…',
    PushStatus.notAvailableInBuild =>
      'Bản build này chưa có Firebase — xem README (mục "Thông báo đẩy"). '
          'Cảnh báo vẫn có ở tab Cảnh báo và Telegram.',
    PushStatus.permissionDenied => 'Bật quyền thông báo cho "Chi tiêu" trong Cài đặt của điện thoại rồi bấm "Thử lại".',
    PushStatus.serverNotConfigured => [
      'Máy chủ chưa cấu hình Firebase (service account FCM) — xem README.',
      ?push.serverError,
    ].join(' '),
    PushStatus.enabled => 'Máy chủ sẽ gửi các cảnh báo quan trọng tới máy này. Bấm "Gửi thử" để kiểm tra.',
    PushStatus.error => push.errorMessage ?? 'Không bật được thông báo đẩy.',
  };

  @override
  Widget build(BuildContext context) {
    final push = Provider.of<PushController?>(context);
    if (push == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final status = push.status;
    final enabled = status == PushStatus.enabled;
    final problem =
        status == PushStatus.error || status == PushStatus.permissionDenied || status == PushStatus.serverNotConfigured;
    final canRetry = problem;
    final (IconData icon, Color color) = enabled
        ? (Icons.notifications_active_outlined, StatusColors.of(context).ok.foreground)
        : problem
        ? (Icons.notifications_off_outlined, StatusColors.of(context).warning.foreground)
        : (Icons.notifications_none, scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListGroup(
          children: [
            ListTile(
              key: const Key('push_status'),
              // Hàng nhiều dòng: icon đứng ở đầu như chữ, không trôi giữa hàng.
              titleAlignment: ListTileTitleAlignment.top,
              leading: SizedBox(
                width: AppLayout.listLeadingSize,
                child: Center(child: Icon(icon, color: color)),
              ),
              title: Text(status == PushStatus.error ? '${status.label}: không bật được' : status.label),
              subtitle: Text(_help(push)),
            ),
          ],
        ),
        const SizedBox(height: Space.s3),
        Wrap(
          spacing: Space.s2,
          runSpacing: Space.s2,
          children: [
            FilledButton.tonalIcon(
              key: const Key('push_test'),
              onPressed: push.canSendTest && !_sending ? () => _sendTest(push) : null,
              icon: _sending ? const BusyIcon() : const Icon(Icons.send_outlined),
              label: Text(_sending ? 'Đang gửi…' : 'Gửi thử'),
            ),
            if (canRetry) TextButton(onPressed: push.retry, child: const Text('Thử lại')),
          ],
        ),
      ],
    );
  }
}
