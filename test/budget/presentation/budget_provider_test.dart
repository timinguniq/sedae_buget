import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

void main() {
  test('monthlyTransactionsProvider loads via usecase', () async {
    final container = ProviderContainer(overrides: [
      transactionUsecaseProvider
          .overrideWithValue(TransactionUsecase(_FakeRepo())),
    ]);
    addTearDown(container.dispose);

    final list = await container.read(monthlyTransactionsProvider.future);
    expect(list.single.amount, 1200);
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
