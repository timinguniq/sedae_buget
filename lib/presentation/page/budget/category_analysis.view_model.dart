import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/usecase/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/budget_home.view_model.dart';
import 'package:sedae_budget/presentation/page/budget/category_manage.view_model.dart';

/// 분석 화면용 항목별 합계. 커스텀 카테고리를 상위 기본 분류에서 분리한다.
/// 또래 비교는 여기가 아니라 [monthlySummaryProvider]의 기본 분류 집계만 쓴다.
/// 카테고리 목록을 못 읽으면 기본 분류만으로 묶는다(합계는 그대로).
final categoryBreakdownProvider = Provider<AsyncValue<List<CategoryBreakdown>>>((ref) {
  final usecase = locator<TransactionUsecase>();
  final customs = ref.watch(customCategoriesProvider).value ?? const <CustomCategory>[];
  return ref
      .watch(monthlyTransactionsProvider)
      .whenData((txs) => usecase.categoryBreakdown(txs, customs));
});
