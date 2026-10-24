import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';
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
    // 실행 횟수를 세고, N번째면 스플래시 동안 전면 광고를 미리 로드한다.
    final launchAd = ref.read(launchInterstitialProvider);
    await launchAd.onAppLaunched();
    final appStatus = ref.read(appStatusProvider.future); // 브랜딩과 함께 점검·업데이트 판정
    await Future.delayed(const Duration(milliseconds: _animationTime));
    // 점검·강제 업데이트면 안내하고 끝낸다(선택 업데이트는 닫고 계속).
    final status = await appStatus;
    if (!mounted) return;
    if (!await showAppStatusDialog(context, status, exitApp: ref.read(appExitProvider))) return;
    // 세션 확인(인증 → 프로필)이 끝날 때까지 기다린다. 실패해도 확인은 끝난 것이다.
    try {
      await ref.read(userProfileProvider.future);
    } catch (_) {
      // 실패도 행선지가 있다(연결 안 됨 화면).
    }
    if (!mounted) return;
    // 이 화면은 이동하면 사라져 ref를 쓸 수 없으므로, 광고를 기다린 뒤의 세션은 앱의 컨테이너에서 읽는다.
    final container = ProviderScope.containerOf(context, listen: false);
    bool sessionReady() => container.read(sessionGateProvider) == SessionGate.ready;
    // 어디로 갈지(로그인·온보딩·연결 안 됨·홈)는 전역 가드(sessionRedirect)가 정한다.
    context.go(RoutePath.budgetHome.path);
    // 전면 광고는 홈에 닿을 때(세션 준비됨)만, 로드를 기다린 뒤에도 세션이 준비됨일 때만 띄운다. 가드가 로그인·온보딩·
    // 연결 안 됨으로 보내거나 기다리는 동안 세션이 끝나면 이번 실행에는 띄우지 않는다. 로드한 광고는 쓰이지 않은 채
    // 광고 서비스에 남고(다음 로드가 정리한다), 실행 카운트는 이미 0으로 돌아가 다음 N번째 실행에 다시 띄운다.
    if (sessionReady()) await launchAd.showIfDue(stillWanted: sessionReady);
  }
}
