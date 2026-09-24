import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

final locator = GetIt.instance;
final _logger = CustomLogger.create(tag: 'DI');

/// API 인프라. 다른 configure*보다 먼저 호출한다. env가 local이면 Stub API를 끼운다.
void configureApiDependencies(AuthTokenStore tokenStore) {
  if (locator.isRegistered<ApiClient>()) return;
  final env = EnvironmentConfig.env;
  final isStub = env == AppEnvironment.local;
  if (!isStub && env.endpoint.server.isEmpty) {
    _logger.w('env=${env.name}인데 서버 주소가 비어 있음 — environment_config.dart에 기입 필요');
  }
  final sessionExpiry = SessionExpiry();
  locator
    ..registerSingleton<AuthTokenStore>(tokenStore)
    ..registerSingleton<SessionExpiry>(sessionExpiry)
    ..registerSingleton<ApiClient>(
      ApiClient.create(
        baseUrl: env.endpoint.server,
        tokenStore: tokenStore,
        sessionExpiry: sessionExpiry,
        extra: [if (isStub) StubApiInterceptor(store: SharedPrefsStubStateStore())],
      ),
    );
}

/// 거래·카테고리 의존성(서버). [configureApiDependencies]가 먼저 호출되어 있어야 한다.
void configureBudgetDependencies() {
  if (locator.isRegistered<TransactionUsecase>()) return;
  locator
    ..registerSingleton<TransactionRepository>(
      TransactionRepositoryImpl(TransactionApi(locator<ApiClient>().dio)),
    )
    ..registerSingleton<TransactionUsecase>(
      TransactionUsecase(locator<TransactionRepository>()),
    )
    ..registerSingleton<CategoryRepository>(
      CategoryRepositoryImpl(CategoryApi(locator<ApiClient>().dio)),
    )
    ..registerSingleton<CategoryUsecase>(
      CategoryUsecase(locator<CategoryRepository>()),
    );
}

/// 또래 통계 의존성(서버). [configureApiDependencies]가 먼저 호출되어 있어야 한다.
void configurePeerDependencies() {
  if (locator.isRegistered<PeerStatsRepository>()) return;
  locator.registerSingleton<PeerStatsRepository>(
    PeerStatsRepositoryImpl(PeerStatsApi(locator<ApiClient>().dio)),
  );
}

/// 인증·프로필 의존성. 둘 다 서버(AuthRepositoryImpl, UserProfileRepositoryImpl).
/// [configureApiDependencies]가 먼저 호출되어 있어야 한다.
void configureUserDependencies() {
  if (locator.isRegistered<AuthUsecase>()) return;
  locator
    ..registerSingleton<AuthRepository>(
      AuthRepositoryImpl(
        AuthApi(locator<ApiClient>().dio),
        locator<AuthTokenStore>(),
        locator<SessionExpiry>(),
      ),
    )
    ..registerSingleton<SocialIdTokenProvider>(StubSocialIdTokenProvider())
    ..registerSingleton<AuthUsecase>(
      AuthUsecase(locator<AuthRepository>(), locator<SocialIdTokenProvider>()),
    )
    ..registerSingleton<UserProfileRepository>(
      UserProfileRepositoryImpl(UserProfileApi(locator<ApiClient>().dio)),
    );
}

/// 앱 이용 가능 여부(점검·업데이트) 판정 재료. Firebase가 초기화되지 않았으면 재료가 없어 판정하지 않는다.
void configureAppStatusDependencies() {
  if (locator.isRegistered<AppStatusSource>()) return;
  locator.registerSingleton<AppStatusSource>(FirebaseAppStatusSource());
}

/// 광고 의존성. web은 google_mobile_ads가 지원하지 않으므로 Null Object([NoAdService])를 끼운다.
void configureAdDependencies(SharedPreferences prefs) {
  if (locator.isRegistered<AdService>()) return;
  final AdService ads = kIsWeb ? const NoAdService() : AdMobAdService();
  locator
    ..registerSingleton<AdService>(ads)
    ..registerSingleton<LaunchInterstitial>(LaunchInterstitial(prefs, ads));
}
