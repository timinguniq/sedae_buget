import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/ads/index.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helper/fakes.dart';

Future<int> _count() async =>
    (await SharedPreferences.getInstance()).getInt(LaunchInterstitial.prefsKey) ?? 0;

void main() {
  Future<LaunchInterstitial> build(FakeAdService ads, {int count = 0}) async {
    SharedPreferences.setMockInitialValues({LaunchInterstitial.prefsKey: count});
    return LaunchInterstitial(await SharedPreferences.getInstance(), ads);
  }

  test('1~4번째 실행은 카운트만 올리고 광고를 건드리지 않는다', () async {
    final ads = FakeAdService();
    final launch = await build(ads, count: 3);
    await launch.onAppLaunched();
    await launch.showIfDue();
    expect(await _count(), 4);
    expect(ads.loadInterstitialCalls, 0);
    expect(ads.showInterstitialCalls, 0);
  });

  test('5번째 실행: 카운트를 0으로 되돌리고 전면 광고를 로드해 띄운다', () async {
    final ads = FakeAdService();
    final launch = await build(ads, count: 4);
    await launch.onAppLaunched();
    expect(await _count(), 0);
    expect(ads.loadInterstitialCalls, 1);
    expect(ads.showInterstitialCalls, 0); // 스플래시가 끝나기 전엔 띄우지 않는다
    await launch.showIfDue();
    expect(ads.showInterstitialCalls, 1);
    await launch.showIfDue(); // 같은 실행에서 두 번 띄우지 않는다
    expect(ads.showInterstitialCalls, 1);
  });

  test('0으로 돌아간 뒤 다시 5번째(10번째 실행)에 띄운다', () async {
    final ads = FakeAdService();
    final launch = await build(ads);
    for (var i = 0; i < 10; i++) {
      await launch.onAppLaunched();
      await launch.showIfDue();
    }
    expect(ads.showInterstitialCalls, 2);
    expect(await _count(), 0);
  });

  test('로드에 실패하면 띄우지 않는다', () async {
    final ads = FakeAdService(interstitial: Future.value(false));
    final launch = await build(ads, count: 4);
    await launch.onAppLaunched();
    await launch.showIfDue();
    expect(ads.showInterstitialCalls, 0);
  });

  test('timeout 안에 로드가 안 끝나면 띄우지 않는다', () async {
    final ads = FakeAdService(interstitial: Completer<bool>().future);
    final launch = await build(ads, count: 4);
    await launch.onAppLaunched();
    await launch.showIfDue(timeout: const Duration(milliseconds: 10));
    expect(ads.showInterstitialCalls, 0);
  });
}
