import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/ads/index.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/initial/splash.page.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.page.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helper/fakes.dart';

const _user = AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자');
const _profile = UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000);

/// 서버 장애 시뮬레이션: 프로필 조회가 항상 실패한다.
class _FailingProfileRepo implements UserProfileRepository {
  @override
  Future<Result<UserProfile?>> current() async => const Result.failure(
        ErrorResult(reason: FailureReason.offline, message: 'network down'),
      );
  @override
  Future<Result<void>> save(UserProfile profile) async => const Result.success(null);
  @override
  Future<Result<void>> clear() async => const Result.success(null);
}

void main() {
  late FakeAdService ads;

  setUp(() => ads = FakeAdService());

  /// 스플래시 게이트 테스트의 공통 의존성: 광고 fake + 준 사용자·프로필.
  Future<ProviderContainer> container({
    AuthUser? user,
    UserProfile? profile,
    UserProfileRepository? profileRepository,
  }) async =>
      fakeContainer(
        user: user,
        profile: profile,
        profileRepository: profileRepository,
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
          GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingFlowPage()),
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

  testWidgets('first launch (not logged in) → leaves splash to onboarding', (t) async {
    await boot(t, await container());
    expect(find.text('먼저 나이대를 알려주세요'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('logged in, no profile → navigates to onboarding', (t) async {
    await boot(t, await container(user: _user));
    expect(find.text('먼저 나이대를 알려주세요'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('logged in, saved profile → navigates to home', (t) async {
    await boot(t, await container(user: _user, profile: _profile));
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('먼저 나이대를 알려주세요'), findsNothing);
  });

  testWidgets('profile fetch fails → still leaves splash', (t) async {
    await boot(t, await container(user: _user, profileRepository: _FailingProfileRepo()));
    // 전환 애니메이션 중이라 SplashPage 자체는 아직 트리에 있을 수 있다. 목적 페이지가 떴는지로 판단.
    expect(find.text('먼저 나이대를 알려주세요'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

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
}
