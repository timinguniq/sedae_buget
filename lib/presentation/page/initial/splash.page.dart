import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

final _logger = CustomLogger.create(tag: (SplashPage).toString());

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with SingleTickerProviderStateMixin {
  static const _animationTime = 2000;

  late AnimationController controller;
  late Animation<double> fadeIn;
  late Animation<double> fadeOut;
  late Animation<Offset> moveUp;
  late Animation<double> circleRadius;
  late Animation<double> circleFadeIn;

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

    fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(1000 / _animationTime, 1, curve: Curves.easeOut),
      ),
    );

    circleFadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: const Interval(1200 / _animationTime, 1, curve: Curves.easeOut)),
    );

    circleRadius = Tween<double>(begin: 0, end: 1000).animate(
      CurvedAnimation(parent: controller, curve: const Interval(1200 / _animationTime, 1, curve: Curves.easeOut)),
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
    final size = MediaQuery.of(context).size;

    return DefaultLayout(
      backgroundColor: Palette.primaryNormal,
      child: Center(
        child: Stack(
          children: [
            /// logo animation
            FadeTransition(
              opacity: fadeOut,
              child: FadeTransition(
                opacity: fadeIn,
                child: SlideTransition(
                  position: moveUp,
                  child: const ImageAsset(CImages.logoWhite, size: 48),
                ),
              ),
            ),

            /// circle animation
            FadeTransition(
              opacity: circleFadeIn,
              child: AnimatedBuilder(
                animation: controller,
                builder: (_, __) => CustomPaint(
                  painter: _CirclePainter(
                    radius: circleRadius.value,
                    offset: Offset(size.width / 3, size.height / 4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> appInitialize() async {
    _logger.i('appInitialize() : start.');
    // 앱 업데이트가 필요한 경우 초기화 중단.
    await postLaunchSetup();

    controller.reset();
    unawaited(controller.forward());
    final animationTime = Future.delayed(const Duration(milliseconds: _animationTime));
/*
    final signInWithTokenResult = await locator<AuthUsecase>().execute<Result>(usecase: SignInWithTokenUsecase());
    if (signInWithTokenResult is Success) {
      await UserDataManager.initialize(delay: animationTime);
    } else {
      await Future.wait([animationTime]);
      if (await locator<AppSettingManager>().getIsFirstInstalled()) {
        CRoute.redirectToOnboarding();
      } else {
        CRoute.redirectToLogin();
      }
    }

 */
    _logger.d('App initialize end');
  }

  Future<void> postLaunchSetup() async {
    _logger.i('postLaunchSetup() : start.');
    final result = await RemoteConfig.checkServiceAvailable();
    _logger.d('postLaunchSetup : checkServiceAvailable=$result');
    if (result != true) {
      Future.delayed(const Duration(seconds: 1), () => exit(0));
      return;
    }

    final storage = await LocalStorage.getInstance();
    final environmentType = RemoteConfig.getAppEnvironment();
    EnvironmentConfig.initialize(environmentType);
    configureDependencyInjection(storage);
  }
}

class _CirclePainter extends CustomPainter {
  const _CirclePainter({
    required this.radius,
    required this.offset,
  });

  final double radius;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.fillWhite
      ..style = PaintingStyle.fill;

    canvas.drawCircle(offset, radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
