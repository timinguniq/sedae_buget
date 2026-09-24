import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';

import '../../helper/stub_server.dart';

/// 요청 헤더를 응답 바디로 되돌려 주는 인터셉터.
class _EchoHeaders extends Interceptor {
  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) =>
      h.resolve(Response(requestOptions: o, statusCode: 200, data: o.headers));
}

/// 실제 서버처럼 오류 응답이 뒤따르는 오류 인터셉터를 거치게 한다.
/// [beforeReply]는 요청이 떠난 뒤 응답이 오기 전에 일어나는 일(예: 다시 로그인).
class _Reply extends Interceptor {
  _Reply(this.status, {this.beforeReply});
  final int status;
  final Future<void> Function()? beforeReply;

  @override
  Future<void> onRequest(RequestOptions o, RequestInterceptorHandler h) async {
    await beforeReply?.call();
    h.reject(
      DioException(
        requestOptions: o,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: o, statusCode: status),
      ),
      true,
    );
  }
}

void main() {
  late MemoryAuthTokenStore tokens;
  late SessionExpiry expiry;
  late int expiredCount;

  setUp(() {
    tokens = MemoryAuthTokenStore();
    expiry = SessionExpiry();
    expiredCount = 0;
    expiry.expired.listen((_) => expiredCount++);
  });

  Dio dioWith(Interceptor server) => Dio()
    ..interceptors.add(AuthTokenInterceptor(tokens, expiry))
    ..interceptors.add(server);

  Future<void> send(Dio dio) async {
    try {
      await dio.get<void>('/x');
    } on DioException catch (_) {}
    await Future<void>.delayed(Duration.zero); // 알림 전달
  }

  test('token present → Authorization: Bearer <token>', () async {
    tokens.token = 'abc';
    final headers = (await dioWith(_EchoHeaders()).get<Map<String, dynamic>>('/x')).data!;
    expect(headers['Authorization'], 'Bearer abc');
  });

  test('no token → no Authorization header', () async {
    final headers = (await dioWith(_EchoHeaders()).get<Map<String, dynamic>>('/x')).data!;
    expect(headers.containsKey('Authorization'), isFalse);
  });

  test('보낸 토큰이 거부되면(401) 토큰을 지우고 세션 만료를 알린다', () async {
    tokens.token = 'abc';
    await send(dioWith(_Reply(401)));
    expect(tokens.token, isNull);
    expect(expiredCount, 1);
  });

  test('토큰 없이 받은 401은 세션 만료가 아니다', () async {
    await send(dioWith(_Reply(401)));
    expect(expiredCount, 0);
  });

  test('401이 아닌 실패는 토큰을 건드리지 않는다', () async {
    tokens.token = 'abc';
    await send(dioWith(_Reply(500)));
    expect(tokens.token, 'abc');
    expect(expiredCount, 0);
  });

  // 옛 토큰으로 보낸 요청의 401이 늦게 와도, 그 사이 새로 받은 토큰은 지켜야 한다.
  test('응답 전에 다시 로그인했으면 새 토큰은 그대로 둔다', () async {
    tokens.token = 'old';
    await send(dioWith(_Reply(401, beforeReply: () async => tokens.token = 'new')));
    expect(tokens.token, 'new');
    expect(expiredCount, 0);
  });
}
