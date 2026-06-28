import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/budget/transaction_local_data_source.dart';
import 'package:sedae_budget/data/budget/transaction_repository_impl.dart';
import 'package:sedae_budget/entity/budget/transaction.dart';
import 'package:sedae_budget/entity/budget/transaction_type.dart';
import 'package:sedae_budget/entity/entity.dart';

class _FakeDataSource implements TransactionLocalDataSource {
  final List<Transaction> store = [];
  bool throwOnGet = false;

  @override
  Future<void> upsert(Transaction tx) async => store.add(tx);

  @override
  Future<List<Transaction>> getMonth(int year, int month) async {
    if (throwOnGet) throw Exception('db error');
    return store;
  }
}

void main() {
  late _FakeDataSource ds;
  late TransactionRepositoryImpl repo;

  setUp(() {
    ds = _FakeDataSource();
    repo = TransactionRepositoryImpl(ds);
  });

  Transaction sample() => Transaction.create(
        amount: 100, categoryId: 1, date: DateTime(2026, 6, 1),
        type: TransactionType.expense,
      );

  test('upsert returns Success with the saved tx', () async {
    final result = await repo.upsert(sample());
    expect(result, isA<Success<Transaction>>());
  });

  test('getMonth wraps datasource errors in Result.failure', () async {
    ds.throwOnGet = true;
    final result = await repo.getMonth(2026, 6);
    expect(result, isA<Error<List<Transaction>>>());
  });
}
