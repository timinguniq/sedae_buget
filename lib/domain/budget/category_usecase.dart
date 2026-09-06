import 'package:sedae_budget/domain/budget/category_repository.dart';
import 'package:sedae_budget/entity/entity.dart';

class CategoryUsecase {
  CategoryUsecase(this._repo);

  final CategoryRepository _repo;

  Future<Result<List<CustomCategory>>> getAll() => _repo.getAll();

  Future<Result<CustomCategory>> add({
    required String name,
    required BudgetCategory base,
  }) =>
      _repo.upsert(CustomCategory.create(name: name.trim(), baseCategoryId: base.id));

  Future<Result<CustomCategory>> update(
    CustomCategory category, {
    required String name,
    required BudgetCategory base,
  }) =>
      _repo.upsert(category.copyWith(name: name.trim(), baseCategoryId: base.id));

  Future<Result<CustomCategory>> delete(CustomCategory category) => _repo.delete(category);
}
