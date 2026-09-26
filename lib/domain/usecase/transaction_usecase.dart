import 'package:sedae_budget/domain/repository/transaction_repository.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 거래를 서버 장부에 읽고 쓰는 흐름. 달의 합계·분류·저축률 계산은 entity([ViewedMonth])가 한다.
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
}
