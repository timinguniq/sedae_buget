import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/budget_home.view_model.dart';
import 'package:sedae_budget/presentation/page/budget/ledger.view_model.dart';
import 'package:sedae_budget/presentation/page/compare/compare.view_model.dart';

import '../../helper/fakes.dart';

final _now = DateTime.now();
final _day = DateTime(_now.year, _now.month, 5);

Transaction _expense(int amount, BudgetCategory c, {String? customCategoryId}) =>
    Transaction.create(
        amount: amount, categoryId: c.id, date: _day, type: TransactionType.expense,
        customCategoryId: customCategoryId);

Transaction _income(int amount) => Transaction.create(
    amount: amount, categoryId: BudgetCategory.etc.id, date: _day, type: TransactionType.income);

/// 이달 개요를 다 읽을 때까지 기다린다(또래 통계·거래가 모두 풀린 뒤의 값).
Future<MonthOverview> _overview(ProviderContainer c) async {
  final sub = c.listen(monthOverviewProvider, (_, _) {});
  addTearDown(sub.close);
  await c.read(monthlyTransactionsProvider.future);
  await c.read(peerStatsProvider.future).then((_) {}, onError: (_) {});
  await c.read(customCategoriesProvider.future).then((_) {}, onError: (_) {});
  return c.read(monthOverviewProvider).requireValue;
}

/// 첫 응답을 [gate]가 풀릴 때까지 붙잡는 또래 통계 저장소.
class _SlowPeer implements PeerStatsRepository {
  final gate = Completer<void>();
  @override
  Future<Result<PeerStats>> forGroup(AgeGroup g) async {
    await gate.future;
    return Result.success(StubPeerData.forGroup(g));
  }

  @override
  Future<Result<Map<AgeGroup, int>>> generationAverages() async => const Result.success({});
}

void main() {
  // 합계·분류·소득 규칙 자체는 ViewedMonth 테스트가 본다. 여기서는 재료가 모이는지만 본다.
  test('보고 있는 달을 이달 거래·사용자 카테고리·프로필 소득으로 만든다', () async {
    const study = CustomCategory(id: 'c2', name: '자기계발', baseCategoryId: 9);
    final c = fakeContainer(
      user: testUser,
      profile: const UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3500000),
      transactions: InMemoryTransactionRepository([
        _expense(1200, BudgetCategory.transport),
        _expense(700, BudgetCategory.etc, customCategoryId: 'c2'),
        _income(5000),
      ]),
      categories: InMemoryCategoryRepository(const [study]),
      peerRepository: FakePeerStatsRepository(),
    );
    final o = await _overview(c);
    expect(o.month.month, c.read(selectedMonthProvider));
    expect(o.month.transactions, hasLength(3));
    expect(o.month.byCategory,
        {BudgetCategory.transport: 1200, BudgetCategory.recreation: 700});
    expect(o.month.income, 3500000);
    expect(o.peer, isNotNull);
  });

  test('보고 있는 달의 이름은 이번 달이면 이번 달, 아니면 M월', () {
    final c = fakeContainer(user: testUser, transactions: InMemoryTransactionRepository());
    expect(c.read(viewedMonthNameProvider), '이번 달');
    c.read(selectedMonthProvider.notifier).prev();
    expect(c.read(viewedMonthNameProvider), '${c.read(selectedMonthProvider).month}월');
  });

  test('selectedMonth prev/next shift the month', () {
    final container = fakeContainer(user: testUser, transactions: InMemoryTransactionRepository());

    final initial = container.read(selectedMonthProvider);
    container.read(selectedMonthProvider.notifier).prev();
    final prev = container.read(selectedMonthProvider);
    expect(prev, DateTime(initial.year, initial.month - 1));
    container.read(selectedMonthProvider.notifier).next();
    expect(container.read(selectedMonthProvider), initial);
  });

  // 이전에는 다음 달로 끝없이 넘어가 아직 오지 않은 달을 볼 수 있었다.
  test('보고 있는 달은 이번 달보다 뒤로 가지 않는다', () {
    final container = fakeContainer(user: testUser, transactions: InMemoryTransactionRepository());
    final notifier = container.read(selectedMonthProvider.notifier);
    final now = DateTime.now();

    expect(notifier.canGoNext, isFalse);
    notifier.next();
    expect(container.read(selectedMonthProvider), DateTime(now.year, now.month));
    notifier.prev();
    expect(notifier.canGoNext, isTrue);
  });

  group('또래 통계', () {
    test('실패하면 peer만 null이고 내 값은 그대로 낸다', () async {
      final c = fakeContainer(
        user: testUser,
        transactions: InMemoryTransactionRepository([_expense(1200, BudgetCategory.transport)]),
        peerRepository: FailingPeerStatsRepository(),
      );
      final o = await _overview(c);
      expect(o.peer, isNull);
      expect(o.month.expense, 1200);
    });

    test('처음 읽는 동안은 기다린다(또래 없는 화면이 먼저 깜박이지 않게)', () async {
      final peer = _SlowPeer();
      final c = fakeContainer(
          user: testUser,
          transactions: InMemoryTransactionRepository([_expense(1200, BudgetCategory.transport)]),
          peerRepository: peer);
      final sub = c.listen(monthOverviewProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(monthlyTransactionsProvider.future);
      expect(c.read(monthOverviewProvider).isLoading, isTrue);

      peer.gate.complete();
      await c.read(peerStatsProvider.future);
      expect(c.read(monthOverviewProvider).requireValue.peer, isNotNull);
    });
  });

  group('overPeer', () {
    // 30대 Stub 또래 평균보다 확실히 많은 금액.
    const lots = 50000000;

    test('거래가 속한 기본 분류의 이달 지출이 또래 평균보다 많으면 true', () async {
      final big = _expense(lots, BudgetCategory.food);
      final small = _expense(1, BudgetCategory.transport);
      final c = fakeContainer(
          user: testUser,
          transactions: InMemoryTransactionRepository([big, small]),
          peerRepository: FakePeerStatsRepository());
      final o = await _overview(c);
      expect(o.overPeer(big), isTrue);
      expect(o.overPeer(small), isFalse);
    });

    test('사용자 카테고리 거래는 그 카테고리의 현재 상위 분류로 비교한다', () async {
      const study = CustomCategory(id: 'c2', name: '자기계발', baseCategoryId: 9);
      // 기타(12)로 적혀 있지만 자기계발의 현재 상위 분류는 오락·문화(9)다.
      final stale = _expense(lots, BudgetCategory.etc, customCategoryId: 'c2');
      final c = fakeContainer(
          user: testUser,
          transactions: InMemoryTransactionRepository([stale]),
          categories: InMemoryCategoryRepository(const [study]),
          peerRepository: FakePeerStatsRepository());
      final o = await _overview(c);
      expect(o.month.byCategory[BudgetCategory.recreation], lots);
      expect(o.overPeer(stale), isTrue);
    });

    test('또래 평균과 같으면 초과가 아니다', () async {
      final avg = StubPeerData.forGroup(AgeGroup.thirties).avgByCategory[BudgetCategory.food]!;
      final same = _expense(avg, BudgetCategory.food);
      final c = fakeContainer(
          user: testUser,
          transactions: InMemoryTransactionRepository([same]),
          peerRepository: FakePeerStatsRepository());
      expect((await _overview(c)).overPeer(same), isFalse);
    });

    // 이전에는 또래 평균이 0인(집계 없음) 분류의 모든 지출에 배지가 붙었다.
    test('또래 평균이 없는 분류는 초과가 아니다', () async {
      final stub = StubPeerData.forGroup(AgeGroup.thirties);
      final tx = _expense(1000, BudgetCategory.education);
      final c = fakeContainer(
          user: testUser,
          transactions: InMemoryTransactionRepository([tx]),
          peerStats: PeerStats(
            ageGroup: stub.ageGroup,
            avgMonthlyExpense: stub.avgMonthlyExpense,
            avgSavingsRate: stub.avgSavingsRate,
            avgByCategory: {...stub.avgByCategory}..remove(BudgetCategory.education),
            samples: stub.samples,
          ));
      expect((await _overview(c)).overPeer(tx), isFalse);
    });

    test('수입 거래나 또래 통계가 없으면 false', () async {
      // 지출이 또래를 넘는 분류에 적힌 수입이라도 배지는 지출에만 붙는다.
      final income = Transaction.create(amount: lots, categoryId: BudgetCategory.food.id,
          date: _day, type: TransactionType.income);
      final big = _expense(lots, BudgetCategory.food);
      final withPeer = fakeContainer(
          user: testUser,
          transactions: InMemoryTransactionRepository([income, big]),
          peerRepository: FakePeerStatsRepository());
      expect((await _overview(withPeer)).overPeer(income), isFalse);

      final withoutPeer = fakeContainer(
          user: testUser,
          transactions: InMemoryTransactionRepository([big]),
          peerRepository: FailingPeerStatsRepository());
      expect((await _overview(withoutPeer)).overPeer(big), isFalse);
    });
  });
}
