import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../utils/currency.dart';
import 'demo_backend.dart';

/// Họ font emoji / ký hiệu mà bản dùng thử nạp sẵn (main_demo.dart) để không phải tải font từ Internet.
const String demoEmojiFontFamily = 'Noto Color Emoji';
const String demoSymbolsFontFamily = 'DejaVu Sans';

/// Thêm font emoji / ký hiệu nạp sẵn vào danh sách font dự phòng của theme.
ThemeData withDemoFontFallback(ThemeData theme) {
  const fallback = [demoEmojiFontFamily, demoSymbolsFontFamily];
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamilyFallback: fallback),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamilyFallback: fallback),
  );
}

/// Bọc app của bản dùng thử: thanh "Bản dùng thử · dữ liệu giả" + nút giả lập ở trên cùng.
class DemoShell extends StatelessWidget {
  const DemoShell({
    super.key,
    required this.backend,
    required this.navigatorKey,
    required this.onReconnect,
    required this.child,
  });

  final DemoBackend backend;
  final GlobalKey<NavigatorState> navigatorKey;

  /// Kết nối lại máy chủ giả sau khi người dùng bấm "Ngắt kết nối".
  final Future<void> Function() onReconnect;
  final Widget child;

  /// Tiêu đề trang (MaterialApp đặt "Chi tiêu"; Title bên trong dựng sau nên ghi đè).
  static const String pageTitle = 'Chi tiêu (bản demo)';

  /// Màn hình rộng hơn mức này (máy tính, máy tính bảng ngang) thì app hiện thành một cột cỡ điện thoại ở giữa.
  static const double wideBreakpoint = 600;

  /// Bề rộng cột "điện thoại" trên màn hình rộng.
  static const double phoneWidth = 440;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final wide = media.size.width > wideBreakpoint;
    // Builder để MediaQuery.removePadding đọc đúng MediaQuery (đã thu hẹp khi màn hình rộng).
    Widget column = Builder(
      builder: (context) => Column(
        children: [
          DemoBanner(backend: backend, navigatorKey: navigatorKey, onReconnect: onReconnect),
          // Navigator là một vùng semantics riêng: BlockSemantics của các route (ModalBarrier) không che mất thanh demo.
          Expanded(
            child: Semantics(
              container: true,
              child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
            ),
          ),
        ],
      ),
    );
    if (wide) {
      // App được thiết kế cho điện thoại: trên màn hình rộng giữ cỡ điện thoại thay vì kéo giãn cả màn hình.
      // MediaQuery cũng báo bề rộng của cột để hộp thoại, bảng trượt và SnackBar nằm gọn trong cột.
      final scheme = theme.colorScheme;
      column = ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.symmetric(vertical: BorderSide(color: scheme.outlineVariant)),
            ),
            child: SizedBox(
              width: phoneWidth,
              child: MediaQuery(
                data: media.copyWith(size: Size(phoneWidth, media.size.height)),
                child: column,
              ),
            ),
          ),
        ),
      );
    }
    return Title(
      title: pageTitle,
      color: theme.colorScheme.primary,
      child: Theme(data: withDemoFontFallback(theme), child: column),
    );
  }
}

/// Thanh mỏng báo đây là bản dùng thử, kèm nút "Giả lập biến động số dư".
class DemoBanner extends StatefulWidget {
  const DemoBanner({super.key, required this.backend, required this.navigatorKey, required this.onReconnect});

  final DemoBackend backend;
  final GlobalKey<NavigatorState> navigatorKey;
  final Future<void> Function() onReconnect;

  @override
  State<DemoBanner> createState() => _DemoBannerState();
}

class _DemoBannerState extends State<DemoBanner> {
  bool _busy = false;

  BuildContext? get _navContext {
    final nav = widget.navigatorKey.currentState;
    return nav?.overlay?.context ?? widget.navigatorKey.currentContext;
  }

  ScaffoldMessengerState? get _messenger {
    final ctx = _navContext;
    return ctx == null ? null : ScaffoldMessenger.maybeOf(ctx);
  }

  void _show(String text) {
    _messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 6)));
  }

  Future<void> _openSheet() async {
    final ctx = _navContext;
    if (ctx == null) return;
    final state = context.read<AppState>();
    final action = await showDemoSimulateSheet(ctx, backend: widget.backend);
    if (action == null || !mounted) return;
    setState(() => _busy = true);
    try {
      switch (action) {
        case DemoReset():
          widget.backend.reset();
          await state.load();
          _show('Đã đặt lại dữ liệu demo');
        case DemoSimulate(:final accountId, :final direction, :final amount, :final description):
          final result = await widget.backend.simulateBankTx(
            accountId: accountId,
            direction: direction,
            amount: amount,
            description: description,
          );
          await state.load();
          // Có thông báo đẩy thì SnackBar "Xem" của PushNavigator (như trên điện thoại) là phản hồi.
          if (!result.pushed) {
            final account = widget.backend.bankAccounts.where((a) => a.id == accountId).firstOrNull?.name ?? '';
            final recorded = '${formatSignedVnd(amount, outgoing: direction == 'out')} · $account đã được ghi nhận.';
            _show(
              result.important
                  ? '$recorded Có cảnh báo mới nhưng máy này chưa đăng ký nhận thông báo đẩy — xem ở tab Cảnh báo.'
                  : '$recorded Biến động này không tạo cảnh báo quan trọng nên không có thông báo đẩy '
                        '(bản thật cũng vậy) — xem ở tab Cảnh báo.',
            );
          }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reconnect() async {
    setState(() => _busy = true);
    try {
      await widget.onReconnect();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final connected = context.select<AppState, bool>((s) => s.isConnected);
    final text = Theme.of(context).textTheme;
    final labelStyle = text.labelMedium?.copyWith(color: scheme.onTertiaryContainer);
    Widget button({required bool narrow}) => connected
        ? FilledButton.icon(
            key: const Key('demo_simulate'),
            onPressed: _busy ? null : _openSheet,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(0, 36),
            ),
            icon: const Icon(Icons.bolt, size: 18),
            label: const Text('Giả lập biến động số dư', maxLines: 1, overflow: TextOverflow.ellipsis),
          )
        : FilledButton.icon(
            key: const Key('demo_reconnect'),
            onPressed: _busy ? null : _reconnect,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(0, 36),
            ),
            icon: const Icon(Icons.link, size: 18),
            // Màn hẹp: chữ ngắn để nhãn "đã ngắt kết nối" bên trái không bị cắt; trình đọc màn hình vẫn đọc đủ câu.
            label: Text(
              narrow ? 'Kết nối lại' : 'Kết nối lại bản dùng thử',
              semanticsLabel: 'Kết nối lại bản dùng thử',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
    return Material(
      color: scheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 460;
              // Nhãn chỉ chiếm phần nó cần (tối đa [maxLabel]); nút lấy phần còn lại, thiếu chỗ thì rút gọn chữ.
              // Khi ngắt kết nối, nút "Kết nối lại" ngắn hơn nên nhãn được rộng hơn để đủ chỗ cho "đã ngắt kết nối".
              final maxLabel = narrow ? (connected ? 112.0 : 156.0) : 280.0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxLabel),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science_outlined, size: 18, color: scheme.onTertiaryContainer),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Semantics(
                            container: true,
                            label: connected ? 'Bản dùng thử · dữ liệu giả' : 'Bản dùng thử · đã ngắt kết nối',
                            excludeSemantics: true,
                            child: Text(
                              switch ((connected, narrow)) {
                                (true, true) => 'Bản dùng thử\ndữ liệu giả',
                                (true, false) => 'Bản dùng thử · dữ liệu giả',
                                (false, true) => 'Bản dùng thử\nđã ngắt kết nối',
                                (false, false) => 'Bản dùng thử · đã ngắt kết nối',
                              },
                              style: labelStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: button(narrow: narrow)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Thao tác chọn trong bảng giả lập.
sealed class DemoSheetAction {
  const DemoSheetAction();
}

/// "Đặt lại dữ liệu demo".
class DemoReset extends DemoSheetAction {
  const DemoReset();
}

/// Một biến động số dư cần tạo.
class DemoSimulate extends DemoSheetAction {
  const DemoSimulate({
    required this.accountId,
    required this.direction,
    required this.amount,
    required this.description,
  });

  final int accountId;
  final String direction;
  final int amount;
  final String description;
}

/// Mẫu biến động có sẵn.
class _Preset {
  const _Preset(this.key, this.title, this.subtitle, this.icon, this.direction, this.amount, this.description);

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final String direction;
  final int amount;
  final String description;
}

const List<_Preset> _presets = [
  _Preset(
    'atm',
    'Rút ATM 3.500.000đ',
    'Tiền ra · chưa phân loại',
    Icons.local_atm,
    'out',
    3500000,
    'RUT TIEN ATM VCB LE DUAN Q1',
  ),
  _Preset(
    'salary',
    'Nhận lương 15.000.000đ',
    'Tiền vào · tự phân loại Thu nhập',
    Icons.payments_outlined,
    'in',
    15000000,
    'CONG TY TNHH ABC TRA LUONG',
  ),
  _Preset(
    'rent',
    'Chuyển tiền trọ 3.000.000đ',
    'Tiền ra · tự phân loại Thuê trọ (quỹ "Tiền trọ")',
    Icons.home_outlined,
    'out',
    3000000,
    'CHUYEN TIEN TRO CHO CO HOA',
  ),
  _Preset(
    'shopping',
    'Mua sắm 600.000đ',
    'Tiền ra · tự phân loại Mua sắm',
    Icons.shopping_bag_outlined,
    'out',
    600000,
    'SHOPEE THANH TOAN DON HANG',
  ),
];

/// Mở bảng "Giả lập biến động số dư"; trả thao tác người dùng chọn (hoặc `null` nếu đóng).
Future<DemoSheetAction?> showDemoSimulateSheet(BuildContext context, {required DemoBackend backend}) {
  return showModalBottomSheet<DemoSheetAction>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    builder: (_) => DemoSimulateSheet(accounts: backend.bankAccounts),
  );
}

/// Nội dung bảng giả lập: các mẫu có sẵn, tự nhập, và đặt lại dữ liệu.
class DemoSimulateSheet extends StatefulWidget {
  const DemoSimulateSheet({super.key, required this.accounts});

  final List<DemoAccountChoice> accounts;

  @override
  State<DemoSimulateSheet> createState() => _DemoSimulateSheetState();
}

class _DemoSimulateSheetState extends State<DemoSimulateSheet> {
  final _amount = TextEditingController();
  final _content = TextEditingController();
  String _direction = 'out';
  int? _accountId;
  String? _amountError;

  int? get _defaultAccount =>
      (widget.accounts.where((a) => a.bank == 'VCB').firstOrNull ?? widget.accounts.firstOrNull)?.id;

  @override
  void initState() {
    super.initState();
    _accountId = _defaultAccount;
  }

  @override
  void dispose() {
    _amount.dispose();
    _content.dispose();
    super.dispose();
  }

  void _pick(_Preset p) {
    final account = _defaultAccount;
    if (account == null) return;
    Navigator.pop(
      context,
      DemoSimulate(accountId: account, direction: p.direction, amount: p.amount, description: p.description),
    );
  }

  void _submitCustom() {
    final amount = parseVnd(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Nhập số tiền lớn hơn 0');
      return;
    }
    final account = _accountId;
    if (account == null) return;
    Navigator.pop(
      context,
      DemoSimulate(accountId: account, direction: _direction, amount: amount, description: _content.text.trim()),
    );
  }

  String _accountLabel(DemoAccountChoice a) => switch (a.bank) {
    'VCB' => '${a.name} (Vietcombank)',
    'MB' => '${a.name} (MB Bank)',
    _ => a.name,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vcb = widget.accounts.where((a) => a.id == _defaultAccount).firstOrNull;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Giả lập biến động số dư', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Tạo một giao dịch ngân hàng giả như webhook SePay gửi về. App tính lại mức an toàn, tạo cảnh báo '
            'và gửi thông báo đẩy khi cảnh báo quan trọng.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (vcb != null)
            Text('Mẫu có sẵn · ${vcb.name}', style: theme.textTheme.labelLarge)
          else
            Text('Mẫu có sẵn', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final p in _presets)
                  ListTile(
                    key: Key('demo_preset_${p.key}'),
                    enabled: vcb != null,
                    leading: Icon(p.icon),
                    title: Text(p.title),
                    subtitle: Text(p.subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pick(p),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Tự nhập', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'out', label: Text('Tiền ra'), icon: Icon(Icons.arrow_upward)),
              ButtonSegment(value: 'in', label: Text('Tiền vào'), icon: Icon(Icons.arrow_downward)),
            ],
            selected: {_direction},
            onSelectionChanged: (s) => setState(() => _direction = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('demo_amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: const [VndInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Số tiền',
              suffixText: 'đ',
              errorText: _amountError,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              if (_amountError != null) setState(() => _amountError = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('demo_content'),
            controller: _content,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Nội dung chuyển khoản',
              hintText: 'VD: GRABFOOD COM TAM',
              helperText: 'Nội dung khớp luật sẽ được tự phân loại (GRABFOOD → Ăn uống, LUONG → Thu nhập…)',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: const Key('demo_account'),
            initialValue: _accountId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tài khoản', border: OutlineInputBorder()),
            items: [for (final a in widget.accounts) DropdownMenuItem(value: a.id, child: Text(_accountLabel(a)))],
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('demo_custom_submit'),
            onPressed: _accountId == null ? null : _submitCustom,
            icon: const Icon(Icons.send),
            label: const Text('Tạo biến động'),
          ),
          const SizedBox(height: 8),
          const Divider(height: 24),
          OutlinedButton.icon(
            key: const Key('demo_reset'),
            onPressed: () => Navigator.pop(context, const DemoReset()),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Đặt lại dữ liệu demo'),
          ),
        ],
      ),
    );
  }
}
