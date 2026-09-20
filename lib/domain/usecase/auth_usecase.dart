import 'package:sedae_budget/domain/repository/auth_repository.dart';
import 'package:sedae_budget/domain/repository/social_id_token_provider.dart';
import 'package:sedae_budget/entity/entity.dart';

class AuthUsecase {
  AuthUsecase(this._repo, this._social);

  final AuthRepository _repo;
  final SocialIdTokenProvider _social;

  Future<Result<AuthUser?>> currentUser() => _repo.currentUser();

  /// 소셜 id_token을 받아 서버 세션으로 교환한다.
  /// 소셜 쪽에서 토큰을 못 받으면 서버를 부르지 않고 그 실패를 그대로 돌려준다.
  Future<Result<AuthUser>> signIn(AuthProvider provider) async {
    final token = await _social.idToken(provider);
    if (token is! Success<String>) return Result.failure(token.failureOrNull!);
    return _repo.signIn(provider, token.data);
  }

  Future<Result<void>> signOut() => _repo.signOut();
}
