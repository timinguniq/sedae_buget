import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/presentation/presentation.dart';

void main() {
  testWidgets('bottom nav switches branch', (tester) async {
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => MainShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/a', builder: (_, _) => const Text('BRANCH_A'))]),
            StatefulShellBranch(routes: [GoRoute(path: '/b', builder: (_, _) => const Text('BRANCH_B'))]),
            StatefulShellBranch(routes: [GoRoute(path: '/c', builder: (_, _) => const Text('BRANCH_C'))]),
            StatefulShellBranch(routes: [GoRoute(path: '/d', builder: (_, _) => const Text('BRANCH_D'))]),
          ],
        ),
      ],
    );
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    expect(find.text('BRANCH_A'), findsOneWidget);
    await tester.tap(find.text('비교'));
    await tester.pump();
    await tester.pump();
    expect(find.text('BRANCH_B'), findsOneWidget);
  });
}
