import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/domain/usecase/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/ledger.view_model.dart';
import 'package:sedae_budget/presentation/page/compare/compare.view_model.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';

/// 이달 장부와 또래 통계를 화면이 바로 쓰는 값으로 묶은 것.
/// 홈·비교·내역·리포트·분석이 모두 이 값을 읽어, 계산 규칙이 화면마다 갈라지지 않는다.
class MonthOverview {
  const MonthOverview({
    required this.transactions,
    required this.catalog,
    required this.expense,
    required this.income,
    required this.byCategory,
    required this.breakdown,
    required this.savingsRate,
    required this.peer,
  });

  /// 또래 통계를 못 읽었을 때([peer]가 null) 보여줄 문구.
  static const peerUnavailable = '또래 통계를 불러오지 못했어요';

  /// 이달 거래(최신순).
  final List<Transaction> transactions;

  /// 거래의 카테고리 판정(표시 이름·기본 분류).
  final CategoryCatalog catalog;

  final int expense;
  final int income;

  /// 기본 분류별 지출. 사용자 카테고리 지출은 상위 분류에 합산된다(또래 비교 기준).
  final Map<BudgetCategory, int> byCategory;

  /// 분석 화면용 항목별 합계(사용자 카테고리를 떼어낸 금액 내림차순).
  final List<CategoryBreakdown> breakdown;

  /// 이달 저축률(%). 소득(프로필 월소득, 없으면 이달 수입)이 없으면 null.
  final int? savingsRate;

  /// 또래 통계. 못 읽었으면 null이고, 내 값은 그대로 보여준다.
  final PeerStats? peer;

  /// 지출이 많은 기본 분류 상위 [n]개(금액 내림차순).
  List<MapEntry<BudgetCategory, int>> topCategories(int n) =>
      (byCategory.entries.where((e) => e.value > 0).toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(n)
          .toList();

  /// [tx]가 속한 기본 분류에서 이달 내 지출이 또래 평균보다 많은가.
  /// 지출이 아니거나 또래 통계가 없으면 false.
  bool overPeer(Transaction tx) {
    final peer = this.peer;
    if (peer == null || tx.type != TransactionType.expense) return false;
    final base = catalog.of(tx).base;
    return (byCategory[base] ?? 0) > (peer.avgByCategory[base] ?? 0);
  }
}

/// 이달 개요. 이달 거래를 못 읽으면 오류, 또래 통계는 처음 한 번만 기다리고 실패하면 빼고 낸다.
/// 사용자 카테고리를 못 읽으면 기본 분류로만 판정한다(합계는 그대로).
final monthOverviewProvider = Provider<AsyncValue<MonthOverview>>((ref) {
  final txs = ref.watch(monthlyTransactionsProvider);
  final peer = ref.watch(peerStatsProvider);
  final catalog = CategoryCatalog(ref.watch(customCategoriesProvider).value ?? const []);
  final profileIncome = ref.watch(userProfileProvider).value?.monthlyIncome;
  final usecase = ref.watch(transactionUsecaseProvider);
  if (!peer.hasValue && !peer.hasError) return const AsyncLoading();
  return txs.whenData((txs) {
    final expense = usecase.totalExpense(txs);
    final income = usecase.totalIncome(txs);
    return MonthOverview(
      transactions: txs,
      catalog: catalog,
      expense: expense,
      income: income,
      byCategory: usecase.categorySummary(txs, catalog),
      breakdown: usecase.categoryBreakdown(txs, catalog),
      savingsRate: usecase.savingsRatePercent(
        income: usecase.effectiveIncome(txIncome: income, profileIncome: profileIncome),
        expense: expense,
      ),
      peer: peer.value,
    );
  });
});
