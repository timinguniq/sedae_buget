import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sedae_budget/entity/budget/budget_category.dart';

part 'custom_category.freezed.dart';

/// 사용자가 직접 만든 카테고리. 기본 분류([BudgetCategory])는 또래 비교의 전제라
/// 수정·삭제할 수 없고, 이 엔티티만 추가·수정·삭제할 수 있다.
@freezed
abstract class CustomCategory with _$CustomCategory {
  const factory CustomCategory({
    required String id,
    required String name,

    /// 상위 기본 분류. 또래 비교 집계는 이 값으로만 이뤄진다.
    required int baseCategoryId,
  }) = _CustomCategory;

  const CustomCategory._();

  BudgetCategory get base => BudgetCategory.fromId(baseCategoryId);
}
