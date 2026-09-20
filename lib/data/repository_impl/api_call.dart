import 'package:dio/dio.dart';
import 'package:sedae_budget/core/http_client/api_exception.dart';
import 'package:sedae_budget/entity/entity.dart';

/// retrofit 호출을 실행하고 [DioException]을 [ApiException]으로 통일한다.
/// data 레이어 안에서만 쓴다 — domain 계약은 [Result]다.
Future<T> callApi<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}

/// [callApi]의 실패를 [Result.failure]로 바꾼다. repository는 모두 이 계약을 쓴다.
Future<Result<T>> guardApi<T>(Future<T> Function() run) async {
  try {
    return Result.success(await callApi(run));
  } on ApiException catch (e) {
    return Result.failure(toErrorResult(e));
  }
}

/// 전송 계층 실패를 도메인 실패로 번역한다. HTTP 상태코드는 여기서 끝난다.
ErrorResult toErrorResult(ApiException e) => ErrorResult(
      reason: _reasonOf(e),
      message: e.message,
      code: _domainCode(e),
    );

FailureReason _reasonOf(ApiException e) {
  switch (e.code) {
    case 'TIMEOUT':
      return FailureReason.timeout;
    case 'NETWORK_ERROR':
      return FailureReason.offline;
  }
  final status = e.statusCode;
  if (status == null) return FailureReason.unknown;
  if (status >= 500) return FailureReason.server;
  return switch (status) {
    401 => FailureReason.unauthorized,
    403 => FailureReason.forbidden,
    404 => FailureReason.notFound,
    409 => FailureReason.conflict,
    400 || 422 => FailureReason.invalid,
    _ => FailureReason.unknown,
  };
}

/// 서버가 준 도메인 코드만 남긴다. `HTTP_500`·`TIMEOUT` 같은 전송 계층 코드는 버린다.
String? _domainCode(ApiException e) {
  if (e.code == 'TIMEOUT' || e.code == 'NETWORK_ERROR') return null;
  if (e.code.startsWith('HTTP_')) return null;
  return e.code;
}
