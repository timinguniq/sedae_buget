import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/core/ads/index.dart';
import 'package:sedae_budget/core/app_config/remote_config.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/initial/splash.page.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';
import 'package:sedae_budget/presentation/route/custom_route.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

const _profile = UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000);

void main() {
  late FakeAdService ads;

  setUp(() => ads = FakeAdService());

  /// 스플래시 광고 테스트의 공통 의존성: 광고 fake + [server](기본은 프로필까지 마친 kakao 사용자의 서버).
  /// 어디로 갈지는 전역 가드가 정한다 — 이동은 auth_gate_widget_test(실제 라우터)가 검증한다.
  Future<ProviderContainer> container(
    WidgetTester t, {
    StubServer? server,
    AppStatusSource? appStatusSource,
    void Function()? exitApp,
  }) async =>
      fakeContainer(
        server: server ?? await t.seedServer(profile: _profile),
        appStatusSource: appStatusSource,
        exitApp: exitApp,
        adService: ads,
        launchInterstitial: await fakeLaunchInterstitial(ads),
      );

  Widget buildApp(ProviderContainer c, GoRouter router) => fakeScope(
        c,
        MaterialApp.router(
            routerConfig: router,
            theme: materialTheme(LightTheme()),
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
    final c = await container(t);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LaunchInterstitial.prefsKey, 4);
    await boot(t, c);
    expect(find.text('HOME'), findsOneWidget);
    expect(ads.showInterstitialCalls, 1);
    expect(prefs.getInt(LaunchInterstitial.prefsKey), 0);
  });

  // 이전에는 가드가 로그인·온보딩으로 보내도 그 화면 위에 전면 광고를 띄웠다.
  // 홈에 닿지 않는 실행이면 그 실행에는 광고를 띄우지 않는다(카운트는 이미 0으로 돌아갔다).
  for (final (name, seed) in [
    ('로그아웃', (WidgetTester t) => t.seedServer(provider: null)),
    ('프로필 필요', (WidgetTester t) => t.seedServer()),
    ('연결 안 됨', (WidgetTester t) async =>
        (await t.seedServer(profile: _profile))..faults.fail('GET', '/v1/me')),
  ]) {
    testWidgets('5번째 실행이어도 $name 상태면 전면 광고를 띄우지 않는다', (t) async {
      final c = await container(t, server: await seed(t));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(LaunchInterstitial.prefsKey, 4);
      await boot(t, c);
      expect(ads.showInterstitialCalls, 0);
      expect(prefs.getInt(LaunchInterstitial.prefsKey), 0);
    });
  }

  // 광고 로드는 최대 5초를 기다린다. 그동안 세션이 끝나면(401·로그아웃) 가드가 로그인 화면으로 보내므로 그 위에 띄우지 않는다.
  testWidgets('5번째 실행에서 광고를 로드하는 동안 세션이 끝나면 전면 광고를 띄우지 않는다', (t) async {
    final load = Completer<bool>();
    ads = FakeAdService(interstitial: load.future);
    final server = await t.seedServer(profile: _profile);
    final c = await container(t, server: server);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LaunchInterstitial.prefsKey, 4);
    await boot(t, c);
    expect(find.text('HOME'), findsOneWidget);
    expect(c.read(sessionGateProvider), SessionGate.ready);

    await t.pump(const Duration(seconds: 1)); // 로드는 시간이 걸리고, 그동안 스플래시는 사라진다
    expect(find.byType(SplashPage), findsNothing);
    await t.untilDone(server.expireSession()); // 서버가 저장된 토큰을 거부(401) → 로그아웃
    await t.pump();
    expect(c.read(sessionGateProvider), SessionGate.signedOut);

    load.complete(true); // 이제야 로드가 끝났다
    await t.pump();
    expect(ads.showInterstitialCalls, 0);
  });

  // 스플래시가 끝날 때 홈으로 가지 않은 실행(로그인 화면 등)은, 로드를 기다리는 동안 로그인해 준비됨이 돼도 띄우지 않는다.
  testWidgets('5번째 실행에서 로그아웃 상태였으면 광고를 로드하는 동안 준비됨이 돼도 띄우지 않는다', (t) async {
    final load = Completer<bool>();
    ads = FakeAdService(interstitial: load.future);
    final c = await container(t, server: await t.seedServer(provider: null));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LaunchInterstitial.prefsKey, 4);
    await boot(t, c);
    expect(c.read(sessionGateProvider), SessionGate.signedOut);

    await t.untilDone(c.read(authProvider.notifier).signIn(AuthProvider.kakao));
    await t.untilDone(c.read(userProfileProvider.notifier).save(_profile));
    expect(c.read(sessionGateProvider), SessionGate.ready);

    load.complete(true);
    await t.pump();
    expect(ads.showInterstitialCalls, 0);
  });

  testWidgets('5번째가 아니면 전면 광고를 띄우지 않는다', (t) async {
    await boot(t, await container(t));
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
      t,
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
