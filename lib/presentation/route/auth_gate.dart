part of 'custom_route.dart';

/// 앱이 어디로 가야 하는지 정하는 세션 상태. 인증·프로필 provider 값으로만 정해진다.
enum SessionGate {
  /// 인증·프로필을 확인하는 중.
  checking,

  /// 확인하지 못했다(서버에 닿지 못함 등). 로그아웃·프로필 없음으로 보지 않는다.
  unreachable,

  signedOut,
  needsProfile,
  ready;

  static SessionGate of(AsyncValue<AuthUser?> auth, AsyncValue<UserProfile?> profile) {
    if (auth.isLoading) return checking;
    if (auth.hasError) return unreachable;
    if (auth.value == null) return signedOut;
    if (profile.isLoading) return checking;
    if (profile.hasError) return unreachable;
    return profile.value == null ? needsProfile : ready;
  }
}

final sessionGateProvider = Provider<SessionGate>(
  (ref) => SessionGate.of(ref.watch(authProvider), ref.watch(userProfileProvider)),
);

/// 세션이 준비되기 전에만 머무는 화면들.
final _gatePaths = {RoutePath.login.path, RoutePath.onboarding.path, RoutePath.unreachable.path};

/// 전역 가드의 순수 결정 함수. [gate]가 요구하는 화면으로 보낸다.
/// 반환이 null이면 현재 위치 유지, 아니면 해당 경로로 리다이렉트.
String? sessionRedirect(SessionGate gate, String location) {
  // 스플래시는 가드 면제(브랜딩과 세션 확인이 끝나면 스스로 떠나고, 그때 재평가).
  if (location == RoutePath.splash.path) return null;
  final required = switch (gate) {
    SessionGate.checking || SessionGate.ready => null,
    SessionGate.unreachable => RoutePath.unreachable.path,
    SessionGate.signedOut => RoutePath.login.path,
    SessionGate.needsProfile => RoutePath.onboarding.path,
  };
  if (required != null) return location == required ? null : required;
  if (gate == SessionGate.ready && _gatePaths.contains(location)) return RoutePath.budgetHome.path;
  return null;
}
