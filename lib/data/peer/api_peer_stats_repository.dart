import 'package:sedae_budget/core/http_client/api_client.dart';
import 'package:sedae_budget/data/peer/peer_stats_json.dart';
import 'package:sedae_budget/data/remote/api_path.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버 집계 또래 통계.
class ApiPeerStatsRepository implements PeerStatsRepository {
  ApiPeerStatsRepository(this._api);

  final ApiClient _api;

  @override
  Future<PeerStats> forGroup(AgeGroup group) async => peerStatsFromJson(
        await _api.get<Map<String, dynamic>>(
          ApiPath.peerStats,
          query: {'ageGroup': group.name},
        ),
      );

  @override
  Future<Map<AgeGroup, int>> generationAverages() async {
    final list = await _api.get<List<dynamic>>(ApiPath.peerGenerations);
    return {
      for (final e in list.cast<Map<String, dynamic>>())
        AgeGroup.values.byName(e['ageGroup'] as String):
            (e['avgMonthlyExpense'] as num).toInt(),
    };
  }
}
