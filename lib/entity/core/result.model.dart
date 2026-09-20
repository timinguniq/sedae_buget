import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sedae_budget/entity/entity.dart';

part 'result.model.freezed.dart';

@freezed
class Result<T> with _$Result {
  const factory Result.success(T data) = Success;

  const factory Result.failure(ErrorResult error) = Error;
}

/// [Result]가 실패일 때 [ResultX.unwrap]이 던진다.
/// AsyncNotifier·FutureProvider 안에서 던지면 화면은 AsyncError로 받는다.
class ResultFailure implements Exception {
  const ResultFailure(this.error);

  final ErrorResult error;

  @override
  String toString() => error.message;
}

extension ResultX<T> on Result<T> {
  /// 성공이면 값, 실패면 [ResultFailure]를 던진다.
  T unwrap() {
    final self = this;
    if (self is Success<T>) return self.data;
    throw ResultFailure((self as Error<T>).error);
  }

  /// 실패면 [ErrorResult], 성공이면 null.
  ErrorResult? get failureOrNull {
    final self = this;
    return self is Error<T> ? self.error : null;
  }
}
