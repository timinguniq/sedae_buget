import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

class _Tokens implements AuthTokenStore {
  @override
  Future<String?> read() async => 'stub.kakao';
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  late PeerStatsRepository repo;

  setUp(() {
    repo = ApiPeerStatsRepository(ApiClient(Dio()
      ..interceptors.add(AuthTokenInterceptor(_Tokens()))
      ..interceptors.add(StubApiInterceptor())));
  });

  test('forGroup parses server JSON into PeerStats equal to StubPeerData', () async {
    final got = await repo.forGroup(AgeGroup.thirties);
    final expected = StubPeerData.forGroup(AgeGroup.thirties);
    expect(got.ageGroup, AgeGroup.thirties);
    expect(got.avgMonthlyExpense, expected.avgMonthlyExpense);
    expect(got.avgSavingsRate, expected.avgSavingsRate);
    expect(got.avgByCategory, expected.avgByCategory);
    expect(got.samples, expected.samples);
  });

  test('generationAverages returns every age group', () async {
    final avgs = await repo.generationAverages();
    expect(avgs.keys, unorderedEquals(AgeGroup.values));
    expect(avgs[AgeGroup.teens], StubPeerData.forGroup(AgeGroup.teens).avgMonthlyExpense);
  });
}
