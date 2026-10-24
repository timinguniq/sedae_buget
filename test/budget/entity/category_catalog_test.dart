import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  const pet = CustomCategory(id: 'c1', name: '반려식물', base: BudgetCategory.etc);
  const study = CustomCategory(id: 'c2', name: '자기계발', base: BudgetCategory.recreation);
  const catalog = CategoryCatalog([pet, study]);

  Transaction tx({BudgetCategory base = BudgetCategory.etc, String? customCategoryId}) => Transaction.create(
        amount: 1000,
        base: base,
        date: DateTime(2026, 9, 6),
        type: TransactionType.expense,
        customCategoryId: customCategoryId,
      );

  test('기본 분류 거래는 적힌 기본 분류 그대로', () {
    final c = catalog.of(tx(base: BudgetCategory.transport));
    expect(c.base, BudgetCategory.transport);
    expect(c.custom, isNull);
    expect(c.label, BudgetCategory.transport.label);
  });

  test('사용자 카테고리 거래는 그 이름으로 보이고 그 상위 분류로 집계된다', () {
    final c = catalog.of(tx(customCategoryId: 'c1'));
    expect(c.custom, pet);
    expect(c.base, BudgetCategory.etc);
    expect(c.label, '반려식물');
  });

  test('거래에 적힌 기본 분류가 낡았으면 사용자 카테고리의 현재 상위 분류를 따른다', () {
    // 자기계발을 취미·여가(14)로 옮기기 전에 기타(19)로 저장된 거래.
    final c = catalog.of(tx(base: BudgetCategory.etc, customCategoryId: 'c2'));
    expect(c.base, BudgetCategory.recreation);
    expect(c.label, '자기계발');
  });

  test('지워진 사용자 카테고리를 가리키면 적힌 기본 분류로 돌아간다', () {
    final c = catalog.of(tx(base: BudgetCategory.etc, customCategoryId: 'gone'));
    expect(c.custom, isNull);
    expect(c.base, BudgetCategory.etc);
    expect(c.label, BudgetCategory.etc.label);
  });

  test('사용자 카테고리를 모르면 기본 분류로만 판정한다', () {
    const unknown = CategoryCatalog.unknown();
    expect(unknown.isComplete, isFalse);
    final c = unknown.of(tx(customCategoryId: 'c1'));
    expect(c.custom, isNull);
    expect(c.base, BudgetCategory.etc);
  });

  test('목록으로 만든 카탈로그는 다 읽은 것이다', () {
    expect(catalog.isComplete, isTrue);
    expect(const CategoryCatalog().isComplete, isTrue);
  });

  test('byId는 id로 찾고 null·없는 id는 null', () {
    expect(catalog.byId('c2'), study);
    expect(catalog.byId('nope'), isNull);
    expect(catalog.byId(null), isNull);
  });
}
