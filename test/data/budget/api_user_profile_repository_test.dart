import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

class _Tokens implements AuthTokenStore {
  String? t = 'stub.kakao';
  @override
  Future<String?> read() async => t;
  @override
  Future<void> write(String token) async => t = token;
  @override
  Future<void> clear() async => t = null;
}

void main() {
  late _Tokens tokens;
  late UserProfileRepository repo;

  setUp(() {
    tokens = _Tokens();
    repo = ApiUserProfileRepository(ApiClient(Dio()
      ..interceptors.add(AuthTokenInterceptor(tokens))
      ..interceptors.add(StubApiInterceptor())));
  });

  test('save → current → clear round-trip (404 → null)', () async {
    expect(await repo.current(), isNull);
    await repo.save(const UserProfile(ageGroup: AgeGroup.twenties, monthlyIncome: 2500000));
    final got = await repo.current();
    expect(got?.ageGroup, AgeGroup.twenties);
    expect(got?.monthlyIncome, 2500000);
    await repo.clear();
    expect(await repo.current(), isNull);
  });

  test('without token → 401 propagates as ApiException', () async {
    tokens.t = null;
    expect(
      () => repo.current(),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'unauthorized', isTrue)),
    );
  });
}
