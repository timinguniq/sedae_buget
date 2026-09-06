import 'package:sedae_budget/entity/entity.dart';

/// 사용자 프로필(나이대·월소득) 영속화. 현재 구현은 로컬 저장소.
abstract class UserProfileRepository {
  Future<UserProfile?> current();
  Future<void> save(UserProfile profile);
  Future<void> clear();
}
