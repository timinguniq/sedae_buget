import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

const _pet = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12);
const _study = CustomCategory(id: 'c2', name: '자기계발', baseCategoryId: 9);

final _day = DateTime(2026, 6, 5);

Transaction _saved({int categoryId = 1, String? customCategoryId, String? memo}) => Transaction(
      id: 't1',
      amount: 1000,
      categoryId: categoryId,
      date: _day,
      type: TransactionType.expense,
      memo: memo,
      customCategoryId: customCategoryId,
      createdAt: DateTime(2026, 6, 5, 9),
      updatedAt: DateTime(2026, 6, 5, 9),
    );

void main() {
  group('새 거래', () {
    test('지출·식비·금액 0으로 시작하고 저장할 수 없다', () {
      final d = TransactionDraft.create(_day);
      expect(d.isEdit, isFalse);
      expect(d.type, TransactionType.expense);
      expect(d.base, BudgetCategory.food);
      expect(d.customCategoryId, isNull);
      expect(d.amount, 0);
      expect(d.canSave, isFalse);
    });

    test('금액이 있으면 저장할 수 있다', () {
      expect(TransactionDraft.create(_day).withAmount(1).canSave, isTrue);
    });

    test('입력한 값으로 새 거래를 만든다', () {
      final tx = TransactionDraft.create(_day)
          .withAmount(12000)
          .withType(TransactionType.income)
          .withDate(DateTime(2026, 6, 7))
          .pickBase(BudgetCategory.transport)
          .withMemo('  버스  ')
          .toTransaction(const CategoryCatalog());
      expect(tx.amount, 12000);
      expect(tx.type, TransactionType.income);
      expect(tx.date, DateTime(2026, 6, 7));
      expect(tx.categoryId, BudgetCategory.transport.id);
      expect(tx.customCategoryId, isNull);
      expect(tx.memo, '버스');
    });

    test('빈 메모는 저장하지 않는다', () {
      final tx = TransactionDraft.create(_day).withAmount(1).withMemo('   ')
          .toTransaction(const CategoryCatalog());
      expect(tx.memo, isNull);
    });
  });

  // 저장을 다시 시도해도(두 번 누름·시간 초과 뒤 재시도) 서버에는 거래가 하나만 생겨야 한다.
  // 서버 계약은 클라이언트 id로 멱등인 PUT이다.
  group('새 거래의 id', () {
    test('같은 초안은 몇 번 저장해도 같은 id다', () {
      final d = TransactionDraft.create(_day).withAmount(1000);
      final first = d.toTransaction(const CategoryCatalog());
      final again = d.withMemo('점심').pickBase(BudgetCategory.transport)
          .toTransaction(const CategoryCatalog());
      expect(again.id, first.id);
    });

    test('다른 초안은 다른 id다', () {
      final a = TransactionDraft.create(_day).toTransaction(const CategoryCatalog());
      final b = TransactionDraft.create(_day).toTransaction(const CategoryCatalog());
      expect(a.id, isNot(b.id));
    });
  });

  // 수입은 카테고리가 없다. 이전에는 수입에도 지출 카테고리(기본값 식료품)가 붙어 그 분류에 섞였다.
  group('수입', () {
    test('지출만 카테고리를 고른다', () {
      final d = TransactionDraft.create(_day);
      expect(d.hasCategory, isTrue);
      expect(d.withType(TransactionType.income).hasCategory, isFalse);
    });

    test('수입의 이름은 수입이다', () {
      final d = TransactionDraft.create(_day).pickCustom(_pet).withType(TransactionType.income);
      expect(d.label(const CategoryCatalog([_pet])), '수입');
    });

    test('수입은 사용자 카테고리 없이 저장한다', () {
      final tx = TransactionDraft.create(_day).withAmount(1).pickCustom(_pet)
          .withType(TransactionType.income).toTransaction(const CategoryCatalog([_pet]));
      expect(tx.type, TransactionType.income);
      expect(tx.customCategoryId, isNull);
    });

    test('지출로 되돌리면 고른 카테고리가 그대로다', () {
      final d = TransactionDraft.create(_day).pickCustom(_pet)
          .withType(TransactionType.income).withType(TransactionType.expense);
      expect(d.label(const CategoryCatalog([_pet])), '반려동물');
    });
  });

  group('카테고리 고르기', () {
    test('사용자 카테고리를 고르면 그 상위 분류가 함께 정해진다', () {
      final d = TransactionDraft.create(_day).pickCustom(_pet);
      expect(d.customCategoryId, 'c1');
      expect(d.base, BudgetCategory.etc);
      expect(d.label(const CategoryCatalog([_pet])), '반려동물');
    });

    test('기본 분류를 고르면 사용자 카테고리 선택이 풀린다', () {
      final d = TransactionDraft.create(_day).pickCustom(_pet).pickBase(BudgetCategory.transport);
      expect(d.customCategoryId, isNull);
      expect(d.base, BudgetCategory.transport);
      expect(d.label(const CategoryCatalog([_pet])), BudgetCategory.transport.label);
    });

    test('목록에 아직 없는 사용자 카테고리는 상위 분류 이름으로 보인다', () {
      final d = TransactionDraft.create(_day).pickCustom(_pet);
      expect(d.label(const CategoryCatalog()), BudgetCategory.etc.label);
    });

    test('고른 사용자 카테고리와 상위 분류를 함께 저장한다', () {
      final tx = TransactionDraft.create(_day).withAmount(1000).pickCustom(_pet)
          .toTransaction(const CategoryCatalog([_pet]));
      expect(tx.customCategoryId, 'c1');
      expect(tx.categoryId, BudgetCategory.etc.id);
    });
  });

  group('기존 거래 고치기', () {
    test('거래의 값으로 시작한다', () {
      final d = TransactionDraft.edit(_saved(memo: '점심'), const CategoryCatalog());
      expect(d.isEdit, isTrue);
      expect(d.amount, 1000);
      expect(d.memo, '점심');
      expect(d.base, BudgetCategory.food);
    });

    test('같은 거래(id·생성 시각)를 고친 값으로 저장한다', () {
      final original = _saved();
      final tx = TransactionDraft.edit(original, const CategoryCatalog())
          .withAmount(2500)
          .toTransaction(const CategoryCatalog());
      expect(tx.id, original.id);
      expect(tx.createdAt, original.createdAt);
      expect(tx.amount, 2500);
    });

    // 자기계발을 기타 → 오락·문화로 옮기기 전에 적힌 거래를 다시 저장해도 옛 분류가 되살아나지 않는다.
    test('사용자 카테고리의 현재 상위 분류를 따른다', () {
      const catalog = CategoryCatalog([_study]);
      final stale = _saved(categoryId: BudgetCategory.etc.id, customCategoryId: 'c2');
      final d = TransactionDraft.edit(stale, catalog);
      expect(d.base, BudgetCategory.recreation);

      final tx = d.toTransaction(catalog);
      expect(tx.customCategoryId, 'c2');
      expect(tx.categoryId, BudgetCategory.recreation.id);
    });

    test('목록을 모르면 고른 그대로 저장한다', () {
      final tx = TransactionDraft.edit(_saved(customCategoryId: 'c1'), const CategoryCatalog())
          .toTransaction(null);
      expect(tx.customCategoryId, 'c1');
      expect(tx.categoryId, BudgetCategory.food.id);
    });

    // 지워진 사용자 카테고리를 계속 가리키면 어디에도 보이지 않는 id가 남는다.
    test('지워진 사용자 카테고리는 거래에 적힌 기본 분류로 되돌린다', () {
      final orphan = _saved(categoryId: BudgetCategory.etc.id, customCategoryId: 'gone');
      final tx = TransactionDraft.edit(orphan, const CategoryCatalog([_pet]))
          .toTransaction(const CategoryCatalog([_pet]));
      expect(tx.customCategoryId, isNull);
      expect(tx.categoryId, BudgetCategory.etc.id);
    });
  });
}
