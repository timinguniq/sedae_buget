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

  /// 서버가 쓴 문구. 서버가 문구를 주지 않았거나 서버에 닿지 못했으면 빈 문자열.
  /// 화면에 보일지는 presentation이 실패 이유를 보고 정한다.
  final String message;

  /// 서버가 준 도메인 코드(예: `CATEGORY_DUPLICATE`). HTTP 상태나 전송 오류 코드는 담지 않는다.
  final String? code;

  @override
  String toString() =>
      'ErrorResult(${reason.name}${code == null ? '' : ', $code'}, $message)';
}
