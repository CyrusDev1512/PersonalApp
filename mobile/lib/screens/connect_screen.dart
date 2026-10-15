import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../state/app_state.dart';
import '../theme/status_colors.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/form_parts.dart';

/// Trạng thái một bước kiểm tra kết nối.
enum _Step { pending, running, done, failed }

/// Màn "Kết nối máy chủ" (surfaces/connect/brief.md): nhập URL + token, kiểm tra /health rồi /api/summary,
/// từng bước hiện trong một danh sách kiểm tra; lỗi nằm ngay ở bước hỏng.
///
/// Lần đầu mở app hiện màn này thay cho trang chủ (không có thanh tiêu đề, có chữ "Chi tiêu"); từ Cài đặt thì mở
/// dạng trang con ([popOnSuccess] = true) để đổi máy chủ / token.
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key, this.initialUrl, this.initialToken, this.popOnSuccess = false});

  static const routeName = '/connect';

  final String? initialUrl;
  final String? initialToken;
  final bool popOnSuccess;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _url;
  late final TextEditingController _token;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  /// Hai bước: /health, rồi token (/api/summary). `null` = chưa bấm kiểm tra.
  (_Step, _Step)? _steps;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.initialUrl ?? '');
    _token = TextEditingController(text: widget.initialToken ?? '');
    _url.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  String? _validateUrl(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nhập địa chỉ máy chủ';
    try {
      ApiClient.normalizeBaseUrl(v);
    } on ApiException catch (e) {
      return e.message;
    }
    return null;
  }

  String _explain(ApiException e, {required bool atHealth}) {
    if (e.isUnauthorized) {
      return 'Sai token: máy chủ từ chối (401). Kiểm tra lại APP_TOKEN trong file .env của máy chủ.';
    }
    if (e.isNetwork) return e.message;
    if (atHealth && e.statusCode == 404) {
      return 'Địa chỉ này không phải máy chủ Chi tiêu (không có /health). Kiểm tra lại URL.';
    }
    return e.message;
  }

  Future<void> _connect() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final state = context.read<AppState>();
    final ApiClient client;
    try {
      client = state.createClient(_url.text, _token.text.trim());
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _steps = (_Step.running, _Step.pending);
    });
    try {
      await client.health();
    } on ApiException catch (e) {
      _fail(_explain(e, atHealth: true), (_Step.failed, _Step.pending));
      return;
    }
    if (!mounted) return;
    setState(() => _steps = (_Step.done, _Step.running));
    try {
      final summaryJson = await client.getSummaryJson();
      await state.connect(client, summaryJson: summaryJson);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _steps = (_Step.done, _Step.done);
      });
      if (widget.popOnSuccess && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      _fail(_explain(e, atHealth: false), (_Step.done, _Step.failed));
    }
  }

  void _fail(String message, (_Step, _Step) steps) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _steps = steps;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final gutter = Gutter.of(context);
    final insecure = ApiClient.isInsecureUrl(_url.text);
    final firstRun = !widget.popOnSuccess;
    final steps = _steps;
    return Scaffold(
      appBar: firstRun ? null : AppBar(title: const Text('Kết nối máy chủ')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(gutter, firstRun ? Space.s10 : Space.s2, gutter, Space.s6),
            children: [
              if (firstRun) ...[
                Semantics(
                  header: true,
                  child: Text('Chi tiêu', maxLines: 1, style: text.displaySmall?.copyWith(color: scheme.primary)),
                ),
                const SizedBox(height: Space.s2),
                Text(
                  'Theo dõi số dư Vietcombank, MB và giữ tiền cho mục tiêu tháng này.',
                  style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: Space.s8),
                Semantics(
                  header: true,
                  child: Text('Kết nối máy chủ', style: text.titleLarge?.copyWith(color: scheme.onSurface)),
                ),
                const SizedBox(height: Space.s2),
              ],
              Text(
                'Nhập địa chỉ máy chủ và APP_TOKEN (trong file .env của máy chủ).',
                style: text.bodyMedium?.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: Space.s5),
              TextFormField(
                key: const Key('connect_url'),
                controller: _url,
                enabled: !_busy,
                keyboardType: TextInputType.url,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ máy chủ (URL)',
                  hintText: 'https://finance.example.com',
                  helperText: 'Nên dùng https:// qua Cloudflare Tunnel',
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
                validator: _validateUrl,
              ),
              if (insecure) ...[
                const SizedBox(height: Space.s2),
                InlineNote(
                  icon: Icons.lock_open,
                  iconColor: StatusColors.of(context).warning.foreground,
                  textColor: scheme.onSurface,
                  text:
                      'Địa chỉ http:// không mã hoá: token sẽ được gửi dạng rõ qua mạng. '
                      'Chỉ dùng trong mạng LAN tin cậy.',
                ),
              ],
              const SizedBox(height: Space.s4),
              TextFormField(
                key: const Key('connect_token'),
                controller: _token,
                enabled: !_busy,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  labelText: 'Token (APP_TOKEN)',
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Hiện token' : 'Ẩn token',
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập token' : null,
                onFieldSubmitted: (_) => _connect(),
              ),
              const SizedBox(height: Space.s6),
              FilledButton.icon(
                key: const Key('connect_submit'),
                onPressed: _busy ? null : _connect,
                icon: _busy ? const BusyIcon() : const Icon(Icons.link),
                label: const Text('Kiểm tra & kết nối'),
              ),
              // Lỗi nằm ngay dưới bước bị lỗi (bước sau chưa chạy thì không đứng trên lỗi).
              if (steps != null) ...[
                const SizedBox(height: Space.s5),
                _StepLine(label: 'Máy chủ phản hồi (/health)', step: steps.$1),
                if (_error != null && steps.$1 == _Step.failed) ...[
                  const SizedBox(height: Space.s2),
                  InlineError(_error!, key: const Key('connect_error')),
                ],
                const SizedBox(height: Space.s2),
                _StepLine(label: 'Token hợp lệ (/api/summary)', step: steps.$2),
              ],
              if (_error != null && (steps == null || steps.$1 != _Step.failed)) ...[
                SizedBox(height: steps == null ? Space.s4 : Space.s2),
                InlineError(_error!, key: const Key('connect_error')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Một bước trong danh sách kiểm tra: icon trạng thái + chữ.
class _StepLine extends StatelessWidget {
  const _StepLine({required this.label, required this.step});

  final String label;
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (Widget icon, String state) = switch (step) {
      _Step.pending => (Icon(Icons.radio_button_unchecked, size: 20, color: scheme.onSurfaceVariant), 'chưa kiểm tra'),
      _Step.running => (const BusyIcon(), 'đang kiểm tra'),
      _Step.done => (Icon(Icons.check_circle, size: 20, color: StatusColors.of(context).ok.foreground), 'đạt'),
      _Step.failed => (Icon(Icons.error, size: 20, color: scheme.error), 'lỗi'),
    };
    return Semantics(
      label: '$label: $state',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox.square(dimension: 24, child: Center(child: icon)),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface)),
          ),
        ],
      ),
    );
  }
}
