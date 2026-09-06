import 'package:sedae_budget/entity/entity.dart';

/// 사용자 프로필(나이대·월소득) 영속화. 구현은 서버(ApiUserProfileRepository).
abstract class UserProfileRepository {
  Future<UserProfile?> current();
  Future<void> save(UserProfile profile);
  Future<void> clear();
}
