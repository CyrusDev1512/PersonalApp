import 'package:flutter/material.dart';

import '../models/category.dart';
import 'list_group.dart';

/// Icon Material cho các danh mục mặc định của máy chủ (`system_key`, backend/app/seed.py).
///
/// Danh mục mặc định dùng icon của app (một bộ icon nhất quán); emoji chỉ còn cho danh mục người dùng tự tạo
/// (đó là dữ liệu của họ). DESIGN.md › Components: không dùng emoji hay ký tự Unicode làm icon giao diện.
const Map<String, IconData> systemCategoryIcons = {
  'food': Icons.restaurant_outlined,
  'rent': Icons.home_outlined,
  'transport': Icons.two_wheeler_outlined,
  'shopping': Icons.shopping_cart_outlined,
  'bills': Icons.receipt_outlined,
  'savings': Icons.savings_outlined,
  'other': Icons.category_outlined,
  'income': Icons.account_balance_wallet_outlined,
  'refund': Icons.undo_outlined,
  'transfer': Icons.swap_horiz_outlined,
};

/// Hình đại diện của một danh mục: icon Material (danh mục mặc định) hoặc emoji (danh mục tự tạo).
@immutable
class CategoryVisual {
  const CategoryVisual({this.icon, this.emoji});

  /// [systemKey] có trong [systemCategoryIcons] thì dùng icon; ngược lại dùng [emoji] nếu có.
  factory CategoryVisual.resolve({String? systemKey, String? emoji}) {
    final icon = systemKey == null ? null : systemCategoryIcons[systemKey];
    if (icon != null) return CategoryVisual(icon: icon);
    final e = emoji?.trim();
    return CategoryVisual(emoji: (e == null || e.isEmpty) ? null : e);
  }

  factory CategoryVisual.of(Category category) =>
      CategoryVisual.resolve(systemKey: category.systemKey, emoji: category.icon);

  final IconData? icon;
  final String? emoji;

  bool get isEmpty => icon == null && emoji == null;

  /// Nhãn chữ cho chip / dòng phụ: danh mục tự tạo giữ emoji ("🎮 Giải trí"), danh mục mặc định chỉ có tên
  /// (icon đi riêng, vd. `avatar` của chip).
  String label(String name) => emoji == null ? name : '$emoji $name';

  /// Icon nhỏ cho chip (`avatar`), `null` khi danh mục dùng emoji trong nhãn.
  Widget? chipAvatar() => icon == null ? null : Icon(icon, size: 18);
}

/// Đĩa 40 dp đầu hàng cho một danh mục; không có danh mục thì [fallbackIcon].
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.visual, this.fallbackIcon = Icons.label_outline});

  factory CategoryAvatar.of(Category category, {Key? key}) =>
      CategoryAvatar(key: key, visual: CategoryVisual.of(category));

  final CategoryVisual visual;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    if (visual.icon != null) return LeadingDisc(icon: visual.icon);
    if (visual.emoji != null) return LeadingDisc(text: visual.emoji);
    return LeadingDisc(icon: fallbackIcon);
  }
}
