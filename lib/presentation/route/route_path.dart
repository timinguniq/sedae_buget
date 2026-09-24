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

  login('/login'),

  /// 세션을 확인하지 못함(서버에 닿지 못함) — 다시 시도
  unreachable('/unreachable'),

  ;

  const RoutePath(this.path);

  final String path;
}
