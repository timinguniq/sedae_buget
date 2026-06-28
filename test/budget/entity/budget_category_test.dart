import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/budget/budget_category.dart';

void main() {
  test('has exactly 12 categories with ids 1..12', () {
    expect(BudgetCategory.values.length, 12);
    expect(BudgetCategory.values.map((e) => e.id).toList(),
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
  });

  test('fromId returns matching category', () {
    expect(BudgetCategory.fromId(7), BudgetCategory.transport);
    expect(BudgetCategory.fromId(1).label, '식료품·비주류음료');
  });
}
