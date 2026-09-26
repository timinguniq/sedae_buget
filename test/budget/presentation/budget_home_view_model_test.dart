import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/budget_home.view_model.dart';
import 'package:sedae_budget/presentation/page/budget/ledger.view_model.dart';
import 'package:sedae_budget/presentation/page/compare/compare.view_model.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';

import '../../helper/fakes.dart';

final _now = DateTime.now();
final _day = DateTime(_now.year, _now.month, 5);

Transaction _expense(int amount, BudgetCategory c, {String? customCategoryId}) =>
    Transaction.create(
        amount: amount, categoryId: c.id, date: _day, type: TransactionType.expense,
        customCategoryId: customCategoryId);

Transaction _income(int amount) => Transaction.create(
    amount: amount, categoryId: BudgetCategory.etc.id, date: _day, type: TransactionType.income);

/// 이달 개요를 다 읽을 때까지 기다린다(거래·또래 통계·사용자 카테고리·프로필이 모두 풀린 뒤의 값).
Future<MonthOverview> _overview(ProviderContainer c) async {
  final sub = c.listen(monthOverviewProvider, (_, _) {});
  addTearDown(sub.close);
  await c.read(monthlyTransactionsProvider.future);
  await c.read(peerStatsProvider.future).then((_) {}, onError: (_) {});
  await c.read(customCategoriesProvider.future).then((_) {}, onError: (_) {});
  await c.read(userProfileProvider.future);
  return c.read(monthOverviewProvider).requireValue;
}

/// kakao로 로그인해 [profile]·[categories]·[transactions]를 심은 서버.
Future<StubServer> _server({
  UserProfile? profile,
  List<CustomCategory> categories = const [],
  List<Transaction> transactions = const [],
  PeerStats Function(AgeGroup)? peerStats,
}) async {
  final server = StubServer(peerStats: peerStats);
  await server.seed(profile: profile, categories: categories, transactions: transactions);
  return server;
}

/// [transactions]만 심은 서버의 컨테이너.
Future<ProviderContainer> _container(List<Transaction> transactions) async =>
    fakeContainer(server: await _server(transactions: transactions));

void main() {
  // 합계·분류·소득 규칙 자체는 ViewedMonth 테스트가 본다. 여기서는 재료가 모이는지만 본다.
  test('보고 있는 달을 이달 거래·사용자 카테고리·프로필 소득으로 만든다', () async {
    const study = CustomCategory(id: 'c2', name: '자기계발', baseCategoryId: 9);
    final c = fakeContainer(server: await _server(
      profile: const UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3500000),
      categories: const [study],
      transactions: [
        _expense(1200, BudgetCategory.transport),
        _expense(700, BudgetCategory.recreation, customCategoryId: 'c2'),
        _income(5000),
      ],
    ));
    final o = await _overview(c);
    expect(o.month.month, c.read(selectedMonthProvider));
    expect(o.month.transactions, hasLength(3));
    expect(o.month.byCategory,
        {BudgetCategory.transport: 1200, BudgetCategory.recreation: 700});
    expect(o.month.income, 3500000);
    expect(o.peer, isNotNull);
  });

  test('보고 있는 달의 이름은 이번 달이면 이번 달, 아니면 M월', () {
    final c = fakeContainer();
    expect(c.read(viewedMonthNameProvider), '이번 달');
    c.read(selectedMonthProvider.notifier).prev();
    expect(c.read(viewedMonthNameProvider), '${c.read(selectedMonthProvider).month}월');
  });

  test('selectedMonth prev/next shift the month', () {
    final container = fakeContainer();

    final initial = container.read(selectedMonthProvider);
    container.read(selectedMonthProvider.notifier).prev();
    final prev = container.read(selectedMonthProvider);
    expect(prev, initial.previous);
    container.read(selectedMonthProvider.notifier).next();
    expect(container.read(selectedMonthProvider), initial);
  });

  // 이전에는 다음 달로 끝없이 넘어가 아직 오지 않은 달을 볼 수 있었다.
  test('보고 있는 달은 이번 달보다 뒤로 가지 않는다', () {
    final container = fakeContainer();
    final notifier = container.read(selectedMonthProvider.notifier);
    final now = DateTime.now();

    expect(notifier.canGoNext, isFalse);
    notifier.next();
    expect(container.read(selectedMonthProvider), YearMonth.of(now));
    notifier.prev();
    expect(notifier.canGoNext, isTrue);
  });

  group('또래 통계', () {
    test('실패하면 peer만 null이고 내 값은 그대로 낸다', () async {
      final server = await _server(transactions: [_expense(1200, BudgetCategory.transport)]);
      server.faults.fail('GET', '/v1/peer', reason: FailureReason.server);
      final o = await _overview(fakeContainer(server: server));
      expect(o.peer, isNull);
      expect(o.month.expense, 1200);
    });

    test('처음 읽는 동안은 기다린다(또래 없는 화면이 먼저 깜박이지 않게)', () async {
      final server = await _server(transactions: [_expense(1200, BudgetCategory.transport)]);
      final peer = server.faults.hold('GET', '/v1/peer/stats');
      final c = fakeContainer(server: server);
      final sub = c.listen(monthOverviewProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(monthlyTransactionsProvider.future);
      expect(c.read(monthOverviewProvider).isLoading, isTrue);

      peer.complete();
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
      final o = await _overview(await _container([big, small]));
      expect(o.overPeer(big), isTrue);
      expect(o.overPeer(small), isFalse);
    });

    test('또래 평균과 같으면 초과가 아니다', () async {
      final avg = StubPeerData.forGroup(AgeGroup.thirties).avgByCategory[BudgetCategory.food]!;
      final same = _expense(avg, BudgetCategory.food);
      expect((await _overview(await _container([same]))).overPeer(same), isFalse);
    });

    // 이전에는 또래 평균이 0인(집계 없음) 분류의 모든 지출에 배지가 붙었다.
    test('또래 평균이 없는 분류는 초과가 아니다', () async {
      final tx = _expense(1000, BudgetCategory.education);
      final server = await _server(transactions: [tx], peerStats: (g) {
        final stub = StubPeerData.forGroup(g);
        return PeerStats(
          ageGroup: stub.ageGroup,
          avgMonthlyExpense: stub.avgMonthlyExpense,
          avgSavingsRate: stub.avgSavingsRate,
          avgByCategory: {...stub.avgByCategory}..remove(BudgetCategory.education),
          samples: stub.samples,
        );
      });
      expect((await _overview(fakeContainer(server: server))).overPeer(tx), isFalse);
    });

    test('수입 거래나 또래 통계가 없으면 false', () async {
      // 지출이 또래를 넘는 분류에 적힌 수입이라도 배지는 지출에만 붙는다.
      final income = Transaction.create(amount: lots, categoryId: BudgetCategory.food.id,
          date: _day, type: TransactionType.income);
      final big = _expense(lots, BudgetCategory.food);
      expect((await _overview(await _container([income, big]))).overPeer(income), isFalse);

      final withoutPeer = await _server(transactions: [big]);
      withoutPeer.faults.fail('GET', '/v1/peer', reason: FailureReason.server);
      expect((await _overview(fakeContainer(server: withoutPeer))).overPeer(big), isFalse);
    });
  });
}
