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
  test('design neutral ramp order (300·400·500·600·700·200) and dark ramp', () {
    expect(Palette.neutral400, const Color(0xFFC9C1B8));
    expect(Palette.neutralRamp, const [
      Color(0xFFDCD5CC), Color(0xFFC9C1B8), Color(0xFFB8B0A8),
      Color(0xFFA29A92), Color(0xFF8C857D), Color(0xFFE6E1D8),
    ]);
    expect(Palette.darkRamp, const [Color(0xFF3A332C), Color(0xFF4A433C), Color(0xFF5A534C)]);
  });
  test('coral soft present for dark badge text', () {
    expect(Palette.coralSoft, const Color(0xFFFF8A6B));
  });
  test('dark tokens distinct from light', () {
    expect(Palette.darkBg, const Color(0xFF1A1714));
    expect(Palette.darkSurface, const Color(0xFF241F1B));
    expect(Palette.darkText, const Color(0xFFF5F1EC));
  });
}
