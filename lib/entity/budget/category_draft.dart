import 'package:sedae_budget/entity/budget/budget_category.dart';
import 'package:sedae_budget/entity/budget/category_name.dart';
import 'package:sedae_budget/entity/budget/custom_category.dart';
import 'package:uuid/uuid.dart';

/// 입력 중인 사용자 카테고리. 카테고리 추가·수정 시트의 규칙(이름 다듬기·저장 가능 여부·상위 분류)을 가진다.
///
/// 초안 하나는 사용자 카테고리 하나다. 저장을 몇 번 시도해도(두 번 누름·시간 초과 뒤 재시도) 같은 [id]로
/// 보내므로, 클라이언트 id로 멱등인 서버에는 카테고리가 하나만 생긴다.
class CategoryDraft {
  const CategoryDraft._({required this.id, required this.name, required this.base, required this.isEdit});

  /// 새 카테고리. 이름 없이 기타 아래에서 시작하고, 저장할 카테고리의 id를 여기서 한 번 정한다.
  CategoryDraft.create() : this._(id: const Uuid().v4(), name: '', base: BudgetCategory.etc, isEdit: false);

  /// [category]를 고친다.
  CategoryDraft.edit(CustomCategory category)
      : this._(id: category.id, name: category.name, base: category.base, isEdit: true);

  /// 저장할 카테고리의 id.
  final String id;

  /// 입력한 그대로의 이름. 저장할 때 다듬는다.
  final String name;

  /// 상위 기본 분류. 또래 비교는 이 분류로 집계된다.
  final BudgetCategory base;

  final bool isEdit;

  /// 다듬은 이름이 비었거나 너무 길면 저장하지 않는다(규칙은 [CategoryName]).
  bool get canSave => CategoryName.tryParse(name) != null;

  CategoryDraft withName(String name) => CategoryDraft._(id: id, name: name, base: base, isEdit: isEdit);

  CategoryDraft pickBase(BudgetCategory base) => CategoryDraft._(id: id, name: name, base: base, isEdit: isEdit);

  /// 저장할 카테고리(이름은 앞뒤 공백을 뗀다).
  CustomCategory toCategory() => CustomCategory(id: id, name: name.trim(), baseCategoryId: base.id);
}
