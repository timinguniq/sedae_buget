import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';

class _FakeRepo implements TransactionRepository {
  Transaction? lastUpserted;

  @override
  Future<Result<Transaction>> upsert(Transaction tx) async {
    lastUpserted = tx;
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

  test('add builds a pending transaction and upserts it', () async {
    await usecase.add(
      amount: 9000, categoryId: 7, date: DateTime(2026, 6, 2),
      type: TransactionType.expense,
    );
    expect(repo.lastUpserted!.amount, 9000);
    expect(repo.lastUpserted!.categoryId, 7);
  });

  test('delete upserts a tombstoned transaction', () async {
    await usecase.delete(expense(1, 1));
    expect(repo.lastUpserted!.deletedAt, isNotNull);
  });

  test('categorySummary sums expenses per category', () {
    final summary = usecase.categorySummary([
      expense(1000, 7),
      expense(500, 7),
      expense(2000, 11),
    ]);
    expect(summary[BudgetCategory.transport], 1500);
    expect(summary[BudgetCategory.diningOut], 2000);
  });

  test('totalExpense ignores income', () {
    final txs = [
      expense(1000, 7),
      Transaction.create(
          amount: 5000, categoryId: 1, date: DateTime(2026, 6, 1),
          type: TransactionType.income),
    ];
    expect(usecase.totalExpense(txs), 1000);
    expect(usecase.totalIncome(txs), 5000);
  });

  group('savings', () {
    test('effectiveIncome prefers positive profile income', () {
      expect(usecase.effectiveIncome(txIncome: 1000000, profileIncome: 3000000), 3000000);
      expect(usecase.effectiveIncome(txIncome: 1000000, profileIncome: 0), 1000000);
      expect(usecase.effectiveIncome(txIncome: 1000000), 1000000);
    });

    test('savingsRatePercent rounds and guards zero income', () {
      expect(usecase.savingsRatePercent(income: 3000000, expense: 2100000), 30);
      expect(usecase.savingsRatePercent(income: 0, expense: 500000), 0);
      expect(usecase.savingsRatePercent(income: 1000000, expense: 1200000), -20);
    });
  });
}
