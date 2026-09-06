import 'package:sedae_budget/entity/entity.dart';

/// 사용자 카테고리 저장소. 기본 분류([BudgetCategory])는 계약 상수라 여기서 다루지 않는다.
abstract class CategoryRepository {
  /// 생성 순서대로.
  Future<Result<List<CustomCategory>>> getAll();

  Future<Result<CustomCategory>> upsert(CustomCategory category);

  /// 삭제한 카테고리를 그대로 돌려준다.
  Future<Result<CustomCategory>> delete(CustomCategory category);
}
