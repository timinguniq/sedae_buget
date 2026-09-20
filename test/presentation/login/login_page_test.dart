import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';
import 'package:sedae_budget/presentation/page/login/login.page.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

import '../../helper/fakes.dart';

/// 서버 세션 교환이 항상 실패하는 저장소.
class _FailingAuthRepo implements AuthRepository {
  static const _down = ErrorResult(reason: FailureReason.server, message: '잠시 후 다시 시도해 주세요.');

  @override
  Future<Result<AuthUser?>> currentUser() async => const Result.success(null);
  @override
  Future<Result<AuthUser>> signIn(AuthProvider provider, String idToken) async =>
      const Result.failure(_down);
  @override
  Future<Result<void>> signOut() async => const Result.success(null);
}

void main() {
  tearDown(() => locator.reset());

  // 이전에는 로그인 실패가 처리되지 않은 비동기 예외로 사라졌다.
  testWidgets('로그인이 실패하면 이유를 보여주고 로그인 화면에 머문다', (t) async {
    final auth = _FailingAuthRepo();
    locator
      ..registerSingleton<AuthRepository>(auth)
      ..registerSingleton<AuthUsecase>(AuthUsecase(auth, StubSocialIdTokenProvider()))
      ..registerSingleton<UserProfileRepository>(InMemoryUserProfileRepository());

    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(ProviderScope(
      child: provider.ChangeNotifierProvider(
        create: (_) => ThemeService(),
        child: MaterialApp(home: const LoginPage(), theme: ThemeService().lightThemeData())),
    ));
    await t.pump();

    await t.tap(find.text('카카오로 시작하기'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400)); // SnackBar 등장

    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('잠시 후 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('renders 3 social buttons and kakao tap signs in', (t) async {
    registerFakeUserDependencies();
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: provider.ChangeNotifierProvider(
        create: (_) => ThemeService(),
        child: MaterialApp(home: const LoginPage(),
          theme: ThemeService().lightThemeData())),
    ));
    await t.pump();

    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('네이버로 시작하기'), findsOneWidget);
    expect(find.text('Google로 시작하기'), findsOneWidget);

    await t.tap(find.text('카카오로 시작하기'));
    await t.pump();
    expect(container.read(authProvider).value?.provider, AuthProvider.kakao);
  });
}
