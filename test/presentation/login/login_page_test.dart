import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/auth_provider.dart';
import 'package:sedae_budget/presentation/page/login/login.page.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

void main() {
  setUp(configureUserDependencies);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders 3 social buttons and kakao tap signs in', (t) async {
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
