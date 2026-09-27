import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  test('상위 분류는 baseCategoryId의 기본 분류다', () {
    const c = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12);
    expect(c.base, BudgetCategory.etc);
  });

  test('maxNameLength is the shared client/server limit', () {
    expect(CustomCategory.maxNameLength, 10);
  });
}
