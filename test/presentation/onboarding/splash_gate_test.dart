import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/presentation/page/initial/splash.page.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.page.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

void main() {
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

  testWidgets('no profile → navigates to onboarding', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(buildApp(buildRouter()));
    await t.pump(); // initial frame + postFrameCallback schedules appInitialize
    await t.pump(const Duration(milliseconds: 2100)); // pass the 2000ms delay
    await t.pump(); // flush provider read microtasks + navigation
    await t.pump(const Duration(milliseconds: 300)); // build the target page

    expect(find.text('나이대를 알려주세요'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('saved profile → navigates to home', (t) async {
    SharedPreferences.setMockInitialValues({
      'user_profile': '{"ageGroup":"thirties","monthlyIncome":3000000}',
    });
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(buildApp(buildRouter()));
    await t.pump(); // initial frame + postFrameCallback schedules appInitialize
    await t.pump(const Duration(milliseconds: 2100)); // pass the 2000ms delay
    await t.pump(); // flush provider read microtasks + navigation
    await t.pump(const Duration(milliseconds: 300)); // build the target page

    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('나이대를 알려주세요'), findsNothing);
  });
}
