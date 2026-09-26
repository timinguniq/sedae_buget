import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../helper/stub_server.dart';

/// 모든 요청을 500으로 떨어뜨린다(서버 장애 시뮬레이션).
class _ServerDown extends Interceptor {
  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) => h.reject(
        DioException(
          requestOptions: o,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: o, statusCode: 500),
        ),
      );
}

void main() {
  late MemoryAuthTokenStore tokens;
  late AuthRepository repo;

  setUp(() {
    final server = StubServer();
    tokens = server.tokens;
    repo = server.auth;
  });

  test('no token → currentUser null', () async {
    expect((await repo.currentUser()).unwrap(), isNull);
  });

  test('signIn stores token and returns user; currentUser round-trips', () async {
    final u = (await repo.signIn(AuthProvider.naver, 'id-token')).unwrap();
    expect(u.nickname, '네이버 사용자');
    expect(u.provider, AuthProvider.naver);
    expect(tokens.token, isNotEmpty);
    expect((await repo.currentUser()).unwrap()?.provider, AuthProvider.naver);
  });

  test('invalid token → 401 → token cleared, 미로그인으로 성공', () async {
    tokens.token = 'garbage';
    final res = await repo.currentUser();
    expect(res.failureOrNull, isNull, reason: '무효 세션은 실패가 아니라 미로그인이다');
    expect(res.unwrap(), isNull);
    expect(tokens.token, isNull);
  });

  test('서버가 저장된 토큰을 거부하면 sessionExpired로 알린다', () async {
    await repo.signIn(AuthProvider.kakao, 'x');
    final expired = expectLater(repo.sessionExpired, emits(null));
    tokens.token = 'garbage';
    await repo.currentUser();
    await expired;
  });

  test('signOut clears token', () async {
    await repo.signIn(AuthProvider.google, 'x');
    await repo.signOut();
    expect(tokens.token, isNull);
  });

  test('server error on /me → server 실패; signOut은 실패를 알리고도 토큰을 지운다', () async {
    final expiry = SessionExpiry();
    final dio = connectToServer(
      env: AppEnvironment.local, tokenStore: tokens, sessionExpiry: expiry,
      localServer: () => _ServerDown(),
    );
    final down = AuthRepositoryImpl(AuthApi(dio), tokens, expiry);
    tokens.token = 'stub.kakao';
    expect((await down.currentUser()).failureOrNull?.reason, FailureReason.server);
    expect(tokens.token, 'stub.kakao'); // 500은 토큰을 지우지 않는다
    // 로그아웃은 서버가 죽어도 로컬 세션을 끝내지만, 실패를 삼키지는 않는다.
    expect((await down.signOut()).failureOrNull?.reason, FailureReason.server);
    expect(tokens.token, isNull);
  });
}
