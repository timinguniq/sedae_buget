import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sedae_budget/core/ads/index.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// 광고 SDK 없이 호출 횟수만 기록하는 fake. 배너는 항상 실패(null), 전면은 [interstitial]의 결과를 따른다.
class FakeAdService implements AdService {
  FakeAdService({Future<bool>? interstitial}) : _interstitial = interstitial ?? Future.value(true);

  final Future<bool> _interstitial;
  int loadInterstitialCalls = 0;
  int showInterstitialCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<BannerAd?> loadBanner() async => null;

  @override
  Future<bool> loadInterstitial() {
    loadInterstitialCalls++;
    return _interstitial;
  }

  @override
  Future<void> showInterstitial() async => showInterstitialCalls++;
}

/// 광고 의존성을 fake로 등록한다. 앱 실행 카운트(SharedPreferences mock)는 0에서 시작한다.
Future<FakeAdService> registerFakeAdDependencies() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final ads = FakeAdService();
  locator
    ..registerSingleton<AdService>(ads)
    ..registerSingleton<LaunchInterstitial>(LaunchInterstitial(prefs, ads));
  return ads;
}

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
