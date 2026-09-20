import 'package:sedae_budget/data/data_source/remote/peer_stats_api.dart';
import 'package:sedae_budget/data/repository_impl/api_call.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버 집계 또래 통계.
class PeerStatsRepositoryImpl implements PeerStatsRepository {
  PeerStatsRepositoryImpl(this._api);

  final PeerStatsApi _api;

  @override
  Future<PeerStats> forGroup(AgeGroup group) async =>
      (await callApi(() => _api.stats(group.name))).toEntity();

  @override
  Future<Map<AgeGroup, int>> generationAverages() async => {
        for (final dto in await callApi(_api.generations)) dto.ageGroup: dto.avgMonthlyExpense,
      };
}
