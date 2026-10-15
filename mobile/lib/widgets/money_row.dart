import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/tokens.dart';

/// Hàng danh sách có số tiền ở cuối (giao dịch, mục tiêu, tài khoản): DESIGN.md › Lists › Row anatomy.
///
/// Đĩa 40 dp đầu hàng, [title] (`titleMedium`, tối đa 3 dòng), [meta] (`bodySmall`, `onSurfaceVariant`), số
/// tiền [amount] căn phải kèm [amountCaption] nhỏ bên dưới, và [below] (pill trạng thái, thanh tiến độ…) dưới
/// phần chữ.
///
/// Chỉ tiêu đề đứng cạnh số tiền; dòng phụ luôn rộng hết hàng, dưới tiêu đề và số tiền (không bị bóp vào cột
/// hẹp cạnh số tiền). Khi chỗ cạnh số tiền hẹp hơn 128 dp (điện thoại 360 dp) mà tiêu đề ở đó phải xuống dòng
/// nhiều hơn khi rộng hết hàng, hàng đó chuyển sang bố cục xếp chồng. Chữ lớn hơn 125%
/// (`textScaler.scale(16) > 20`) thì mọi hàng xếp chồng: tiêu đề và dòng phụ chiếm hết bề ngang, số tiền xuống
/// dòng riêng dưới dòng phụ, vẫn căn phải để các số tiền thành một cột. Không dùng `ListTile.trailing` (nó bóp
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
      maxLines: 3,
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

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TitleAmountLayout(
          textDirection: Directionality.of(context),
          stacked: stacked,
          title: titleBlock,
          meta: metaBlock,
          amount: amountBlock,
        ),
        if (below != null) ...[const SizedBox(height: Space.s2), below!],
      ],
    );

    Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppLayout.listRowTwoLineMinHeight),
      child: Padding(
        padding: padding,
        child: Row(
          // Hàng cao (pill, chữ lớn): đĩa đầu hàng đứng ở đầu như danh sách M3 ba dòng, không trôi giữa hàng.
          crossAxisAlignment: CrossAxisAlignment.start,
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
    // Nhãn riêng thay cho chữ con, nhưng thao tác chạm của InkWell vẫn phải còn trong nút gộp (TalkBack kích
    // hoạt được): InkWell bọc ngoài phần bị loại khỏi semantics.
    if (semanticLabel != null) row = Semantics(label: semanticLabel, excludeSemantics: true, child: row);
    if (onTap != null) row = InkWell(onTap: onTap, child: row);
    return MergeSemantics(
      child: Semantics(button: onTap != null, child: row),
    );
  }
}

enum _Slot { title, meta, amount }

/// Tiêu đề + số tiền trên cùng một dòng (khi tiêu đề vừa), dòng phụ rộng hết hàng ở dưới.
///
/// - Cạnh nhau: tiêu đề ở đầu, số tiền căn cuối, cách 16 dp; dòng phụ dưới phần cao hơn của hai thứ đó.
/// - Xếp chồng ([stacked], hoặc chỗ cạnh số tiền < [minBesideWidth] mà tiêu đề ở đó cần thêm dòng): tiêu đề,
///   dòng phụ, rồi số tiền căn cuối trên dòng riêng (cách 4 dp).
class _TitleAmountLayout extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  const _TitleAmountLayout({
    required this.textDirection,
    required this.stacked,
    required this.title,
    this.meta,
    this.amount,
  });

  /// Chỗ cạnh số tiền tối thiểu để tiêu đề dài vẫn đứng cạnh (dưới mức này tiêu đề dài xuống dòng quá nhiều).
  static const double minBesideWidth = 128;

  final TextDirection textDirection;
  final bool stacked;
  final Widget title;
  final Widget? meta;
  final Widget? amount;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.title => title,
    _Slot.meta => meta,
    _Slot.amount => amount,
  };

  @override
  _RenderTitleAmount createRenderObject(BuildContext context) => _RenderTitleAmount(textDirection, stacked);

  @override
  void updateRenderObject(BuildContext context, _RenderTitleAmount renderObject) {
    renderObject
      ..textDirection = textDirection
      ..stacked = stacked;
  }
}

class _RenderTitleAmount extends RenderBox with SlottedContainerRenderObjectMixin<_Slot, RenderBox> {
  _RenderTitleAmount(this._textDirection, this._stacked);

  static const double _gap = Space.s4;
  static const double _stackedAmountGap = Space.s1;

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  bool _stacked;
  set stacked(bool value) {
    if (value == _stacked) return;
    _stacked = value;
    markNeedsLayout();
  }

  RenderBox? get _title => childForSlot(_Slot.title);
  RenderBox? get _meta => childForSlot(_Slot.meta);
  RenderBox? get _amount => childForSlot(_Slot.amount);

  @override
  Iterable<RenderBox> get children => [?_title, ?_meta, ?_amount];

  // Đọc màn hình: tiêu đề, dòng phụ, rồi số tiền (như thứ tự đọc của hàng cũ).
  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) => children.forEach(visitor);

  /// Bố cục cạnh nhau hay xếp chồng ở bề rộng [width], với bề rộng số tiền [amountWidth].
  bool _sideBySide(double width, double amountWidth) {
    final title = _title;
    if (_stacked || title == null || _amount == null) return false;
    final beside = width - _gap - amountWidth;
    if (beside <= 0) return false;
    if (beside >= _TitleAmountLayout.minBesideWidth) return true;
    // Chỗ hẹp: chỉ đứng cạnh khi tiêu đề không phải xuống dòng nhiều hơn so với khi rộng hết hàng.
    return title.getMaxIntrinsicHeight(beside) <= title.getMaxIntrinsicHeight(width) + 0.5;
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    // Không bị giới hạn bề ngang (hiếm, vd. đo bề rộng tự nhiên): rộng bằng một dòng tiêu đề + số tiền.
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : getMaxIntrinsicWidth(double.infinity);
    Size place(RenderBox? child, BoxConstraints c) {
      if (child == null) return Size.zero;
      return dry ? ChildLayoutHelper.dryLayoutChild(child, c) : ChildLayoutHelper.layoutChild(child, c);
    }

    final amountSize = place(_amount, BoxConstraints(maxWidth: width));
    final side = _sideBySide(width, amountSize.width);
    final titleWidth = side ? width - _gap - amountSize.width : width;
    final titleSize = place(_title, BoxConstraints(maxWidth: titleWidth));
    final metaSize = place(_meta, BoxConstraints(maxWidth: width));

    double x(double childWidth, {required bool end}) =>
        (end == (_textDirection == TextDirection.ltr)) ? width - childWidth : 0;

    double height;
    Offset titleAt = Offset(x(titleSize.width, end: false), 0);
    Offset amountAt;
    Offset metaAt;
    if (side) {
      final top = titleSize.height > amountSize.height ? titleSize.height : amountSize.height;
      amountAt = Offset(x(amountSize.width, end: true), 0);
      metaAt = Offset(x(metaSize.width, end: false), top);
      height = metaAt.dy + metaSize.height;
    } else {
      metaAt = Offset(x(metaSize.width, end: false), titleSize.height);
      final amountTop = metaAt.dy + metaSize.height + (_amount == null ? 0 : _stackedAmountGap);
      amountAt = Offset(x(amountSize.width, end: true), amountTop);
      height = amountTop + amountSize.height;
    }
    if (!dry) {
      void put(RenderBox? child, Offset offset) {
        if (child != null) (child.parentData! as BoxParentData).offset = offset;
      }

      put(_title, titleAt);
      put(_meta, metaAt);
      put(_amount, amountAt);
    }
    return constraints.constrain(Size(width, height));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _layout(constraints, dry: true);

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  @override
  double computeMinIntrinsicWidth(double height) {
    var w = 0.0;
    for (final c in children) {
      final cw = c.getMinIntrinsicWidth(double.infinity);
      if (cw > w) w = cw;
    }
    return w;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final title = _title?.getMaxIntrinsicWidth(double.infinity) ?? 0;
    final amount = _amount?.getMaxIntrinsicWidth(double.infinity) ?? 0;
    final meta = _meta?.getMaxIntrinsicWidth(double.infinity) ?? 0;
    final line = title + (amount > 0 ? _gap + amount : 0);
    return line > meta ? line : meta;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _layout(BoxConstraints(maxWidth: width), dry: true).height;

  @override
  double computeMaxIntrinsicHeight(double width) => _layout(BoxConstraints(maxWidth: width), dry: true).height;

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(child, offset + (child.parentData! as BoxParentData).offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children) {
      final offset = (child.parentData! as BoxParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) => child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
