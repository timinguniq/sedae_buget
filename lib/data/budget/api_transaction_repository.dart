import 'package:sedae_budget/core/http_client/api_client.dart';
import 'package:sedae_budget/data/budget/transaction_json.dart';
import 'package:sedae_budget/data/remote/api_path.dart';
import 'package:sedae_budget/data/remote/api_result.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버 단독 거래 저장소. id는 클라이언트 UUID로 PUT(upsert), 타임스탬프는 서버 응답을 따른다.
class ApiTransactionRepository implements TransactionRepository {
  ApiTransactionRepository(this._api);

  final ApiClient _api;

  @override
  Future<Result<Transaction>> upsert(Transaction tx) => guardApi(
        () async => transactionFromJson(
          await _api.put<Map<String, dynamic>>(
            ApiPath.transaction(tx.id),
            body: transactionToBody(tx),
          ),
        ),
      );

  @override
  Future<Result<Transaction>> delete(Transaction tx) => guardApi(() async {
        await _api.delete(ApiPath.transaction(tx.id));
        return tx;
      });

  @override
  Future<Result<List<Transaction>>> getMonth(int year, int month) =>
      getRange(DateTime(year, month), DateTime(year, month + 1)); // 12월이면 다음 해 1월로 자동 보정

  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) =>
      guardApi(() async {
        final list = await _api.get<List<dynamic>>(
          ApiPath.transactions,
          query: {'from': utcQuery(start), 'to': utcQuery(end)},
        );
        return list.cast<Map<String, dynamic>>().map(transactionFromJson).toList();
      });
}
