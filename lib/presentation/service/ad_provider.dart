import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/ads/index.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';

/// 광고 SDK 경계. DI에 등록된 [AdService]를 위젯에 넘긴다.
final adServiceProvider = Provider<AdService>((_) => locator<AdService>());

/// N번째 실행 전면 광고 정책.
final launchInterstitialProvider =
    Provider<LaunchInterstitial>((_) => locator<LaunchInterstitial>());
