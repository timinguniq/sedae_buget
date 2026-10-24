part of 'custom_route.dart';

enum RoutePath {
  /// splash
  splash('/splash'),

  onboarding('/onboarding'),

  /// budget tabs
  budgetHome('/budget'),
  compare('/compare'),
  history('/history'),
  report('/report'),

  /// budget detail (pushed)
  transactionEdit('/budget/edit'),
  categoryAnalysis('/budget/category'),
  categoryManage('/budget/category/manage'),

  /// setting
  setting('/setting'),

  /// 프로필(나이대·월 소득) 수정 (설정의 프로필 카드에서 push)
  profileEdit('/setting/profile'),

  login('/login'),

  /// 이용약관 · 개인정보처리방침 (설정·로그인 화면에서 push)
  terms('/terms'),

  /// 세션을 확인하지 못함(서버에 닿지 못함) — 다시 시도
  unreachable('/unreachable'),

  ;

  const RoutePath(this.path);

  final String path;
}
