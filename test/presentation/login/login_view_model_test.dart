import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';

import '../../helper/fakes.dart';

void main() {
  test('signIn saves user; signOut clears', () async {
    final c = fakeContainer();
    expect(await c.read(authProvider.future), isNull);
    await c.read(authProvider.notifier).signIn(AuthProvider.kakao);
    expect(c.read(authProvider).value?.provider, AuthProvider.kakao);
    expect(c.read(authProvider).value?.nickname, '카카오 사용자');
    await c.read(authProvider.notifier).signOut();
    expect(c.read(authProvider).value, isNull);
  });
}
