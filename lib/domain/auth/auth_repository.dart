import 'package:sedae_budget/entity/entity.dart';

/// 로그인 사용자 영속화. 현재 구현은 로컬 저장소.
/// Phase 2에서 서버 세션과 결합할 때 구현체만 교체한다.
abstract class AuthRepository {
  Future<AuthUser?> currentUser();
  Future<void> saveUser(AuthUser user);
  Future<void> clearUser();
}
