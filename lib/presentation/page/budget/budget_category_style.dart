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
        BudgetCategory.food => const CategoryStyle(Icons.restaurant, Palette.primaryNormal),
        BudgetCategory.alcoholTobacco => const CategoryStyle(Icons.local_bar, Color(0xFFA29A92)),
        BudgetCategory.clothing => const CategoryStyle(Icons.checkroom, Color(0xFFB8B0A8)),
        BudgetCategory.housing => const CategoryStyle(Icons.home_outlined, Color(0xFF8C857D)),
        BudgetCategory.household => const CategoryStyle(Icons.chair_outlined, Color(0xFFCFC8BF)),
        BudgetCategory.health => const CategoryStyle(Icons.favorite_outline, Color(0xFFDCD5CC)),
        BudgetCategory.transport => const CategoryStyle(Icons.directions_bus, Color(0xFFA29A92)),
        BudgetCategory.communication => const CategoryStyle(Icons.smartphone, Color(0xFFB8B0A8)),
        BudgetCategory.recreation => const CategoryStyle(Icons.movie_outlined, Color(0xFF8C857D)),
        BudgetCategory.education => const CategoryStyle(Icons.school_outlined, Color(0xFFCFC8BF)),
        BudgetCategory.diningOut => const CategoryStyle(Icons.lunch_dining, Color(0xFFE6E1D8)),
        BudgetCategory.etc => const CategoryStyle(Icons.more_horiz, Color(0xFFDCD5CC)),
      };
}
