import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:sedae_budget/data/data_source/remote/api_path.dart';
import 'package:sedae_budget/data/dto/custom_category_dto.dart';

part 'category_api.g.dart';

/// 사용자 카테고리 엔드포인트(`/v1/categories`) 명세. 기본 분류(1~12)는 다루지 않는다.
@RestApi()
abstract class CategoryApi {
  factory CategoryApi(Dio dio) = _CategoryApi;

  /// 생성 순서.
  @GET(ApiPath.categories)
  Future<List<CustomCategoryDto>> list();

  /// id는 클라이언트 UUID(upsert) — 거래와 같은 규칙.
  @PUT('${ApiPath.categories}/{id}')
  Future<CustomCategoryDto> put(@Path('id') String id, @Body() CustomCategoryBodyDto body);

  @DELETE('${ApiPath.categories}/{id}')
  Future<void> delete(@Path('id') String id);
}
