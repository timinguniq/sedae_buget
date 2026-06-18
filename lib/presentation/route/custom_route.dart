import 'package:sedae_budget/presentation/presentation.dart';
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
    /// splash
    GoRoute(
      path: RoutePath.splash.path,
      builder: (_, _) => const SplashPage(),
    ),

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
