import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/budget_provider.dart';

class _FakeRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async =>
      Result.success(tx);

  @override
  Future<Result<List<Transaction>>> getMonth(int year, int month) async =>
      Result.success([
        Transaction.create(
            amount: 1200, categoryId: 7, date: DateTime(year, month, 5),
            type: TransactionType.expense),
      ]);

  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}

void main() {
  setUp(() =>
      locator.registerSingleton<TransactionUsecase>(TransactionUsecase(_FakeRepo())));
  tearDown(() => locator.reset());

  test('monthlyTransactionsProvider loads via usecase', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final list = await container.read(monthlyTransactionsProvider.future);
    expect(list.single.amount, 1200);
  });

  test('monthlySummaryProvider derives expense/income/byCategory from monthly txs',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(monthlyTransactionsProvider.future);
    final s = container.read(monthlySummaryProvider).requireValue;
    expect(s.expense, 1200);
    expect(s.income, 0);
    expect(s.byCategory[BudgetCategory.transport], 1200);
  });

  test('selectedMonth prev/next shift the month', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initial = container.read(selectedMonthProvider);
    container.read(selectedMonthProvider.notifier).prev();
    final prev = container.read(selectedMonthProvider);
    expect(prev.month, initial.month == 1 ? 12 : initial.month - 1);
  });
}
