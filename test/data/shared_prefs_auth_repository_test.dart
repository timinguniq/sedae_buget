import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('save → current → clear round-trip', () async {
    final AuthRepository repo = SharedPrefsAuthRepository();
    expect(await repo.currentUser(), isNull);
    await repo.saveUser(
        const AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자'));
    expect((await repo.currentUser())?.nickname, '카카오 사용자');
    await repo.clearUser();
    expect(await repo.currentUser(), isNull);
  });

  test('reads legacy key auth_user written before refactor', () async {
    SharedPreferences.setMockInitialValues(
        {'auth_user': '{"provider":"kakao","nickname":"카카오 사용자"}'});
    expect((await SharedPrefsAuthRepository().currentUser())?.provider,
        AuthProvider.kakao);
  });
}
