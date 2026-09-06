import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

class _Tokens implements AuthTokenStore {
  String? t = 'stub.kakao';
  @override
  Future<String?> read() async => t;
  @override
  Future<void> write(String token) async => t = token;
  @override
  Future<void> clear() async => t = null;
}

Transaction _tx(DateTime date, {int amount = 1000}) => Transaction.create(
      amount: amount, categoryId: 7, date: date, type: TransactionType.expense, memo: 'm',
    );

void main() {
  late _Tokens tokens;
  late TransactionRepository repo;

  setUp(() {
    tokens = _Tokens();
    repo = ApiTransactionRepository(ApiClient(Dio()
      ..interceptors.add(AuthTokenInterceptor(tokens))
      ..interceptors.add(StubApiInterceptor())));
  });

  test('upsert returns Success with server-stamped local timestamps', () async {
    final tx = _tx(DateTime(2026, 9, 6));
    final res = await repo.upsert(tx);
    expect(res, isA<Success<Transaction>>());
    final saved = (res as Success<Transaction>).data;
    expect(saved.id, tx.id);
    expect(saved.amount, 1000);
    expect(saved.memo, 'm');
    expect(saved.date, DateTime(2026, 9, 6));
    expect(saved.createdAt.isUtc, isFalse);
  });

  test('getMonth returns only that month, newest first', () async {
    await repo.upsert(_tx(DateTime(2026, 9, 1), amount: 1));
    await repo.upsert(_tx(DateTime(2026, 9, 10), amount: 2));
    await repo.upsert(_tx(DateTime(2026, 10, 1), amount: 3));
    final res = await repo.getMonth(2026, 9);
    final list = (res as Success<List<Transaction>>).data;
    expect(list.map((t) => t.amount), [2, 1]);
  });

  test('getMonth(12) rolls over to next January exclusively', () async {
    await repo.upsert(_tx(DateTime(2026, 12, 31, 23, 59), amount: 1));
    await repo.upsert(_tx(DateTime(2027, 1, 1), amount: 2));
    final list = ((await repo.getMonth(2026, 12)) as Success<List<Transaction>>).data;
    expect(list.map((t) => t.amount), [1]);
  });

  test('delete returns the tx and removes it from the server', () async {
    final tx = _tx(DateTime(2026, 9, 6));
    await repo.upsert(tx);
    final res = await repo.delete(tx);
    expect(res, isA<Success<Transaction>>());
    expect((res as Success<Transaction>).data.id, tx.id);
    final after = await repo.getMonth(2026, 9);
    expect((after as Success<List<Transaction>>).data, isEmpty);
  });

  test('update via upsert keeps id and changes fields', () async {
    final tx = _tx(DateTime(2026, 9, 6));
    await repo.upsert(tx);
    await repo.upsert(tx.copyWith(amount: 999));
    final list = ((await repo.getMonth(2026, 9)) as Success<List<Transaction>>).data;
    expect(list.single.id, tx.id);
    expect(list.single.amount, 999);
  });

  test('without token → Result.failure with server code', () async {
    tokens.t = null;
    final res = await repo.getMonth(2026, 9);
    expect(res, isA<Error<List<Transaction>>>());
    expect((res as Error<List<Transaction>>).error.resultCode, 'AUTH_002');
  });
}
