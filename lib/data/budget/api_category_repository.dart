import 'package:sedae_budget/core/http_client/api_client.dart';
import 'package:sedae_budget/data/budget/custom_category_json.dart';
import 'package:sedae_budget/data/remote/api_path.dart';
import 'package:sedae_budget/data/remote/api_result.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 서버 단독 사용자 카테고리 저장소. id는 클라이언트 UUID로 PUT(upsert) — 거래와 같은 규칙.
class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(this._api);

  final ApiClient _api;

  @override
  Future<Result<List<CustomCategory>>> getAll() => guardApi(() async {
        final list = await _api.get<List<dynamic>>(ApiPath.categories);
        return list.cast<Map<String, dynamic>>().map(customCategoryFromJson).toList();
      });

  @override
  Future<Result<CustomCategory>> upsert(CustomCategory category) => guardApi(
        () async => customCategoryFromJson(
          await _api.put<Map<String, dynamic>>(
            ApiPath.category(category.id),
            body: customCategoryToBody(category),
          ),
        ),
      );

  @override
  Future<Result<CustomCategory>> delete(CustomCategory category) => guardApi(() async {
        await _api.delete(ApiPath.category(category.id));
        return category;
      });
}
