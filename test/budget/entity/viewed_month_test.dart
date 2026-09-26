import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

// 반려동물 → 기타(12), 자기계발 → 오락·문화(9)
const _pet = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12);
const _study = CustomCategory(id: 'c2', name: '자기계발', baseCategoryId: 9);

Transaction _expense(int amount, BudgetCategory c, {String? customCategoryId}) =>
    Transaction.create(
        amount: amount, categoryId: c.id, date: DateTime(2026, 9, 5),
        type: TransactionType.expense, customCategoryId: customCategoryId);

Transaction _income(int amount) => Transaction.create(
    amount: amount, categoryId: BudgetCategory.food.id, date: DateTime(2026, 9, 1),
    type: TransactionType.income);

ViewedMonth _month(
  List<Transaction> txs, {
  List<CustomCategory> customs = const [],
  int? profileIncome,
  DateTime? month,
}) =>
    ViewedMonth(
      month: month ?? DateTime(2026, 9),
      transactions: txs,
      catalog: CategoryCatalog(customs),
      profileIncome: profileIncome,
    );

void main() {
  group('지출', () {
    test('지출 합계와 건수는 수입을 빼고 센다', () {
      final m = _month([
        _expense(1000, BudgetCategory.transport),
        _expense(500, BudgetCategory.transport),
        _income(5000),
      ]);
      expect(m.expense, 1500);
      expect(m.expenseCount, 2);
    });

    // 거래에 적힌 기본 분류가 낡아도 또래 비교는 사용자 카테고리의 현재 상위 분류로 모은다.
    test('기본 분류별 합계는 사용자 카테고리 지출을 그 현재 상위 분류로 모은다', () {
      final m = _month([
        _expense(1000, BudgetCategory.transport),
        _expense(3000, BudgetCategory.etc, customCategoryId: 'c2'),
      ], customs: const [_study]);
      expect(m.byCategory[BudgetCategory.transport], 1000);
      expect(m.byCategory[BudgetCategory.recreation], 3000);
      expect(m.byCategory[BudgetCategory.etc], isNull);
    });

    // 수입은 카테고리가 없다. 이전에는 입력 기본값(식료품)으로 잡혀 카테고리 관리 건수와 내역 필터에 섞였다.
    test('수입은 어떤 분류의 합계·건수·필터·분석에도 들지 않는다', () {
      final m = _month([_income(3000000), _expense(1000, BudgetCategory.food)]);
      expect(m.byCategory[BudgetCategory.food], 1000);
      expect(m.inCategory(BudgetCategory.food).single.type, TransactionType.expense);
      expect(m.baseOnlyCount(BudgetCategory.food), 1);
      expect(m.breakdown.single.amount, 1000);
    });

    test('분류 필터는 사용자 카테고리 지출도 상위 분류로 모은다', () {
      final m = _month([
        _expense(1000, BudgetCategory.etc),
        _expense(2000, BudgetCategory.etc, customCategoryId: 'c1'),
        _expense(3000, BudgetCategory.transport),
      ], customs: const [_pet]);
      expect(m.inCategory(BudgetCategory.etc).map((t) => t.amount), [1000, 2000]);
    });

    // 분석 화면과 같은 기준: 사용자 카테고리로 뗀 지출만 빼고, 지워진 카테고리를 가리키는 지출은 기본 분류로 센다.
    test('기본 분류 건수는 사용자 카테고리로 뗀 지출을 빼고 센다', () {
      final m = _month([
        _expense(1000, BudgetCategory.etc),
        _expense(1000, BudgetCategory.etc, customCategoryId: 'c1'),
        _expense(1000, BudgetCategory.etc, customCategoryId: 'gone'),
      ], customs: const [_pet]);
      expect(m.baseOnlyCount(BudgetCategory.etc), 2);
    });

    test('topCategories는 지출이 많은 기본 분류를 n개까지 금액 내림차순으로 낸다', () {
      final m = _month([
        _expense(100, BudgetCategory.food),
        _expense(300, BudgetCategory.transport),
        _expense(200, BudgetCategory.health),
      ]);
      expect(m.topCategories(2).map((e) => e.key), [BudgetCategory.transport, BudgetCategory.health]);
    });
  });

  group('분석', () {
    test('사용자 카테고리를 기본 분류에서 떼어내 금액 내림차순으로 낸다', () {
      final m = _month([
        _expense(5000, BudgetCategory.etc),
        _expense(9000, BudgetCategory.etc, customCategoryId: 'c1'),
        _expense(1000, BudgetCategory.recreation, customCategoryId: 'c2'),
      ], customs: const [_pet, _study]);
      expect(m.breakdown.map((r) => r.custom?.name ?? r.base.label),
          ['반려동물', BudgetCategory.etc.label, '자기계발']);
      expect(m.breakdown.map((r) => r.amount), [9000, 5000, 1000]);
      // 사용자 카테고리 행도 상위 기본 분류를 들고 있다(또래 비교 기준).
      expect(m.breakdown.first.base, BudgetCategory.etc);
      // 기본 분류 합계는 사용자 카테고리 지출까지 모은 그대로다.
      expect(m.byCategory[BudgetCategory.etc], 14000);
    });

    test('쓰지 않은 사용자 카테고리는 빼고, 지워진 카테고리 지출은 기본 분류로 낸다', () {
      final m = _month([_expense(3000, BudgetCategory.etc, customCategoryId: 'gone')],
          customs: const [_pet]);
      expect(m.breakdown.single.custom, isNull);
      expect(m.breakdown.single.base, BudgetCategory.etc);
    });

    test('도넛 조각은 상위 n개와 나머지 합이다', () {
      final m = _month([
        for (final (i, c) in BudgetCategory.values.take(8).indexed) _expense(1000 * (8 - i), c),
      ]);
      final s = m.slices(6);
      expect(s.top.map((r) => r.amount), [8000, 7000, 6000, 5000, 4000, 3000]);
      expect(s.rest, 2000 + 1000);
      expect(_month([_expense(1000, BudgetCategory.food)]).slices(6).rest, 0);
    });
  });

  test('거래 이름: 지출은 카테고리 이름, 수입은 수입', () {
    final pet = _expense(1000, BudgetCategory.etc, customCategoryId: 'c1');
    final bus = _expense(1000, BudgetCategory.transport);
    final salary = _income(3000000);
    final m = _month([pet, bus, salary], customs: const [_pet]);
    expect(m.labelOf(pet), '반려동물');
    expect(m.labelOf(bus), BudgetCategory.transport.label);
    expect(m.labelOf(salary), '수입');
    expect(m.baseOf(pet), BudgetCategory.etc);
    expect(m.baseOf(salary), isNull);
  });

  group('소득·잔액·저축률', () {
    test('소득은 프로필 월소득이고, 없으면 이달 수입의 합계다', () {
      expect(_month([_income(1000000)], profileIncome: 3000000).income, 3000000);
      expect(_month([_income(1000000)], profileIncome: 0).income, 1000000);
      expect(_month([_income(1000000)]).income, 1000000);
      expect(_month([_expense(1000, BudgetCategory.food)]).income, isNull);
    });

    // 이전에는 홈 히어로가 거래 수입(₩0)을, 같은 화면의 저축률은 프로필 소득을 기준으로 했다.
    test('잔액은 소득에서 지출을 뺀 값이다', () {
      expect(_month([_expense(700000, BudgetCategory.food)], profileIncome: 3500000).balance, 2800000);
      expect(_month([_expense(700000, BudgetCategory.food)]).balance, isNull);
    });

    test('저축률은 반올림하고, 소득이 없으면 null, 지출이 소득보다 많으면 음수다', () {
      expect(_month([_expense(2100000, BudgetCategory.food)], profileIncome: 3000000).savingsRate, 30);
      expect(_month([_expense(500000, BudgetCategory.food)]).savingsRate, isNull);
      expect(_month([_expense(1200000, BudgetCategory.food)], profileIncome: 1000000).savingsRate, -20);
    });

    test('소득 대비 지출(%)은 저축률의 보수다', () {
      expect(_month([_expense(1200000, BudgetCategory.food)], profileIncome: 1000000).expenseRatio, 120);
      expect(_month([_expense(1000, BudgetCategory.food)]).expenseRatio, isNull);
    });
  });

  test('expenseOf는 지출만 더한다', () {
    expect(ViewedMonth.expenseOf([_expense(1000, BudgetCategory.food), _income(5000)]), 1000);
  });
}
