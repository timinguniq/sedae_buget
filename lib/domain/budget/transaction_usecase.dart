import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/entity/entity.dart';

class TransactionUsecase {
  TransactionUsecase(this._repo);

  final TransactionRepository _repo;

  Future<Result<Transaction>> add({
    required int amount,
    required int categoryId,
    required DateTime date,
    required TransactionType type,
    String? memo,
  }) {
    return _repo.upsert(Transaction.create(
      amount: amount,
      categoryId: categoryId,
      date: date,
      type: type,
      memo: memo,
    ));
  }

  Future<Result<Transaction>> update(Transaction tx) => _repo.upsert(tx);

  Future<Result<Transaction>> delete(Transaction tx) => _repo.delete(tx);

  Future<Result<List<Transaction>>> getMonth(int year, int month) =>
      _repo.getMonth(year, month);

  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) =>
      _repo.getRange(start, end);

  Map<BudgetCategory, int> categorySummary(List<Transaction> txs) {
    final map = <BudgetCategory, int>{};
    for (final t in txs.where((t) => t.type == TransactionType.expense)) {
      final c = BudgetCategory.fromId(t.categoryId);
      map[c] = (map[c] ?? 0) + t.amount;
    }
    return map;
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
