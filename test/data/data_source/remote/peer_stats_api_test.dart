import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../../helper/recording_interceptor.dart';

PeerStatsApi _api(RecordingInterceptor server) => PeerStatsApi(Dio()..interceptors.add(server));

void main() {
  test('stats → GET /v1/peer/stats?ageGroup, 또래 통계를 돌려준다', () async {
    final expected = StubPeerData.forGroup(AgeGroup.thirties);
    final server = RecordingInterceptor(body: PeerStatsDto.fromEntity(expected).toJson());

    final stats = (await _api(server).stats('thirties')).toEntity();

    expect(server.single.method, 'GET');
    expect(server.single.path, '/v1/peer/stats');
    expect(server.single.queryParameters, {'ageGroup': 'thirties'});
    expect(stats.ageGroup, AgeGroup.thirties);
    expect(stats.avgMonthlyExpense, expected.avgMonthlyExpense);
    expect(stats.avgSavingsRate, expected.avgSavingsRate);
    expect(stats.avgByCategory, expected.avgByCategory);
    expect(stats.samples, expected.samples);
  });

  test('generations → GET /v1/peer/generations, 나이대별 평균을 돌려준다', () async {
    final server = RecordingInterceptor(body: [
      {'ageGroup': 'teens', 'avgMonthlyExpense': 800000},
      {'ageGroup': 'thirties', 'avgMonthlyExpense': 2600000},
    ]);

    final averages = await _api(server).generations();

    expect(server.single.method, 'GET');
    expect(server.single.path, '/v1/peer/generations');
    expect(
      {for (final dto in averages) dto.ageGroup: dto.avgMonthlyExpense},
      {AgeGroup.teens: 800000, AgeGroup.thirties: 2600000},
    );
  });
}
