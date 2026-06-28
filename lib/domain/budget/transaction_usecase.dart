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

  Future<Result<Transaction>> update(Transaction tx) =>
      _repo.upsert(tx.markUpdated());

  Future<Result<Transaction>> delete(Transaction tx) =>
      _repo.upsert(tx.markDeleted());

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
}
