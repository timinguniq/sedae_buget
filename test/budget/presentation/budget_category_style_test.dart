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

  // 목록과 칩에서 분류를 아이콘으로 구별하므로 두 분류가 같은 아이콘을 쓰지 않는다.
  test('every category has a distinct icon', () {
    final icons = BudgetCategory.values.map((c) => c.style.icon).toSet();
    expect(icons, hasLength(BudgetCategory.values.length));
  });
}
