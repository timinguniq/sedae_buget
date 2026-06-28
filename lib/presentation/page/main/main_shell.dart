import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/presentation/presentation.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      bottomNavigationBar: BudgetBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        onFabTap: () => context.push(RoutePath.transactionEdit.path),
      ),
      child: navigationShell,
    );
  }
}
