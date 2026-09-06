import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

class _Tokens implements AuthTokenStore {
  String? t;
  @override
  Future<String?> read() async => t;
  @override
  Future<void> write(String token) async => t = token;
  @override
  Future<void> clear() async => t = null;
}

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
  late _Tokens tokens;
  late AuthRepository repo;

  setUp(() {
    tokens = _Tokens();
    final api = ApiClient(Dio()
      ..interceptors.add(AuthTokenInterceptor(tokens))
      ..interceptors.add(StubApiInterceptor()));
    repo = ApiAuthRepository(api, tokens);
  });

  test('no token → currentUser null', () async {
    expect(await repo.currentUser(), isNull);
  });

  test('signIn stores token and returns user; currentUser round-trips', () async {
    final u = await repo.signIn(AuthProvider.naver, 'id-token');
    expect(u.nickname, '네이버 사용자');
    expect(u.provider, AuthProvider.naver);
    expect(tokens.t, isNotEmpty);
    expect((await repo.currentUser())?.provider, AuthProvider.naver);
  });

  test('invalid token → 401 → token cleared, null', () async {
    tokens.t = 'garbage';
    expect(await repo.currentUser(), isNull);
    expect(tokens.t, isNull);
  });

  test('signOut clears token', () async {
    await repo.signIn(AuthProvider.google, 'x');
    await repo.signOut();
    expect(tokens.t, isNull);
  });

  test('server error on /me propagates; signOut still clears token', () async {
    final api = ApiClient(Dio()
      ..interceptors.add(AuthTokenInterceptor(tokens))
      ..interceptors.add(_ServerDown()));
    final down = ApiAuthRepository(api, tokens);
    tokens.t = 'stub.kakao';
    expect(() => down.currentUser(), throwsA(isA<ApiException>()));
    expect(tokens.t, 'stub.kakao'); // 500은 토큰을 지우지 않는다
    await down.signOut();
    expect(tokens.t, isNull);
  });
}
