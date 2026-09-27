import 'package:sedae_budget/entity/entity.dart';

/// 나이대의 API 값(`docs/api-contract.md`). 앱의 [AgeGroup]과 서버 값의 대응은 여기만 안다.
/// 나이대가 늘면 이 switch가 컴파일 오류로 알려 준다.
extension AgeGroupWire on AgeGroup {
  String get wire => switch (this) {
        AgeGroup.teens => 'teens',
        AgeGroup.twenties => 'twenties',
        AgeGroup.thirties => 'thirties',
        AgeGroup.forties => 'forties',
        AgeGroup.fiftiesPlus => 'fiftiesPlus',
      };
}

/// API 값 [raw]가 가리키는 나이대. 모르는 값(서버가 늘렸거나 바꾼 나이대)이면 null.
AgeGroup? ageGroupFromWire(Object? raw) {
  for (final g in AgeGroup.values) {
    if (g.wire == raw) return g;
  }
  return null;
}
