import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/widget/social_login_button.dart';
import 'package:sedae_budget/presentation/page/main/main_shell.dart';
import 'package:sedae_budget/presentation/route/custom_route.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

const _loginMark = 'Google로 시작하기';
const _onboardingMark = '먼저 나이대를 알려주세요';
const _unreachableMark = '서버에 연결하지 못했어요';
const _expiredMark = '로그인이 만료됐어요. 다시 로그인해 주세요';
const _profile = UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000);

Widget _buildApp(ProviderContainer container) => fakeScope(
      container,
      Consumer(
          builder: (_, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
            theme: materialTheme(LightTheme()),
          ),
        ),
    );

/// 게이트 테스트의 공통 의존성: [server](Stub) + 광고·테마 fake.
Future<ProviderContainer> _container(StubServer server) async {
  final ads = FakeAdService();
  return fakeContainer(
    server: server,
    adService: ads,
    themeModeStore: await fakeThemeModeStore(),
    launchInterstitial: await fakeLaunchInterstitial(ads),
  );
}

/// kakao로 로그인해 [profile]까지 마친 서버. 로그인하지 않았으면 [signedIn]을 false로.
Future<StubServer> _server(WidgetTester t, {bool signedIn = true, UserProfile? profile}) =>
    t.seedServer(provider: signedIn ? AuthProvider.kakao : null, profile: profile);

Future<void> _boot(WidgetTester t, ProviderContainer container) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(_buildApp(container));
  await t.pump(); // splash + postFrameCallback
  await t.pump(const Duration(milliseconds: 2100)); // splash 2초 경과
  await t.pump(); // splash가 go() → redirect 평가
  await t.pump(const Duration(milliseconds: 300)); // 대상 페이지 build
  await t.settle(); // 대상 페이지가 보낸 요청(홈의 이달 거래 등)
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  testWidgets('미로그인 → 로그인 화면', (t) async {
    await _boot(t, await _container(await _server(t, signedIn: false)));
    expect(find.text(_loginMark), findsOneWidget);
    expect(find.text(_onboardingMark), findsNothing);
  });

  testWidgets('로그인 + 프로필 없음 → 온보딩', (t) async {
    await _boot(t, await _container(await _server(t)));
    expect(find.text(_onboardingMark), findsOneWidget);
    expect(find.text(_loginMark), findsNothing);
  });

  testWidgets('로그인 + 프로필 → 홈(MainShell)', (t) async {
    await _boot(t, await _container(await _server(t, profile: _profile)));
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text(_loginMark), findsNothing);
    expect(find.text(_onboardingMark), findsNothing);
  });

  testWidgets('로그인 화면에서 첫 소셜 버튼 탭 → (프로필 없음) 온보딩', (t) async {
    await _boot(t, await _container(await _server(t, signedIn: false))); // 로그인 화면 진입
    expect(find.text(_loginMark), findsOneWidget);

    await t.tap(find.byType(SocialLoginButton).first); // kakao
    await t.settle(); // signIn → 프로필 확정(없음) → redirect → 온보딩 build
    expect(find.text(_onboardingMark), findsOneWidget);
  });

  testWidgets('설정에서 로그아웃 → 로그인 화면', (t) async {
    await _boot(t, await _container(await _server(t, profile: _profile))); // 홈 진입
    expect(find.byType(MainShell), findsOneWidget);

    rootNavigatorKey.currentContext!.go(RoutePath.setting.path);
    await t.settle(); // 설정 화면 build

    await t.tap(find.text('로그아웃'));
    await t.settle(); // signOut → 프로필 null 확정 → redirect → 로그인 화면 build
    expect(find.text(_loginMark), findsOneWidget);
    expect(find.text(_expiredMark), findsNothing);
  });

  // 오프라인이라고 로그인 화면으로 보내면 멀쩡한 세션을 버리게 된다.
  testWidgets('토큰이 있는데 서버에 닿지 못하면 로그인이 아니라 연결 안 됨 화면', (t) async {
    final server = await _server(t, profile: _profile);
    server.faults.fail('GET', '/v1/me');
    await _boot(t, await _container(server));
    expect(find.text(_unreachableMark), findsOneWidget);
    expect(find.text(_loginMark), findsNothing);
  });

  // 온보딩으로 보내면 다시 입력한 값이 기존 프로필을 덮어쓴다.
  testWidgets('프로필 조회가 실패하면 온보딩이 아니라 연결 안 됨 화면', (t) async {
    final server = await _server(t, profile: _profile);
    server.faults.fail('GET', '/v1/me/profile');
    await _boot(t, await _container(server));
    expect(find.text(_unreachableMark), findsOneWidget);
    expect(find.text(_onboardingMark), findsNothing);
  });

  testWidgets('연결 안 됨 화면에서 다시 시도해 서버가 돌아왔으면 홈으로', (t) async {
    final server = await _server(t, profile: _profile);
    server.faults.fail('GET', '/v1/me');
    await _boot(t, await _container(server));
    expect(find.text(_unreachableMark), findsOneWidget);

    server.faults.heal();
    await t.tap(find.text('다시 시도'));
    await t.settle(); // 다시 확인 → 인증·프로필 확정 → redirect → 홈 build
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('쓰는 중 세션이 만료되면 로그인 화면으로 가고 안내 문구를 보여준다', (t) async {
    final server = await _server(t, profile: _profile);
    await _boot(t, await _container(server)); // 홈 진입
    expect(find.byType(MainShell), findsOneWidget);

    await t.untilDone(server.expireSession()); // 서버가 저장된 토큰을 거부(401)
    await t.settle(); // 만료 알림 → 로그아웃 → redirect → 로그인 화면 build
    expect(find.text(_loginMark), findsOneWidget);
    expect(find.text(_expiredMark), findsOneWidget);
  });
}
