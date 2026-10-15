import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../screens/goal_form_screen.dart';
import '../screens/tx_action_sheet.dart';
import '../state/app_state.dart';
import '../state/home_tabs.dart';
import '../theme/tokens.dart';
import '../utils/dates.dart';
import '../utils/text.dart';
import 'alert_row.dart';
import 'common.dart';
import 'form_parts.dart';

/// Hành động tiếp theo chọn trong bảng chi tiết cảnh báo.
enum AlertSheetAction { openTransaction, openGoal, openUncategorized }

/// Mục tiêu của cảnh báo trong số liệu đang có (tháng này, tháng sau); `null` nếu không tìm thấy.
GoalView? findAlertGoal(AppState state, int? goalId) {
  if (goalId == null) return null;
  final all = [...?state.summary?.goals, ...state.nextMonthGoals];
  for (final g in all) {
    if (g.id == goalId) return g;
  }
  return null;
}

/// Mở bảng chi tiết cảnh báo (cùng một bảng cho tab Cảnh báo và thông báo đẩy), rồi làm hành động người dùng
/// chọn: "Phân loại giao dịch" / "Xem giao dịch" (tải giao dịch, mở bảng phân loại), "Xem mục tiêu" (mở form mục
/// tiêu), hoặc với bản tin nhắc giao dịch chưa phân loại: tab Giao dịch đã lọc "Chưa phân loại".
Future<void> showAlertDetail(BuildContext context, {required ApiClient client, required Alert alert, Key? key}) async {
  final state = context.read<AppState>();
  final goal = findAlertGoal(state, alert.goalId);
  final tabs = Provider.of<HomeTabRequests?>(context, listen: false);
  // Tải sẵn giao dịch để nút nói đúng việc ("Phân loại giao dịch" khi còn chưa phân loại); dùng lại khi bấm.
  final txId = alert.transactionId;
  final txFuture = txId == null ? null : _loadTx(client, txId);
  final action = await showModalBottomSheet<AlertSheetAction>(
    context: context,
    // Đọc màn hình: vùng tối phía sau bảng là "Đóng" (mặc định Flutter đọc "Scrim", chưa dịch).
    barrierLabel: 'Đóng',
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: AppLayout.sheetConstraints(context),
    builder: (_) => AlertDetailSheet(
      key: key,
      alert: alert,
      canOpenGoal: goal != null,
      canOpenUncategorized: tabs != null,
      transaction: txFuture,
    ),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case AlertSheetAction.openTransaction:
      if (txFuture == null) return;
      final (tx, error) = await txFuture;
      if (!context.mounted) return;
      if (tx != null) {
        await showTxActionSheet(context, client: client, tx: tx);
      } else if (error != null) {
        showError(context, error);
      }
    case AlertSheetAction.openGoal:
      if (goal == null) return;
      await Navigator.of(context).pushNamed(GoalFormScreen.routeName, arguments: GoalFormArgs(goal: goal));
    case AlertSheetAction.openUncategorized:
      tabs?.request(HomeTab.transactions, uncategorized: true);
  }
}

/// Giao dịch của cảnh báo, hoặc lỗi tải (không ném lỗi: bảng vẫn mở được khi chưa tải xong hay lỗi).
Future<(Tx?, ApiException?)> _loadTx(ApiClient client, int id) async {
  try {
    return (await client.getTransaction(id), null);
  } on ApiException catch (e) {
    return (null, e);
  }
}

/// Bảng chi tiết một cảnh báo: đĩa theo mức + tiêu đề, giờ đầy đủ, nội dung đã làm sạch (chọn được để sao chép)
/// và một nút filled cho bước tiếp theo theo ngữ cảnh: "Phân loại giao dịch" (giao dịch còn chưa phân loại, hoặc
/// bản tin nhắc giao dịch chưa phân loại), "Xem giao dịch", "Xem mục tiêu"; không có thì không có nút.
class AlertDetailSheet extends StatelessWidget {
  const AlertDetailSheet({
    super.key,
    required this.alert,
    this.canOpenGoal = false,
    this.canOpenUncategorized = false,
    this.transaction,
  });

  final Alert alert;
  final bool canOpenGoal;

  /// Có thể mở tab Giao dịch đã lọc "Chưa phân loại" (đang trong khung chính).
  final bool canOpenUncategorized;

  /// Giao dịch của cảnh báo (đang tải); quyết định nhãn nút.
  final Future<(Tx?, ApiException?)>? transaction;

  AlertSheetAction? get _action {
    if (alert.transactionId != null) return AlertSheetAction.openTransaction;
    if (alert.goalId != null && canOpenGoal) return AlertSheetAction.openGoal;
    if (canOpenUncategorized && (mentionedUncategorized(alert.message) ?? 0) > 0) {
      return AlertSheetAction.openUncategorized;
    }
    return null;
  }

  /// Giao dịch còn chưa phân loại? Trước khi tải xong: theo nội dung cảnh báo ("Danh mục: (chưa phân loại)").
  bool _txUncategorized(Tx? tx) => tx != null ? tx.isUncategorized : alert.message.contains('(chưa phân loại)');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final action = _action;
    final created = alert.createdAt;
    final message = cleanAlertMessage(alert.message);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Space.s5, 0, Space.s5, Space.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AlertDisc(alert: alert),
                    const SizedBox(width: Space.s4),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          alertDisplayTitle(alert),
                          style: theme.textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
                        ),
                      ),
                    ),
                  ],
                ),
                if (created != null) ...[
                  const SizedBox(height: Space.s2),
                  Text(
                    formatLongDateTimeIct(created),
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                if (message.isNotEmpty) ...[
                  const SizedBox(height: Space.s4),
                  SelectableText(message, style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface)),
                ],
              ],
            ),
          ),
        ),
        if (action != null)
          StickyActionBar(
            horizontalPadding: Space.s5,
            primary: switch (action) {
              AlertSheetAction.openTransaction => FutureBuilder<(Tx?, ApiException?)>(
                future: transaction,
                builder: (context, snapshot) => _button(
                  context,
                  action,
                  _txUncategorized(snapshot.data?.$1)
                      ? (Icons.label_outline, 'Phân loại giao dịch')
                      : (Icons.receipt_long_outlined, 'Xem giao dịch'),
                ),
              ),
              AlertSheetAction.openGoal => _button(context, action, (Icons.flag_outlined, 'Xem mục tiêu')),
              AlertSheetAction.openUncategorized => _button(context, action, (
                Icons.label_outline,
                'Phân loại giao dịch',
              )),
            },
          ),
      ],
    );
  }

  Widget _button(BuildContext context, AlertSheetAction action, (IconData, String) look) => FilledButton.icon(
    key: const Key('alert_detail_action'),
    onPressed: () => Navigator.of(context).pop(action),
    icon: Icon(look.$1),
    label: Text(look.$2),
  );
}
