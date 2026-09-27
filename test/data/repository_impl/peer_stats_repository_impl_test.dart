import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../helper/fake_http_adapter.dart';
import '../../helper/stub_server.dart';

void main() {
  late PeerStatsRepository repo;

  setUp(() async {
    final server = StubServer();
    await server.signIn(AuthProvider.kakao);
    repo = server.peerStats;
  });

  test('forGroup parses server JSON into PeerStats equal to StubPeerData', () async {
    final got = (await repo.forGroup(AgeGroup.thirties)).unwrap();
    final expected = StubPeerData.forGroup(AgeGroup.thirties);
    expect(got.ageGroup, AgeGroup.thirties);
    expect(got.avgMonthlyExpense, expected.avgMonthlyExpense);
    expect(got.avgSavingsRate, expected.avgSavingsRate);
    expect(got.avgByCategory, expected.avgByCategory);
    expect(got.samples, expected.samples);
  });

  test('forGroup asks the server for the given age group', () async {
    for (final group in AgeGroup.values) {
      expect((await repo.forGroup(group)).unwrap().ageGroup, group);
    }
  });

  test('generationAverages returns every age group', () async {
    final avgs = (await repo.generationAverages()).unwrap();
    expect(avgs.keys, unorderedEquals(AgeGroup.values));
    expect(avgs[AgeGroup.teens], StubPeerData.forGroup(AgeGroup.teens).avgMonthlyExpense);
  });

  test('세대별 평균에서 모르는 나이대 행은 버린다', () async {
    final repo = PeerStatsRepositoryImpl(PeerStatsApi(fakeDio(FakeHttpAdapter.reply(200,
        '[{"ageGroup":"teens","avgMonthlyExpense":800000},{"ageGroup":"lateTwenties","avgMonthlyExpense":1}]'))));
    expect((await repo.generationAverages()).unwrap(), {AgeGroup.teens: 800000});
  });

  test('또래 통계는 응답의 나이대가 무엇이든 요청한 나이대로 읽는다', () async {
    final repo = PeerStatsRepositoryImpl(PeerStatsApi(fakeDio(FakeHttpAdapter.reply(200,
        '{"ageGroup":"lateTwenties","avgMonthlyExpense":1900000,"avgSavingsRate":0.2,'
        '"avgByCategory":{"1":300000},"samples":[1000000]}'))));
    final stats = (await repo.forGroup(AgeGroup.twenties)).unwrap();
    expect(stats.ageGroup, AgeGroup.twenties);
    expect(stats.avgMonthlyExpense, 1900000);
  });
}
