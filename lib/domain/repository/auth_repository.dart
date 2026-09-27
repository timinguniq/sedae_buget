import 'package:sedae_budget/entity/entity.dart';

/// 서버 세션 인증. 토큰 보관은 구현체 소관.
abstract class AuthRepository {
  /// 로그인되어 있지 않으면 `success(null)`. 서버가 저장된 세션을 거부했거나(이때 [sessionExpired]로도 알린다)
  /// 기기에서 세션을 읽지 못해도 세션을 버리고 `success(null)`이다. 그 밖의 실패(서버에 닿지 못함 등)는 [Result.failure].
  Future<Result<AuthUser?>> currentUser();

  /// [provider]의 소셜 id_token을 받아 서버 세션으로 교환하고 사용자를 돌려준다.
  /// 소셜 쪽에서 토큰을 못 받으면 서버를 부르지 않고 그 실패를 그대로 돌려준다.
  Future<Result<AuthUser>> signIn(AuthProvider provider);

  /// 이 기기의 세션을 끝낸다. 서버에도 알리지만 서버가 응답하지 않아도 성공이다(서버 세션은 만료로 끝난다).
  /// 기기에서 토큰을 지우지 못하면 [Result.failure]이고 로그인 상태는 그대로다.
  Future<Result<void>> signOut();

  /// 세션이 끝났다: 서버가 저장된 토큰을 거부했다(토큰 만료·폐기). 앱을 켤 때 세션을 확인하다가도, 쓰는 중에도
  /// 알린다. 쓰는 중에 기기에서 세션을 읽지 못해도 같다. 알릴 때는 로컬 토큰 지우기를 이미 시도했다.
  Stream<void> get sessionExpired;
}
