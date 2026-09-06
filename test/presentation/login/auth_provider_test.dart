import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/auth_provider.dart';

import '../../helper/fakes.dart';

void main() {
  setUp(() => registerFakeUserDependencies());
  tearDown(() => locator.reset());

  test('signIn saves user; signOut clears', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(authProvider.future), isNull);
    await c.read(authProvider.notifier).signIn(AuthProvider.kakao);
    expect(c.read(authProvider).value?.provider, AuthProvider.kakao);
    expect(c.read(authProvider).value?.nickname, '카카오 사용자');
    await c.read(authProvider.notifier).signOut();
    expect(c.read(authProvider).value, isNull);
  });
}
