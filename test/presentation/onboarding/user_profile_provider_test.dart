import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/auth_provider.dart';
import 'package:sedae_budget/presentation/page/onboarding/user_profile_provider.dart';

import '../../helper/fakes.dart';

const _user = AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자');
const _profile = UserProfile(ageGroup: AgeGroup.twenties, monthlyIncome: 2500000);

void main() {
  tearDown(() => locator.reset());

  test('logged in + nothing saved → null', () async {
    registerFakeUserDependencies(user: _user);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(userProfileProvider.future), isNull);
  });

  test('not logged in → null even if the server has a profile', () async {
    registerFakeUserDependencies(profile: _profile);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(userProfileProvider.future), isNull);
  });

  test('save() persists and updates state', () async {
    registerFakeUserDependencies(user: _user);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(userProfileProvider.future);
    await c.read(userProfileProvider.notifier).save(_profile);
    expect(c.read(userProfileProvider).value?.ageGroup, AgeGroup.twenties);
    // 새 컨테이너에서 다시 읽어도 유지(저장소는 get_it 싱글턴)
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    expect((await c2.read(userProfileProvider.future))?.monthlyIncome, 2500000);
  });

  test('signIn refetches the profile from the server; signOut clears it', () async {
    registerFakeUserDependencies(profile: _profile);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(userProfileProvider.future), isNull);

    await c.read(authProvider.notifier).signIn(AuthProvider.kakao);
    expect((await c.read(userProfileProvider.future))?.ageGroup, AgeGroup.twenties);

    await c.read(authProvider.notifier).signOut();
    expect(await c.read(userProfileProvider.future), isNull);
  });
}
