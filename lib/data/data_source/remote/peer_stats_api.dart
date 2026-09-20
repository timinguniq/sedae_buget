import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:sedae_budget/data/data_source/remote/api_path.dart';
import 'package:sedae_budget/data/dto/peer_stats_dto.dart';

part 'peer_stats_api.g.dart';

/// 또래 통계 엔드포인트(`/v1/peer/*`) 명세.
@RestApi()
abstract class PeerStatsApi {
  factory PeerStatsApi(Dio dio) = _PeerStatsApi;

  @GET(ApiPath.peerStats)
  Future<PeerStatsDto> stats(@Query('ageGroup') String ageGroup);

  /// 나이대별 월평균 지출.
  @GET(ApiPath.peerGenerations)
  Future<List<GenerationAverageDto>> generations();
}
