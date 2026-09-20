import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:sedae_budget/data/data_source/remote/api_path.dart';
import 'package:sedae_budget/data/dto/transaction_dto.dart';

part 'transaction_api.g.dart';

/// 거래 엔드포인트(`/v1/transactions`) 명세. 일시는 모두 UTC ISO-8601.
@RestApi()
abstract class TransactionApi {
  factory TransactionApi(Dio dio) = _TransactionApi;

  /// `[from, to)` 반개구간. date 내림차순.
  @GET(ApiPath.transactions)
  Future<List<TransactionDto>> list(@Query('from') String from, @Query('to') String to);

  /// id는 클라이언트 UUID(upsert). 타임스탬프는 서버 응답을 따른다.
  @PUT('${ApiPath.transactions}/{id}')
  Future<TransactionDto> put(@Path('id') String id, @Body() TransactionBodyDto body);

  @DELETE('${ApiPath.transactions}/{id}')
  Future<void> delete(@Path('id') String id);
}
