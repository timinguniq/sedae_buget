import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/compare/compare.view_model.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';

import '../../helper/fakes.dart';

void main() {
  // 세대별 평균도 로그인 뒤 요청이라 토큰이 필요하다(계약). 세션이 바뀌면 다시 읽어야 한다.
  group('세대별 평균', () {
    // 이전에는 세션이 끝나 401로 실패하면 다시 로그인해도 '다시 시도'를 누를 때까지 오류로 남았다.
    test('읽다가 세션이 만료돼도 다시 로그인하면 다시 읽는다', () async {
      final server = StubServer();
      await server.signIn(AuthProvider.kakao);
      final c = fakeContainer(server: server);
      expect(await c.read(authProvider.future), testUser);
      // 로그인한 채로 세대별 평균의 첫 요청을 보낸다. 서버는 저장된 토큰을 거부한다(401).
      server.tokens.token = 'expired';
      // 리포트 화면처럼 계속 본다. 아무도 보지 않으면 세션이 바뀌어도 다음에 볼 때까지 다시 만들지 않아
      // 아래 첫 읽기가 끝나지 않는다.
      final sub = c.listen(generationAvgProvider, (_, _) {});
      addTearDown(sub.close);

      await c.read(generationAvgProvider.future).then((_) {}, onError: (_) {});
      await Future<void>.delayed(Duration.zero);
      expect(c.read(authProvider).value, isNull);

      await c.read(authProvider.notifier).signIn(AuthProvider.kakao);

      expect((await c.read(generationAvgProvider.future)).keys, AgeGroup.values);
    });

    test('로그인 전에는 서버를 부르지 않고 비어 있다', () async {
      final server = StubServer();
      final c = fakeContainer(server: server);

      expect(await c.read(generationAvgProvider.future), isEmpty);
      expect(server.faults.count('GET', '/v1/peer/generations'), 0);
    });
  });
}
