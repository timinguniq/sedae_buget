import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../helper/stub_server.dart';

void main() {
  late MemoryAuthTokenStore tokens;
  late UserProfileRepository repo;

  setUp(() async {
    final server = StubServer();
    await server.signIn(AuthProvider.kakao);
    tokens = server.tokens;
    repo = server.profiles;
  });

  test('save → current → clear round-trip (404 → null)', () async {
    expect((await repo.current()).unwrap(), isNull);
    await repo.save(const UserProfile(ageGroup: AgeGroup.twenties, monthlyIncome: 2500000));
    final got = (await repo.current()).unwrap();
    expect(got?.ageGroup, AgeGroup.twenties);
    expect(got?.monthlyIncome, 2500000);
    await repo.clear();
    expect((await repo.current()).unwrap(), isNull);
  });

  test('without token → 401이 unauthorized 실패로 온다', () async {
    tokens.token = null;
    expect((await repo.current()).failureOrNull?.reason, FailureReason.unauthorized);
  });
}
