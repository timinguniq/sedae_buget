import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';

/// 지정한 상태코드·바디로 즉시 실패시키는 테스트용 인터셉터.
class _Reject extends Interceptor {
  _Reject(this.status, [this.body]);
  final int status;
  final Object? body;

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) => h.reject(
        DioException(
          requestOptions: o,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: o, statusCode: status, data: body),
        ),
      );
}

class _Resolve extends Interceptor {
  _Resolve(this.body);
  final Object? body;

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) =>
      h.resolve(Response(requestOptions: o, statusCode: 200, data: body));
}

class _Timeout extends Interceptor {
  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) => h.reject(
        DioException(requestOptions: o, type: DioExceptionType.connectionTimeout),
      );
}

ApiClient _client(Interceptor i) => ApiClient(Dio()..interceptors.add(i));

void main() {
  test('get returns typed body', () async {
    final api = _client(_Resolve({'a': 1}));
    expect(await api.get<Map<String, dynamic>>('/x'), {'a': 1});
  });

  test('server error body {code,message} → ApiException with same code', () async {
    final api = _client(_Reject(401, {'code': 'AUTH_002', 'message': '로그인이 필요합니다.'}));
    expect(
      () => api.get<Map<String, dynamic>>('/x'),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'AUTH_002')
          .having((e) => e.message, 'message', '로그인이 필요합니다.')
          .having((e) => e.isUnauthorized, 'unauthorized', isTrue)),
    );
  });

  test('non-JSON error body → HTTP_<status>', () async {
    final api = _client(_Reject(500, '<html>'));
    expect(
      () => api.get<dynamic>('/x'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'HTTP_500')),
    );
  });

  test('404 → isNotFound', () async {
    final api = _client(_Reject(404, {'code': 'NOT_FOUND', 'message': ''}));
    expect(
      () => api.delete('/x'),
      throwsA(isA<ApiException>().having((e) => e.isNotFound, 'notFound', isTrue)),
    );
  });

  test('timeout → TIMEOUT', () async {
    final api = _client(_Timeout());
    expect(
      () => api.post<dynamic>('/x', body: {}),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TIMEOUT')),
    );
  });
}
