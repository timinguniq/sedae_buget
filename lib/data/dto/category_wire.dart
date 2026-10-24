import 'package:sedae_budget/entity/entity.dart';

/// 기본 분류의 API id(`docs/api-contract.md`의 `categoryId`·`baseCategoryId`·또래 통계 키).
/// 앱의 [BudgetCategory]와 서버 id의 대응은 여기만 안다. 분류가 늘면 이 switch가 컴파일 오류로 알려 준다.
extension BudgetCategoryWire on BudgetCategory {
  int get wire => switch (this) {
        BudgetCategory.groceries => 1,
        BudgetCategory.diningOut => 2,
        BudgetCategory.cafe => 3,
        BudgetCategory.drinks => 4,
        BudgetCategory.shopping => 5,
        BudgetCategory.beauty => 6,
        BudgetCategory.household => 7,
        BudgetCategory.housing => 8,
        BudgetCategory.communication => 9,
        BudgetCategory.transport => 10,
        BudgetCategory.car => 11,
        BudgetCategory.health => 12,
        BudgetCategory.education => 13,
        BudgetCategory.recreation => 14,
        BudgetCategory.travel => 15,
        BudgetCategory.pet => 16,
        BudgetCategory.gifts => 17,
        BudgetCategory.finance => 18,
        BudgetCategory.etc => 19,
      };
}

/// API id [raw]가 가리키는 기본 분류. 모르는 id(서버가 늘린 분류, 수입에 적힌 아무 값)나 정수가 아니면 null.
/// 모를 때 어떻게 읽을지는 서버 응답을 엔티티로 바꾸는 쪽(DTO)이 정한다.
BudgetCategory? budgetCategoryFromWire(Object? raw) {
  if (raw is! int) return null; // 1.0 == 1이라 정수만 받는다
  for (final c in BudgetCategory.values) {
    if (c.wire == raw) return c;
  }
  return null;
}
