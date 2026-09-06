import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 분석 화면 한 줄. [custom]이 null이면 기본 분류 자체, 아니면 사용자 카테고리.
typedef CategoryBreakdown = ({BudgetCategory base, CustomCategory? custom, int amount});

class TransactionUsecase {
  TransactionUsecase(this._repo);

  final TransactionRepository _repo;

  Future<Result<Transaction>> add({
    required int amount,
    required int categoryId,
    required DateTime date,
    required TransactionType type,
    String? memo,
    String? customCategoryId,
  }) {
    return _repo.upsert(Transaction.create(
      amount: amount,
      categoryId: categoryId,
      date: date,
      type: type,
      memo: memo,
      customCategoryId: customCategoryId,
    ));
  }

  Future<Result<Transaction>> update(Transaction tx) => _repo.upsert(tx);

  Future<Result<Transaction>> delete(Transaction tx) => _repo.delete(tx);

  Future<Result<List<Transaction>>> getMonth(int year, int month) =>
      _repo.getMonth(year, month);

  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) =>
      _repo.getRange(start, end);

  /// 기본 분류(통계청 12분류)별 지출 합계. 커스텀 카테고리 지출도 상위 분류에 합산된다.
  /// 또래 비교는 항상 이 집계만 쓴다.
  Map<BudgetCategory, int> categorySummary(List<Transaction> txs) {
    final map = <BudgetCategory, int>{};
    for (final t in txs.where((t) => t.type == TransactionType.expense)) {
      final c = BudgetCategory.fromId(t.categoryId);
      map[c] = (map[c] ?? 0) + t.amount;
    }
    return map;
  }

  /// 분석 화면용 항목별 합계. 커스텀 카테고리 지출은 상위 기본 분류에서 떼어내 별도 항목으로 낸다.
  /// 금액 내림차순. 또래 평균이 있는 항목은 [CategoryBreakdown.custom]이 null인 기본 분류뿐이다.
  List<CategoryBreakdown> categoryBreakdown(
    List<Transaction> txs,
    List<CustomCategory> customs,
  ) {
    final base = <BudgetCategory, int>{};
    final byCustom = <String, int>{};
    for (final t in txs.where((t) => t.type == TransactionType.expense)) {
      final custom = customs.byId(t.customCategoryId);
      if (custom == null) {
        final c = BudgetCategory.fromId(t.categoryId);
        base[c] = (base[c] ?? 0) + t.amount;
      } else {
        byCustom[custom.id] = (byCustom[custom.id] ?? 0) + t.amount;
      }
    }
    return [
      for (final e in base.entries) (base: e.key, custom: null, amount: e.value),
      for (final c in customs)
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

  /// 저축률(%) = (소득 - 지출) / 소득 × 100, 반올림. 소득 0이면 0.
  int savingsRatePercent({required int income, required int expense}) =>
      income > 0 ? ((income - expense) * 100 / income).round() : 0;
}
