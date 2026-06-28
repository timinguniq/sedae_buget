/// 통계청 가계동향조사 12대 분류 (집계 비교의 전제, 고정 세트)
enum BudgetCategory {
  food(1, '식료품·비주류음료'),
  alcoholTobacco(2, '주류·담배'),
  clothing(3, '의류·신발'),
  housing(4, '주거·수도·광열'),
  household(5, '가정용품·가사서비스'),
  health(6, '보건'),
  transport(7, '교통'),
  communication(8, '통신'),
  recreation(9, '오락·문화'),
  education(10, '교육'),
  diningOut(11, '음식·숙박(외식)'),
  etc(12, '기타 상품·서비스');

  const BudgetCategory(this.id, this.label);

  final int id;
  final String label;

  /// Throws [StateError] if [id] is not one of the 12 defined category ids.
  static BudgetCategory fromId(int id) =>
      BudgetCategory.values.firstWhere((e) => e.id == id);
}
