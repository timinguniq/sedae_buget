import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/theme/theme.dart';

void main() {
  test('builds distinct light and dark ThemeData', () {
    expect(materialTheme(LightTheme()).scaffoldBackgroundColor, const Color(0xFFFBFAF7));
    expect(materialTheme(DarkTheme()).scaffoldBackgroundColor, const Color(0xFF1A1714));
  });

  test('filled button theme is design coral h54 r16', () {
    final style = materialTheme(LightTheme()).filledButtonTheme.style!;
    expect(style.minimumSize!.resolve({})!.height, 54);
    expect(style.backgroundColor!.resolve({}), const Color(0xFFF2603C));
    final shape = style.shape!.resolve({}) as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(16));
    expect(style.textStyle!.resolve({})!.fontWeight, FontWeight.w700);
  });

  test('switch and slider themes use coral', () {
    final theme = materialTheme(LightTheme());
    expect(theme.switchTheme.trackColor!.resolve({WidgetState.selected}), const Color(0xFFF2603C));
    expect(theme.sliderTheme.activeTrackColor, const Color(0xFFF2603C));
    expect(theme.sliderTheme.trackHeight, 8);
  });
}
