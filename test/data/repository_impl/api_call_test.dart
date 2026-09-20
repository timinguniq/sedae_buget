import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

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

/// retrofit 명세를 거친 실제 호출 경로로 검증한다.
Future<AuthUserDto> _me(Interceptor i) => callApi(AuthApi(Dio()..interceptors.add(i)).me);

void main() {
  test('success → returns the parsed value', () async {
    final user = await _me(_Resolve({'provider': 'kakao', 'nickname': 'n'}));
    expect(user.nickname, 'n');
  });

  test('server error body {code,message} → ApiException with same code', () async {
    expect(
      () => _me(_Reject(401, {'code': 'AUTH_002', 'message': '로그인이 필요합니다.'})),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'AUTH_002')
          .having((e) => e.message, 'message', '로그인이 필요합니다.')
          .having((e) => e.isUnauthorized, 'unauthorized', isTrue)),
    );
  });

  test('non-JSON error body → HTTP_<status>', () async {
    expect(
      () => _me(_Reject(500, '<html>')),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'HTTP_500')),
    );
  });

  test('404 → isNotFound', () async {
    expect(
      () => _me(_Reject(404, {'code': 'NOT_FOUND', 'message': ''})),
      throwsA(isA<ApiException>().having((e) => e.isNotFound, 'notFound', isTrue)),
    );
  });

  test('timeout → TIMEOUT', () async {
    expect(
      () => _me(_Timeout()),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TIMEOUT')),
    );
  });

  test('guardApi: success → Result.success, ApiException → Result.failure(code, message)',
      () async {
    final ok = await guardApi(() => _me(_Resolve({'provider': 'kakao', 'nickname': 'n'})));
    expect((ok as Success<AuthUserDto>).data.nickname, 'n');

    final failed =
        await guardApi(() => _me(_Reject(409, {'code': 'DUP', 'message': '중복'})));
    final error = (failed as Error<AuthUserDto>).error;
    expect(error.resultCode, 'DUP');
    expect(error.message, '중복');
  });
}
