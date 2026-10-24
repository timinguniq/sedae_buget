import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/core/dependency_injection/server_repositories.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

final locator = GetIt.instance;

/// 서버에 닿는 저장소 다섯(인증·프로필·거래·카테고리·또래 통계). 조립은 [ServerRepositories]가 한다.
/// 빌드 환경이 local이면 Stub API가 서버 대신 답한다.
void configureServerDependencies(AuthTokenStore tokenStore) {
  if (locator.isRegistered<AuthRepository>()) return;
  final server = ServerRepositories.connect(
    env: AppEnvironment.current,
    tokenStore: tokenStore,
    localServer: () => StubApiInterceptor(store: SharedPrefsStubStateStore()),
  );
  locator
    ..registerSingleton<AuthRepository>(server.auth)
    ..registerSingleton<UserProfileRepository>(server.profiles)
    ..registerSingleton<TransactionRepository>(server.transactions)
    ..registerSingleton<CategoryRepository>(server.categories)
    ..registerSingleton<PeerStatsRepository>(server.peerStats);
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

/// 테마 모드 저장. [prefs]는 앱을 켤 때 읽어 둔 것이라 첫 화면부터 고른 테마로 그린다.
void configureThemeDependencies(SharedPreferences prefs) {
  if (locator.isRegistered<ThemeModeStore>()) return;
  locator.registerSingleton<ThemeModeStore>(ThemeModeStore(prefs));
}
