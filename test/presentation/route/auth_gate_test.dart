import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/route/custom_route.dart';

void main() {
  const noUser = AsyncData<AuthUser?>(null);
  const noProfile = AsyncData<UserProfile?>(null);
  final user = AsyncData<AuthUser?>(
      const AuthUser(provider: AuthProvider.kakao, nickname: '카카오 사용자'));
  final profile = AsyncData<UserProfile?>(
      const UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000));

  String? gate(
          AsyncValue<AuthUser?> a, AsyncValue<UserProfile?> p, String loc) =>
      authGateRedirect(auth: a, profile: p, location: loc);

  test('스플래시는 가드 면제', () {
    expect(gate(const AsyncLoading(), const AsyncLoading(), '/splash'), isNull);
  });
  test('로딩 중(비스플래시)에는 리다이렉트 안 함', () {
    expect(gate(const AsyncLoading(), const AsyncLoading(), '/budget'), isNull);
  });
  test('미로그인 → /login', () {
    expect(gate(noUser, noProfile, '/budget'), '/login');
  });
  test('미로그인 + 이미 /login → 유지', () {
    expect(gate(noUser, noProfile, '/login'), isNull);
  });
  test('로그인 + 프로필 없음 → /onboarding', () {
    expect(gate(user, noProfile, '/budget'), '/onboarding');
  });
  test('로그인 + 프로필 없음 + 이미 /onboarding → 유지', () {
    expect(gate(user, noProfile, '/onboarding'), isNull);
  });
  test('로그인 + 프로필 + /login → /budget', () {
    expect(gate(user, profile, '/login'), '/budget');
  });
  test('로그인 + 프로필 + /onboarding → /budget', () {
    expect(gate(user, profile, '/onboarding'), '/budget');
  });
  test('로그인 + 프로필 + 일반 화면 → 유지', () {
    expect(gate(user, profile, '/budget'), isNull);
  });
}
