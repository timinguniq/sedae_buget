import 'package:flutter/foundation.dart';

/// AdMob 광고 단위 ID.
///
/// 앱 ID(`ca-app-pub-9818502417467314~5756772402`)는 여기가 아니라
/// AndroidManifest.xml(`com.google.android.gms.ads.APPLICATION_ID`)과
/// Info.plist(`GADApplicationIdentifier`)에 들어간다.
///
/// 디버그 빌드는 구글 데모 단위를 쓴다 — 개발 중 실제 광고를 띄우고 누르면
/// 무효 트래픽으로 계정이 정지될 수 있다. 릴리즈 빌드는 자동으로 실제 단위를 쓴다.
abstract final class AdUnitIds {
  static String get banner => kDebugMode ? _demoBanner : _banner;
  static String get interstitial => kDebugMode ? _demoInterstitial : _interstitial;

  // AdMob 앱은 플랫폼별로 따로 등록한다. 아래는 발급받은 한 세트를 양쪽에 같이 쓴다.
  // iOS 앱을 AdMob에 별도 등록했다면 _demo*처럼 플랫폼으로 분기해 iOS 단위를 넣는다.
  static const _banner = 'ca-app-pub-9818502417467314/5645091765';
  static const _interstitial = 'ca-app-pub-9818502417467314/6223676263';

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static String get _demoBanner => _isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get _demoInterstitial => _isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';
}
