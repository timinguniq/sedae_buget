import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/theme/theme.dart';

void main() {
  test('primary is coral, not legacy orange', () {
    expect(Palette.primaryNormal, const Color(0xFFF2603C));
  });
  test('light surface and bg differ (cards sit above bg)', () {
    expect(Palette.surface, const Color(0xFFFFFFFF));
    expect(Palette.backgroundNormal, const Color(0xFFFBFAF7));
  });
  test('coral tint present for selected/tinted backgrounds', () {
    expect(Palette.coralTint, const Color(0xFFFEF0EB));
  });
  test('dark tokens distinct from light', () {
    expect(Palette.darkBg, const Color(0xFF1A1714));
    expect(Palette.darkSurface, const Color(0xFF241F1B));
    expect(Palette.darkText, const Color(0xFFF5F1EC));
  });
}
