import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/budget/budget_category.dart';
import 'package:sedae_budget/presentation/page/budget/budget_category_style.dart';

void main() {
  test('every category has an icon and color', () {
    for (final c in BudgetCategory.values) {
      final s = c.style;
      expect(s.icon, isNotNull);
    }
  });
}
