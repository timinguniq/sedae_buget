import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/budget_provider.dart';

/// 최근 6개월 자기 지출 추이 (oldest → newest).
final selfTrendProvider =
    FutureProvider<List<({DateTime month, int expense})>>((ref) async {
  final anchor = ref.watch(selectedMonthProvider);
  final usecase = ref.read(transactionUsecaseProvider);
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
