import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedae_budget/presentation/presentation.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to system mode', () {
    expect(ThemeService().themeMode, ThemeMode.system);
  });

  test('setMode persists and notifies', () async {
    final s = ThemeService();
    var notified = 0;
    s.addListener(() => notified++);
    await s.setMode(ThemeMode.dark);
    expect(s.themeMode, ThemeMode.dark);
    expect(notified, greaterThan(0));

    final reloaded = ThemeService();
    await reloaded.loadPersisted();
    expect(reloaded.themeMode, ThemeMode.dark);
  });

  test('builds distinct light and dark ThemeData', () {
    final s = ThemeService();
    expect(s.lightThemeData().scaffoldBackgroundColor, const Color(0xFFFBFAF7));
    expect(s.darkThemeData().scaffoldBackgroundColor, const Color(0xFF1A1714));
  });

  test('filled button theme is design coral h54 r16', () {
    final style = ThemeService().lightThemeData().filledButtonTheme.style!;
    expect(style.minimumSize!.resolve({})!.height, 54);
    expect(style.backgroundColor!.resolve({}), const Color(0xFFF2603C));
    final shape = style.shape!.resolve({}) as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(16));
    expect(style.textStyle!.resolve({})!.fontWeight, FontWeight.w700);
  });

  test('switch and slider themes use coral', () {
    final theme = ThemeService().lightThemeData();
    expect(theme.switchTheme.trackColor!.resolve({WidgetState.selected}), const Color(0xFFF2603C));
    expect(theme.sliderTheme.activeTrackColor, const Color(0xFFF2603C));
    expect(theme.sliderTheme.trackHeight, 8);
  });
}
