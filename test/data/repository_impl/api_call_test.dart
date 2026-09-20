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

  group('guardApi', () {
    Future<ErrorResult> failureOf(Interceptor i) async =>
        (await guardApi(() => _me(i))).failureOrNull!;

    test('성공 → Result.success', () async {
      final ok = await guardApi(() => _me(_Resolve({'provider': 'kakao', 'nickname': 'n'})));
      expect((ok as Success<AuthUserDto>).data.nickname, 'n');
    });

    test('서버 도메인 코드와 문구는 그대로 옮긴다', () async {
      final error = await failureOf(_Reject(409, {'code': 'DUP', 'message': '중복'}));
      expect(error.code, 'DUP');
      expect(error.message, '중복');
    });

    test('상태코드를 도메인 분류로 바꾼다', () async {
      expect((await failureOf(_Reject(401, {'code': 'AUTH_002', 'message': ''}))).reason,
          FailureReason.unauthorized);
      expect((await failureOf(_Reject(403, {'code': 'CATEGORY_IMMUTABLE', 'message': ''}))).reason,
          FailureReason.forbidden);
      expect((await failureOf(_Reject(404, {'code': 'NOT_FOUND', 'message': ''}))).reason,
          FailureReason.notFound);
      expect((await failureOf(_Reject(409, {'code': 'DUP', 'message': ''}))).reason,
          FailureReason.conflict);
      expect((await failureOf(_Reject(400, {'code': 'VALIDATION', 'message': ''}))).reason,
          FailureReason.invalid);
      expect((await failureOf(_Reject(500, '<html>'))).reason, FailureReason.server);
      expect((await failureOf(_Timeout())).reason, FailureReason.timeout);
    });

    test('HTTP·전송 계층 코드는 domain seam을 넘지 않는다', () async {
      // 이전에는 resultCode에 'HTTP_500'·'TIMEOUT'이 그대로 담겨 위젯까지 갔다.
      expect((await failureOf(_Reject(500, '<html>'))).code, isNull);
      expect((await failureOf(_Timeout())).code, isNull);
    });

    test('모르는 상태코드는 unknown', () async {
      final error = await failureOf(_Reject(418, {'code': 'TEAPOT', 'message': ''}));
      expect(error.reason, FailureReason.unknown);
      expect(error.code, 'TEAPOT');
    });
  });
}
