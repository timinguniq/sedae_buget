import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/ledger.view_model.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';

import '../../helper/fakes.dart';

const _pet = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12);

final _now = DateTime.now();
final _thisMonth = DateTime(_now.year, _now.month, 1);

Transaction _expense(int amount) => Transaction.create(
    amount: amount, categoryId: 1, date: _thisMonth, type: TransactionType.expense);

/// 로그인한 사용자마다 다른 데이터를 돌려주는 서버 흉내.
class _PerUserTransactions implements TransactionRepository {
  _PerUserTransactions(this._auth, this._byUser);
  final InMemoryAuthRepository _auth;
  final Map<AuthProvider, List<Transaction>> _byUser;

  InMemoryTransactionRepository get _current =>
      InMemoryTransactionRepository(_byUser[_auth.user?.provider] ?? const []);

  @override
  Future<Result<Transaction>> upsert(Transaction tx) => _current.upsert(tx);
  @override
  Future<Result<Transaction>> delete(Transaction tx) => _current.delete(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) => _current.getMonth(y, m);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime s, DateTime e) => _current.getRange(s, e);
}

class _PerUserCategories implements CategoryRepository {
  _PerUserCategories(this._auth, this._byUser);
  final InMemoryAuthRepository _auth;
  final Map<AuthProvider, List<CustomCategory>> _byUser;

  InMemoryCategoryRepository get _current =>
      InMemoryCategoryRepository(_byUser[_auth.user?.provider] ?? const []);

  @override
  Future<Result<List<CustomCategory>>> getAll() => _current.getAll();
  @override
  Future<Result<CustomCategory>> upsert(CustomCategory c) => _current.upsert(c);
  @override
  Future<Result<CustomCategory>> delete(CustomCategory c) => _current.delete(c);
}

void main() {
  test('거래를 추가하면 최근 6개월 추이에도 반영된다', () async {
    final c = fakeContainer(user: testUser, transactions: InMemoryTransactionRepository());
    expect((await c.read(selfTrendProvider.future)).last.expense, 0);

    final res = await c.read(monthlyTransactionsProvider.notifier).add(
        amount: 7000, categoryId: 1, date: _thisMonth, type: TransactionType.expense);
    expect(res.failureOrNull, isNull);

    expect((await c.read(monthlyTransactionsProvider.future)).single.amount, 7000);
    expect((await c.read(selfTrendProvider.future)).last.expense, 7000);
  });

  test('다른 사용자로 다시 로그인하면 이전 사용자의 장부가 남지 않는다', () async {
    final auth = InMemoryAuthRepository(testUser);
    final c = fakeContainer(
      authRepository: auth,
      transactions: _PerUserTransactions(auth, {AuthProvider.kakao: [_expense(1111)]}),
      categories: _PerUserCategories(auth, {AuthProvider.kakao: const [_pet]}),
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
