import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.page.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

import '../../helper/fakes.dart';

/// 프로필 저장이 항상 실패하는 저장소(네트워크 오류 시나리오).
class _FailingSaveRepo implements UserProfileRepository {
  @override
  Future<Result<UserProfile?>> current() async => const Result.success(null);
  @override
  Future<Result<void>> save(UserProfile profile) async => const Result.failure(
        ErrorResult(reason: FailureReason.offline, message: '네트워크에 연결할 수 없습니다.'),
      );
}

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
    await t.pumpWidget(fakeScope(container, provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: MaterialApp.router(routerConfig: router,
        theme: ThemeService().lightThemeData()))));
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
    await pumpToIncomeStep(t, fakeContainer(profileRepository: _FailingSaveRepo()));

    await t.tap(find.text('시작하기'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400)); // SnackBar 등장

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
    await t.pumpWidget(fakeScope(fakeContainer(), provider.ChangeNotifierProvider(
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
