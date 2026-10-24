import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/budget/budget_category.dart';

void main() {
  // 이름과 선언 순서(화면 순서)는 API 계약(docs/api-contract.md)의 기본 분류 표와 같다.
  // API id는 data/dto/category_wire.dart가 정한다(category_wire_test).
  test('19 labels in declaration order', () {
    expect(BudgetCategory.values.map((e) => e.label).toList(), [
      '장보기', '외식·배달', '카페·간식', '술·유흥', '쇼핑·패션', '뷰티·미용', '생활용품·가전',
      '주거·관리비', '통신·구독', '교통', '자동차', '의료·건강', '교육', '취미·여가',
      '여행·숙박', '반려동물', '경조사·선물', '금융·세금', '기타',
    ]);
  });
}
