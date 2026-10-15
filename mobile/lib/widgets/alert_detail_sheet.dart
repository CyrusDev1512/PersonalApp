import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../screens/goal_form_screen.dart';
import '../screens/tx_action_sheet.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../utils/dates.dart';
import 'alert_row.dart';
import 'common.dart';
import 'form_parts.dart';

/// Hành động tiếp theo chọn trong bảng chi tiết cảnh báo.
enum AlertSheetAction { openTransaction, openGoal }

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
/// chọn: "Xem giao dịch" (tải giao dịch, mở bảng phân loại) hoặc "Xem mục tiêu" (mở form mục tiêu).
Future<void> showAlertDetail(BuildContext context, {required ApiClient client, required Alert alert, Key? key}) async {
  final state = context.read<AppState>();
  final goal = findAlertGoal(state, alert.goalId);
  final action = await showModalBottomSheet<AlertSheetAction>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: AppLayout.sheetConstraints(context),
    builder: (_) => AlertDetailSheet(key: key, alert: alert, canOpenGoal: goal != null),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case AlertSheetAction.openTransaction:
      final id = alert.transactionId;
      if (id == null) return;
      try {
        final tx = await client.getTransaction(id);
        if (!context.mounted) return;
        await showTxActionSheet(context, client: client, tx: tx);
      } on ApiException catch (e) {
        if (context.mounted) showError(context, e);
      }
    case AlertSheetAction.openGoal:
      if (goal == null) return;
      await Navigator.of(context).pushNamed(GoalFormScreen.routeName, arguments: GoalFormArgs(goal: goal));
  }
}

/// Bảng chi tiết một cảnh báo: đĩa theo mức + tiêu đề, giờ đầy đủ, nội dung (chọn được để sao chép) và một
/// nút filled cho bước tiếp theo theo ngữ cảnh ("Xem giao dịch" / "Xem mục tiêu"), không có thì không có nút.
class AlertDetailSheet extends StatelessWidget {
  const AlertDetailSheet({super.key, required this.alert, this.canOpenGoal = false});

  final Alert alert;
  final bool canOpenGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final AlertSheetAction? action = alert.transactionId != null
        ? AlertSheetAction.openTransaction
        : (alert.goalId != null && canOpenGoal ? AlertSheetAction.openGoal : null);
    final created = alert.createdAt;
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
                if (alert.message.trim().isNotEmpty) ...[
                  const SizedBox(height: Space.s4),
                  SelectableText(
                    alert.message.trim(),
                    style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (action != null)
          StickyActionBar(
            horizontalPadding: Space.s5,
            primary: FilledButton.icon(
              key: const Key('alert_detail_action'),
              onPressed: () => Navigator.of(context).pop(action),
              icon: Icon(action == AlertSheetAction.openTransaction ? Icons.receipt_long_outlined : Icons.flag_outlined),
              label: Text(action == AlertSheetAction.openTransaction ? 'Xem giao dịch' : 'Xem mục tiêu'),
            ),
          ),
      ],
    );
  }
}
