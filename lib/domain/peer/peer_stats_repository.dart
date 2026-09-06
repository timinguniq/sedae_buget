import 'package:sedae_budget/entity/entity.dart';

/// 또래(같은 나이대) 집계 통계 조회. 구현은 서버(ApiPeerStatsRepository).
abstract class PeerStatsRepository {
  Future<PeerStats> forGroup(AgeGroup group);

  /// 나이대별 월평균 지출(리포트 세대별 차트).
  Future<Map<AgeGroup, int>> generationAverages();
}
