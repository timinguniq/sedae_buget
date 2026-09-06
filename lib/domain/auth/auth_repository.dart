import 'package:sedae_budget/entity/entity.dart';

/// 서버 세션 기반 인증. 토큰 보관은 구현체 소관.
abstract class AuthRepository {
  /// 토큰이 없으면 null. 토큰이 무효(401)면 폐기 후 null. 그 외 오류는 예외.
  Future<AuthUser?> currentUser();

  /// 소셜 id_token을 서버 세션으로 교환하고 사용자를 돌려준다.
  Future<AuthUser> signIn(AuthProvider provider, String idToken);

  Future<void> signOut();
}
