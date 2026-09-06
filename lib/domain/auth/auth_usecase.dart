import 'package:sedae_budget/domain/auth/auth_repository.dart';
import 'package:sedae_budget/entity/entity.dart';

class AuthUsecase {
  AuthUsecase(this._repo);

  final AuthRepository _repo;

  Future<AuthUser?> currentUser() => _repo.currentUser();

  /// 백엔드 없음 → 목업 로그인. Phase 2에서 소셜 OIDC id_token 교환으로 교체.
  Future<AuthUser> signInMock(AuthProvider provider) async {
    final user = AuthUser(provider: provider, nickname: '${provider.label} 사용자');
    await _repo.saveUser(user);
    return user;
  }

  Future<void> signOut() => _repo.clearUser();
}
