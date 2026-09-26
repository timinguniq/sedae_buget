import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';

import '../../helper/fakes.dart';

const _profile = UserProfile(ageGroup: AgeGroup.twenties, monthlyIncome: 2500000);

/// kakao 사용자가 프로필을 저장해 둔 뒤 로그아웃한 서버.
Future<StubServer> _savedThenSignedOut() async {
  final server = StubServer();
  await server.seed(profile: _profile);
  (await server.auth.signOut()).unwrap();
  return server;
}

void main() {
  test('logged in + nothing saved → null', () async {
    final server = StubServer();
    await server.signIn(AuthProvider.kakao);
    expect(await fakeContainer(server: server).read(userProfileProvider.future), isNull);
  });

  test('not logged in → null even if the server has a profile', () async {
    final c = fakeContainer(server: await _savedThenSignedOut());
    expect(await c.read(userProfileProvider.future), isNull);
  });

  test('save() persists and updates state', () async {
    final server = StubServer();
    await server.signIn(AuthProvider.kakao);
    final c = fakeContainer(server: server);
    await c.read(userProfileProvider.future);
    await c.read(userProfileProvider.notifier).save(_profile);
    expect(c.read(userProfileProvider).value?.ageGroup, AgeGroup.twenties);
    // 같은 서버를 보는 새 컨테이너(앱 재시작)에서 다시 읽어도 유지된다.
    final c2 = fakeContainer(server: server);
    expect((await c2.read(userProfileProvider.future))?.monthlyIncome, 2500000);
  });

  test('signIn refetches the profile from the server; signOut clears it', () async {
    final c = fakeContainer(server: await _savedThenSignedOut());
    expect(await c.read(userProfileProvider.future), isNull);

    await c.read(authProvider.notifier).signIn(AuthProvider.kakao);
    expect((await c.read(userProfileProvider.future))?.ageGroup, AgeGroup.twenties);

    await c.read(authProvider.notifier).signOut();
    expect(await c.read(userProfileProvider.future), isNull);
  });
}
