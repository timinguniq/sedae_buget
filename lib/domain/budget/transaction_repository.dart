import 'package:sedae_budget/entity/entity.dart';

abstract class TransactionRepository {
  Future<Result<Transaction>> upsert(Transaction tx);

  /// 삭제한 거래를 그대로 돌려준다.
  Future<Result<Transaction>> delete(Transaction tx);

  Future<Result<List<Transaction>>> getMonth(int year, int month);
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end);
}
