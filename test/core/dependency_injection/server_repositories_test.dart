import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/core/dependency_injection/server_repositories.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../helper/stub_server.dart';

void main() {
  // 앱은 requestLog를 넘기지 않는다. 기본값이 release 여부를 따르는지는 release가 아닌 VM 테스트에서
  // 로그가 남는 것으로만 확인할 수 있다(release에서 끄는 쪽은 connectToServer 테스트가 본다).
  test('requestLog를 넘기지 않으면 release가 아닐 때 요청 로그를 남긴다', () async {
    final lines = <String>[];
    await runZoned(
      () async {
        final server = ServerRepositories.connect(
          env: AppEnvironment.local,
          tokenStore: MemoryAuthTokenStore(),
          localServer: StubApiInterceptor.new,
        );
        await server.auth.signIn(AuthProvider.kakao);
      },
      zoneSpecification: ZoneSpecification(print: (_, _, _, line) => lines.add(line)),
    );
    expect(lines.join('\n'), contains('/v1/auth/login'));
  });
}
