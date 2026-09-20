import 'package:dio/dio.dart';
import 'package:sedae_budget/core/http_client/api_exception.dart';
import 'package:sedae_budget/entity/entity.dart';

/// retrofit 호출을 실행하고 [DioException]을 [ApiException]으로 통일한다.
Future<T> callApi<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}

/// [callApi]의 실패를 [Result.failure]로 바꾼다. Result 계약을 쓰는 repository용.
Future<Result<T>> guardApi<T>(Future<T> Function() run) async {
  try {
    return Result.success(await callApi(run));
  } on ApiException catch (e) {
    return Result.failure(ErrorResult(resultCode: e.code, message: e.message));
  }
}
