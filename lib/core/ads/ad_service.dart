import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 광고 SDK 경계. 페이지/위젯은 이 인터페이스만 본다.
/// 실패는 예외 대신 null/false로 알린다 — 광고가 안 떠도 앱은 그대로 돌아가야 한다.
abstract interface class AdService {
  /// SDK 초기화. 여러 번 불러도 한 번만 초기화한다.
  Future<void> initialize();

  /// 배너(320×100) 로드. 실패하면 null. 돌려받은 광고는 쓰는 쪽이 dispose 한다.
  Future<BannerAd?> loadBanner();

  /// 전면 광고 로드. 로드됐으면 true. 이후 [showInterstitial]로 띄운다.
  Future<bool> loadInterstitial();

  /// 로드해 둔 전면 광고를 띄운다. 없으면 아무것도 안 한다.
  Future<void> showInterstitial();
}

/// 광고를 지원하지 않는 플랫폼(web)·테스트용 Null Object.
class NoAdService implements AdService {
  const NoAdService();

  @override
  Future<void> initialize() async {}

  @override
  Future<BannerAd?> loadBanner() async => null;

  @override
  Future<bool> loadInterstitial() async => false;

  @override
  Future<void> showInterstitial() async {}
}
