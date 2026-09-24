import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/route/custom_route.dart';

void main() {
  const user = AsyncData<AuthUser?>(AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자'));
  const noUser = AsyncData<AuthUser?>(null);
  const profile = AsyncData<UserProfile?>(
      UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000));
  const noProfile = AsyncData<UserProfile?>(null);
  final offline = AsyncError<Never>(
      const ResultFailure(ErrorResult(reason: FailureReason.offline, message: '')), StackTrace.empty);

  group('SessionGate.of', () {
    test('인증을 확인하는 중이면 확인 중', () {
      expect(SessionGate.of(const AsyncLoading(), const AsyncLoading()), SessionGate.checking);
    });
    test('인증 확인에 실패하면 로그아웃이 아니라 연결 안 됨', () {
      expect(SessionGate.of(offline, noProfile), SessionGate.unreachable);
    });
    test('사용자가 없으면 로그아웃', () {
      expect(SessionGate.of(noUser, noProfile), SessionGate.signedOut);
    });
    test('프로필을 확인하는 중이면 확인 중', () {
      expect(SessionGate.of(user, const AsyncLoading()), SessionGate.checking);
    });
    test('프로필 조회에 실패하면 프로필 없음이 아니라 연결 안 됨', () {
      expect(SessionGate.of(user, offline), SessionGate.unreachable);
    });
    test('프로필이 없으면 프로필 필요', () {
      expect(SessionGate.of(user, noProfile), SessionGate.needsProfile);
    });
    test('사용자와 프로필이 있으면 준비됨', () {
      expect(SessionGate.of(user, profile), SessionGate.ready);
    });
  });

  group('sessionRedirect', () {
    String? go(SessionGate gate, String location) => sessionRedirect(gate, location);

    test('스플래시는 가드 면제', () {
      for (final gate in SessionGate.values) {
        expect(go(gate, '/splash'), isNull, reason: gate.name);
      }
    });
    test('확인 중에는 이동시키지 않는다', () {
      expect(go(SessionGate.checking, '/budget'), isNull);
      expect(go(SessionGate.checking, '/unreachable'), isNull);
    });
    test('연결 안 됨 → /unreachable (이미 있으면 유지)', () {
      expect(go(SessionGate.unreachable, '/budget'), '/unreachable');
      expect(go(SessionGate.unreachable, '/login'), '/unreachable');
      expect(go(SessionGate.unreachable, '/unreachable'), isNull);
    });
    test('로그아웃 → /login (이미 있으면 유지)', () {
      expect(go(SessionGate.signedOut, '/budget'), '/login');
      expect(go(SessionGate.signedOut, '/unreachable'), '/login');
      expect(go(SessionGate.signedOut, '/login'), isNull);
    });
    test('프로필 필요 → /onboarding (이미 있으면 유지)', () {
      expect(go(SessionGate.needsProfile, '/budget'), '/onboarding');
      expect(go(SessionGate.needsProfile, '/onboarding'), isNull);
    });
    test('준비됨 + 게이트 화면 → 홈', () {
      for (final gate in ['/login', '/onboarding', '/unreachable']) {
        expect(go(SessionGate.ready, gate), '/budget', reason: gate);
      }
    });
    test('준비됨 + 일반 화면 → 유지', () {
      expect(go(SessionGate.ready, '/budget'), isNull);
      expect(go(SessionGate.ready, '/setting'), isNull);
    });
  });
}
