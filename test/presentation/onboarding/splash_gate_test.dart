import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/ads/index.dart';
import 'package:sedae_budget/core/app_config/remote_config.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/initial/splash.page.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helper/fakes.dart';

const _user = AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자');
const _profile = UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000);

void main() {
  late FakeAdService ads;

  setUp(() => ads = FakeAdService());

  /// 스플래시 광고 테스트의 공통 의존성: 광고 fake + 준 사용자·프로필.
  /// 어디로 갈지는 전역 가드가 정한다 — 이동은 auth_gate_widget_test(실제 라우터)가 검증한다.
  Future<ProviderContainer> container({
    AuthUser? user,
    UserProfile? profile,
    AppStatusSource? appStatusSource,
    void Function()? exitApp,
  }) async =>
      fakeContainer(
        user: user,
        profile: profile,
        appStatusSource: appStatusSource,
        exitApp: exitApp,
        adService: ads,
        launchInterstitial: await fakeLaunchInterstitial(ads),
      );

  Widget buildApp(ProviderContainer c, GoRouter router) => fakeScope(
        c,
        provider.ChangeNotifierProvider(
          create: (_) => ThemeService(),
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeService().lightThemeData(),
          ),
        ),
      );

  GoRouter buildRouter() => GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
          GoRoute(path: '/budget', builder: (_, _) => const Scaffold(body: Text('HOME'))),
        ],
      );

  Future<void> boot(WidgetTester t, ProviderContainer c) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(buildApp(c, buildRouter()));
    await t.pump(); // initial frame + postFrameCallback schedules appInitialize
    await t.pump(const Duration(milliseconds: 2100)); // pass the 2000ms delay
    await t.pump(); // flush provider read microtasks + navigation
    await t.pump(const Duration(milliseconds: 300)); // build the target page
  }

  testWidgets('4번 켠 뒤(5번째 실행) → 홈 진입 후 전면 광고를 띄우고 카운트를 0으로', (t) async {
    final c = await container(user: _user, profile: _profile);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LaunchInterstitial.prefsKey, 4);
    await boot(t, c);
    expect(find.text('HOME'), findsOneWidget);
    expect(ads.showInterstitialCalls, 1);
    expect(prefs.getInt(LaunchInterstitial.prefsKey), 0);
  });

  testWidgets('5번째가 아니면 전면 광고를 띄우지 않는다', (t) async {
    await boot(t, await container(user: _user, profile: _profile));
    expect(find.text('HOME'), findsOneWidget);
    expect(ads.loadInterstitialCalls, 0);
    expect(ads.showInterstitialCalls, 0);
    expect((await SharedPreferences.getInstance()).getInt(LaunchInterstitial.prefsKey), 1);
  });

  // 점검 중이면 세션·광고로 넘어가지 않고, 확인하면 앱을 끝낸다.
  testWidgets('점검 중이면 스플래시에서 안내하고, 확인하면 이동 없이 앱을 끝낸다', (t) async {
    var exited = 0;
    final maintenance = AppInitialInfo(
      android: const AppVersion(releaseVersion: 1, minimumAvailableVersion: 1, link: 'a'),
      ios: const AppVersion(releaseVersion: 1, minimumAvailableVersion: 1, link: 'i'),
      serviceStatus: AppServiceStatus(
        available: false,
        noticeTitle: '점검 중이에요',
        noticeContent: '곧 돌아올게요',
        expectedTimeToBeAvailable: DateTime(2026, 9, 24, 23),
      ),
    );
    await boot(t, await container(
      user: _user,
      profile: _profile,
      appStatusSource: FakeAppStatusSource(info: maintenance),
      exitApp: () => exited++,
    ));
    expect(find.text('점검 중이에요'), findsOneWidget);

    await t.tap(find.text('확인'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(exited, 1);
    expect(find.text('HOME'), findsNothing);
    expect(ads.showInterstitialCalls, 0);
  });
}
