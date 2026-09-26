import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 사용자가 고른 테마 모드를 기기에 둔다.
/// 앱을 켤 때 이미 읽어 둔 [SharedPreferences]로 바로 읽어서, 첫 화면부터 고른 테마로 그린다.
class ThemeModeStore {
  ThemeModeStore(this._prefs);

  static const _key = 'theme_mode';

  final SharedPreferences _prefs;

  /// 고른 적이 없거나 알 수 없는 값이면 시스템 설정을 따른다.
  ThemeMode read() =>
      ThemeMode.values.firstWhere((m) => m.name == _prefs.getString(_key), orElse: () => ThemeMode.system);

  Future<void> write(ThemeMode mode) => _prefs.setString(_key, mode.name);
}
