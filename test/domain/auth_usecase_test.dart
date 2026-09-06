import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

class _MemAuthRepo implements AuthRepository {
  AuthUser? _u;

  @override
  Future<AuthUser?> currentUser() async => _u;

  @override
  Future<void> saveUser(AuthUser user) async => _u = user;

  @override
  Future<void> clearUser() async => _u = null;
}

void main() {
  test('signInMock builds "<provider> 사용자" and persists', () async {
    final repo = _MemAuthRepo();
    final u = await AuthUsecase(repo).signInMock(AuthProvider.kakao);
    expect(u.nickname, '카카오 사용자');
    expect(await repo.currentUser(), u);
  });

  test('signOut clears', () async {
    final repo = _MemAuthRepo();
    final uc = AuthUsecase(repo);
    await uc.signInMock(AuthProvider.google);
    await uc.signOut();
    expect(await repo.currentUser(), isNull);
  });
}
