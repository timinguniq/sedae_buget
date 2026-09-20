import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/budget_home.view_model.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';

/// 최근 6개월 자기 지출 추이 (oldest → newest).
final selfTrendProvider =
    FutureProvider<List<({DateTime month, int expense})>>((ref) async {
  final anchor = ref.watch(selectedMonthProvider);
  final usecase = ref.watch(transactionUsecaseProvider);
  const n = 6;
  final start = DateTime(anchor.year, anchor.month - (n - 1));
  final end = DateTime(anchor.year, anchor.month + 1); // exclusive
  // 실패를 빈 목록으로 감추면 "지출 0"인 평탄한 추이로 보인다. 그대로 드러낸다.
  final txs = (await usecase.getRange(start, end)).unwrap();
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
  final usecase = ref.watch(transactionUsecaseProvider);
  final income = usecase.effectiveIncome(
    txIncome: s.income,
    profileIncome: ref.watch(userProfileProvider).value?.monthlyIncome,
  );
  return usecase.savingsRatePercent(income: income, expense: s.expense);
});
