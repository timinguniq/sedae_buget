import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.page.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

import '../../helper/fakes.dart';

void main() {
  setUp(() => registerFakeUserDependencies());
  tearDown(() => locator.reset());

  testWidgets('age select enables 다음, income step shows 시작하기', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final router = GoRouter(initialLocation: '/onboarding', routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingFlowPage()),
      GoRoute(path: '/budget', builder: (_, _) => const Scaffold(body: Text('HOME'))),
    ]);
    await t.pumpWidget(ProviderScope(child: provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: MaterialApp.router(routerConfig: router,
        theme: ThemeService().lightThemeData()))));
    await t.pump();

    expect(find.text('다음'), findsOneWidget);
    await t.tap(find.text('20대'));
    await t.pump();
    await t.tap(find.text('다음'));
    await t.pump(); // process tap → starts nextPage() animation
    await t.pump(const Duration(milliseconds: 300)); // advance through 250ms animation
    await t.pump(); // rebuild after onPageChanged setState
    expect(find.text('시작하기'), findsOneWidget);
  });
}
