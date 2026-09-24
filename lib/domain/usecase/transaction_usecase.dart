import 'package:sedae_budget/domain/repository/transaction_repository.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 분석 화면 한 줄. [custom]이 null이면 기본 분류 자체, 아니면 사용자 카테고리.
typedef CategoryBreakdown = ({BudgetCategory base, CustomCategory? custom, int amount});

class TransactionUsecase {
  TransactionUsecase(this._repo);

  final TransactionRepository _repo;

  /// 새 거래든 고친 거래든 id로 저장한다(서버 upsert).
  Future<Result<Transaction>> save(Transaction tx) => _repo.upsert(tx);

  Future<Result<Transaction>> delete(Transaction tx) => _repo.delete(tx);

  Future<Result<List<Transaction>>> getMonth(int year, int month) =>
      _repo.getMonth(year, month);

  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) =>
      _repo.getRange(start, end);

  /// 기본 분류(통계청 12분류)별 지출 합계. 커스텀 카테고리 지출도 상위 분류에 합산된다.
  /// 또래 비교는 항상 이 집계만 쓴다.
  Map<BudgetCategory, int> categorySummary(List<Transaction> txs, CategoryCatalog catalog) {
    final map = <BudgetCategory, int>{};
    for (final t in txs.where((t) => t.type == TransactionType.expense)) {
      final c = catalog.of(t).base;
      map[c] = (map[c] ?? 0) + t.amount;
    }
    return map;
  }

  /// 분석 화면용 항목별 합계. 커스텀 카테고리 지출은 상위 기본 분류에서 떼어내 별도 항목으로 낸다.
  /// 금액 내림차순. 또래 평균이 있는 항목은 [CategoryBreakdown.custom]이 null인 기본 분류뿐이다.
  List<CategoryBreakdown> categoryBreakdown(List<Transaction> txs, CategoryCatalog catalog) {
    final base = <BudgetCategory, int>{};
    final byCustom = <String, int>{};
    for (final t in txs.where((t) => t.type == TransactionType.expense)) {
      final c = catalog.of(t);
      if (c.custom == null) {
        base[c.base] = (base[c.base] ?? 0) + t.amount;
      } else {
        byCustom[c.custom!.id] = (byCustom[c.custom!.id] ?? 0) + t.amount;
      }
    }
    return [
      for (final e in base.entries) (base: e.key, custom: null, amount: e.value),
      for (final c in catalog.customs)
        if ((byCustom[c.id] ?? 0) > 0) (base: c.base, custom: c, amount: byCustom[c.id]!),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
  }

  int totalExpense(List<Transaction> txs) => txs
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  int totalIncome(List<Transaction> txs) => txs
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  /// 저축률 계산의 소득 기준. 프로필 월소득이 양수면 그것, 아니면 이달 수입 거래 합.
  int effectiveIncome({required int txIncome, int? profileIncome}) =>
      (profileIncome ?? 0) > 0 ? profileIncome! : txIncome;

  /// 저축률(%) = (소득 - 지출) / 소득 × 100, 반올림. 소득이 없으면 계산할 수 없어 null.
  int? savingsRatePercent({required int income, required int expense}) =>
      income > 0 ? ((income - expense) * 100 / income).round() : null;
}
