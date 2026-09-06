import 'package:sedae_budget/entity/entity.dart';

/// 또래(같은 나이대) 집계 통계 조회.
/// 현재 구현은 결정적 목업. Phase 2에서 Gleam 서버 구현으로 교체(비동기 계약 유지).
abstract class PeerStatsRepository {
  Future<PeerStats> forGroup(AgeGroup group);
}
