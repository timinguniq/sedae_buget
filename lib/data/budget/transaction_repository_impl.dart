import 'package:sedae_budget/data/budget/transaction_local_data_source.dart';
import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/entity/budget/transaction.dart';
import 'package:sedae_budget/entity/entity.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._local);

  final TransactionLocalDataSource _local;

  @override
  Future<Result<Transaction>> upsert(Transaction tx) async {
    try {
      await _local.upsert(tx);
      return Result.success(tx);
    } catch (e) {
      return Result.failure(
        ErrorResult(resultCode: 'LOCAL_DB_ERROR', message: e.toString()),
      );
    }
  }

  @override
  Future<Result<List<Transaction>>> getMonth(int year, int month) async {
    try {
      final list = await _local.getMonth(year, month);
      return Result.success(list);
    } catch (e) {
      return Result.failure(
        ErrorResult(resultCode: 'LOCAL_DB_ERROR', message: e.toString()),
      );
    }
  }
}
