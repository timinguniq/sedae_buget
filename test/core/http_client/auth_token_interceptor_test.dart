import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';

class _MemTokens implements AuthTokenStore {
  String? t;
  @override
  Future<String?> read() async => t;
  @override
  Future<void> write(String token) async => t = token;
  @override
  Future<void> clear() async => t = null;
}

/// 요청 헤더를 응답 바디로 되돌려 주는 인터셉터.
class _EchoHeaders extends Interceptor {
  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) =>
      h.resolve(Response(requestOptions: o, statusCode: 200, data: o.headers));
}

void main() {
  late _MemTokens tokens;
  late ApiClient api;

  setUp(() {
    tokens = _MemTokens();
    api = ApiClient(Dio()
      ..interceptors.add(AuthTokenInterceptor(tokens))
      ..interceptors.add(_EchoHeaders()));
  });

  test('token present → Authorization: Bearer <token>', () async {
    tokens.t = 'abc';
    final headers = await api.get<Map<String, dynamic>>('/x');
    expect(headers['Authorization'], 'Bearer abc');
  });

  test('no token → no Authorization header', () async {
    final headers = await api.get<Map<String, dynamic>>('/x');
    expect(headers.containsKey('Authorization'), isFalse);
  });
}
