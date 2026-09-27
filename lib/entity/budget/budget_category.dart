/// 지출의 기본 분류 19개 (또래 집계 비교의 전제, 고정 세트).
/// id는 API 계약(`docs/api-contract.md`)의 `categoryId`이고, 선언 순서가 화면에 보이는 순서다.
enum BudgetCategory {
  groceries(1, '장보기'),
  diningOut(2, '외식·배달'),
  cafe(3, '카페·간식'),
  drinks(4, '술·유흥'),
  shopping(5, '쇼핑·패션'),
  beauty(6, '뷰티·미용'),
  household(7, '생활용품·가전'),
  housing(8, '주거·관리비'),
  communication(9, '통신·구독'),
  transport(10, '교통'),
  car(11, '자동차'),
  health(12, '의료·건강'),
  education(13, '교육'),
  recreation(14, '취미·여가'),
  travel(15, '여행·숙박'),
  pet(16, '반려동물'),
  gifts(17, '경조사·선물'),
  finance(18, '금융·세금'),
  etc(19, '기타');

  const BudgetCategory(this.id, this.label);

  final int id;
  final String label;

  /// Throws [StateError] if [id] is not one of the defined category ids.
  static BudgetCategory fromId(int id) =>
      BudgetCategory.values.firstWhere((e) => e.id == id);

  /// 기본 분류가 아니면 null. 서버에서 온 id처럼 모를 수 있는 값은 이것으로 읽고,
  /// 모를 때 어떻게 할지는 서버 응답을 엔티티로 바꾸는 쪽(DTO)이 정한다.
  static BudgetCategory? tryFromId(int id) {
    for (final c in BudgetCategory.values) {
      if (c.id == id) return c;
    }
    return null;
  }
}
