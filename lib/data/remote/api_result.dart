import 'package:sedae_budget/core/http_client/api_exception.dart';
import 'package:sedae_budget/entity/entity.dart';

/// [ApiException]을 [Result.failure]로 바꾼다. Result 계약을 쓰는 repository용.
Future<Result<T>> guardApi<T>(Future<T> Function() run) async {
  try {
    return Result.success(await run());
  } on ApiException catch (e) {
    return Result.failure(ErrorResult(resultCode: e.code, message: e.message));
  }
}
