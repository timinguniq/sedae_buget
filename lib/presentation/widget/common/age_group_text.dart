import 'package:sedae_budget/entity/entity.dart';

/// 나이대를 화면에서 부르는 말(이름 '10대'는 [AgeGroup.label]). 앱의 나이대 문구는 모두 여기 있다.
/// 나이대가 늘면 이 switch들이 컴파일 오류로 알려 준다.
extension AgeGroupText on AgeGroup {
  /// 온보딩 나이대 카드의 숫자 배지: '10'·'50+'.
  String get badge => switch (this) {
        AgeGroup.teens => '10',
        AgeGroup.twenties => '20',
        AgeGroup.thirties => '30',
        AgeGroup.forties => '40',
        AgeGroup.fiftiesPlus => '50+',
      };

  /// 온보딩 나이대 카드의 설명: '학생 · 첫 용돈 관리'.
  String get lifeStage => switch (this) {
        AgeGroup.teens => '학생 · 첫 용돈 관리',
        AgeGroup.twenties => '사회초년생 · 첫 독립',
        AgeGroup.thirties => '결혼 · 내 집 마련',
        AgeGroup.forties => '자녀 교육 · 안정기',
        AgeGroup.fiftiesPlus => '노후 · 건강 관리',
      };

  /// 리포트 세대별 대표 소비 칩(디자인 문구 — 또래 통계에 대표 항목이 없다): '간식'.
  String get signatureSpend => switch (this) {
        AgeGroup.teens => '간식',
        AgeGroup.twenties => '카페·모임',
        AgeGroup.thirties => '육아·주거',
        AgeGroup.forties => '자녀교육',
        AgeGroup.fiftiesPlus => '건강',
      };
}
