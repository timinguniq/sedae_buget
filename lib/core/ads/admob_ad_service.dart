import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sedae_budget/core/ads/ad_service.dart';
import 'package:sedae_budget/core/ads/ad_unit_ids.dart';
import 'package:sedae_budget/core/util/logger/custom_logger.dart';

final _logger = CustomLogger.create(tag: 'AdMob');

/// google_mobile_ads 구현. 로드 전에 초기화가 끝나 있도록 [initialize]를 안에서 기다린다.
class AdMobAdService implements AdService {
  Future<void>? _initialized;
  InterstitialAd? _interstitial;

  @override
  Future<void> initialize() => _initialized ??= _initialize();

  Future<void> _initialize() async {
    try {
      await MobileAds.instance.initialize();
    } catch (e, s) {
      _logger.w('MobileAds 초기화 실패: $e', stackTrace: s);
    }
  }

  @override
  Future<BannerAd?> loadBanner() async {
    await initialize();
    final loaded = Completer<bool>();
    final ad = BannerAd(
      adUnitId: AdUnitIds.banner,
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => loaded.complete(true),
        onAdFailedToLoad: (_, err) {
          _logger.w('배너 로드 실패: $err');
          loaded.complete(false);
        },
      ),
    );
    try {
      await ad.load();
    } catch (e, s) {
      _logger.w('배너 로드 예외: $e', stackTrace: s);
      if (!loaded.isCompleted) loaded.complete(false);
    }
    if (await loaded.future) return ad;
    await _dispose(ad);
    return null;
  }

  @override
  Future<bool> loadInterstitial() async {
    await initialize();
    final previous = _interstitial;
    _interstitial = null;
    if (previous != null) await _dispose(previous);

    final loaded = Completer<bool>();
    try {
      await InterstitialAd.load(
        adUnitId: AdUnitIds.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitial = ad;
            loaded.complete(true);
          },
          onAdFailedToLoad: (err) {
            _logger.w('전면 광고 로드 실패: $err');
            loaded.complete(false);
          },
        ),
      );
    } catch (e, s) {
      _logger.w('전면 광고 로드 예외: $e', stackTrace: s);
      if (!loaded.isCompleted) loaded.complete(false);
    }
    return loaded.future;
  }

  @override
  Future<void> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) return;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) => unawaited(_dispose(ad)),
      onAdFailedToShowFullScreenContent: (ad, err) {
        _logger.w('전면 광고 표시 실패: $err');
        unawaited(_dispose(ad));
      },
    );
    try {
      await ad.show();
    } catch (e, s) {
      _logger.w('전면 광고 표시 예외: $e', stackTrace: s);
      await _dispose(ad);
    }
  }

  Future<void> _dispose(Ad ad) async {
    try {
      await ad.dispose();
    } catch (_) {
      // 플러그인이 없는 환경(web/테스트)에서는 dispose도 실패한다. 무시.
    }
  }
}
