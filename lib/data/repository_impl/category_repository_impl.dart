import 'package:sedae_budget/data/data_source/remote/category_api.dart';
import 'package:sedae_budget/data/dto/custom_category_dto.dart';
import 'package:sedae_budget/data/repository_impl/api_call.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버 단독 사용자 카테고리 저장소. id는 클라이언트 UUID로 PUT(upsert) — 거래와 같은 규칙.
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._api);

  final CategoryApi _api;

  @override
  Future<Result<List<CustomCategory>>> getAll() =>
      guardApi(() async => [for (final dto in await _api.list()) dto.toEntity()]);

  @override
  Future<Result<CustomCategory>> upsert(CustomCategory category) => guardApi(
        () async => (await _api.put(category.id, CustomCategoryBodyDto.fromEntity(category)))
            .toEntity(),
      );

  @override
  Future<Result<CustomCategory>> delete(CustomCategory category) => guardApi(() async {
        await _api.delete(category.id);
        return category;
      });
}
