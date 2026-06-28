import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with SingleTickerProviderStateMixin {
  static const _animationTime = 2000;

  late AnimationController controller;
  late Animation<double> fadeIn;
  late Animation<Offset> moveUp;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(duration: const Duration(milliseconds: _animationTime), vsync: this);
    fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0, 500 / _animationTime)),
    );

    moveUp = Tween<Offset>(begin: const Offset(0, 3), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0, 700 / _animationTime, curve: Curves.easeInOutSine)),
    );

    controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(appInitialize()));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      backgroundColor: context.color.primary.normal,
      child: Center(
        child: FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(
            position: moveUp,
            child: const MascotDongle(size: 88, faceColor: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> appInitialize() async {
    await Future.delayed(const Duration(milliseconds: _animationTime));
    if (mounted) context.go(RoutePath.budgetHome.path);
  }
}
