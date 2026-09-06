import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

final _lightTheme = LightTheme();
final _darkTheme = DarkTheme();

/// 현재 Material 밝기에 맞는 앱 테마 토큰 접근자. theme 계층 소유(presentation 의존 없음).
extension AppThemeContext on BuildContext {
  AppTheme get theme => Theme.of(this).brightness == Brightness.dark ? _darkTheme : _lightTheme;

  AppColor get color => theme.color;

  AppDeco get deco => theme.deco;

  AppTypo get typo => theme.typo;
}
