import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/theme/theme.dart';

void main() {
  test('light vs dark backgrounds differ', () {
    expect(LightTheme().color.background.normal, const Color(0xFFFBFAF7));
    expect(DarkTheme().color.background.normal, const Color(0xFF1A1714));
  });
  test('both expose surface + primary.tint', () {
    expect(LightTheme().color.background.surface, const Color(0xFFFFFFFF));
    expect(DarkTheme().color.primary.tint, const Color(0xFF3A241C));
  });
  test('primary coral shared across themes', () {
    expect(LightTheme().color.primary.normal, const Color(0xFFF2603C));
    expect(DarkTheme().color.primary.normal, const Color(0xFFF2603C));
  });
}
