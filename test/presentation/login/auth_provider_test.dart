import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/auth_provider.dart';

void main() {
  setUp(configureUserDependencies);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('signInMock saves user; signOut clears', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(authProvider.future), isNull);
    await c.read(authProvider.notifier).signInMock(AuthProvider.kakao);
    expect(c.read(authProvider).value?.provider, AuthProvider.kakao);
    expect(c.read(authProvider).value?.nickname, '카카오 사용자');
    await c.read(authProvider.notifier).signOut();
    expect(c.read(authProvider).value, isNull);
  });
}
