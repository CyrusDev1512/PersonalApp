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

/// Emoji mặc định của các danh mục máy chủ tạo sẵn (backend/app/seed.py) → `system_key`. Dùng khi dữ liệu không
/// kèm `system_key` (mục tiêu chỉ có `category_icon`), để mục tiêu và giao dịch hiện danh mục cùng một kiểu.
const Map<String, String> systemCategoryEmoji = {
  '🍜': 'food',
  '🏠': 'rent',
  '🛵': 'transport',
  '🛒': 'shopping',
  '🧾': 'bills',
  '🐷': 'savings',
  '📦': 'other',
  '💰': 'income',
  '↩️': 'refund',
  '↔️': 'transfer',
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

  /// Chỉ biết emoji (mục tiêu): emoji mặc định của danh mục máy chủ → icon như ở Giao dịch; emoji khác → emoji.
  factory CategoryVisual.fromEmoji(String? emoji) {
    final e = emoji?.trim();
    return CategoryVisual.resolve(systemKey: e == null ? null : systemCategoryEmoji[e], emoji: e);
  }

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

/// Nội dung một mục danh mục trong ô chọn (form mục tiêu, nhập tay): icon + tên (danh mục mặc định) hoặc
/// "emoji + tên" (danh mục tự tạo), giống chip ở bảng phân loại.
class CategoryOptionLabel extends StatelessWidget {
  const CategoryOptionLabel(this.category, {super.key});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisual.of(category);
    final text = Text(visual.label(category.name), overflow: TextOverflow.ellipsis);
    if (visual.icon == null) return text;
    return Row(
      children: [
        Icon(visual.icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Flexible(child: text),
      ],
    );
  }
}
