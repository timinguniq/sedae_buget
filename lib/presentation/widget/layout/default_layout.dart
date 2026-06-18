import 'package:flutter/material.dart';
import 'package:sedae_budget/presentation/presentation.dart';

class DefaultLayout extends StatelessWidget {
  const DefaultLayout({
    super.key,
    this.appBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.isLoading,
    required this.child,
  });

  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final FloatingActionButton? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool? isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LoadingIndicator(
      isLoading: isLoading ?? false,
      child: Scaffold(
        appBar: appBar,
        backgroundColor: backgroundColor ?? context.color.background.normal,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        drawer: drawer,
        body: SafeArea(
          child: child,
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
