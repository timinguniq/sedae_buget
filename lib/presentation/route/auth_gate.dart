part of 'custom_route.dart';

/// 인증/온보딩 전역 가드의 순수 결정 함수.
/// 반환이 null이면 현재 위치 유지, 아니면 해당 경로로 리다이렉트.
String? authGateRedirect({
  required AsyncValue<AuthUser?> auth,
  required AsyncValue<UserProfile?> profile,
  required String location,
}) {
  // 스플래시는 가드 면제(2초 브랜딩 후 스스로 이동 → 그때 재평가).
  if (location == RoutePath.splash.path) return null;
  // 인증/프로필 로딩 중에는 이동시키지 않음.
  if (auth.isLoading || profile.isLoading) return null;

  final authed = auth.value != null;
  final hasProfile = profile.value != null;

  // 1) 미로그인 → 로그인 강제.
  if (!authed) {
    return location == RoutePath.login.path ? null : RoutePath.login.path;
  }
  // 2) 로그인했지만 프로필 없음 → 온보딩 강제.
  if (!hasProfile) {
    return location == RoutePath.onboarding.path
        ? null
        : RoutePath.onboarding.path;
  }
  // 3) 로그인 + 프로필 완료 → 게이트 화면에 있으면 홈으로.
  if (location == RoutePath.login.path ||
      location == RoutePath.onboarding.path) {
    return RoutePath.budgetHome.path;
  }
  return null;
}
