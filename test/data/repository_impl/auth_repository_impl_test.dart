import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
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

enum _TokenOp { read, write, clear }

/// secure storage 고장 흉내: [broken] 작업에서 [PlatformException]을 던지고, 나머지는 메모리에 둔다.
class _BrokenTokenStore extends MemoryAuthTokenStore {
  _BrokenTokenStore(this.broken);

  final _TokenOp broken;

  Future<Never> _fail() async => throw PlatformException(code: 'keystore');

  @override
  Future<String?> read() => broken == _TokenOp.read ? _fail() : super.read();

  @override
  Future<void> write(String token) => broken == _TokenOp.write ? _fail() : super.write(token);

  @override
  Future<void> clear() => broken == _TokenOp.clear ? _fail() : super.clear();
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

  /// 요청 헤더는 서버의 토큰 저장소로 붙고, 저장소 구현만 고장 난 토큰 저장소를 쓴다.
  AuthRepository brokenRepo(_TokenOp broken) =>
      AuthRepositoryImpl(AuthApi(server.dio), _BrokenTokenStore(broken), server.sessionExpiry);

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
    // 토큰을 먼저 지우면 로그아웃 요청이 인증 없이 가서 401로 실패한다.
    expect((await repo.signOut()).failureOrNull, isNull);
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

  group('토큰 저장소가 던져도 저장소는 던지지 않고 실패를 돌려준다', () {
    test('못 읽으면 currentUser → unknown 실패', () async {
      final res = await brokenRepo(_TokenOp.read).currentUser();
      expect(res.failureOrNull?.reason, FailureReason.unknown);
    });

    test('못 쓰면 signIn → unknown 실패', () async {
      final res = await brokenRepo(_TokenOp.write).signIn(AuthProvider.kakao, 'x');
      expect(res.failureOrNull?.reason, FailureReason.unknown);
    });

    test('못 지우면 서버 로그아웃이 성공해도 signOut → unknown 실패', () async {
      await server.signIn(AuthProvider.kakao); // 로그인해야 서버 로그아웃이 성공한다
      final res = await brokenRepo(_TokenOp.clear).signOut();
      expect(res.failureOrNull?.reason, FailureReason.unknown);
    });

    test('서버 로그아웃도 실패하면 signOut은 서버 실패를 먼저 알린다', () async {
      server.faults.fail('POST', '/v1/auth/logout', reason: FailureReason.server);
      final res = await brokenRepo(_TokenOp.clear).signOut();
      expect(res.failureOrNull?.reason, FailureReason.server);
    });
  });
}
