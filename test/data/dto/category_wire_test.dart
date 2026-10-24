import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/dto/category_wire.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  // API 계약(docs/api-contract.md)의 기본 분류 표: 선언 순서가 id 1~19다.
  test('기본 분류의 API id는 계약 표 순서대로 1~19다', () {
    expect(BudgetCategory.values.map((c) => c.wire).toList(), List.generate(19, (i) => i + 1));
  });

  test('API id로 기본 분류를 읽는다', () {
    expect(budgetCategoryFromWire(10), BudgetCategory.transport);
    expect(budgetCategoryFromWire(19), BudgetCategory.etc);
  });

  // 서버가 늘린 분류, 수입에 적힌 아무 값, 정수가 아닌 값. 어떻게 읽을지는 DTO가 정한다.
  test('모르는 id는 null이다', () {
    expect(budgetCategoryFromWire(0), isNull);
    expect(budgetCategoryFromWire(20), isNull);
    expect(budgetCategoryFromWire('3'), isNull);
    expect(budgetCategoryFromWire(1.0), isNull);
    expect(budgetCategoryFromWire(null), isNull);
  });
}
