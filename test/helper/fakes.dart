import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sedae_budget/core/ads/index.dart';
import 'package:sedae_budget/core/app_config/remote_config.dart';
import 'package:sedae_budget/core/local_storage/theme_mode_store.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/initial/app_status.view_model.dart';
import 'package:sedae_budget/presentation/service/ad_provider.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';
import 'package:sedae_budget/presentation/service/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stub_server.dart';

export 'stub_server.dart';

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

/// 점검·업데이트 판정 재료 fake. 기본은 원격 정보 없음(= 쓸 수 있음).
class FakeAppStatusSource implements AppStatusSource {
  FakeAppStatusSource({this.info, this.build = 1});

  final AppInitialInfo? info;
  final int? build;
  final updates = StreamController<AppInitialInfo>.broadcast();

  @override
  Future<AppInitialInfo?> fetchInitialInfo() async => info;

  @override
  Stream<AppInitialInfo> get initialInfoUpdates => updates.stream;

  @override
  Future<int?> currentBuild() async => build;
}

/// 앱 실행 카운트(SharedPreferences mock)를 0에서 시작시키고 광고 정책을 만든다.
Future<LaunchInterstitial> fakeLaunchInterstitial(FakeAdService ads) async {
  SharedPreferences.setMockInitialValues({});
  return LaunchInterstitial(await SharedPreferences.getInstance(), ads);
}

/// 비어 있는 테마 모드 저장소(SharedPreferences mock). 고른 적이 없으니 시스템 모드다.
Future<ThemeModeStore> fakeThemeModeStore() async {
  SharedPreferences.setMockInitialValues({});
  return ThemeModeStore(await SharedPreferences.getInstance());
}

/// 테스트용 ProviderContainer. 서버는 [server](Stub, 기본은 로그인 전의 빈 서버)이고,
/// 서버 밖의 재료(광고·원격 설정·테마 저장소·앱 종료)만 fake로 바꾼다.
///
/// 전역 get_it을 등록·reset하는 대신 의존성 seam(`service/*_provider.dart`)을 override한다.
/// 테스트가 끝나면 스스로 dispose한다.
ProviderContainer fakeContainer({
  StubServer? server,
  AdService? adService,
  LaunchInterstitial? launchInterstitial,
  AppStatusSource? appStatusSource,
  ThemeModeStore? themeModeStore,
  void Function()? exitApp,
}) {
  final s = server ?? StubServer();
  final container = ProviderContainer(
    // 실패한 provider를 자동 재시도하면 타이머가 테스트 끝까지 남는다. 테스트는 한 번만 본다.
    retry: (_, _) => null,
    overrides: [
      authUsecaseProvider.overrideWithValue(AuthUsecase(s.auth, StubSocialIdTokenProvider())),
      userProfileRepositoryProvider.overrideWithValue(s.profiles),
      transactionUsecaseProvider.overrideWithValue(TransactionUsecase(s.transactions)),
      categoryUsecaseProvider.overrideWithValue(CategoryUsecase(s.categories)),
      peerStatsRepositoryProvider.overrideWithValue(s.peerStats),
      if (adService != null) adServiceProvider.overrideWithValue(adService),
      if (launchInterstitial != null)
        launchInterstitialProvider.overrideWithValue(launchInterstitial),
      appStatusSourceProvider.overrideWithValue(appStatusSource ?? FakeAppStatusSource()),
      if (themeModeStore != null) themeModeStoreProvider.overrideWithValue(themeModeStore),
      // 테스트가 점검 안내를 확인해도 테스트 프로세스가 끝나지 않게 한다.
      appExitProvider.overrideWithValue(exitApp ?? () {}),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// [fakeContainer]가 만든 컨테이너를 위젯 트리에 끼운다.
Widget fakeScope(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(container: container, child: child);
