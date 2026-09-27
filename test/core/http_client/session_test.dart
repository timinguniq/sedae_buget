import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/entity/entity.dart';

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
  late Session session;
  late int expiredCount;

  setUp(() {
    tokens = MemoryAuthTokenStore();
    session = Session(tokens);
    expiredCount = 0;
    session.expired.listen((_) => expiredCount++);
  });

  Dio dioWith(Interceptor server) => Dio()
    ..interceptors.add(session.interceptor)
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

  // 로그아웃은 지운 토큰을 직접 적어 보낸다. 그 사이 새로 로그인했어도 새 토큰으로 덮으면 새 세션이 끝난다.
  test('요청에 이미 Authorization이 있으면 지금 토큰으로 덮지 않는다', () async {
    tokens.token = 'new';
    final headers = (await dioWith(_EchoHeaders())
            .get<Map<String, dynamic>>('/x', options: Options(headers: {'Authorization': 'Bearer old'})))
        .data!;
    expect(headers['Authorization'], 'Bearer old');
  });

  test('빈 토큰은 세션이 아니고 요청에 붙이지 않는다', () async {
    tokens.token = '';
    expect(await session.isActive, isFalse);
    final headers = (await dioWith(_EchoHeaders()).get<Map<String, dynamic>>('/x')).data!;
    expect(headers.containsKey('Authorization'), isFalse);
  });

  // 요청은 토큰을 읽어 보냈는데, 거부(401)가 올 때는 저장소를 읽지 못한다. 세션은 끝난 것이다.
  test('401을 받을 때 저장소를 못 읽으면 세션이 끝났다고 알린다', () async {
    tokens.token = 'abc';
    await send(dioWith(_Reply(401, beforeReply: () async => tokens.failRead = true)));
    expect(expiredCount, 1);
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

  // 이전에는 읽기 실패가 요청 오류가 되어 '인터넷에 연결되어 있지 않아요'로 보였다.
  test('쓰는 중 토큰을 못 읽으면 세션 만료로 알리고, 지우기를 시도하고, 토큰 없이 보낸다', () async {
    tokens
      ..token = 'abc'
      ..failRead = true;
    final headers = (await dioWith(_EchoHeaders()).get<Map<String, dynamic>>('/x')).data!;
    await Future<void>.delayed(Duration.zero);
    expect(headers.containsKey('Authorization'), isFalse);
    expect(expiredCount, 1);
    tokens.failRead = false;
    expect(tokens.token, isNull);
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

  group('저장소', () {
    test('저장된 토큰이 있으면 세션이 있다', () async {
      expect(await session.isActive, isFalse);
      expect((await session.start('abc')).failureOrNull, isNull);
      expect(await session.isActive, isTrue);
      expect((await session.end()).failureOrNull, isNull);
      expect(await session.isActive, isFalse);
    });

    // 앱을 켤 때 확인하는 경로다. 로그인 화면으로 보내되 만료로 알리지는 않는다.
    test('못 읽으면 세션이 없고, 지우기를 시도하고, 만료로 알리지 않는다', () async {
      tokens
        ..token = 'abc'
        ..failRead = true;
      expect(await session.isActive, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(expiredCount, 0);
      tokens.failRead = false;
      expect(tokens.token, isNull);
    });

    test('못 쓰거나 못 지우면 던지지 않고 unknown 실패다', () async {
      tokens.failWrite = true;
      expect((await session.start('abc')).failureOrNull?.reason, FailureReason.unknown);
      tokens
        ..token = 'abc'
        ..failClear = true;
      expect((await session.end()).failureOrNull?.reason, FailureReason.unknown);
      expect(tokens.token, 'abc');
    });
  });
}
