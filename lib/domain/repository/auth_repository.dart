import 'package:sedae_budget/entity/entity.dart';

/// 서버 세션 기반 인증. 토큰 보관은 구현체 소관.
abstract class AuthRepository {
  /// 로그인되어 있지 않으면 `success(null)`. 세션이 무효면 폐기하고 `success(null)`.
  /// 그 밖의 실패는 [Result.failure].
  Future<Result<AuthUser?>> currentUser();

  /// 소셜 id_token을 서버 세션으로 교환하고 사용자를 돌려준다.
  Future<Result<AuthUser>> signIn(AuthProvider provider, String idToken);

  /// 서버 세션과 로컬 토큰을 모두 끝낸다.
  /// 서버가 응답하지 않아도 로컬 세션은 끝나지만, 그 사실을 [Result.failure]로 알린다.
  Future<Result<void>> signOut();
}
