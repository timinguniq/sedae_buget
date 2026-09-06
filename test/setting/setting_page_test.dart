import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../helper/fakes.dart';

void main() {
  setUp(() {
    registerFakeCategoryDependencies();
    SharedPreferences.setMockInitialValues({}); // ThemeService 테마 모드 저장용
    PackageInfo.setMockInitialValues(
      appName: 'sedae', packageName: 'com.sedae.budget',
      version: '1.0.0', buildNumber: '1', buildSignature: '');
  });
  tearDown(() => locator.reset());

  Widget app(ThemeService service) => ProviderScope(
        child: provider.ChangeNotifierProvider<ThemeService>.value(
          value: service,
          child: const MaterialApp(home: SettingPage()),
        ),
      );

  testWidgets('renders and dark chip switches theme mode', (tester) async {
    registerFakeUserDependencies();
    final service = ThemeService();
    await tester.pumpWidget(app(service));
    await tester.pump();

    expect(find.text('설정'), findsOneWidget);
    expect(find.byType(RoundIconButton), findsOneWidget);
    expect(find.byType(ThemeModeSelector), findsOneWidget);
    expect(find.text('화면'), findsOneWidget);
    expect(find.text('일반'), findsOneWidget);
    expect(find.byKey(const Key('category-manage-tile')), findsOneWidget);
    expect(find.text('로그아웃'), findsNothing); // 게스트

    await tester.tap(find.text('다크'));
    await tester.pump();
    expect(service.themeMode, ThemeMode.dark);
  });

  testWidgets('logged in: bottom logout button is shown', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    registerFakeUserDependencies(
      user: const AuthUser(provider: AuthProvider.naver, nickname: '네이버 사용자'),
    );
    await tester.pumpWidget(app(ThemeService()));
    await tester.pump();
    await tester.pump();

    expect(find.byType(LogoutButton), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('네이버'), findsOneWidget); // provider 배지
  });
}
