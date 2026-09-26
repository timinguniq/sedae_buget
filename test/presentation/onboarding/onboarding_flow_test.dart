import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.page.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

void main() {

  /// 온보딩을 띄우고 소득 단계까지 진행한다.
  Future<void> pumpToIncomeStep(WidgetTester t, ProviderContainer container) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final router = GoRouter(initialLocation: '/onboarding', routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingFlowPage()),
      GoRoute(path: '/budget', builder: (_, _) => const Scaffold(body: Text('HOME'))),
    ]);
    await t.pumpWidget(fakeScope(container, MaterialApp.router(routerConfig: router,
        theme: materialTheme(LightTheme()))));
    await t.pump();
    await t.tap(find.text('20대'));
    await t.pump();
    await t.tap(find.text('다음'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    await t.pump();
  }

  // 이전에는 저장 실패를 버리고 홈으로 보냈고, 가드가 말없이 온보딩으로 되돌렸다.
  testWidgets('프로필 저장이 실패하면 홈으로 가지 않고 이유를 보여준다', (t) async {
    final server = await t.seedServer();
    server.faults.fail('PUT', '/v1/me/profile');
    await pumpToIncomeStep(t, fakeContainer(server: server));

    await t.tap(find.text('시작하기'));
    await t.settle(); // 저장 실패 → SnackBar 등장

    expect(find.text('HOME'), findsNothing);
    expect(find.text('저장하지 못했어요. 인터넷에 연결되어 있지 않아요'), findsOneWidget);
  });

  testWidgets('age select enables 다음, income step shows 시작하기', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final router = GoRouter(initialLocation: '/onboarding', routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingFlowPage()),
      GoRoute(path: '/budget', builder: (_, _) => const Scaffold(body: Text('HOME'))),
    ]);
    await t.pumpWidget(fakeScope(fakeContainer(), MaterialApp.router(routerConfig: router,
        theme: materialTheme(LightTheme()))));
    await t.pump();

    expect(find.text('다음'), findsOneWidget);
    await t.tap(find.text('20대'));
    await t.pump();
    await t.tap(find.text('다음'));
    await t.pump(); // process tap → starts nextPage() animation
    await t.pump(const Duration(milliseconds: 300)); // advance through 250ms animation
    await t.pump(); // rebuild after onPageChanged setState
    expect(find.text('시작하기'), findsOneWidget);
    // 소득은 서버에 저장된다. 이전 문구는 '기기에 안전하게 보관'이라고 했다.
    expect(find.text('소득 정보는 저축률 계산과 또래 비교에만 쓰이고, 비교는 익명 통계로만 이뤄져요.'), findsOneWidget);
    expect(find.textContaining('기기에'), findsNothing);
  });
}
