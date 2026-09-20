import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/domain/usecase/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';

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
  TransactionUsecase get _usecase => ref.read(transactionUsecaseProvider);

  @override
  Future<List<Transaction>> build() async {
    final month = ref.watch(selectedMonthProvider);
    return (await _usecase.getMonth(month.year, month.month)).unwrap();
  }

  /// 변경 메서드는 서버 결과를 그대로 돌려준다. 실패를 호출부가 보고 문구를 띄운다.
  Future<Result<Transaction>> add({
    required int amount,
    required int categoryId,
    required DateTime date,
    required TransactionType type,
    String? memo,
    String? customCategoryId,
  }) =>
      _apply(() => _usecase.add(
            amount: amount,
            categoryId: categoryId,
            date: date,
            type: type,
            memo: memo,
            customCategoryId: customCategoryId,
          ));

  Future<Result<Transaction>> edit(Transaction tx) => _apply(() => _usecase.update(tx));

  Future<Result<Transaction>> delete(Transaction tx) => _apply(() => _usecase.delete(tx));

  Future<Result<Transaction>> _apply(Future<Result<Transaction>> Function() run) async {
    final res = await run();
    if (res.failureOrNull == null) ref.invalidateSelf();
    return res;
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
  final usecase = ref.watch(transactionUsecaseProvider);
  return ref.watch(monthlyTransactionsProvider).whenData((txs) => (
        expense: usecase.totalExpense(txs),
        income: usecase.totalIncome(txs),
        byCategory: usecase.categorySummary(txs),
      ));
});
