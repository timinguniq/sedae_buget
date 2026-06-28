import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';

final transactionUsecaseProvider =
    Provider<TransactionUsecase>((ref) => locator<TransactionUsecase>());

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void prev() => state = DateTime(state.year, state.month - 1);
  void next() => state = DateTime(state.year, state.month + 1);
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);

class MonthlyTransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final month = ref.watch(selectedMonthProvider);
    final res =
        await ref.read(transactionUsecaseProvider).getMonth(month.year, month.month);
    if (res is Success<List<Transaction>>) {
      return res.data;
    }
    throw Exception((res as Error<List<Transaction>>).error.message);
  }

  Future<void> add({
    required int amount,
    required int categoryId,
    required DateTime date,
    required TransactionType type,
    String? memo,
  }) async {
    await ref.read(transactionUsecaseProvider).add(
          amount: amount,
          categoryId: categoryId,
          date: date,
          type: type,
          memo: memo,
        );
    ref.invalidateSelf();
  }

  Future<void> edit(Transaction tx) async {
    await ref.read(transactionUsecaseProvider).update(tx);
    ref.invalidateSelf();
  }

  Future<void> delete(Transaction tx) async {
    await ref.read(transactionUsecaseProvider).delete(tx);
    ref.invalidateSelf();
  }
}

final monthlyTransactionsProvider =
    AsyncNotifierProvider<MonthlyTransactionsNotifier, List<Transaction>>(
        MonthlyTransactionsNotifier.new);
