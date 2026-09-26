import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';

import '../../helper/fakes.dart';

/// kakao로 로그인해 둔 서버.
Future<StubServer> _signedIn() async {
  final server = StubServer();
  await server.signIn(AuthProvider.kakao);
  return server;
}

void main() {
  test('signIn saves user; signOut clears', () async {
    final c = fakeContainer();
    expect(await c.read(authProvider.future), isNull);
    await c.read(authProvider.notifier).signIn(AuthProvider.kakao);
    expect(c.read(authProvider).value?.provider, AuthProvider.kakao);
    expect(c.read(authProvider).value?.nickname, '카카오 사용자');
    await c.read(authProvider.notifier).signOut();
    expect(c.read(authProvider).value, isNull);
  });

  // 로그인 실패를 오류 상태로 두면 가드가 '서버에 연결하지 못함'으로 읽는다. 실패는 결과로만 알린다.
  test('로그인이 실패하면 로그아웃 상태로 두고 실패를 돌려준다', () async {
    final server = StubServer();
    server.faults.fail('POST', '/v1/auth/login');
    final c = fakeContainer(server: server);
    await c.read(authProvider.future);

    final res = await c.read(authProvider.notifier).signIn(AuthProvider.kakao);

    expect(res.failureOrNull?.reason, FailureReason.offline);
    expect(c.read(authProvider), const AsyncData<AuthUser?>(null));
  });

  test('쓰는 중 세션이 만료되면 로그아웃되고, 다시 로그인하면 만료 표시가 지워진다', () async {
    final server = await _signedIn();
    final c = fakeContainer(server: server);
    expect(await c.read(authProvider.future), isNotNull);
    expect(c.read(sessionExpiredProvider), isFalse);

    await server.expireSession();
    await Future<void>.delayed(Duration.zero);

    expect(c.read(authProvider).value, isNull);
    expect(c.read(sessionExpiredProvider), isTrue);

    await c.read(authProvider.notifier).signIn(AuthProvider.kakao);
    expect(c.read(sessionExpiredProvider), isFalse);
  });

  test('직접 로그아웃하면 만료 표시가 지워진다', () async {
    final server = await _signedIn();
    final c = fakeContainer(server: server);
    await c.read(authProvider.future);
    await server.expireSession();
    await Future<void>.delayed(Duration.zero);

    await c.read(authProvider.notifier).signOut();

    expect(c.read(sessionExpiredProvider), isFalse);
  });

  test('세션 확인에 실패하면 retry로 다시 확인한다', () async {
    final server = await _signedIn();
    server.faults.fail('GET', '/v1/me', times: 1);
    final c = fakeContainer(server: server);
    await expectLater(c.read(authProvider.future), throwsA(isA<ResultFailure>()));

    c.read(authProvider.notifier).retry();

    expect(await c.read(authProvider.future), testUser);
  });
}
