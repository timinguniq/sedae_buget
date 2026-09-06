import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

class _MemAuthRepo implements AuthRepository {
  AuthUser? _u;
  String? receivedIdToken;

  @override
  Future<AuthUser?> currentUser() async => _u;

  @override
  Future<AuthUser> signIn(AuthProvider provider, String idToken) async {
    receivedIdToken = idToken;
    return _u = AuthUser(provider: provider, nickname: '${provider.label} 사용자');
  }

  @override
  Future<void> signOut() async => _u = null;
}

class _FixedToken implements SocialIdTokenProvider {
  @override
  Future<String> idToken(AuthProvider provider) async => 't-${provider.name}';
}

void main() {
  test('signIn fetches id_token for the provider and exchanges it', () async {
    final repo = _MemAuthRepo();
    final u = await AuthUsecase(repo, _FixedToken()).signIn(AuthProvider.kakao);
    expect(repo.receivedIdToken, 't-kakao');
    expect(u.nickname, '카카오 사용자');
    expect(await repo.currentUser(), u);
  });

  test('signOut clears', () async {
    final repo = _MemAuthRepo();
    final uc = AuthUsecase(repo, _FixedToken());
    await uc.signIn(AuthProvider.google);
    await uc.signOut();
    expect(await repo.currentUser(), isNull);
  });
}
