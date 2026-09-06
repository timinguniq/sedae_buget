import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// presentation 테스트용 인메모리 fake. 실제 API 구현체 대신 get_it에 등록한다.
class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository([this.user]);

  AuthUser? user;

  @override
  Future<AuthUser?> currentUser() async => user;

  @override
  Future<AuthUser> signIn(AuthProvider provider, String idToken) async =>
      user = AuthUser(provider: provider, nickname: '${provider.label} 사용자');

  @override
  Future<void> signOut() async => user = null;
}

class InMemoryUserProfileRepository implements UserProfileRepository {
  InMemoryUserProfileRepository([this.profile]);

  UserProfile? profile;

  @override
  Future<UserProfile?> current() async => profile;

  @override
  Future<void> save(UserProfile p) async => profile = p;

  @override
  Future<void> clear() async => profile = null;
}

/// Stub 서버와 같은 결정적 수치를 돌려주는 또래 통계 fake.
class FakePeerStatsRepository implements PeerStatsRepository {
  @override
  Future<PeerStats> forGroup(AgeGroup g) async => StubPeerData.forGroup(g);

  @override
  Future<Map<AgeGroup, int>> generationAverages() async =>
      {for (final g in AgeGroup.values) g: StubPeerData.forGroup(g).avgMonthlyExpense};
}

/// 또래 통계 의존성을 fake로 등록한다.
void registerFakePeerDependencies() =>
    locator.registerSingleton<PeerStatsRepository>(FakePeerStatsRepository());

/// 인증·프로필 의존성을 fake로 등록한다. `tearDown(() => locator.reset())`과 함께 쓴다.
void registerFakeUserDependencies({AuthUser? user, UserProfile? profile}) {
  final auth = InMemoryAuthRepository(user);
  locator
    ..registerSingleton<AuthRepository>(auth)
    ..registerSingleton<AuthUsecase>(AuthUsecase(auth, StubSocialIdTokenProvider()))
    ..registerSingleton<UserProfileRepository>(InMemoryUserProfileRepository(profile));
}
