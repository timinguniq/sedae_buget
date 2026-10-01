import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  const pet = CustomCategory(id: 'c1', name: '반려식물', baseCategoryId: 19);

  test('새 초안은 이름 없이 기타 아래에서 시작하고 저장할 수 없다', () {
    final d = CategoryDraft.create();
    expect(d.id, isNotEmpty);
    expect(d.isEdit, isFalse);
    expect(d.base, BudgetCategory.etc);
    expect(d.canSave, isFalse);
  });

  test('초안 하나는 몇 번을 바꿔도 같은 id로 저장한다', () {
    final d = CategoryDraft.create();
    final changed = d.withName('반려식물').pickBase(BudgetCategory.recreation);
    expect(changed.toCategory().id, d.id);
    expect(CategoryDraft.create().id, isNot(d.id));
  });

  test('이름은 앞뒤 공백을 떼고 저장한다', () {
    final c = CategoryDraft.create().withName('  반려식물 ').toCategory();
    expect(c.name, '반려식물');
    expect(c.base, BudgetCategory.etc);
  });

  test('다듬은 이름이 비었거나 최대 길이를 넘으면 저장하지 않는다', () {
    final d = CategoryDraft.create();
    expect(d.withName('   ').canSave, isFalse);
    expect(d.withName('a' * CategoryName.maxLength).canSave, isTrue);
    expect(d.withName(' ${'a' * CategoryName.maxLength} ').canSave, isTrue);
    expect(d.withName('a' * (CategoryName.maxLength + 1)).canSave, isFalse);
  });

  // 입력 칸은 보이는 글자로 10자까지 받는다. 이전에는 초안이 UTF-16으로 세어 이모지 6개(12)를 막았다.
  test('이름은 보이는 글자로 센다(이모지·이어 붙인 이모지도 한 자)', () {
    final d = CategoryDraft.create();
    expect(d.withName('🐶' * 10).canSave, isTrue);
    expect(d.withName('👨‍👩‍👧' * 10).canSave, isTrue);
    expect(d.withName('🐶' * 11).canSave, isFalse);
  });

  test('고치는 초안은 그 카테고리의 id·이름·상위 분류로 시작한다', () {
    final d = CategoryDraft.edit(pet);
    expect(d.isEdit, isTrue);
    expect(d.name, '반려식물');
    expect(d.base, BudgetCategory.etc);
    expect(d.pickBase(BudgetCategory.groceries).toCategory(),
        const CustomCategory(id: 'c1', name: '반려식물', baseCategoryId: 1));
  });
}
