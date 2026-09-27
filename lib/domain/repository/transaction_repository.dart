import 'package:sedae_budget/entity/entity.dart';

abstract class TransactionRepository {
  Future<Result<Transaction>> upsert(Transaction tx);

  /// 삭제한 거래를 그대로 돌려준다.
  Future<Result<Transaction>> delete(Transaction tx);

  /// [start] 이상 [end] 미만 날짜의 거래.
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end);
}
