import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/usecase/category_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 사용자가 만든 카테고리 목록(서버). 기본 분류([BudgetCategory])는 계약 상수라 여기 없다.
///
/// 변경 메서드는 서버 결과를 그대로 돌려준다. 이름 중복·길이처럼 사용자가 바로 고칠 수 있는
/// 오류라 화면에서 문구를 보여주고, 성공하면 만들어진 카테고리를 호출부가 이어서 쓴다.
class CustomCategoriesNotifier extends AsyncNotifier<List<CustomCategory>> {
  CategoryUsecase get _usecase => locator<CategoryUsecase>();

  @override
  Future<List<CustomCategory>> build() async => (await _usecase.getAll()).unwrap();

  Future<Result<CustomCategory>> add({
    required String name,
    required BudgetCategory base,
  }) =>
      _apply(() => _usecase.add(name: name, base: base));

  Future<Result<CustomCategory>> edit(
    CustomCategory category, {
    required String name,
    required BudgetCategory base,
  }) =>
      _apply(() => _usecase.update(category, name: name, base: base));

  Future<Result<CustomCategory>> remove(CustomCategory category) =>
      _apply(() => _usecase.delete(category));

  Future<Result<CustomCategory>> _apply(
      Future<Result<CustomCategory>> Function() run) async {
    final res = await run();
    if (res.failureOrNull == null) ref.invalidateSelf();
    return res;
  }
}

/// 실패면 사용자에게 보여줄 문구, 성공이면 null.
String? categoryErrorMessage(Result<CustomCategory> res) {
  final error = res.failureOrNull;
  if (error == null) return null;
  return error.message.isEmpty ? '저장하지 못했어요' : error.message;
}

final customCategoriesProvider =
    AsyncNotifierProvider<CustomCategoriesNotifier, List<CustomCategory>>(
        CustomCategoriesNotifier.new);
