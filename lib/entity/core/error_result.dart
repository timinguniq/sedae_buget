import 'package:sedae_budget/entity/core/failure_reason.dart';

/// 도메인 계약의 실패. 모든 repository는 실패를 이 타입으로 돌려준다.
class ErrorResult {
  const ErrorResult({
    required this.reason,
    required this.message,
    this.code,
  });

  /// 호출부가 분기하는 기준.
  final FailureReason reason;

  /// 사용자에게 보여줄 수 있는 문구. 서버가 문구를 주지 않으면 빈 문자열.
  final String message;

  /// 서버가 준 도메인 코드(예: `CATEGORY_DUPLICATE`). HTTP 상태나 전송 오류 코드는 담지 않는다.
  final String? code;

  @override
  String toString() =>
      'ErrorResult(${reason.name}${code == null ? '' : ', $code'}, $message)';
}
