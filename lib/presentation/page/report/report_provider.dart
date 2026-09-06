import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/budget_provider.dart';
import 'package:sedae_budget/presentation/page/onboarding/user_profile_provider.dart';

/// 최근 6개월 자기 지출 추이 (oldest → newest).
final selfTrendProvider =
    FutureProvider<List<({DateTime month, int expense})>>((ref) async {
  final anchor = ref.watch(selectedMonthProvider);
  final usecase = locator<TransactionUsecase>();
  const n = 6;
  final start = DateTime(anchor.year, anchor.month - (n - 1));
  final end = DateTime(anchor.year, anchor.month + 1); // exclusive
  final res = await usecase.getRange(start, end);
  final txs =
      res is Success<List<Transaction>> ? res.data : <Transaction>[];
  return List.generate(n, (i) {
    final m = DateTime(anchor.year, anchor.month - (n - 1) + i);
    final expense = usecase.totalExpense(
        txs.where((t) => t.date.year == m.year && t.date.month == m.month).toList());
    return (month: m, expense: expense);
  });
});

/// 이달 저축률(%). 소득 우선순위 규칙은 usecase에 있다. 요약 로딩 전에는 null.
final savingsRateProvider = Provider<int?>((ref) {
  final s = ref.watch(monthlySummaryProvider).value;
  if (s == null) return null;
  final usecase = locator<TransactionUsecase>();
  final income = usecase.effectiveIncome(
    txIncome: s.income,
    profileIncome: ref.watch(userProfileProvider).value?.monthlyIncome,
  );
  return usecase.savingsRatePercent(income: income, expense: s.expense);
});
