/// 또래 비교의 기준이 되는 나이대(세대) 구간.
enum AgeGroup {
  teens('10대'),
  twenties('20대'),
  thirties('30대'),
  forties('40대'),
  fiftiesPlus('50대+');

  const AgeGroup(this.label);

  final String label;
}
