import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:sedae_budget/entity/budget/budget_category.dart';
import 'package:sedae_budget/entity/budget/transaction.dart';

part 'custom_category.freezed.dart';
part 'custom_category.g.dart';

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

  /// 새 카테고리. id는 클라이언트 UUID(거래와 같은 규칙).
  factory CustomCategory.create({
    required String name,
    required int baseCategoryId,
  }) =>
      CustomCategory(id: const Uuid().v4(), name: name, baseCategoryId: baseCategoryId);

  factory CustomCategory.fromJson(Map<String, dynamic> json) =>
      _$CustomCategoryFromJson(json);

  /// 이름 최대 길이. 클라이언트 입력 제한과 서버 검증이 같은 값을 쓴다.
  static const maxNameLength = 10;

  BudgetCategory get base => BudgetCategory.fromId(baseCategoryId);
}

extension CustomCategoryListX on List<CustomCategory> {
  /// id로 찾기. [id]가 null이거나 없는 id면 null.
  CustomCategory? byId(String? id) {
    if (id == null) return null;
    for (final c in this) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// 거래에 표시할 카테고리 이름. 커스텀 카테고리가 지정돼 있으면 그 이름, 아니면 기본 분류 이름.
  String labelFor(Transaction tx) =>
      byId(tx.customCategoryId)?.name ?? BudgetCategory.fromId(tx.categoryId).label;
}
