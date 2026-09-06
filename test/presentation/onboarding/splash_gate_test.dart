import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/initial/splash.page.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.page.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

import '../../helper/fakes.dart';

const _user = AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자');
const _profile = UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000);

/// 서버 장애 시뮬레이션: 프로필 조회가 항상 실패한다.
class _FailingProfileRepo implements UserProfileRepository {
  @override
  Future<UserProfile?> current() async => throw Exception('network down');
  @override
  Future<void> save(UserProfile profile) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  tearDown(() => locator.reset());

  Widget buildApp(GoRouter router) => ProviderScope(
        child: provider.ChangeNotifierProvider(
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

  Future<void> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(buildApp(buildRouter()));
    await t.pump(); // initial frame + postFrameCallback schedules appInitialize
    await t.pump(const Duration(milliseconds: 2100)); // pass the 2000ms delay
    await t.pump(); // flush provider read microtasks + navigation
    await t.pump(const Duration(milliseconds: 300)); // build the target page
  }

  testWidgets('first launch (not logged in) → leaves splash to onboarding', (t) async {
    registerFakeUserDependencies();
    await boot(t);
    expect(find.text('나이대를 알려주세요'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('logged in, no profile → navigates to onboarding', (t) async {
    registerFakeUserDependencies(user: _user);
    await boot(t);
    expect(find.text('나이대를 알려주세요'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('logged in, saved profile → navigates to home', (t) async {
    registerFakeUserDependencies(user: _user, profile: _profile);
    await boot(t);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('나이대를 알려주세요'), findsNothing);
  });

  testWidgets('profile fetch fails → still leaves splash', (t) async {
    registerFakeUserDependencies(user: _user, profileRepository: _FailingProfileRepo());
    await boot(t);
    // 전환 애니메이션 중이라 SplashPage 자체는 아직 트리에 있을 수 있다. 목적 페이지가 떴는지로 판단.
    expect(find.text('나이대를 알려주세요'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });
}
