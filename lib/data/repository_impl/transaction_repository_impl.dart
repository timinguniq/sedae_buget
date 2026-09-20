import 'package:sedae_budget/data/data_source/remote/transaction_api.dart';
import 'package:sedae_budget/data/dto/transaction_dto.dart';
import 'package:sedae_budget/data/repository_impl/api_call.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버 단독 거래 저장소. id는 클라이언트 UUID로 PUT(upsert), 타임스탬프는 서버 응답을 따른다.
/// 일시는 UTC로 보내고 로컬 시각으로 돌려준다.
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._api);

  final TransactionApi _api;

  @override
  Future<Result<Transaction>> upsert(Transaction tx) => guardApi(
        () async => (await _api.put(tx.id, TransactionBodyDto.fromEntity(tx))).toEntity(),
      );

  @override
  Future<Result<Transaction>> delete(Transaction tx) => guardApi(() async {
        await _api.delete(tx.id);
        return tx;
      });

  @override
  Future<Result<List<Transaction>>> getMonth(int year, int month) =>
      getRange(DateTime(year, month), DateTime(year, month + 1)); // 12월이면 다음 해 1월로 자동 보정

  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) => guardApi(
        () async => [
          for (final dto in await _api.list(utcQuery(start), utcQuery(end))) dto.toEntity(),
        ],
      );
}
