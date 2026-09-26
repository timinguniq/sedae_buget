import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/app_config/environment_config.dart';
import 'package:sedae_budget/core/http_client/server_connection.dart';
import 'package:sedae_budget/core/http_client/session_expiry.dart';

import '../../helper/stub_server.dart';

/// local 환경에서 서버 대신 답하는 인터셉터. 받은 요청을 기록하고 200으로 답한다.
class _LocalServer extends Interceptor {
  final requests = <RequestOptions>[];

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    requests.add(o);
    h.resolve(Response(requestOptions: o, statusCode: 200, data: {'ok': true}));
  }
}

Dio _connect(AppEnvironment env, {bool release = false, _LocalServer? local, String? token}) =>
    connectToServer(
      env: env,
      tokenStore: MemoryAuthTokenStore(token),
      sessionExpiry: SessionExpiry(),
      localServer: () => local ?? _LocalServer(),
      release: release,
    );

/// [body]가 print한 줄을 모은다.
Future<List<String>> _printed(Future<void> Function() body) async {
  final lines = <String>[];
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(print: (_, _, _, line) => lines.add(line)),
  );
  return lines;
}

void main() {
  test('환경 이름이 없거나 모르는 이름이면 local(Stub)이다', () {
    expect(AppEnvironment.parse(''), AppEnvironment.local);
    expect(AppEnvironment.parse('moon'), AppEnvironment.local);
    expect(AppEnvironment.parse('dev'), AppEnvironment.dev);
  });

  test('local이면 토큰을 붙인 요청에 서버 대신 local 서버가 답한다', () async {
    final local = _LocalServer();
    final res = await _connect(AppEnvironment.local, local: local, token: 'stub.kakao').get('/v1/me');
    expect(res.data, {'ok': true});
    expect(local.requests.single.headers['Authorization'], 'Bearer stub.kakao');
  });

  // 이전에는 경고 로그만 남기고 모든 호출이 네트워크 오류('연결 안 됨')가 됐다.
  test('local이 아닌데 서버 주소가 비었으면 시작할 때 멈춘다', () {
    final unset = AppEnvironment.values.where((e) => e != AppEnvironment.local && e.server.isEmpty);
    for (final env in unset) {
      expect(() => _connect(env), throwsStateError, reason: env.name);
    }
  });

  group('요청 로그', () {
    Future<List<String>> signInLog({required bool release}) => _printed(() async {
          await _connect(AppEnvironment.local, release: release)
              .post('/v1/auth/login', data: {'provider': 'kakao', 'idToken': 'secret-id-token'});
        });

    test('debug는 요청 바디까지 남긴다', () async {
      expect((await signInLog(release: false)).join('\n'), contains('secret-id-token'));
    });

    // 이전에는 release 빌드도 로그인 idToken·거래 금액·메모를 기기 로그에 남겼다.
    test('release는 남기지 않는다', () async {
      expect(await signInLog(release: true), isEmpty);
    });
  });
}
