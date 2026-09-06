import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/widget/social_login_button.dart';
import 'package:sedae_budget/presentation/page/main/main_shell.dart';
import 'package:sedae_budget/presentation/route/custom_route.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

const _loginMark = '시작하면 이용약관 및 개인정보처리방침에 동의하게 됩니다.';
const _onboardingMark = '나이대를 알려주세요';
const _authUserJson = '{"provider":"kakao","nickname":"카카오 사용자"}';
const _profileJson = '{"ageGroup":"thirties","monthlyIncome":3000000}';

/// 홈까지 도달하는 케이스가 실제 DB를 타지 않도록 하는 빈 저장소.
class _EmptyRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async =>
      const Result.success([]);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}

Widget _buildApp() => ProviderScope(
      child: provider.ChangeNotifierProvider(
        create: (_) => ThemeService(),
        child: Consumer(
          builder: (_, ref, _) => MaterialApp.router(
            routerConfig: ref.watch(routerProvider),
            theme: ThemeService().lightThemeData(),
          ),
        ),
      ),
    );

Future<void> _boot(WidgetTester t) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(_buildApp());
  await t.pump(); // splash + postFrameCallback
  await t.pump(const Duration(milliseconds: 2100)); // splash 2초 경과
  await t.pump(); // splash가 go() → redirect 평가
  await t.pump(const Duration(milliseconds: 300)); // 대상 페이지 build
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));
  setUp(() {
    configureUserDependencies();
    configurePeerDependencies();
    locator.registerSingleton<TransactionUsecase>(TransactionUsecase(_EmptyRepo()));
  });
  tearDown(() => locator.reset());

  testWidgets('미로그인 → 로그인 화면', (t) async {
    SharedPreferences.setMockInitialValues({});
    await _boot(t);
    expect(find.text(_loginMark), findsOneWidget);
    expect(find.text(_onboardingMark), findsNothing);
  });

  testWidgets('로그인 + 프로필 없음 → 온보딩', (t) async {
    SharedPreferences.setMockInitialValues({'auth_user': _authUserJson});
    await _boot(t);
    expect(find.text(_onboardingMark), findsOneWidget);
    expect(find.text(_loginMark), findsNothing);
  });

  testWidgets('로그인 + 프로필 → 홈(MainShell)', (t) async {
    SharedPreferences.setMockInitialValues({
      'auth_user': _authUserJson,
      'user_profile': _profileJson,
    });
    await _boot(t);
    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text(_loginMark), findsNothing);
    expect(find.text(_onboardingMark), findsNothing);
  });

  testWidgets('로그인 화면에서 첫 소셜 버튼 탭 → (프로필 없음) 온보딩', (t) async {
    SharedPreferences.setMockInitialValues({});
    await _boot(t); // 로그인 화면 진입
    expect(find.text(_loginMark), findsOneWidget);

    await t.tap(find.byType(SocialLoginButton).first); // kakao
    await t.pump(); // signInMock → state 변경 → refreshListenable → redirect
    await t.pump(const Duration(milliseconds: 300)); // 온보딩 build
    expect(find.text(_onboardingMark), findsOneWidget);
  });
}
