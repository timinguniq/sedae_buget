import 'package:sedae_budget/core/ads/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱을 [threshold]번째 켤 때마다 전면 광고를 띄우는 정책.
/// 실행 횟수는 SharedPreferences에 세고, 기준에 닿으면 0으로 되돌려 다음 [threshold]번을 다시 센다.
class LaunchInterstitial {
  LaunchInterstitial(this._prefs, this._ads, {this.threshold = 5});

  static const prefsKey = 'app_launch_count';

  final SharedPreferences _prefs;
  final AdService _ads;
  final int threshold;

  Future<bool>? _loading;

  /// 앱 실행 1회를 센다. 이번이 [threshold]번째면 카운트를 0으로 되돌리고 전면 광고 로드를 시작한다.
  /// 스플래시 진입 시 1회 호출.
  Future<void> onAppLaunched() async {
    final count = (_prefs.getInt(prefsKey) ?? 0) + 1;
    final due = count >= threshold;
    await _prefs.setInt(prefsKey, due ? 0 : count);
    if (due) _loading = _ads.loadInterstitial();
  }

  /// [onAppLaunched]가 로드를 시작했으면 로드가 끝나길(최대 [timeout]) 기다렸다가 띄운다.
  /// 아니면 아무것도 안 한다. 한 번 띄우면 다음 [onAppLaunched] 전까지 다시 띄우지 않는다.
  Future<void> showIfDue({Duration timeout = const Duration(seconds: 5)}) async {
    final loading = _loading;
    if (loading == null) return;
    _loading = null;
    final loaded = await loading.timeout(timeout, onTimeout: () => false);
    if (loaded) await _ads.showInterstitial();
  }
}
