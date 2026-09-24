import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  test('create assigns a uuid and keeps name/base', () {
    final c = CustomCategory.create(name: '반려동물', baseCategoryId: 12);
    expect(c.id, isNotEmpty);
    expect(c.name, '반려동물');
    expect(c.base, BudgetCategory.etc);
  });

  test('maxNameLength is the shared client/server limit', () {
    expect(CustomCategory.maxNameLength, 10);
  });
}
