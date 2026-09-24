import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helper/stub_server.dart';

/// 앱과 같은 순서로 local(Stub) 환경을 조립한다. 광고는 SDK가 필요해 빼고 조립한다.
MemoryAuthTokenStore _configure() {
  final tokens = MemoryAuthTokenStore();
  configureApiDependencies(tokens);
  configureBudgetDependencies();
  configurePeerDependencies();
  configureUserDependencies();
  return tokens;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => locator.reset());

  // 토큰 인터셉터가 Stub보다 앞에 있고 모든 저장소가 같은 클라이언트를 써야 로그인한 사용자로 호출된다.
  test('조립한 의존성으로 로그인 → 거래 저장 → 조회가 된다', () async {
    _configure();

    final user = (await locator<AuthUsecase>().signIn(AuthProvider.kakao)).unwrap();
    expect(user.provider, AuthProvider.kakao);

    final tx = Transaction.create(
        amount: 1000, categoryId: 1, date: DateTime(2026, 9, 3), type: TransactionType.expense);
    (await locator<TransactionUsecase>().save(tx)).unwrap();
    expect((await locator<TransactionUsecase>().getMonth(2026, 9)).unwrap().single.id, tx.id);
    expect((await locator<PeerStatsRepository>().forGroup(AgeGroup.thirties)).unwrap().ageGroup,
        AgeGroup.thirties);
  });

  test('서버가 토큰을 거부하면 AuthUsecase.sessionExpired로 알린다', () async {
    final tokens = _configure();
    final auth = locator<AuthUsecase>();
    await auth.signIn(AuthProvider.kakao);

    final expired = expectLater(auth.sessionExpired, emits(null));
    tokens.token = 'garbage';
    await auth.currentUser();
    await expired;
    expect(tokens.token, isNull);
  });
}
