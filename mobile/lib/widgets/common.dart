import 'package:flutter/material.dart';

import '../api/api_client.dart';

export 'section_header.dart';
export 'state_views.dart';

/// Thông báo lỗi ngắn (SnackBar) với lời của máy chủ.
void showError(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : 'Có lỗi xảy ra: $error';
  showInfo(context, message);
}

/// SnackBar nổi (DESIGN.md › Snackbars): 4 s, 6 s khi có nút ([actionLabel] + [onAction], vd. "Hoàn tác").
void showInfo(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final hasAction = actionLabel != null && onAction != null;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: hasAction ? 6 : 4),
        persist: false,
        action: hasAction ? SnackBarAction(label: actionLabel, onPressed: onAction) : null,
      ),
    );
}
