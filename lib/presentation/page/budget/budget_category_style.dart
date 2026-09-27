import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/budget/budget_category.dart';
import 'package:sedae_budget/theme/theme.dart';

class CategoryStyle {
  const CategoryStyle(this.icon, this.color);
  final IconData icon;
  final Color color;
}

extension BudgetCategoryStyleX on BudgetCategory {
  CategoryStyle get style => switch (this) {
        BudgetCategory.groceries => const CategoryStyle(Icons.shopping_basket_outlined, Palette.primaryNormal),
        BudgetCategory.diningOut => const CategoryStyle(Icons.lunch_dining, Color(0xFFE6E1D8)),
        BudgetCategory.cafe => const CategoryStyle(Icons.local_cafe_outlined, Color(0xFFB8B0A8)),
        BudgetCategory.drinks => const CategoryStyle(Icons.local_bar, Color(0xFFA29A92)),
        BudgetCategory.shopping => const CategoryStyle(Icons.checkroom, Color(0xFFB8B0A8)),
        BudgetCategory.beauty => const CategoryStyle(Icons.content_cut, Color(0xFFCFC8BF)),
        BudgetCategory.household => const CategoryStyle(Icons.chair_outlined, Color(0xFFCFC8BF)),
        BudgetCategory.housing => const CategoryStyle(Icons.home_outlined, Color(0xFF8C857D)),
        BudgetCategory.communication => const CategoryStyle(Icons.smartphone, Color(0xFFB8B0A8)),
        BudgetCategory.transport => const CategoryStyle(Icons.directions_bus, Color(0xFFA29A92)),
        BudgetCategory.car => const CategoryStyle(Icons.directions_car_outlined, Color(0xFF8C857D)),
        BudgetCategory.health => const CategoryStyle(Icons.favorite_outline, Color(0xFFDCD5CC)),
        BudgetCategory.education => const CategoryStyle(Icons.school_outlined, Color(0xFFCFC8BF)),
        BudgetCategory.recreation => const CategoryStyle(Icons.movie_outlined, Color(0xFF8C857D)),
        BudgetCategory.travel => const CategoryStyle(Icons.flight_outlined, Color(0xFFA29A92)),
        BudgetCategory.pet => const CategoryStyle(Icons.pets, Color(0xFFE6E1D8)),
        BudgetCategory.gifts => const CategoryStyle(Icons.card_giftcard, Color(0xFFDCD5CC)),
        BudgetCategory.finance => const CategoryStyle(Icons.account_balance_outlined, Color(0xFFB8B0A8)),
        BudgetCategory.etc => const CategoryStyle(Icons.more_horiz, Color(0xFFDCD5CC)),
      };
}
