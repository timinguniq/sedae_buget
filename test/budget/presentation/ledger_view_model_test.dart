import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/ledger.view_model.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';

import '../../helper/fakes.dart';
import '../../helper/stub_server.dart';

const _pet = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12);

final _now = DateTime.now();
final _thisMonth = DateTime(_now.year, _now.month, 1);

Transaction _expense(int amount) => Transaction.create(
    amount: amount, categoryId: 1, date: _thisMonth, type: TransactionType.expense);

void main() {
  test('거래를 추가하면 최근 6개월 추이에도 반영된다', () async {
    final c = fakeContainer(
        user: testUser, transactions: InMemoryTransactionRepository(),
        categories: InMemoryCategoryRepository());
    expect((await c.read(selfTrendProvider.future)).last.expense, 0);

    final res = await c.read(monthlyTransactionsProvider.notifier)
        .save(TransactionDraft.create(_thisMonth).withAmount(7000));
    expect(res.failureOrNull, isNull);

    expect((await c.read(monthlyTransactionsProvider.future)).single.amount, 7000);
    expect((await c.read(selfTrendProvider.future)).last.expense, 7000);
  });

  // 거래를 저장할 때 사용자 카테고리 목록을 아직 읽지 않았어도, 다 읽은 목록으로 판정한다.
  test('저장은 불러온 사용자 카테고리 목록으로 카테고리를 맞춘다', () async {
    final repo = InMemoryTransactionRepository();
    final c = fakeContainer(
        user: testUser, transactions: repo, categories: InMemoryCategoryRepository(const [_pet]));

    await c.read(monthlyTransactionsProvider.notifier)
        .save(TransactionDraft.create(_thisMonth).withAmount(1000).pickCustom(_pet));

    expect(repo.items.values.single.customCategoryId, _pet.id);
    expect(repo.items.values.single.categoryId, BudgetCategory.etc.id);
  });

  // 목록을 못 읽었다고 거래 저장까지 막지 않는다. 지워졌는지 판정할 수 없으니 고른 그대로 둔다.
  test('사용자 카테고리 목록을 못 읽어도 고른 그대로 저장한다', () async {
    final repo = InMemoryTransactionRepository();
    final c = fakeContainer(user: testUser, transactions: repo, categories: _UnreadableCategories());

    final res = await c.read(monthlyTransactionsProvider.notifier)
        .save(TransactionDraft.create(_thisMonth).withAmount(1000).pickCustom(_pet));

    expect(res.failureOrNull, isNull);
    expect(repo.items.values.single.customCategoryId, _pet.id);
  });

  test('지워진 사용자 카테고리를 가리키는 거래를 저장하면 기본 분류로 되돌린다', () async {
    final orphan = Transaction.create(
        amount: 1000, categoryId: BudgetCategory.etc.id, date: _thisMonth,
        type: TransactionType.expense, customCategoryId: 'gone');
    final repo = InMemoryTransactionRepository([orphan]);
    final c = fakeContainer(
        user: testUser, transactions: repo, categories: InMemoryCategoryRepository(const [_pet]));
    final catalog = CategoryCatalog(await c.read(customCategoriesProvider.future));

    await c.read(monthlyTransactionsProvider.notifier)
        .save(TransactionDraft.edit(orphan, catalog).withAmount(2000));

    final saved = repo.items[orphan.id]!;
    expect(saved.amount, 2000);
    expect(saved.customCategoryId, isNull);
    expect(saved.categoryId, BudgetCategory.etc.id);
  });

  // Stub 서버가 사용자마다 데이터를 따로 둔다(계약). 장부는 세션이 바뀌면 새 사용자로 다시 읽어야 한다.
  test('다른 사용자로 다시 로그인하면 이전 사용자의 장부가 남지 않는다', () async {
    final server = StubServer();
    await server.signIn(AuthProvider.kakao);
    (await server.transactions.upsert(_expense(1111))).unwrap();
    (await server.categories.upsert(_pet)).unwrap();
    final c = fakeContainer(
      authRepository: server.auth,
      profileRepository: server.profiles,
      transactions: server.transactions,
      categories: server.categories,
    );
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
    final repo = InMemoryTransactionRepository([_expense(1000)]);
    final c = fakeContainer(user: testUser, transactions: repo);
    expect(await c.read(monthlyTransactionsProvider.future), hasLength(1));

    await c.read(authProvider.notifier).signOut();
    final reads = repo.monthReads;

    expect(await c.read(monthlyTransactionsProvider.future), isEmpty);
    expect(repo.monthReads, reads);
  });

  // 서버는 카테고리를 지우면 그 거래를 기본 분류로 되돌리고, 상위 분류를 바꾸면 거래를 옮긴다.
  test('사용자 카테고리를 지우면 이달 거래를 다시 읽는다', () async {
    final repo = InMemoryTransactionRepository();
    final c = fakeContainer(
        user: testUser, transactions: repo, categories: InMemoryCategoryRepository(const [_pet]));
    await c.read(monthlyTransactionsProvider.future);
    final reads = repo.monthReads;

    await c.read(customCategoriesProvider.notifier).remove(_pet);
    await c.read(monthlyTransactionsProvider.future);

    expect(repo.monthReads, reads + 1);
    expect(await c.read(customCategoriesProvider.future), isEmpty);
  });

  test('사용자 카테고리의 상위 분류를 바꾸면 이달 거래를 다시 읽는다', () async {
    final repo = InMemoryTransactionRepository();
    final c = fakeContainer(
        user: testUser, transactions: repo, categories: InMemoryCategoryRepository(const [_pet]));
    await c.read(monthlyTransactionsProvider.future);
    final reads = repo.monthReads;

    await c.read(customCategoriesProvider.notifier)
        .edit(_pet, name: _pet.name, base: BudgetCategory.recreation);
    await c.read(monthlyTransactionsProvider.future);

    expect(repo.monthReads, reads + 1);
  });

  test('저장이 실패하면 다시 읽지 않는다', () async {
    final repo = InMemoryTransactionRepository();
    final c = fakeContainer(user: testUser, transactions: repo, categories: _FailingCategories());
    await c.read(monthlyTransactionsProvider.future);
    final reads = repo.monthReads;

    final res = await c.read(customCategoriesProvider.notifier).remove(_pet);
    await c.read(monthlyTransactionsProvider.future);

    expect(res.failureOrNull, isNotNull);
    expect(repo.monthReads, reads);
  });
}

class _FailingCategories implements CategoryRepository {
  static const _offline = ErrorResult(reason: FailureReason.offline, message: '오프라인');
  @override
  Future<Result<List<CustomCategory>>> getAll() async => const Result.success([_pet]);
  @override
  Future<Result<CustomCategory>> upsert(CustomCategory c) async => const Result.failure(_offline);
  @override
  Future<Result<CustomCategory>> delete(CustomCategory c) async => const Result.failure(_offline);
}

/// 목록을 읽지 못하는 서버(오프라인).
class _UnreadableCategories implements CategoryRepository {
  static const _offline = ErrorResult(reason: FailureReason.offline, message: '오프라인');
  @override
  Future<Result<List<CustomCategory>>> getAll() async => const Result.failure(_offline);
  @override
  Future<Result<CustomCategory>> upsert(CustomCategory c) async => const Result.failure(_offline);
  @override
  Future<Result<CustomCategory>> delete(CustomCategory c) async => const Result.failure(_offline);
}
