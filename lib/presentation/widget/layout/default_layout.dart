import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

class DefaultLayout extends StatelessWidget {
  const DefaultLayout({
    super.key,
    this.backgroundColor,
    this.bottomNavigationBar,
    required this.child,
  });

  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? context.color.background.normal,
      body: SafeArea(
        child: child,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
