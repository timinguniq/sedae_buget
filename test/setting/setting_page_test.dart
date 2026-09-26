import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../helper/fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'sedae', packageName: 'com.sedae.budget',
      version: '1.0.0', buildNumber: '1', buildSignature: '');
  });

  Widget app(ProviderContainer container) => fakeScope(container, const MaterialApp(home: SettingPage()));

  testWidgets('renders and dark chip switches theme mode', (tester) async {
    final store = await fakeThemeModeStore();
    final container = fakeContainer(themeModeStore: store);
    await tester.pumpWidget(app(container));
    await tester.settle();

    expect(find.text('설정'), findsOneWidget);
    expect(find.byType(RoundIconButton), findsOneWidget);
    expect(find.byType(ThemeModeSelector), findsOneWidget);
    expect(find.text('화면'), findsOneWidget);
    expect(find.text('일반'), findsOneWidget);
    expect(find.byKey(const Key('category-manage-tile')), findsOneWidget);
    expect(find.text('로그아웃'), findsNothing); // 로그아웃 상태

    await tester.tap(find.text('다크'));
    await tester.settle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(store.read(), ThemeMode.dark); // 다음 실행에도 다크로 시작한다
  });

  testWidgets('logged in: bottom logout button is shown', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final container = fakeContainer(
      server: await tester.seedServer(provider: AuthProvider.naver),
      themeModeStore: await fakeThemeModeStore(),
    );
    await tester.pumpWidget(app(container));
    await tester.settle();

    expect(find.byType(LogoutButton), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('네이버'), findsOneWidget); // provider 배지
  });
}
