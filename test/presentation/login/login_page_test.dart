import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';
import 'package:sedae_budget/presentation/page/login/login.page.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

/// 로그인 교환이 서버 오류(500, 바디 문구 [message])로 실패하는 서버.
StubServer _failingLogin([String message = '잠시 후 다시 시도해 주세요.']) =>
    StubServer()..faults.fail('POST', '/v1/auth/login', reason: FailureReason.server, message: message);

void main() {

  // 이전에는 로그인 실패가 처리되지 않은 비동기 예외로 사라졌다.
  testWidgets('로그인이 실패하면 이유를 보여주고 로그인 화면에 머문다', (t) async {
    final container = fakeContainer(server: _failingLogin());

    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(fakeScope(
      container,
      MaterialApp(home: const LoginPage(), theme: materialTheme(LightTheme())),
    ));
    await t.pump();

    await t.tap(find.text('카카오로 시작하기'));
    await t.settle(); // SnackBar 등장

    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('로그인하지 못했어요. 서버에 문제가 생겼어요. 잠시 후 다시 시도해 주세요'), findsOneWidget);
  });

  // 서버가 코드만 주고 문구를 안 주면 빈 SnackBar가 뜨면 안 된다.
  testWidgets('서버 문구가 비어 있어도 이유를 보여준다', (t) async {
    final container = fakeContainer(server: _failingLogin(''));

    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await t.pumpWidget(fakeScope(
      container,
      MaterialApp(home: const LoginPage(), theme: materialTheme(LightTheme())),
    ));
    await t.pump();

    await t.tap(find.text('카카오로 시작하기'));
    await t.settle();

    expect(find.text('로그인하지 못했어요. 서버에 문제가 생겼어요. 잠시 후 다시 시도해 주세요'), findsOneWidget);
  });

  testWidgets('renders 3 social buttons and kakao tap signs in', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    final container = fakeContainer();

    await t.pumpWidget(fakeScope(
      container,
      MaterialApp(home: const LoginPage(),
          theme: materialTheme(LightTheme())),
    ));
    await t.pump();

    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(find.text('네이버로 시작하기'), findsOneWidget);
    expect(find.text('Google로 시작하기'), findsOneWidget);

    await t.tap(find.text('카카오로 시작하기'));
    await t.settle();
    expect(container.read(authProvider).value?.provider, AuthProvider.kakao);
  });
}
