import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../state/app_state.dart';

/// Màn "Kết nối máy chủ": nhập URL + token, kiểm tra /health rồi /api/summary.
///
/// Lần đầu mở app hiện màn này thay cho trang chủ; từ Cài đặt thì mở dạng trang
/// con ([popOnSuccess] = true) để đổi máy chủ / token.
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
  String? _step;
  String? _error;

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
      _step = 'Đang kiểm tra máy chủ (/health)…';
    });
    try {
      await client.health();
    } on ApiException catch (e) {
      _fail(_explain(e, atHealth: true));
      return;
    }
    if (!mounted) return;
    setState(() => _step = 'Đang kiểm tra token (/api/summary)…');
    try {
      final summaryJson = await client.getSummaryJson();
      await state.connect(client, summaryJson: summaryJson);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = null;
      });
      if (widget.popOnSuccess && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      _fail(_explain(e, atHealth: false));
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _step = null;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insecure = ApiClient.isInsecureUrl(_url.text);
    return Scaffold(
      appBar: AppBar(title: const Text('Kết nối máy chủ')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Nhập địa chỉ máy chủ backend và APP_TOKEN (trong file .env của máy chủ). '
                'Nên dùng địa chỉ https:// qua Cloudflare Tunnel.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('connect_url'),
                controller: _url,
                enabled: !_busy,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ máy chủ (URL)',
                  hintText: 'https://finance.example.com',
                  prefixIcon: Icon(Icons.dns_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validateUrl,
              ),
              if (insecure) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_open, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Địa chỉ http:// không mã hoá: token sẽ được gửi dạng rõ qua mạng. '
                          'Chỉ dùng trong mạng LAN tin cậy; khi dùng ngoài nhà hãy dùng https://.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('connect_token'),
                controller: _token,
                enabled: !_busy,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Token (APP_TOKEN)',
                  prefixIcon: const Icon(Icons.key_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Hiện token' : 'Ẩn token',
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập token' : null,
                onFieldSubmitted: (_) => _connect(),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('connect_submit'),
                onPressed: _busy ? null : _connect,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.link),
                label: const Text('Kiểm tra & kết nối'),
              ),
              if (_step != null) ...[const SizedBox(height: 12), Text(_step!, textAlign: TextAlign.center)],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
