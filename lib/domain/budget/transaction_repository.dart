import 'package:sedae_budget/entity/budget/transaction.dart';
import 'package:sedae_budget/entity/entity.dart';

abstract class TransactionRepository {
  Future<Result<Transaction>> upsert(Transaction tx);
  Future<Result<List<Transaction>>> getMonth(int year, int month);
}
