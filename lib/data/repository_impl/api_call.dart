import 'package:dio/dio.dart';
import 'package:sedae_budget/core/util/logger/custom_logger.dart';
import 'package:sedae_budget/entity/entity.dart';

final _logger = CustomLogger.create(tag: 'api');

/// retrofit 호출([run])을 [Result]로 바꾼다. repository는 서버를 모두 이것으로 부른다.
///
/// 모든 실패가 여기서 [ErrorResult]로 끝나고 repository는 던지지 않는다.
/// - 응답을 못 받음: 시간 초과면 timeout, 그 밖은 offline.
/// - 오류 응답: 상태코드로 [FailureReason]을 정하고, 서버 바디 `{code, message}`의 도메인 코드와 문구만 옮긴다.
///   HTTP 상태·전송 오류 코드와 Dio의 개발자용 문구는 여기서 버린다.
/// - 해석할 수 없는 성공 응답(빈 바디·빠진 필드·모르는 값): server.
///
/// [recover]가 실패를 값으로 바꾸면(예: 프로필이 아직 없음) 그 값으로 성공한다. null이면 실패 그대로다.
Future<Result<T>> guardApi<T>(
  Future<T> Function() run, {
  Result<T>? Function(ErrorResult failure)? recover,
}) async {
  try {
    return Result.success(await run());
  } on DioException catch (e) {
    final failure = _failureOf(e);
    return recover?.call(failure) ?? Result.failure(failure);
  } catch (e, s) {
    _logger.e('서버 응답을 해석하지 못했어요', error: e, stackTrace: s);
    return const Result.failure(ErrorResult(reason: FailureReason.server, message: ''));
  }
}

ErrorResult _failureOf(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const ErrorResult(reason: FailureReason.timeout, message: '');
    case DioExceptionType.badResponse:
      final data = e.response?.data;
      final body = data is Map && data['code'] is String ? data : null;
      return ErrorResult(
        reason: _reasonOf(e.response?.statusCode),
        message: (body?['message'] as String?) ?? '',
        code: body?['code'] as String?,
      );
    default:
      return const ErrorResult(reason: FailureReason.offline, message: '');
  }
}

FailureReason _reasonOf(int? status) {
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
