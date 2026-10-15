import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Hàng danh sách có số tiền ở cuối (giao dịch, mục tiêu, tài khoản): DESIGN.md › Lists › Row anatomy.
///
/// Đĩa 40 dp đầu hàng, [title] (`titleMedium`), [meta] (`bodySmall`, `onSurfaceVariant`), số tiền [amount]
/// căn phải kèm [amountCaption] nhỏ bên dưới, và [below] (pill trạng thái, thanh tiến độ…) dưới phần chữ.
///
/// Chữ lớn hơn 125% (`textScaler.scale(16) > 20`): tiêu đề và dòng phụ chiếm hết bề ngang, số tiền xuống dòng
/// riêng dưới dòng phụ, vẫn căn phải để các số tiền thành một cột. Không dùng `ListTile.trailing` (nó bóp
/// tiêu đề về 0 khi số tiền dài).
///
/// Cả hàng là một nút đọc màn hình (chữ + số tiền gộp lại); [onTap] biến nó thành nút bấm.
class MoneyRow extends StatelessWidget {
  const MoneyRow({
    super.key,
    this.leading,
    required this.title,
    this.meta,
    this.amount,
    this.amountCaption,
    this.below,
    this.onTap,
    this.semanticLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: AppLayout.listRowPaddingH, vertical: Space.s3),
  });

  final Widget? leading;
  final Widget title;
  final Widget? meta;

  /// Thường là `MoneyText(…, style: MoneyStyle.list)`, hoặc chữ "chưa biết số dư".
  final Widget? amount;

  /// Chú thích dưới số tiền ("còn phải giữ", "còn được chi").
  final Widget? amountCaption;

  /// Nội dung dưới phần chữ, rộng hết hàng (trừ đĩa đầu hàng).
  final Widget? below;
  final VoidCallback? onTap;

  /// Ghi đè nhãn đọc màn hình của cả hàng.
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;

  /// Hàng đang ở bố cục xếp chồng (chữ > 125%).
  static bool stacksAmount(BuildContext context) => AppLayout.isLargeText(MediaQuery.textScalerOf(context));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final stacked = stacksAmount(context);

    final titleBlock = DefaultTextStyle.merge(
      style: text.titleMedium!.copyWith(color: scheme.onSurface),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      child: title,
    );
    final metaBlock = meta == null
        ? null
        : DefaultTextStyle.merge(
            style: text.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
            child: meta!,
          );
    final amountBlock = amount == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultTextStyle.merge(
                style: TextStyle(color: scheme.onSurface),
                child: amount!,
              ),
              if (amountCaption != null)
                DefaultTextStyle.merge(
                  style: text.bodySmall!.copyWith(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.end,
                  child: amountCaption!,
                ),
            ],
          );

    final textColumn = <Widget>[titleBlock, ?metaBlock];
    Widget content;
    if (stacked || amountBlock == null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...textColumn,
          if (amountBlock != null) ...[
            const SizedBox(height: Space.s1),
            Align(alignment: AlignmentDirectional.centerEnd, child: amountBlock),
          ],
          if (below != null) ...[const SizedBox(height: Space.s2), below!],
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: textColumn,
                ),
              ),
              const SizedBox(width: Space.s4),
              amountBlock,
            ],
          ),
          if (below != null) ...[const SizedBox(height: Space.s2), below!],
        ],
      );
    }

    Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppLayout.listRowTwoLineMinHeight),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              SizedBox.square(
                dimension: AppLayout.listLeadingSize,
                child: Center(child: leading),
              ),
              const SizedBox(width: Space.s4),
            ],
            Expanded(child: content),
          ],
        ),
      ),
    );
    if (onTap != null) row = InkWell(onTap: onTap, child: row);
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        label: semanticLabel,
        excludeSemantics: semanticLabel != null,
        child: row,
      ),
    );
  }
}
