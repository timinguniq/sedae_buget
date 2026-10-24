/// 지출의 기본 분류 19개 (또래 집계 비교의 전제, 고정 세트). 선언 순서가 화면에 보이는 순서다.
/// API 계약(`docs/api-contract.md`)의 id는 `data/dto/category_wire.dart`만 안다.
enum BudgetCategory {
  groceries('장보기'),
  diningOut('외식·배달'),
  cafe('카페·간식'),
  drinks('술·유흥'),
  shopping('쇼핑·패션'),
  beauty('뷰티·미용'),
  household('생활용품·가전'),
  housing('주거·관리비'),
  communication('통신·구독'),
  transport('교통'),
  car('자동차'),
  health('의료·건강'),
  education('교육'),
  recreation('취미·여가'),
  travel('여행·숙박'),
  pet('반려동물'),
  gifts('경조사·선물'),
  finance('금융·세금'),
  etc('기타');

  const BudgetCategory(this.label);

  final String label;
}
