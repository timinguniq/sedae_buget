import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/widget/common/failure_message.dart';

ErrorResult _f(FailureReason reason, [String message = '']) =>
    ErrorResult(reason: reason, message: message);

void main() {
  test('하던 일과 이유를 잇는다', () {
    expect(failureMessage(UserAction.save, _f(FailureReason.offline)),
        '저장하지 못했어요. 인터넷에 연결되어 있지 않아요');
  });

  test('하던 일마다 앞부분이 다르다', () {
    const heads = {
      UserAction.save: '저장하지 못했어요.',
      UserAction.delete: '삭제하지 못했어요.',
      UserAction.load: '불러오지 못했어요.',
      UserAction.signIn: '로그인하지 못했어요.',
    };
    expect(heads.keys.toSet(), UserAction.values.toSet());
    for (final e in heads.entries) {
      expect(failureMessage(e.key, _f(FailureReason.offline)), startsWith(e.value));
    }
  });

  test('모든 실패 이유가 문구를 가진다', () {
    const reasons = {
      FailureReason.offline: '인터넷에 연결되어 있지 않아요',
      FailureReason.timeout: '응답이 늦어요. 잠시 후 다시 시도해 주세요',
      FailureReason.server: '서버에 문제가 생겼어요. 잠시 후 다시 시도해 주세요',
      FailureReason.notFound: '이미 지워졌거나 찾을 수 없어요',
      FailureReason.forbidden: '이 항목은 바꿀 수 없어요',
      FailureReason.conflict: '이미 같은 항목이 있어요',
      FailureReason.invalid: '입력한 값을 확인해 주세요',
      FailureReason.unauthorized: '로그인이 필요해요',
      FailureReason.unknown: '문제가 생겼어요. 잠시 후 다시 시도해 주세요',
    };
    expect(reasons.keys.toSet(), FailureReason.values.toSet());
    for (final e in reasons.entries) {
      expect(failureMessage(UserAction.load, _f(e.key)), '불러오지 못했어요. ${e.value}');
    }
  });

  test('서버 문구는 사용자가 고칠 수 있는 실패(conflict·invalid)에서만 쓴다', () {
    expect(failureMessage(UserAction.save, _f(FailureReason.conflict, '같은 이름의 카테고리가 있어요')),
        '저장하지 못했어요. 같은 이름의 카테고리가 있어요');
    expect(failureMessage(UserAction.save, _f(FailureReason.invalid, '이름은 20자까지예요')),
        '저장하지 못했어요. 이름은 20자까지예요');
    expect(failureMessage(UserAction.save, _f(FailureReason.server, 'java.lang.NullPointerException')),
        '저장하지 못했어요. 서버에 문제가 생겼어요. 잠시 후 다시 시도해 주세요');
    expect(failureMessage(UserAction.save, _f(FailureReason.conflict, '  ')),
        '저장하지 못했어요. 이미 같은 항목이 있어요');
  });

  // 화면은 불러오기 실패를 AsyncError로 받는다. 이전에는 '$e'를 그대로 보여 빈 화면이 되기도 했다.
  test('화면이 받은 오류(ResultFailure)나 알 수 없는 오류도 문구가 된다', () {
    expect(failureMessage(UserAction.load, ResultFailure(_f(FailureReason.offline))),
        '불러오지 못했어요. 인터넷에 연결되어 있지 않아요');
    expect(failureMessage(UserAction.load, StateError('Bad state: No element')),
        '불러오지 못했어요. 문제가 생겼어요. 잠시 후 다시 시도해 주세요');
  });
}
