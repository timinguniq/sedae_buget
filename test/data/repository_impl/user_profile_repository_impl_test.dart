import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../helper/fake_http_adapter.dart';
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

  test('save → current round-trip (404 → null first)', () async {
    expect((await repo.current()).unwrap(), isNull);
    await repo.save(const UserProfile(ageGroup: AgeGroup.twenties, monthlyIncome: 2500000));
    final got = (await repo.current()).unwrap();
    expect(got?.ageGroup, AgeGroup.twenties);
    expect(got?.monthlyIncome, 2500000);
  });

  test('without token → 401이 unauthorized 실패로 온다', () async {
    tokens.token = null;
    expect((await repo.current()).failureOrNull?.reason, FailureReason.unauthorized);
  });

  // 이전에는 모든 404를 '프로필 없음'으로 읽었다. 서버에 프로필 경로가 없거나 주소가 틀리면
  // 로그인한 사용자 전원이 온보딩으로 가서 기존 프로필을 덮어쓸 수 있었다.
  test('프로필 없음(PROFILE_NOT_FOUND)이 아닌 404는 실패다', () async {
    final repo = UserProfileRepositoryImpl(
        UserProfileApi(fakeDio(FakeHttpAdapter.reply(404, errorBody('NOT_FOUND')))));
    expect((await repo.current()).failureOrNull?.reason, FailureReason.notFound);
  });
}
