import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/ads/index.dart';

void main() {
  const demo = 'ca-app-pub-3940256099942544/';

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('디버그 빌드(테스트 포함)는 플랫폼별 구글 데모 단위를 쓴다', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AdUnitIds.banner, '${demo}6300978111');
    expect(AdUnitIds.interstitial, '${demo}1033173712');

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(AdUnitIds.banner, '${demo}2934735716');
    expect(AdUnitIds.interstitial, '${demo}4411468910');
  });
}
