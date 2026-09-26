import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sedae_budget/domain/domain.dart';
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
const _offline = ErrorResult(reason: FailureReason.offline, message: '네트워크에 연결할 수 없습니다.');
const _user = AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자');
const _profile = UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000);

/// 홈까지 도달하는 케이스가 실제 저장소를 타지 않도록 하는 빈 저장소.
class _EmptyRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<Transaction>> delete(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async =>
      const Result.success([]);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}

Widget _buildApp(ProviderContainer container) => fakeScope(
      container,
      Consumer(
          builder: (_, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
            theme: materialTheme(LightTheme()),
          ),
        ),
    );

/// [online]이 false인 동안 세션 확인이 네트워크 오류로 실패하는 서버(토큰은 있다).
class _OfflineAuth extends InMemoryAuthRepository {
  _OfflineAuth(super.user);
  bool online = false;

  @override
  Future<Result<AuthUser?>> currentUser() async =>
      online ? super.currentUser() : const Result.failure(_offline);
}

/// 프로필 조회가 네트워크 오류로 실패하는 서버.
class _OfflineProfile extends InMemoryUserProfileRepository {
  _OfflineProfile(super.profile);

  @override
  Future<Result<UserProfile?>> current() async => const Result.failure(_offline);
}

/// 게이트 테스트의 공통 의존성: 빈 거래 저장소 + 또래 통계·광고 fake.
Future<ProviderContainer> _container({
  AuthUser? user,
  UserProfile? profile,
  AuthRepository? authRepository,
  UserProfileRepository? profileRepository,
}) async {
  final ads = FakeAdService();
  return fakeContainer(
    user: user,
    profile: profile,
    authRepository: authRepository,
    profileRepository: profileRepository,
    transactions: _EmptyRepo(),
    categories: InMemoryCategoryRepository(),
    peerRepository: FakePeerStatsRepository(),
    adService: ads,
    themeModeStore: await fakeThemeModeStore(),
    launchInterstitial: await fakeLaunchInterstitial(ads),
  );
}

Future<void> _boot(WidgetTester t, ProviderContainer container) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(_buildApp(container));
  await t.pump(); // splash + postFrameCallback
  await t.pump(const Duration(milliseconds: 2100)); // splash 2초 경과
  await t.pump(); // splash가 go() → redirect 평가
  await t.pump(const Duration(milliseconds: 300)); // 대상 페이지 build
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  testWidgets('미로그인 → 로그인 화면', (t) async {
    await _boot(t, await _container());
    expect(find.text(_loginMark), findsOneWidget);
    expect(find.text(_onboardingMark), findsNothing);
  });

  testWidgets('로그인 + 프로필 없음 → 온보딩', (t) async {
    await _boot(t, await _container(user: _user));
    expect(find.text(_onboardingMark), findsOneWidget);
    expect(find.text(_loginMark), findsNothing);
  });

  testWidgets('로그인 + 프로필 → 홈(MainShell)', (t) async {
    await _boot(t, await _container(user: _user, profile: _profile));
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text(_loginMark), findsNothing);
    expect(find.text(_onboardingMark), findsNothing);
  });

  testWidgets('로그인 화면에서 첫 소셜 버튼 탭 → (프로필 없음) 온보딩', (t) async {
    await _boot(t, await _container()); // 로그인 화면 진입
    expect(find.text(_loginMark), findsOneWidget);

    await t.tap(find.byType(SocialLoginButton).first); // kakao
    await t.pump(); // signIn → auth 변경 → 프로필 재조회(loading) → 가드 보류
    await t.pump(); // 프로필 확정 → refreshListenable → redirect
    await t.pump(const Duration(milliseconds: 300)); // 온보딩 build
    expect(find.text(_onboardingMark), findsOneWidget);
  });

  testWidgets('설정에서 로그아웃 → 로그인 화면', (t) async {
    await _boot(t, await _container(user: _user, profile: _profile)); // 홈 진입
    expect(find.byType(MainShell), findsOneWidget);

    rootNavigatorKey.currentContext!.go(RoutePath.setting.path);
    await t.pump();
    await t.pump(const Duration(milliseconds: 300)); // 설정 화면 build

    await t.tap(find.text('로그아웃'));
    await t.pump(); // signOut → auth 변경 → 프로필 재조회(loading) → 가드 보류
    await t.pump(); // 프로필 null 확정 → refreshListenable → redirect
    await t.pump(const Duration(milliseconds: 300)); // 로그인 화면 build
    expect(find.text(_loginMark), findsOneWidget);
    expect(find.text(_expiredMark), findsNothing);
  });

  // 오프라인이라고 로그인 화면으로 보내면 멀쩡한 세션을 버리게 된다.
  testWidgets('토큰이 있는데 서버에 닿지 못하면 로그인이 아니라 연결 안 됨 화면', (t) async {
    await _boot(t, await _container(authRepository: _OfflineAuth(_user), profile: _profile));
    expect(find.text(_unreachableMark), findsOneWidget);
    expect(find.text(_loginMark), findsNothing);
  });

  // 온보딩으로 보내면 다시 입력한 값이 기존 프로필을 덮어쓴다.
  testWidgets('프로필 조회가 실패하면 온보딩이 아니라 연결 안 됨 화면', (t) async {
    await _boot(t, await _container(user: _user, profileRepository: _OfflineProfile(_profile)));
    expect(find.text(_unreachableMark), findsOneWidget);
    expect(find.text(_onboardingMark), findsNothing);
  });

  testWidgets('연결 안 됨 화면에서 다시 시도해 서버가 돌아왔으면 홈으로', (t) async {
    final auth = _OfflineAuth(_user);
    await _boot(t, await _container(authRepository: auth, profile: _profile));
    expect(find.text(_unreachableMark), findsOneWidget);

    auth.online = true;
    await t.tap(find.text('다시 시도'));
    await t.pump(); // 다시 확인 → 인증·프로필 확정
    await t.pump(); // refreshListenable → redirect
    await t.pump(const Duration(milliseconds: 300)); // 홈 build
    expect(find.byType(MainShell), findsOneWidget);
  });

  testWidgets('쓰는 중 세션이 만료되면 로그인 화면으로 가고 안내 문구를 보여준다', (t) async {
    final auth = InMemoryAuthRepository(_user);
    await _boot(t, await _container(authRepository: auth, profile: _profile)); // 홈 진입
    expect(find.byType(MainShell), findsOneWidget);

    auth.expireSession();
    await t.pump(); // 만료 알림 → 로그아웃
    await t.pump(); // 프로필 null 확정 → redirect
    await t.pump(const Duration(milliseconds: 300)); // 로그인 화면 build
    expect(find.text(_loginMark), findsOneWidget);
    expect(find.text(_expiredMark), findsOneWidget);
  });
}
