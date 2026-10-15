import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Tiêu đề một phần nội dung ("Mục tiêu tháng 10", "Dự báo cuối tháng"): `titleLarge` 22 sp / 700.
///
/// Trên tiêu đề 32 dp (khoảng giữa các phần), dưới 8 dp tới nội dung: luôn nhiều chỗ phía trên hơn phía dưới.
/// Không có nhãn nhỏ viết hoa phía trên (no eyebrows). [first]: phần đầu trang, không chừa 32 dp phía trên.
/// Là tiêu đề cho trình đọc màn hình (nhảy theo tiêu đề).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.first = false});

  final String title;

  /// Nút chữ ở cuối hàng ("Xem tất cả").
  final Widget? trailing;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : AppLayout.sectionGap, bottom: AppLayout.headingToContent),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface)),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
