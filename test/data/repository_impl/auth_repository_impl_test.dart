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

/// 요청받은 소셜 로그인을 기록하고 고정 토큰을 준다.
class _FixedToken implements SocialIdTokenProvider {
  final asked = <AuthProvider>[];

  @override
  Future<Result<String>> idToken(AuthProvider provider) async {
    asked.add(provider);
    return Result.success('t-${provider.name}');
  }
}

/// 소셜 SDK 쪽에서 토큰을 받지 못하는 상황.
class _FailingToken implements SocialIdTokenProvider {
  @override
  Future<Result<String>> idToken(AuthProvider provider) async => const Result.failure(
        ErrorResult(reason: FailureReason.unknown, message: '소셜 로그인이 취소되었습니다.'),
      );
}

void main() {
  late StubServer server;
  late MemoryAuthTokenStore tokens;
  late AuthRepository repo;

  setUp(() {
    server = StubServer();
    tokens = server.tokens;
    repo = server.auth;
  });

  test('no token → currentUser null', () async {
    expect((await repo.currentUser()).unwrap(), isNull);
  });

  test('signIn stores token and returns user; currentUser round-trips', () async {
    final u = (await repo.signIn(AuthProvider.naver)).unwrap();
    expect(u.nickname, '네이버 사용자');
    expect(u.provider, AuthProvider.naver);
    expect(tokens.token, isNotEmpty);
    expect((await repo.currentUser()).unwrap()?.provider, AuthProvider.naver);
  });

  test('소셜 id_token을 받아 서버 세션으로 바꾼다', () async {
    final social = _FixedToken();
    final auth = AuthRepositoryImpl(AuthApi(server.dio), server.session, social);
    expect((await auth.signIn(AuthProvider.kakao)).unwrap().provider, AuthProvider.kakao);
    expect(social.asked, [AuthProvider.kakao]);
  });

  test('id_token을 못 받으면 서버를 부르지 않고 그 실패를 돌려준다', () async {
    final auth = AuthRepositoryImpl(AuthApi(server.dio), server.session, _FailingToken());
    final res = await auth.signIn(AuthProvider.kakao);
    expect(res.failureOrNull?.message, '소셜 로그인이 취소되었습니다.');
    expect(server.faults.count('POST', '/v1/auth/login'), 0);
    expect(tokens.token, isNull);
  });

  test('invalid token → 401 → token cleared, 미로그인으로 성공', () async {
    tokens.token = 'garbage';
    final res = await repo.currentUser();
    expect(res.failureOrNull, isNull, reason: '무효 세션은 실패가 아니라 미로그인이다');
    expect(res.unwrap(), isNull);
    expect(tokens.token, isNull);
  });

  test('서버가 저장된 토큰을 거부하면 sessionExpired로 알린다', () async {
    await repo.signIn(AuthProvider.kakao);
    final expired = expectLater(repo.sessionExpired, emits(null));
    tokens.token = 'garbage';
    await repo.currentUser();
    await expired;
  });

  test('signOut clears token', () async {
    await repo.signIn(AuthProvider.google);
    // 토큰을 먼저 지우면 로그아웃 요청이 인증 없이 가서 401로 실패한다.
    expect((await repo.signOut()).failureOrNull, isNull);
    expect(tokens.token, isNull);
  });

  test('server error on /me → server 실패, 토큰은 그대로', () async {
    final session = Session(tokens);
    final dio = connectToServer(
      env: AppEnvironment.local, session: session, localServer: () => _ServerDown(),
    );
    final down = AuthRepositoryImpl(AuthApi(dio), session, StubSocialIdTokenProvider());
    tokens.token = 'stub.kakao.t';
    expect((await down.currentUser()).failureOrNull?.reason, FailureReason.server);
    expect(tokens.token, 'stub.kakao.t'); // 500은 토큰을 지우지 않는다

  });

  group('토큰 저장소가 던져도 저장소는 던지지 않는다', () {
    // 다시 시도해도 고쳐지지 않는 실패라 '연결 안 됨'에 가두지 않고 다시 로그인하게 한다.
    test('못 읽으면 세션이 없는 것으로 보고(로그아웃 상태) 토큰 지우기를 시도한다', () async {
      await server.signIn(AuthProvider.kakao);
      tokens.failRead = true;

      final res = await repo.currentUser();

      expect(res.failureOrNull, isNull);
      expect(res.unwrap(), isNull);
      expect(server.faults.count('GET', '/v1/me'), 0);
      tokens.failRead = false;
      expect(tokens.token, isNull);
    });

    test('못 쓰면 signIn → unknown 실패', () async {
      tokens.failWrite = true;
      final res = await repo.signIn(AuthProvider.kakao);
      expect(res.failureOrNull?.reason, FailureReason.unknown);
    });

    test('못 지우면 signOut → unknown 실패, 토큰은 남는다', () async {
      await server.signIn(AuthProvider.kakao);
      tokens.failClear = true;
      final res = await repo.signOut();
      expect(res.failureOrNull?.reason, FailureReason.unknown);
      expect(tokens.token, isNotNull);
    });
  });

  // 서버 세션은 만료로 끝난다. 사용자가 원한 것은 이 기기에서 로그아웃하는 것이다.
  test('서버 로그아웃이 실패해도 로컬 토큰을 지웠으면 signOut은 성공이다', () async {
    await server.signIn(AuthProvider.kakao);
    server.faults.fail('POST', '/v1/auth/logout', reason: FailureReason.server);
    expect((await repo.signOut()).failureOrNull, isNull);
    expect(tokens.token, isNull);
  });
}
