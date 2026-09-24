import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  const pet = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12);
  const study = CustomCategory(id: 'c2', name: '자기계발', baseCategoryId: 9);
  const catalog = CategoryCatalog([pet, study]);

  Transaction tx({int categoryId = 12, String? customCategoryId}) => Transaction.create(
        amount: 1000,
        categoryId: categoryId,
        date: DateTime(2026, 9, 6),
        type: TransactionType.expense,
        customCategoryId: customCategoryId,
      );

  test('기본 분류 거래는 적힌 기본 분류 그대로', () {
    final c = catalog.of(tx(categoryId: 7));
    expect(c.base, BudgetCategory.transport);
    expect(c.custom, isNull);
    expect(c.label, BudgetCategory.transport.label);
  });

  test('사용자 카테고리 거래는 그 이름으로 보이고 그 상위 분류로 집계된다', () {
    final c = catalog.of(tx(customCategoryId: 'c1'));
    expect(c.custom, pet);
    expect(c.base, BudgetCategory.etc);
    expect(c.label, '반려동물');
  });

  test('거래에 적힌 기본 분류가 낡았으면 사용자 카테고리의 현재 상위 분류를 따른다', () {
    // 자기계발을 오락·문화(9)로 옮기기 전에 기타(12)로 저장된 거래.
    final c = catalog.of(tx(categoryId: 12, customCategoryId: 'c2'));
    expect(c.base, BudgetCategory.recreation);
    expect(c.label, '자기계발');
  });

  test('지워진 사용자 카테고리를 가리키면 적힌 기본 분류로 돌아간다', () {
    final c = catalog.of(tx(categoryId: 12, customCategoryId: 'gone'));
    expect(c.custom, isNull);
    expect(c.base, BudgetCategory.etc);
    expect(c.label, BudgetCategory.etc.label);
  });

  test('사용자 카테고리를 모르면(목록 없음) 기본 분류로만 판정한다', () {
    final c = const CategoryCatalog().of(tx(customCategoryId: 'c1'));
    expect(c.custom, isNull);
    expect(c.base, BudgetCategory.etc);
  });

  test('byId는 id로 찾고 null·없는 id는 null', () {
    expect(catalog.byId('c2'), study);
    expect(catalog.byId('nope'), isNull);
    expect(catalog.byId(null), isNull);
  });
}
