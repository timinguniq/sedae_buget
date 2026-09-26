import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/setting/widget/logout_button.dart';
import 'package:sedae_budget/presentation/page/setting/widget/profile_card.dart';
import 'package:sedae_budget/presentation/page/setting/widget/provider_badge.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

/// 설정 화면과 같은 구성: 프로필 카드 + 하단 로그아웃 버튼.
Widget _wrap(ProviderContainer container) => fakeScope(
      container,
      MaterialApp(
          home: const Scaffold(body: Column(children: [ProfileCard(), LogoutButton()])),
          theme: materialTheme(LightTheme()),
        ),
    );

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // 세션 게이트가 로그아웃 상태에선 설정을 보여주지 않는다. 로그아웃 직후 한 프레임은 아무것도 그리지 않는다.
  testWidgets('signed out: draws neither the card nor 로그아웃', (t) async {
    final container = fakeContainer();
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(_wrap(container));
    await t.settle();

    expect(find.byType(MascotDongle), findsNothing);
    expect(find.text('로그아웃'), findsNothing);
    expect(find.byType(ProviderBadge), findsNothing);
  });

  testWidgets('logged-in: shows nickname + provider badge; logout clears both', (t) async {
    final container = fakeContainer(server: await t.seedServer());
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(_wrap(container));
    await t.settle();

    expect(find.text('카카오 사용자'), findsOneWidget);
    expect(find.text('카카오 로그인'), findsOneWidget); // 프로필(나이대) 없을 때의 부제
    expect(find.byType(ProviderBadge), findsOneWidget);
    expect(find.text('카카오'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);

    await t.tap(find.text('로그아웃'));
    await t.settle();

    expect(find.text('카카오 사용자'), findsNothing);
    expect(find.text('로그아웃'), findsNothing);
  });

  testWidgets('logged-in with profile: subtitle is the age group', (t) async {
    final container = fakeContainer(
      server: await t.seedServer(
        provider: AuthProvider.google,
        profile: const UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000),
      ),
    );
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(_wrap(container));
    await t.settle();

    expect(find.text(AgeGroup.thirties.label), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
  });
}
