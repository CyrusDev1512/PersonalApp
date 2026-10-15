import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../screens/tx_action_sheet.dart';
import '../state/app_state.dart';
import '../state/home_tabs.dart';
import '../utils/text.dart';
import '../widgets/alert_detail_sheet.dart';
import 'push_service.dart';

/// Xử lý thông báo đẩy ở tầng app (ngoài mọi màn hình):
/// - bấm thông báo có `transaction_id` → tải giao dịch, mở bảng thao tác giao dịch;
///   không có → chuyển sang tab Cảnh báo (và mở cảnh báo nếu có `alert_id`);
/// - thông báo đến khi app đang mở → SnackBar kèm nút "Xem" + tải lại tổng quan.
class PushNavigator {
  PushNavigator({required this.state, required this.tabs, required this.navigatorKey, required this.messengerKey});

  final AppState state;
  final HomeTabRequests tabs;
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  BuildContext? get _context => navigatorKey.currentState?.overlay?.context ?? navigatorKey.currentContext;

  /// Thông báo đến khi app đang mở (Android không tự hiện lên khay hệ thống).
  void handleForeground(PushMessage message) {
    if (!state.isConnected) return;
    unawaited(state.load());
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    // Gọn: tiêu đề + dòng đầu của nội dung (mỗi dòng tối đa 1 hàng); đầy đủ thì bấm "Xem". Emoji đầu tiêu đề
    // (soạn cho Telegram) bỏ đi như ở tab Cảnh báo.
    final title = stripLeadingEmoji(message.title?.trim() ?? '');
    final firstLine = (message.body ?? '').trim().split('\n').first.trim();
    final heading = title.isNotEmpty ? title : (firstLine.isNotEmpty ? firstLine : 'Có cảnh báo mới');
    final detail = title.isNotEmpty ? firstLine : '';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('push_snackbar'),
          content: Builder(
            builder: (context) {
              final style = DefaultTextStyle.of(context).style;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (detail.isNotEmpty) Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              );
            },
          ),
          // DESIGN.md › Snackbars: 6 s khi có nút.
          duration: const Duration(seconds: 6),
          persist: false,
          action: SnackBarAction(label: 'Xem', onPressed: () => unawaited(handleOpened(message))),
        ),
      );
  }

  /// Người dùng bấm vào thông báo (hoặc "Xem" trên SnackBar).
  Future<void> handleOpened(PushMessage message) async {
    final client = state.client;
    if (client == null) return;
    final alertId = message.alertIdValue;
    final txId = message.transactionIdValue;
    if (txId != null) {
      Tx? tx;
      try {
        tx = await client.getTransaction(txId);
      } on ApiException catch (e) {
        _showMessage('Không mở được giao dịch: ${e.message}');
      }
      if (tx != null) {
        if (alertId != null) unawaited(_markRead(client, alertId));
        final context = _context;
        if (context == null || !context.mounted || !identical(state.client, client)) return;
        await showTxActionSheet(context, client: client, tx: tx);
        return;
      }
    }
    await _openAlert(client, alertId);
  }

  /// Chuyển sang tab Cảnh báo; có [alertId] thì tải và hiện nội dung cảnh báo (đánh dấu đã đọc).
  Future<void> _openAlert(ApiClient client, int? alertId) async {
    Alert? alert;
    if (alertId != null) {
      try {
        alert = await client.getAlert(alertId);
        if (!alert.read) alert = await client.markAlertRead(alertId);
      } on ApiException catch (e) {
        if (alert == null) _showMessage('Không mở được cảnh báo: ${e.message}');
      }
    }
    if (!identical(state.client, client)) return;
    tabs.request(HomeTab.alerts);
    unawaited(state.load());
    final shown = alert;
    final context = _context;
    if (shown == null || context == null || !context.mounted) return;
    // Cùng bảng chi tiết với tab Cảnh báo (nút "Xem giao dịch" / "Xem mục tiêu" theo ngữ cảnh).
    await showAlertDetail(context, client: client, alert: shown, key: const Key('push_alert_dialog'));
  }

  Future<void> _markRead(ApiClient client, int alertId) async {
    try {
      await client.markAlertRead(alertId);
      if (identical(state.client, client)) await state.load();
    } on ApiException {
      // Không quan trọng: cảnh báo vẫn còn trong tab Cảnh báo.
    }
  }

  void _showMessage(String text) {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}
