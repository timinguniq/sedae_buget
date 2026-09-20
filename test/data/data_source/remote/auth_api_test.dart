import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../../helper/recording_interceptor.dart';

AuthApi _api(RecordingInterceptor server) => AuthApi(Dio()..interceptors.add(server));

const _user = {'id': 'u_1', 'provider': 'kakao', 'nickname': '카카오 사용자'};

void main() {
  test('login → POST /v1/auth/login {provider,idToken}, 토큰과 사용자를 돌려준다', () async {
    final server = RecordingInterceptor(body: {'accessToken': 'tok', 'user': _user});

    final res = await _api(server)
        .login(const LoginRequestDto(provider: AuthProvider.kakao, idToken: 'id-token'));

    expect(server.single.method, 'POST');
    expect(server.single.path, '/v1/auth/login');
    expect(server.single.data, {'provider': 'kakao', 'idToken': 'id-token'});
    expect(res.accessToken, 'tok');
    expect(res.user.provider, AuthProvider.kakao);
    expect(res.user.nickname, '카카오 사용자');
  });

  test('logout → POST /v1/auth/logout (바디 없음)', () async {
    final server = RecordingInterceptor(status: 204);

    await _api(server).logout();

    expect(server.single.method, 'POST');
    expect(server.single.path, '/v1/auth/logout');
    expect(server.single.data, isNull);
  });

  test('me → GET /v1/me, 사용자를 돌려준다', () async {
    final server = RecordingInterceptor(body: _user);

    final user = await _api(server).me();

    expect(server.single.method, 'GET');
    expect(server.single.path, '/v1/me');
    expect(user.provider, AuthProvider.kakao);
    expect(user.nickname, '카카오 사용자');
  });
}
