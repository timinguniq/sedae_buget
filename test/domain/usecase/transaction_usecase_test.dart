import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/domain/repository/transaction_repository.dart';
import 'package:sedae_budget/domain/usecase/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';

class _FakeRepo implements TransactionRepository {
  Transaction? lastUpserted;
  Transaction? lastDeleted;

  @override
  Future<Result<Transaction>> upsert(Transaction tx) async {
    lastUpserted = tx;
    return Result.success(tx);
  }

  @override
  Future<Result<Transaction>> delete(Transaction tx) async {
    lastDeleted = tx;
    return Result.success(tx);
  }

  @override
  Future<Result<List<Transaction>>> getMonth(int year, int month) async =>
      const Result.success([]);

  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}

Transaction expense(int amount, int categoryId) => Transaction.create(
      amount: amount, categoryId: categoryId, date: DateTime(2026, 6, 1),
      type: TransactionType.expense,
    );

void main() {
  late _FakeRepo repo;
  late TransactionUsecase usecase;

  setUp(() {
    repo = _FakeRepo();
    usecase = TransactionUsecase(repo);
  });

  test('save upserts the given transaction unchanged', () async {
    final tx = expense(1, 1);
    await usecase.save(tx);
    expect(repo.lastUpserted, tx);
  });

  test('delete delegates to repository delete', () async {
    final tx = expense(1, 1);
    await usecase.delete(tx);
    expect(repo.lastDeleted, tx);
    expect(repo.lastUpserted, isNull);
  });
}
