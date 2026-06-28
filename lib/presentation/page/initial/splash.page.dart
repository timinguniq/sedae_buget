import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/presentation/page/onboarding/user_profile_provider.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  static const _animationTime = 2000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(appInitialize()));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      backgroundColor: context.color.background.normal,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LottieAsset(CLotties.splashIcon, width: 134, height: 134, repeat: false),
                const SizedBox(height: 28),
                Text('세대 가계부', style: context.typo.title3.copyWith(
                  fontWeight: context.typo.extraBold,
                  letterSpacing: -0.6,
                  color: context.color.label.normal,
                )),
                const SizedBox(height: 7),
                Text('내 또래는 얼마나 쓸까?', style: context.typo.caption1W600.copyWith(
                  color: context.color.label.assistive,
                )),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 46),
              child: const LottieAsset(CLotties.splashLoadingDots, height: 20, repeat: true),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> appInitialize() async {
    await Future.delayed(const Duration(milliseconds: _animationTime));
    final profile = await ref.read(userProfileProvider.future);
    if (!mounted) return;
    context.go(profile == null ? RoutePath.onboarding.path : RoutePath.budgetHome.path);
  }
}
