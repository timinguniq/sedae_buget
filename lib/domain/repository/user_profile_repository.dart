import 'package:sedae_budget/entity/entity.dart';

/// 사용자 프로필(나이대·월소득) 영속화. 구현은 서버(UserProfileRepositoryImpl).
abstract class UserProfileRepository {
  /// 아직 만들지 않았으면 `success(null)`.
  Future<Result<UserProfile?>> current();

  Future<Result<void>> save(UserProfile profile);
}
