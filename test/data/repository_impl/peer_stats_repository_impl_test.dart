import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

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
}
