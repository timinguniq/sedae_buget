import 'package:sedae_budget/domain/auth/auth_repository.dart';
import 'package:sedae_budget/domain/auth/social_id_token_provider.dart';
import 'package:sedae_budget/entity/entity.dart';

class AuthUsecase {
  AuthUsecase(this._repo, this._social);

  final AuthRepository _repo;
  final SocialIdTokenProvider _social;

  Future<AuthUser?> currentUser() => _repo.currentUser();

  /// 소셜 id_token을 받아 서버 세션으로 교환한다.
  Future<AuthUser> signIn(AuthProvider provider) async =>
      _repo.signIn(provider, await _social.idToken(provider));

  Future<void> signOut() => _repo.signOut();
}
