import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  const pet = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12);
  const study = CustomCategory(id: 'c2', name: '자기계발', baseCategoryId: 9);

  Transaction tx({String? customCategoryId, int categoryId = 12}) => Transaction.create(
        amount: 1000,
        categoryId: categoryId,
        date: DateTime(2026, 9, 6),
        type: TransactionType.expense,
        customCategoryId: customCategoryId,
      );

  test('create assigns a uuid and keeps name/base', () {
    final c = CustomCategory.create(name: '반려동물', baseCategoryId: 12);
    expect(c.id, isNotEmpty);
    expect(c.name, '반려동물');
    expect(c.base, BudgetCategory.etc);
  });

  test('byId finds by id and returns null for unknown/null', () {
    const list = [pet, study];
    expect(list.byId('c2'), study);
    expect(list.byId('nope'), isNull);
    expect(list.byId(null), isNull);
  });

  test('labelFor prefers the custom name, falls back to the base label', () {
    const list = [pet, study];
    expect(list.labelFor(tx(customCategoryId: 'c1')), '반려동물');
    expect(list.labelFor(tx()), BudgetCategory.etc.label);
    // 지워진 카테고리를 가리키면 상위 기본 분류 이름으로 되돌아간다.
    expect(list.labelFor(tx(customCategoryId: 'gone')), BudgetCategory.etc.label);
  });

  test('maxNameLength is the shared client/server limit', () {
    expect(CustomCategory.maxNameLength, 10);
  });
}
