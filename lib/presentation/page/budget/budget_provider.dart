import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';

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
  TransactionUsecase get _usecase => locator<TransactionUsecase>();

  @override
  Future<List<Transaction>> build() async {
    final month = ref.watch(selectedMonthProvider);
    final res = await _usecase.getMonth(month.year, month.month);
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
    await _usecase.add(
      amount: amount,
      categoryId: categoryId,
      date: date,
      type: type,
      memo: memo,
    );
    ref.invalidateSelf();
  }

  Future<void> edit(Transaction tx) async {
    await _usecase.update(tx);
    ref.invalidateSelf();
  }

  Future<void> delete(Transaction tx) async {
    await _usecase.delete(tx);
    ref.invalidateSelf();
  }
}

final monthlyTransactionsProvider =
    AsyncNotifierProvider<MonthlyTransactionsNotifier, List<Transaction>>(
        MonthlyTransactionsNotifier.new);

/// 이달 거래의 파생 요약(뷰 상태). 위젯은 usecase 대신 이 값을 읽는다.
typedef MonthlySummary = ({
  int expense,
  int income,
  Map<BudgetCategory, int> byCategory,
});

final monthlySummaryProvider = Provider<AsyncValue<MonthlySummary>>((ref) {
  final usecase = locator<TransactionUsecase>();
  return ref.watch(monthlyTransactionsProvider).whenData((txs) => (
        expense: usecase.totalExpense(txs),
        income: usecase.totalIncome(txs),
        byCategory: usecase.categorySummary(txs),
      ));
});
