import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/setting/widget/profile_card.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

import '../../helper/fakes.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: provider.ChangeNotifierProvider(
        create: (_) => ThemeService(),
        child: MaterialApp(
          home: Scaffold(body: child),
          theme: ThemeService().lightThemeData(),
        ),
      ),
    );

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  tearDown(() => locator.reset());

  testWidgets('guest: shows 게스트 and 로그인 button, no 로그아웃', (t) async {
    registerFakeUserDependencies();
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(_wrap(const ProfileCard()));
    await t.pump();
    await t.pump();

    expect(find.text('게스트'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('로그아웃'), findsNothing);
  });

  testWidgets('logged-in: shows nickname + provider label; logout returns to guest', (t) async {
    registerFakeUserDependencies(
      user: const AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자'),
    );
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(_wrap(const ProfileCard()));
    await t.pump();
    await t.pump();
    await t.pump();

    expect(find.text('카카오 사용자'), findsOneWidget);
    expect(find.text('카카오 로그인'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);

    await t.tap(find.text('로그아웃'));
    await t.pump();

    expect(find.text('게스트'), findsOneWidget);
    expect(find.text('로그아웃'), findsNothing);
  });
}
