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

/// 인메모리 사용자 카테고리 저장소. 생성 순서를 유지한다(서버 계약과 동일).
class InMemoryCategoryRepository implements CategoryRepository {
  InMemoryCategoryRepository([List<CustomCategory> seed = const []]) {
    for (final c in seed) {
      items[c.id] = c;
    }
  }

  final Map<String, CustomCategory> items = {};

  @override
  Future<Result<List<CustomCategory>>> getAll() async =>
      Result.success(items.values.toList());

  @override
  Future<Result<CustomCategory>> upsert(CustomCategory category) async {
    items[category.id] = category;
    return Result.success(category);
  }

  @override
  Future<Result<CustomCategory>> delete(CustomCategory category) async {
    items.remove(category.id);
    return Result.success(category);
  }
}

/// 사용자 카테고리 의존성을 fake로 등록한다.
InMemoryCategoryRepository registerFakeCategoryDependencies([
  List<CustomCategory> seed = const [],
]) {
  final repo = InMemoryCategoryRepository(seed);
  locator
    ..registerSingleton<CategoryRepository>(repo)
    ..registerSingleton<CategoryUsecase>(CategoryUsecase(repo));
  return repo;
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
/// [profileRepository]를 주면 [profile] 대신 그 저장소를 등록한다(실패 시나리오용).
void registerFakeUserDependencies({
  AuthUser? user,
  UserProfile? profile,
  UserProfileRepository? profileRepository,
}) {
  final auth = InMemoryAuthRepository(user);
  locator
    ..registerSingleton<AuthRepository>(auth)
    ..registerSingleton<AuthUsecase>(AuthUsecase(auth, StubSocialIdTokenProvider()))
    ..registerSingleton<UserProfileRepository>(
      profileRepository ?? InMemoryUserProfileRepository(profile),
    );
}
