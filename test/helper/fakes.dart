import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sedae_budget/core/ads/index.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/compare/compare.view_model.dart';
import 'package:sedae_budget/presentation/service/ad_provider.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// presentation 테스트용 인메모리 fake. 전역 get_it을 만지는 대신
/// `ProviderScope(overrides: ...)`로 끼운다(seam은 service/*_provider.dart).
class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository([this.user]);

  AuthUser? user;

  @override
  Future<Result<AuthUser?>> currentUser() async => Result.success(user);

  @override
  Future<Result<AuthUser>> signIn(AuthProvider provider, String idToken) async =>
      Result.success(user = AuthUser(provider: provider, nickname: '${provider.label} 사용자'));

  @override
  Future<Result<void>> signOut() async {
    user = null;
    return const Result.success(null);
  }
}

class InMemoryUserProfileRepository implements UserProfileRepository {
  InMemoryUserProfileRepository([this.profile]);

  UserProfile? profile;

  @override
  Future<Result<UserProfile?>> current() async => Result.success(profile);

  @override
  Future<Result<void>> save(UserProfile p) async {
    profile = p;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> clear() async {
    profile = null;
    return const Result.success(null);
  }
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

/// Stub 서버와 같은 결정적 수치를 돌려주는 또래 통계 fake.
class FakePeerStatsRepository implements PeerStatsRepository {
  @override
  Future<Result<PeerStats>> forGroup(AgeGroup g) async =>
      Result.success(StubPeerData.forGroup(g));

  @override
  Future<Result<Map<AgeGroup, int>>> generationAverages() async => Result.success(
      {for (final g in AgeGroup.values) g: StubPeerData.forGroup(g).avgMonthlyExpense});
}

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

/// 앱 실행 카운트(SharedPreferences mock)를 0에서 시작시키고 광고 정책을 만든다.
Future<LaunchInterstitial> fakeLaunchInterstitial(FakeAdService ads) async {
  SharedPreferences.setMockInitialValues({});
  return LaunchInterstitial(await SharedPreferences.getInstance(), ads);
}

/// 테스트용 ProviderContainer. 준 재료만 fake로 바꾼다.
///
/// 전역 get_it을 등록·reset하는 대신 의존성 seam(`service/*_provider.dart`)을 override한다.
/// 테스트가 끝나면 스스로 dispose한다.
ProviderContainer fakeContainer({
  AuthUser? user,
  UserProfile? profile,
  AuthRepository? authRepository,
  UserProfileRepository? profileRepository,
  bool fakeUser = true,
  TransactionRepository? transactions,
  CategoryRepository? categories,
  PeerStatsRepository? peerRepository,
  PeerStats? peerStats,
  AdService? adService,
  LaunchInterstitial? launchInterstitial,
}) {
  final auth = authRepository ?? InMemoryAuthRepository(user);
  final container = ProviderContainer(
    // 실패한 provider를 자동 재시도하면 타이머가 테스트 끝까지 남는다. 테스트는 한 번만 본다.
    retry: (_, _) => null,
    overrides: [
      if (fakeUser) ...[
        authUsecaseProvider.overrideWithValue(AuthUsecase(auth, StubSocialIdTokenProvider())),
        userProfileRepositoryProvider.overrideWithValue(
          profileRepository ?? InMemoryUserProfileRepository(profile),
        ),
      ],
      if (transactions != null)
        transactionUsecaseProvider.overrideWithValue(TransactionUsecase(transactions)),
      if (categories != null)
        categoryUsecaseProvider.overrideWithValue(CategoryUsecase(categories)),
      if (peerRepository != null)
        peerStatsRepositoryProvider.overrideWithValue(peerRepository),
      if (peerStats != null) peerStatsProvider.overrideWith((_) => peerStats),
      if (adService != null) adServiceProvider.overrideWithValue(adService),
      if (launchInterstitial != null)
        launchInterstitialProvider.overrideWithValue(launchInterstitial),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// [fakeContainer]가 만든 컨테이너를 위젯 트리에 끼운다.
Widget fakeScope(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(container: container, child: child);
