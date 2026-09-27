import 'package:sedae_budget/data/data_source/remote/peer_stats_api.dart';
import 'package:sedae_budget/data/dto/age_group_wire.dart';
import 'package:sedae_budget/data/repository_impl/api_call.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버 집계 또래 통계.
class PeerStatsRepositoryImpl implements PeerStatsRepository {
  PeerStatsRepositoryImpl(this._api);

  final PeerStatsApi _api;

  @override
  Future<Result<PeerStats>> forGroup(AgeGroup group) =>
      guardApi(() async => (await _api.stats(group.wire)).toEntity(group));

  @override
  Future<Result<Map<AgeGroup, int>>> generationAverages() => guardApi(() async => {
        // 모르는 나이대 행은 버린다.
        for (final dto in await _api.generations()) ?dto.group: dto.avgMonthlyExpense,
      });
}
