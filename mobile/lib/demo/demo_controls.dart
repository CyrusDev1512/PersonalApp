import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../utils/currency.dart';
import '../widgets/form_parts.dart';
import '../widgets/list_group.dart';
import 'demo_backend.dart';

/// Họ font emoji / ký hiệu mà bản dùng thử nạp sẵn (main_demo.dart) để không phải tải font từ Internet.
const String demoEmojiFontFamily = 'Noto Color Emoji';
const String demoSymbolsFontFamily = 'DejaVu Sans';

final Map<Brightness, ThemeData> _demoThemes = {};

/// Theme của app với font emoji / ký hiệu nạp sẵn làm font dự phòng cho MỌI kiểu chữ (cả kiểu chữ của
/// component theme: ô danh sách, SnackBar, chip…), để engine web không đi tải font dự phòng.
ThemeData withDemoFontFallback(ThemeData theme) => _demoThemes.putIfAbsent(
  theme.brightness,
  () => buildTheme(theme.brightness, fontFamilyFallback: const [demoEmojiFontFamily, demoSymbolsFontFamily]),
);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Màn hình rộng: thanh demo trải hết bề ngang; app tự đổi sang NavigationRail và cột nội dung tối đa 720 dp
    // (HomeShell), bảng trượt tối đa 640 dp (theme) thay vì thu cả app về một cột cỡ điện thoại.
    final column = Builder(
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final connected = context.select<AppState, bool>((s) => s.isConnected);
    final labelStyle = theme.textTheme.labelLarge!.copyWith(color: scheme.onTertiaryContainer);
    final buttonText = connected ? 'Giả lập biến động số dư' : 'Kết nối lại bản dùng thử';
    // Nút demo không dùng màu men lam (dành cho "Thêm mục tiêu"): filled `tertiary` trên dải `tertiaryContainer`.
    final button = FilledButton.icon(
      key: Key(connected ? 'demo_simulate' : 'demo_reconnect'),
      onPressed: _busy ? null : (connected ? _openSheet : _reconnect),
      style: FilledButton.styleFrom(
        backgroundColor: scheme.tertiary,
        foregroundColor: scheme.onTertiary,
        padding: const EdgeInsetsDirectional.only(start: Space.s4, end: Space.s6),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      icon: Icon(connected ? Icons.bolt : Icons.link, size: 18),
      label: Text(buttonText),
    );
    const labelText = 'Bản dùng thử · dữ liệu giả';
    final label = Semantics(
      container: true,
      label: 'Bản dùng thử, dữ liệu giả',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.science_outlined, size: 18, color: scheme.onTertiaryContainer),
          const SizedBox(width: Space.s2),
          Flexible(child: Text(labelText, style: labelStyle)),
        ],
      ),
    );
    return Material(
      color: scheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: Space.s4, end: Space.s3),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double textWidth(String text) {
                final painter = TextPainter(
                  text: TextSpan(text: text, style: labelStyle),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  maxLines: 1,
                )..layout();
                final width = painter.width;
                painter.dispose();
                return width;
              }

              // Như OverflowBar: nhãn và nút chung một hàng khi cả hai vừa ở bề rộng tự nhiên; không thì nút
              // xuống hàng thứ hai, căn cuối. Không bao giờ cắt chữ.
              final labelWidth = 18 + Space.s2 + textWidth(labelText);
              final buttonWidth = Space.s4 + 18 + Space.s2 + textWidth(buttonText) + Space.s6;
              final oneRow = labelWidth + Space.s4 + buttonWidth <= constraints.maxWidth;
              if (oneRow) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppLayout.touchTargetMin),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: label),
                      const SizedBox(width: Space.s4),
                      button,
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: Space.s3, bottom: Space.s1),
                    child: Align(alignment: AlignmentDirectional.centerStart, child: label),
                  ),
                  Align(alignment: AlignmentDirectional.centerEnd, child: button),
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
    constraints: AppLayout.sheetConstraints(context),
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
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final vcb = widget.accounts.where((a) => a.id == _defaultAccount).firstOrNull;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Space.s5, 0, Space.s5, Space.s5 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Giả lập biến động số dư', style: text.headlineSmall?.copyWith(color: scheme.onSurface)),
          ),
          const SizedBox(height: Space.s1),
          Text(
            'Tạo một giao dịch ngân hàng giả như webhook SePay gửi về. App tính lại mức an toàn, tạo cảnh báo '
            'và gửi thông báo đẩy khi cảnh báo quan trọng.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: Space.s6),
          Text(vcb != null ? 'Mẫu có sẵn · ${vcb.name}' : 'Mẫu có sẵn', style: text.titleSmall),
          const SizedBox(height: Space.s2),
          ListGroup(
            children: [
              for (final p in _presets)
                ListTile(
                  key: Key('demo_preset_${p.key}'),
                  enabled: vcb != null,
                  leading: LeadingDisc(icon: p.icon),
                  title: Text(p.title),
                  subtitle: Text(p.subtitle),
                  onTap: () => _pick(p),
                ),
            ],
          ),
          const SizedBox(height: Space.s6),
          Text('Tự nhập', style: text.titleSmall),
          const SizedBox(height: Space.s2),
          AdaptiveSegmentedButton<String>(
            choices: const [
              SegmentChoice('out', 'Tiền ra', icon: Icons.north_east),
              SegmentChoice('in', 'Tiền vào', icon: Icons.south_west),
            ],
            selected: _direction,
            onChanged: (v) => setState(() => _direction = v),
          ),
          const SizedBox(height: Space.s4),
          MoneyField(
            key: const Key('demo_amount'),
            controller: _amount,
            label: 'Số tiền',
            hint: 'VD: 120.000',
            errorText: _amountError,
            onChanged: (_) {
              if (_amountError != null) setState(() => _amountError = null);
            },
          ),
          const SizedBox(height: Space.s4),
          TextField(
            key: const Key('demo_content'),
            controller: _content,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Nội dung chuyển khoản',
              hintText: 'VD: GRABFOOD COM TAM',
              helperText: 'Nội dung khớp luật sẽ được tự phân loại (GRABFOOD → Ăn uống, LUONG → Thu nhập…)',
            ),
          ),
          const SizedBox(height: Space.s4),
          DropdownButtonFormField<int>(
            key: const Key('demo_account'),
            initialValue: _accountId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tài khoản'),
            items: [for (final a in widget.accounts) DropdownMenuItem(value: a.id, child: Text(_accountLabel(a)))],
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: Space.s4),
          FilledButton.icon(
            key: const Key('demo_custom_submit'),
            onPressed: _accountId == null ? null : _submitCustom,
            style: FilledButton.styleFrom(backgroundColor: scheme.tertiary, foregroundColor: scheme.onTertiary),
            icon: const Icon(Icons.bolt),
            label: const Text('Tạo biến động'),
          ),
          const SizedBox(height: Space.s6),
          const Divider(),
          const SizedBox(height: Space.s4),
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
