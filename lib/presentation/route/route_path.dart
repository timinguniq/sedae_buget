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

  ;

  const RoutePath(this.path);

  final String path;
}
