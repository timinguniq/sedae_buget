import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/budget_home.page.dart';
import 'package:sedae_budget/presentation/page/budget/transaction_list.page.dart';
import 'package:sedae_budget/presentation/page/budget/category_analysis.page.dart';
import 'package:sedae_budget/presentation/page/budget/transaction_edit.page.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'route_path.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

abstract class CRoute {
  CRoute._();

  //static void redirectToMain() => (rootNavigatorKey.currentContext!).go(RoutePath.main.path);

  static bool canPop() => (rootNavigatorKey.currentContext!).canPop();

  static void pop<T>([T? result]) => canPop() ? (rootNavigatorKey.currentContext!).pop<T?>(result) : null;
}

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePath.splash.path,
  routes: [
    GoRoute(path: RoutePath.splash.path, builder: (_, _) => const SplashPage()),
    GoRoute(path: RoutePath.onboarding.path, builder: (_, _) => const OnboardingFlowPage()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: RoutePath.budgetHome.path, builder: (_, _) => const BudgetHomePage())]),
        StatefulShellBranch(routes: [GoRoute(path: RoutePath.compare.path, builder: (_, _) => const ComingSoonPlaceholder(title: '세대 비교'))]),
        StatefulShellBranch(routes: [GoRoute(path: RoutePath.history.path, builder: (_, _) => const TransactionListPage())]),
        StatefulShellBranch(routes: [GoRoute(path: RoutePath.report.path, builder: (_, _) => const ComingSoonPlaceholder(title: '리포트'))]),
      ],
    ),
    GoRoute(path: RoutePath.transactionEdit.path, builder: (_, state) =>
        TransactionEditPage(existing: state.extra as Transaction?)),
    GoRoute(path: RoutePath.categoryAnalysis.path, builder: (_, _) => const CategoryAnalysisPage()),
    GoRoute(path: RoutePath.setting.path, builder: (_, _) => const SettingPage()),
  ],
  debugLogDiagnostics: true,
  observers: [
    //FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    //AmplitudeNavigatorObserver(),
  ],
);

/*
CustomTransitionPage<dynamic> mainPageBuilder(_, GoRouterState state, Widget child) {
  final currentIndex = mainTab.indexWhere((e) => e.routePath.path == state.matchedLocation);
  final isNextTab = prevHomeTabIndex == -1 || prevHomeTabIndex < currentIndex;

  final tab = mainTab[currentIndex];
  return CustomTransitionPage(
    key: tab.key,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, __, child) => MainPage(
      child: SlideTransition(
        position: animation.drive(
          Tween(begin: Offset(isNextTab ? 1 : -1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.ease)),
        ),
        child: child,
      ),
    ),
    child: tab.screen,
  );
}
*/
class _NotUsed extends StatelessWidget {
  const _NotUsed();

  @override
  Widget build(BuildContext context) {
    return const Text('Not Used');
  }
}
