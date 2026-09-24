import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';

import '../../helper/fakes.dart';

const _offline = ErrorResult(reason: FailureReason.offline, message: '네트워크에 연결할 수 없습니다.');

/// 로그인 교환이 항상 실패하는 서버.
class _FailingSignIn extends InMemoryAuthRepository {
  @override
  Future<Result<AuthUser>> signIn(AuthProvider provider, String idToken) async =>
      const Result.failure(_offline);
}

/// 처음 한 번은 세션 확인이 네트워크 오류로 실패하는 서버.
class _FlakyAuth extends InMemoryAuthRepository {
  _FlakyAuth(super.user);
  int failures = 1;

  @override
  Future<Result<AuthUser?>> currentUser() async {
    if (failures-- > 0) return const Result.failure(_offline);
    return super.currentUser();
  }
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
    final c = fakeContainer(authRepository: _FailingSignIn());
    await c.read(authProvider.future);

    final res = await c.read(authProvider.notifier).signIn(AuthProvider.kakao);

    expect(res.failureOrNull?.message, _offline.message);
    expect(c.read(authProvider), const AsyncData<AuthUser?>(null));
  });

  test('쓰는 중 세션이 만료되면 로그아웃되고, 다시 로그인하면 만료 표시가 지워진다', () async {
    final auth = InMemoryAuthRepository(testUser);
    final c = fakeContainer(authRepository: auth);
    expect(await c.read(authProvider.future), isNotNull);
    expect(c.read(sessionExpiredProvider), isFalse);

    auth.expireSession();
    await Future<void>.delayed(Duration.zero);

    expect(c.read(authProvider).value, isNull);
    expect(c.read(sessionExpiredProvider), isTrue);

    await c.read(authProvider.notifier).signIn(AuthProvider.kakao);
    expect(c.read(sessionExpiredProvider), isFalse);
  });

  test('직접 로그아웃하면 만료 표시가 지워진다', () async {
    final auth = InMemoryAuthRepository(testUser);
    final c = fakeContainer(authRepository: auth);
    await c.read(authProvider.future);
    auth.expireSession();
    await Future<void>.delayed(Duration.zero);

    await c.read(authProvider.notifier).signOut();

    expect(c.read(sessionExpiredProvider), isFalse);
  });

  test('세션 확인에 실패하면 retry로 다시 확인한다', () async {
    final c = fakeContainer(authRepository: _FlakyAuth(testUser));
    await expectLater(c.read(authProvider.future), throwsA(isA<ResultFailure>()));

    c.read(authProvider.notifier).retry();

    expect(await c.read(authProvider.future), testUser);
  });
}
