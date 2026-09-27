import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

final _september = YearMonth.of(DateTime(2026, 9));

Transaction _expense(int amount, BudgetCategory c, {String? customCategoryId}) => Transaction.create(
    amount: amount, categoryId: c.id, date: DateTime(2026, 9, 5), type: TransactionType.expense,
    customCategoryId: customCategoryId);

Transaction _income(int amount) => Transaction.create(
    amount: amount, categoryId: BudgetCategory.etc.id, date: DateTime(2026, 9, 1), type: TransactionType.income);

/// 식료품 40만·교통 25만 평균, 월평균 100만, 저축률 20%, 표본 셋.
PeerStats _peer({int avg = 1000000, List<int> samples = const [700000, 900000, 1200000]}) => PeerStats(
      ageGroup: AgeGroup.thirties,
      avgMonthlyExpense: avg,
      avgSavingsRate: 0.2,
      avgByCategory: {BudgetCategory.food: 400000, BudgetCategory.transport: 250000},
      samples: samples,
    );

MonthOverview _overview(
  List<Transaction> txs, {
  PeerStats? peer,
  int? profileIncome,
  List<CustomCategory> customs = const [],
}) =>
    MonthOverview(
      month: ViewedMonth(
        month: _september,
        transactions: txs,
        catalog: CategoryCatalog(customs),
        profileIncome: profileIncome,
      ),
      peer: peer,
    );

/// 견준 결과. 견주지 않았으면 테스트가 실패한다.
PeerCompared _compared(MonthOverview o) => o.standing as PeerCompared;

void main() {
  test('또래와 견줘 총지출·순위·분류별·가장 큰 차이·저축률을 낸다', () {
    final o = _overview(
      [_expense(500000, BudgetCategory.food), _expense(300000, BudgetCategory.transport)],
      peer: _peer(),
      profileIncome: 1000000,
    );
    final c = _compared(o);
    expect(c.total?.percent, -20);
    expect(c.rank?.rank, 3); // 90만·120만이 더 많이 씀
    expect(o.category(BudgetCategory.food)?.percent, 25);
    expect(o.category(BudgetCategory.diningOut), isNull); // 또래 값 없음
    expect(o.largestGap?.category, BudgetCategory.food);
    expect(c.savings.mine, 20);
    expect(c.savings.peer, 20);
  });

  // 이전에는 지출 0원인 달을 비교 탭은 '내역을 추가하면…'으로, 홈은 '100% 덜·상위 100%'로,
  // 리포트는 '또래 상위 100%'로 서로 다르게 말했다.
  test('빈 달(지출 0원)은 또래와 견주지 않는다', () {
    final o = _overview([_income(3000000)], peer: _peer(), profileIncome: 3000000);
    expect(o.standing, isA<PeerEmptyMonth>());
    expect(o.category(BudgetCategory.food), isNull);
    expect(o.largestGap, isNull);
    expect(o.topCategories(3), isEmpty);
  });

  test('또래 통계를 못 읽었으면 비교는 모두 없고 내 값은 그대로다', () {
    final o = _overview([_expense(500000, BudgetCategory.food)], profileIncome: 1000000);
    expect(o.standing, isA<PeerUnavailable>());
    expect(o.month.expense, 500000);
    expect(o.peerTopCategory, isNull);
    expect(o.topCategories(3).single.peer, isNull);
  });

  // 또래 월평균·표본은 없어도 견준 것이다: 그 값만 비고 저축률 비교는 남는다.
  test('또래 월평균·표본이 없으면 총지출 비교·막대·순위만 없다', () {
    final c = _compared(_overview([_expense(1, BudgetCategory.food)],
        peer: _peer(avg: 0, samples: const []), profileIncome: 1000000));
    expect(c.total, isNull);
    expect(c.totalBars, isNull);
    expect(c.rank, isNull);
    expect(c.savings.peer, 20);
  });

  test('많이 쓴 분류는 금액 순으로 그 분류의 또래 비교와 함께 낸다', () {
    final o = _overview(
      [_expense(300000, BudgetCategory.food), _expense(500000, BudgetCategory.diningOut)],
      peer: _peer(),
    );
    final top = o.topCategories(3);
    expect(top.map((e) => e.category), [BudgetCategory.diningOut, BudgetCategory.food]);
    expect(top.map((e) => e.amount), [500000, 300000]);
    expect(top.first.peer, isNull); // 외식은 또래 값이 없다
    expect(top.last.peer?.percent, -25);
  });

  // 또래 비교는 기본 분류로만 한다. 사용자 카테고리로 뗀 행에는 또래 값을 붙이지 않는다.
  test('분석 행은 기본 분류 행만 또래와 견준다', () {
    const pet = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 1);
    final o = _overview(
      [_expense(100000, BudgetCategory.food), _expense(50000, BudgetCategory.food, customCategoryId: 'c1')],
      peer: _peer(),
      customs: const [pet],
    );
    final rows = o.analysisRows(6);
    expect(rows.map((r) => r.item?.label), [BudgetCategory.food.label, '반려동물']);
    expect(rows.first.peer?.mine, 100000);
    expect(rows.last.peer, isNull);
  });

  test('분석 행은 금액이 큰 n줄과 나머지를 묶은 줄이고, 합은 이달 지출이다', () {
    final o = _overview([
      for (final (i, c) in BudgetCategory.values.take(8).indexed) _expense(1000 * (8 - i), c),
    ], peer: _peer());
    final rows = o.analysisRows(6);
    expect(rows.map((r) => r.amount), [8000, 7000, 6000, 5000, 4000, 3000, 2000 + 1000]);
    expect(rows.last.item, isNull);
    expect(rows.last.peer, isNull);
    expect(rows.fold(0, (s, r) => s + r.amount), o.month.expense);
    expect(_overview([_expense(1000, BudgetCategory.food)]).analysisRows(6).single.item?.base, BudgetCategory.food);
  });

  test('또래 통계를 못 읽었거나 빈 달이면 분석 행에 또래 비교가 없다', () {
    expect(_overview([_expense(500000, BudgetCategory.food)]).analysisRows(6).single.peer, isNull);
    expect(_overview([_income(1000)], peer: _peer()).analysisRows(6), isEmpty);
  });

  // 막대 길이는 큰 쪽을 1로 둔 비율이다. 이전에는 페이지가 clamp(1, 1 << 62)로 나눴고,
  // 웹(JS)에서 1 << 62가 0이라 비교 탭이 예외로 멈췄다.
  test('총지출 막대는 큰 쪽을 1로 둔 비율이다', () {
    final more = _compared(_overview([_expense(2000000, BudgetCategory.food)], peer: _peer())).totalBars!;
    expect(more.mine, 1.0);
    expect(more.peer, 0.5);
    final less = _compared(_overview([_expense(250000, BudgetCategory.food)], peer: _peer())).totalBars!;
    expect(less.mine, 0.25);
    expect(less.peer, 1.0);
    expect(_compared(_overview([_expense(1, BudgetCategory.food)], peer: _peer(avg: 0))).totalBars, isNull);
  });

  test('저축률 막대는 큰 쪽을 1로 두고, 음수 저축률은 0이다', () {
    final bars = _compared(_overview([_expense(500000, BudgetCategory.food)], peer: _peer(), profileIncome: 1000000))
        .savingsBars;
    expect(bars.mine, 1.0); // 내 50% · 또래 20%
    expect(bars.peer, 0.4);
    final overspent =
        _compared(_overview([_expense(1500000, BudgetCategory.food)], peer: _peer(), profileIncome: 1000000));
    expect(overspent.savings.mine, -50);
    expect(overspent.savingsBars.mine, 0.0);
    expect(overspent.savingsBars.peer, 1.0);
  });

  test('저축률이 또래와 같거나 높으면 또래만큼 모으는 것이고, 소득이 없으면 모른다', () {
    const peer = 20;
    expect(const SavingsComparison(mine: peer, peer: peer).atLeastPeer, isTrue);
    expect(const SavingsComparison(mine: peer - 1, peer: peer).atLeastPeer, isFalse);
    expect(const SavingsComparison(mine: null, peer: peer).atLeastPeer, isFalse);
  });

  test('또래가 가장 많이 쓰는 분류', () {
    final o = _overview([_expense(1, BudgetCategory.food)], peer: _peer());
    expect(o.peerTopCategory, BudgetCategory.food);
  });
}
