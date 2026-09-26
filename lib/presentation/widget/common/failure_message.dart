import 'package:sedae_budget/entity/entity.dart';

/// 실패했을 때 사용자가 하던 일. 실패 문구의 앞부분이 된다.
enum UserAction {
  save('저장하지 못했어요'),
  delete('삭제하지 못했어요'),
  load('불러오지 못했어요'),
  signIn('로그인하지 못했어요');

  const UserAction(this.failed);

  final String failed;
}

/// [error]를 사용자에게 보여줄 문구로 바꾼다: "{하던 일}. {이유}".
///
/// [error]는 저장소가 돌려준 [ErrorResult]이거나, 화면이 AsyncError로 받은 오류다.
/// 서버가 쓴 문구는 사용자가 고칠 수 있는 실패(conflict·invalid)에서만 이유로 쓴다.
/// 앱의 실패 문구는 모두 여기서 정한다.
String failureMessage(UserAction action, Object error) {
  final failure = switch (error) {
    ErrorResult e => e,
    ResultFailure f => f.error,
    _ => null,
  };
  return '${action.failed}. ${_reason(failure)}';
}

String _reason(ErrorResult? failure) {
  if (failure == null) return _unknown;
  final server = failure.message.trim();
  final fixable = failure.reason == FailureReason.conflict || failure.reason == FailureReason.invalid;
  if (fixable && server.isNotEmpty) return server;
  return switch (failure.reason) {
    FailureReason.offline => '인터넷에 연결되어 있지 않아요',
    FailureReason.timeout => '응답이 늦어요. 잠시 후 다시 시도해 주세요',
    FailureReason.server => '서버에 문제가 생겼어요. 잠시 후 다시 시도해 주세요',
    FailureReason.notFound => '이미 지워졌거나 찾을 수 없어요',
    FailureReason.forbidden => '이 항목은 바꿀 수 없어요',
    FailureReason.conflict => '이미 같은 항목이 있어요',
    FailureReason.invalid => '입력한 값을 확인해 주세요',
    FailureReason.unauthorized => '로그인이 필요해요',
    FailureReason.unknown => _unknown,
  };
}

const _unknown = '문제가 생겼어요. 잠시 후 다시 시도해 주세요';
