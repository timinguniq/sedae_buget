import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

const _pet = CustomCategory(id: 'c1', name: '반려식물', base: BudgetCategory.etc);
const _study = CustomCategory(id: 'c2', name: '자기계발', base: BudgetCategory.recreation);

final _day = DateTime(2026, 6, 5);

Transaction _saved({BudgetCategory base = BudgetCategory.groceries, String? customCategoryId, String? memo}) =>
    Transaction(
      id: 't1',
      amount: 1000,
      base: base,
      date: _day,
      type: TransactionType.expense,
      memo: memo,
      customCategoryId: customCategoryId,
      createdAt: DateTime(2026, 6, 5, 9),
      updatedAt: DateTime(2026, 6, 5, 9),
    );

void main() {
  group('새 거래', () {
    test('지출·장보기·금액 0으로 시작하고 저장할 수 없다', () {
      final d = TransactionDraft.create(_day);
      expect(d.isEdit, isFalse);
      expect(d.type, TransactionType.expense);
      expect(d.base, BudgetCategory.groceries);
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
          .withDate(DateTime(2026, 6, 7))
          .pickBase(BudgetCategory.transport)
          .withMemo('  버스  ')
          .toTransaction(const CategoryCatalog());
      expect(tx.amount, 12000);
      expect(tx.type, TransactionType.expense);
      expect(tx.date, DateTime(2026, 6, 7));
      expect(tx.base, BudgetCategory.transport);
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
  // 새 거래는 지출만 적으므로 수입 초안은 전에 적은 수입을 고칠 때만 생긴다.
  group('수입', () {
    const catalog = CategoryCatalog([_pet]);
    final income = _saved().copyWith(type: TransactionType.income);

    test('지출만 카테고리를 고른다', () {
      expect(TransactionDraft.create(_day).hasCategory, isTrue);
      expect(TransactionDraft.edit(income, catalog).hasCategory, isFalse);
    });

    test('수입의 이름은 수입이다', () {
      final d = TransactionDraft.edit(income, catalog).pickCustom(_pet);
      expect(d.label(catalog), '수입');
    });

    test('수입은 사용자 카테고리 없이 저장한다', () {
      final tx = TransactionDraft.edit(income, catalog).pickCustom(_pet).toTransaction(catalog);
      expect(tx.type, TransactionType.income);
      expect(tx.customCategoryId, isNull);
    });
  });

  group('카테고리 고르기', () {
    test('사용자 카테고리를 고르면 그 상위 분류가 함께 정해진다', () {
      final d = TransactionDraft.create(_day).pickCustom(_pet);
      expect(d.customCategoryId, 'c1');
      expect(d.base, BudgetCategory.etc);
      expect(d.label(const CategoryCatalog([_pet])), '반려식물');
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
      expect(tx.base, BudgetCategory.etc);
    });
  });

  // 보고 있는 달은 이번 달보다 뒤로 갈 수 없어서, 미래로 적힌 거래는 어느 화면에도 보이지 않는다.
  group('고를 수 있는 가장 늦은 날짜', () {
    final today = DateTime(2026, 9, 26, 14);

    test('새 거래는 오늘까지다', () {
      expect(TransactionDraft.create(today).latestDate(today), today);
    });

    // 이미 미래로 적힌 거래를 고칠 때 그 날짜를 고를 수 없으면 날짜 선택기가 열리지 않는다.
    test('이미 미래로 적힌 거래를 고칠 때는 그 날짜까지다', () {
      final future = _saved().copyWith(date: DateTime(2026, 10, 5));
      expect(TransactionDraft.edit(future, const CategoryCatalog()).latestDate(today), DateTime(2026, 10, 5));
    });

    test('지난 날짜로 적힌 거래를 고칠 때는 오늘까지다', () {
      expect(TransactionDraft.edit(_saved(), const CategoryCatalog()).latestDate(today), today);
    });
  });

  group('고를 수 있는 가장 이른 날짜', () {
    test('보고 있는 달의 하한(2020년 1월 1일)이다', () {
      expect(TransactionDraft.create(DateTime(2026, 9, 5)).earliestDate, DateTime(2020, 1, 1));
    });

    // 이전에는 날짜 선택이 2020년부터라 그보다 이른 거래를 고치면 날짜 선택이 assert로 멈췄다.
    test('그보다 이른 거래를 고칠 때는 그 날짜까지다', () {
      final old = _saved().copyWith(date: DateTime(2019, 12, 27, 13, 5));
      expect(TransactionDraft.edit(old, const CategoryCatalog()).earliestDate, DateTime(2019, 12, 27));
    });
  });

  group('기존 거래 고치기', () {
    // 수입은 카테고리가 없다. 서버가 수입에 사용자 카테고리 id를 적었어도 목록으로 판정하지 않고
    // 읽어 둔 분류 그대로 둔다(모르는 분류 id는 DTO가 기타로 읽는다).
    test('수입을 고칠 때는 분류를 판정하지 않는다', () {
      final income = _saved(base: BudgetCategory.shopping, customCategoryId: 'c1')
          .copyWith(type: TransactionType.income);
      final d = TransactionDraft.edit(income, const CategoryCatalog([_pet]));
      expect(d.hasCategory, isFalse);
      expect(d.base, BudgetCategory.shopping);
      expect(d.customCategoryId, isNull);
    });

    // 서버도 앱도 수입의 분류를 쓰지 않으므로 읽어 둔 값을 그대로 보낸다.
    test('수입을 다시 저장해도 읽어 둔 분류 그대로다', () {
      final income = _saved(base: BudgetCategory.shopping).copyWith(type: TransactionType.income);
      final tx = TransactionDraft.edit(income, const CategoryCatalog()).toTransaction(const CategoryCatalog());
      expect(tx.base, BudgetCategory.shopping);
    });

    test('거래의 값으로 시작한다', () {
      final d = TransactionDraft.edit(_saved(memo: '점심'), const CategoryCatalog());
      expect(d.isEdit, isTrue);
      expect(d.amount, 1000);
      expect(d.memo, '점심');
      expect(d.base, BudgetCategory.groceries);
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

    // 자기계발을 기타 → 취미·여가로 옮기기 전에 적힌 거래를 다시 저장해도 옛 분류가 되살아나지 않는다.
    test('사용자 카테고리의 현재 상위 분류를 따른다', () {
      const catalog = CategoryCatalog([_study]);
      final stale = _saved(base: BudgetCategory.etc, customCategoryId: 'c2');
      final d = TransactionDraft.edit(stale, catalog);
      expect(d.base, BudgetCategory.recreation);

      final tx = d.toTransaction(catalog);
      expect(tx.customCategoryId, 'c2');
      expect(tx.base, BudgetCategory.recreation);
    });

    test('목록을 모르면 고른 그대로 저장한다', () {
      final tx = TransactionDraft.edit(_saved(customCategoryId: 'c1'), const CategoryCatalog())
          .toTransaction(const CategoryCatalog.unknown());
      expect(tx.customCategoryId, 'c1');
      expect(tx.base, BudgetCategory.groceries);
    });

    // 이전에는 '모름'을 null로, 다 읽은 빈 목록을 []로 나타내 두 값의 뜻이 반대였다.
    // 화면이 만든 빈 목록이 저장으로 넘어가면 사용자 카테고리가 조용히 떨어졌다.
    test('다 읽은 빈 목록이면 사용자 카테고리를 떼고, 모르면 남긴다', () {
      final draft = TransactionDraft.edit(_saved(customCategoryId: 'c1'), const CategoryCatalog.unknown());
      expect(draft.toTransaction(const CategoryCatalog()).customCategoryId, isNull);
      expect(draft.toTransaction(const CategoryCatalog.unknown()).customCategoryId, 'c1');
    });

    // 지워진 사용자 카테고리를 계속 가리키면 어디에도 보이지 않는 id가 남는다.
    test('지워진 사용자 카테고리는 거래에 적힌 기본 분류로 되돌린다', () {
      final orphan = _saved(base: BudgetCategory.etc, customCategoryId: 'gone');
      final tx = TransactionDraft.edit(orphan, const CategoryCatalog([_pet]))
          .toTransaction(const CategoryCatalog([_pet]));
      expect(tx.customCategoryId, isNull);
      expect(tx.base, BudgetCategory.etc);
    });
  });
}
