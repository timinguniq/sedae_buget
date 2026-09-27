import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/budget/budget_category.dart';

void main() {
  test('has exactly 19 categories with ids 1..19', () {
    expect(BudgetCategory.values.map((e) => e.id).toList(), List.generate(19, (i) => i + 1));
  });

  // 이름과 id는 API 계약(docs/api-contract.md)의 기본 분류 표와 같다.
  test('labels in id order', () {
    expect(BudgetCategory.values.map((e) => e.label).toList(), [
      '장보기', '외식·배달', '카페·간식', '술·유흥', '쇼핑·패션', '뷰티·미용', '생활용품·가전',
      '주거·관리비', '통신·구독', '교통', '자동차', '의료·건강', '교육', '취미·여가',
      '여행·숙박', '반려동물', '경조사·선물', '금융·세금', '기타',
    ]);
  });

  test('fromId returns matching category', () {
    expect(BudgetCategory.fromId(10), BudgetCategory.transport);
    expect(BudgetCategory.fromId(19), BudgetCategory.etc);
  });
}
