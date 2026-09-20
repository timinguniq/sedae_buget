import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';

import '../../helper/fakes.dart';

const _user = AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자');
const _profile = UserProfile(ageGroup: AgeGroup.twenties, monthlyIncome: 2500000);

void main() {
  test('logged in + nothing saved → null', () async {
    final c = fakeContainer(user: _user);
    expect(await c.read(userProfileProvider.future), isNull);
  });

  test('not logged in → null even if the server has a profile', () async {
    final c = fakeContainer(profile: _profile);
    expect(await c.read(userProfileProvider.future), isNull);
  });

  test('save() persists and updates state', () async {
    final repo = InMemoryUserProfileRepository();
    final c = fakeContainer(user: _user, profileRepository: repo);
    await c.read(userProfileProvider.future);
    await c.read(userProfileProvider.notifier).save(_profile);
    expect(c.read(userProfileProvider).value?.ageGroup, AgeGroup.twenties);
    // 같은 저장소를 쓰는 새 컨테이너에서 다시 읽어도 유지된다.
    final c2 = fakeContainer(user: _user, profileRepository: repo);
    expect((await c2.read(userProfileProvider.future))?.monthlyIncome, 2500000);
  });

  test('signIn refetches the profile from the server; signOut clears it', () async {
    final c = fakeContainer(profile: _profile);
    expect(await c.read(userProfileProvider.future), isNull);

    await c.read(authProvider.notifier).signIn(AuthProvider.kakao);
    expect((await c.read(userProfileProvider.future))?.ageGroup, AgeGroup.twenties);

    await c.read(authProvider.notifier).signOut();
    expect(await c.read(userProfileProvider.future), isNull);
  });
}
