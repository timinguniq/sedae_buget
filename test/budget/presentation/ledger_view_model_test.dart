import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/ledger.view_model.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';

import '../../helper/fakes.dart';

const _pet = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12);

final _now = DateTime.now();
final _thisMonth = DateTime(_now.year, _now.month, 1);

Transaction _expense(int amount) => Transaction.create(
    amount: amount, categoryId: 1, date: _thisMonth, type: TransactionType.expense);

/// kakao로 로그인해 [categories]·[transactions]를 심은 서버.
Future<StubServer> _server({
  List<CustomCategory> categories = const [],
  List<Transaction> transactions = const [],
}) async {
  final server = StubServer();
  await server.seed(categories: categories, transactions: transactions);
  return server;
}

/// 서버에 저장된 이달 거래.
Future<List<Transaction>> _saved(StubServer server) async =>
    (await server.transactions.getMonth(_thisMonth.year, _thisMonth.month)).unwrap();

/// 서버가 받은 거래 조회 수(이달·추이 모두).
int _reads(StubServer server) => server.faults.count('GET', '/v1/transactions');

void main() {
  test('거래를 추가하면 최근 6개월 추이에도 반영된다', () async {
    final c = fakeContainer(server: await _server());
    expect((await c.read(selfTrendProvider.future)).last.expense, 0);

    final res = await c.read(monthlyTransactionsProvider.notifier)
        .save(TransactionDraft.create(_thisMonth).withAmount(7000));
    expect(res.failureOrNull, isNull);

    expect((await c.read(monthlyTransactionsProvider.future)).single.amount, 7000);
    expect((await c.read(selfTrendProvider.future)).last.expense, 7000);
  });

  // 거래를 저장할 때 사용자 카테고리 목록을 아직 읽지 않았어도, 다 읽은 목록으로 판정한다.
  test('저장은 불러온 사용자 카테고리 목록으로 카테고리를 맞춘다', () async {
    final server = await _server(categories: const [_pet]);
    final c = fakeContainer(server: server);

    await c.read(monthlyTransactionsProvider.notifier)
        .save(TransactionDraft.create(_thisMonth).withAmount(1000).pickCustom(_pet));

    final saved = (await _saved(server)).single;
    expect(saved.customCategoryId, _pet.id);
    expect(saved.categoryId, BudgetCategory.etc.id);
  });

  // 목록을 못 읽었다고 거래 저장까지 막지 않는다. 지워졌는지 판정할 수 없으니 고른 그대로 둔다.
  test('사용자 카테고리 목록을 못 읽어도 고른 그대로 저장한다', () async {
    final server = await _server(categories: const [_pet]);
    server.faults.fail('GET', '/v1/categories');
    final c = fakeContainer(server: server);

    final res = await c.read(monthlyTransactionsProvider.notifier)
        .save(TransactionDraft.create(_thisMonth).withAmount(1000).pickCustom(_pet));

    expect(res.failureOrNull, isNull);
    expect((await _saved(server)).single.customCategoryId, _pet.id);
  });

  // Stub 서버가 사용자마다 데이터를 따로 둔다(계약). 장부는 세션이 바뀌면 새 사용자로 다시 읽어야 한다.
  test('다른 사용자로 다시 로그인하면 이전 사용자의 장부가 남지 않는다', () async {
    final c = fakeContainer(server: await _server(categories: const [_pet], transactions: [_expense(1111)]));
    expect((await c.read(monthlyTransactionsProvider.future)).single.amount, 1111);
    expect((await c.read(selfTrendProvider.future)).last.expense, 1111);
    expect(await c.read(customCategoriesProvider.future), const [_pet]);

    await c.read(authProvider.notifier).signOut();
    await c.read(authProvider.notifier).signIn(AuthProvider.google);

    expect(await c.read(monthlyTransactionsProvider.future), isEmpty);
    expect((await c.read(selfTrendProvider.future)).last.expense, 0);
    expect(await c.read(customCategoriesProvider.future), isEmpty);
  });

  test('로그아웃하면 서버를 부르지 않고 비어 있다', () async {
    final server = await _server(transactions: [_expense(1000)]);
    final c = fakeContainer(server: server);
    expect(await c.read(monthlyTransactionsProvider.future), hasLength(1));

    await c.read(authProvider.notifier).signOut();
    final reads = _reads(server);

    expect(await c.read(monthlyTransactionsProvider.future), isEmpty);
    expect(_reads(server), reads);
  });

  // 서버는 카테고리를 지우면 그 거래를 기본 분류로 되돌리고, 상위 분류를 바꾸면 거래를 옮긴다.
  test('사용자 카테고리를 지우면 이달 거래를 다시 읽는다', () async {
    final server = await _server(categories: const [_pet]);
    final c = fakeContainer(server: server);
    await c.read(monthlyTransactionsProvider.future);
    final reads = _reads(server);

    await c.read(customCategoriesProvider.notifier).remove(_pet);
    await c.read(monthlyTransactionsProvider.future);

    expect(_reads(server), reads + 1);
    expect(await c.read(customCategoriesProvider.future), isEmpty);
  });

  test('사용자 카테고리의 상위 분류를 바꾸면 이달 거래를 다시 읽는다', () async {
    final server = await _server(categories: const [_pet]);
    final c = fakeContainer(server: server);
    await c.read(monthlyTransactionsProvider.future);
    final reads = _reads(server);

    await c.read(customCategoriesProvider.notifier)
        .edit(_pet, name: _pet.name, base: BudgetCategory.recreation);
    await c.read(monthlyTransactionsProvider.future);

    expect(_reads(server), reads + 1);
  });

  test('저장이 실패하면 다시 읽지 않는다', () async {
    final server = await _server(categories: const [_pet]);
    server.faults.fail('DELETE', '/v1/categories');
    final c = fakeContainer(server: server);
    await c.read(monthlyTransactionsProvider.future);
    final reads = _reads(server);

    final res = await c.read(customCategoriesProvider.notifier).remove(_pet);
    await c.read(monthlyTransactionsProvider.future);

    expect(res.failureOrNull, isNotNull);
    expect(_reads(server), reads);
  });
}
