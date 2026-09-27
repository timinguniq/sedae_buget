import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../helper/stub_server.dart';

Transaction _tx(DateTime date, {int amount = 1000}) => Transaction.create(
      amount: amount, categoryId: 10, date: date, type: TransactionType.expense, memo: 'm',
    );

/// [year]년 [month]월의 거래(보고 있는 달을 읽는 방식 그대로).
Future<Result<List<Transaction>>> _month(TransactionRepository repo, int year, int month) {
  final m = YearMonth.of(DateTime(year, month));
  return repo.getRange(m.start, m.end);
}

void main() {
  late MemoryAuthTokenStore tokens;
  late TransactionRepository repo;

  setUp(() async {
    final server = StubServer();
    await server.signIn(AuthProvider.kakao);
    tokens = server.tokens;
    repo = server.transactions;
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

  test('한 달 범위는 그 달의 거래만 최신순으로 돌려준다', () async {
    await repo.upsert(_tx(DateTime(2026, 9, 1), amount: 1));
    await repo.upsert(_tx(DateTime(2026, 9, 10), amount: 2));
    await repo.upsert(_tx(DateTime(2026, 10, 1), amount: 3));
    final res = await _month(repo, 2026, 9);
    final list = (res as Success<List<Transaction>>).data;
    expect(list.map((t) => t.amount), [2, 1]);
  });

  test('12월 범위는 다음 해 1월 1일을 넣지 않는다', () async {
    await repo.upsert(_tx(DateTime(2026, 12, 31, 23, 59), amount: 1));
    await repo.upsert(_tx(DateTime(2027, 1, 1), amount: 2));
    final list = ((await _month(repo, 2026, 12)) as Success<List<Transaction>>).data;
    expect(list.map((t) => t.amount), [1]);
  });

  test('delete returns the tx and removes it from the server', () async {
    final tx = _tx(DateTime(2026, 9, 6));
    await repo.upsert(tx);
    final res = await repo.delete(tx);
    expect(res, isA<Success<Transaction>>());
    expect((res as Success<Transaction>).data.id, tx.id);
    final after = await _month(repo, 2026, 9);
    expect((after as Success<List<Transaction>>).data, isEmpty);
  });

  test('update via upsert keeps id and changes fields', () async {
    final tx = _tx(DateTime(2026, 9, 6));
    await repo.upsert(tx);
    await repo.upsert(tx.copyWith(amount: 999));
    final list = ((await _month(repo, 2026, 9)) as Success<List<Transaction>>).data;
    expect(list.single.id, tx.id);
    expect(list.single.amount, 999);
  });

  test('without token → Result.failure with server code', () async {
    tokens.token = null;
    final res = await _month(repo, 2026, 9);
    expect(res, isA<Error<List<Transaction>>>());
    expect(res.failureOrNull?.code, 'AUTH_002');
    expect(res.failureOrNull?.reason, FailureReason.unauthorized);
  });
}
