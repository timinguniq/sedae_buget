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
  test('이달 거래에서 지출·수입·기본 분류별 합계를 낸다', () async {
    final c = fakeContainer(
      user: testUser,
      transactions: InMemoryTransactionRepository(
          [_expense(1200, BudgetCategory.transport), _income(5000)]),
      peerRepository: FakePeerStatsRepository(),
    );
    final o = await _overview(c);
    expect(o.expense, 1200);
    expect(o.income, 5000);
    expect(o.byCategory, {BudgetCategory.transport: 1200});
    expect(o.transactions, hasLength(2));
    expect(o.peer, isNotNull);
  });

  test('selectedMonth prev/next shift the month', () {
    final container = fakeContainer(user: testUser, transactions: InMemoryTransactionRepository());

    final initial = container.read(selectedMonthProvider);
    container.read(selectedMonthProvider.notifier).prev();
    final prev = container.read(selectedMonthProvider);
    expect(prev.month, initial.month == 1 ? 12 : initial.month - 1);
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
      expect(o.expense, 1200);
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

  group('저축률', () {
    Future<int?> rate({int? profileIncome, List<Transaction> txs = const []}) async {
      final c = fakeContainer(
        user: testUser,
        profile: profileIncome == null
            ? null
            : UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: profileIncome),
        transactions: InMemoryTransactionRepository(txs),
        peerRepository: FakePeerStatsRepository(),
      );
      return (await _overview(c)).savingsRate;
    }

    test('소득이 없으면 null', () async {
      expect(await rate(txs: [_expense(500000, BudgetCategory.food)]), isNull);
      expect(await rate(profileIncome: 0, txs: [_expense(500000, BudgetCategory.food)]), isNull);
    });

    test('프로필 월소득이 있으면 그것을, 없으면 이달 수입을 기준으로 한다', () async {
      final txs = [_expense(700000, BudgetCategory.food), _income(1000000)];
      expect(await rate(profileIncome: 3500000, txs: txs), 80);
      expect(await rate(profileIncome: 0, txs: txs), 30);
    });
  });

  test('topCategories는 지출이 많은 기본 분류를 n개까지 금액 내림차순으로 낸다', () async {
    final c = fakeContainer(
      user: testUser,
      transactions: InMemoryTransactionRepository([
        _expense(90000, BudgetCategory.transport),
        _expense(540000, BudgetCategory.food),
        _expense(320000, BudgetCategory.diningOut),
        _expense(180000, BudgetCategory.clothing),
      ]),
      peerRepository: FakePeerStatsRepository(),
    );
    final top = (await _overview(c)).topCategories(3);
    expect(top.map((e) => e.key),
        [BudgetCategory.food, BudgetCategory.diningOut, BudgetCategory.clothing]);
    expect(top.first.value, 540000);
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
      expect(o.byCategory[BudgetCategory.recreation], lots);
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
