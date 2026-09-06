// test/theme/app_typo_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/theme/theme.dart';

void main() {
  test('Pretendard exposes extraBold w800', () {
    expect(const Pretendard().extraBold, FontWeight.w800);
  });

  test('amountDisplay uses w800 Pretendard', () {
    final typo = AppTypo(typo: const Pretendard(), fontColor: const Color(0xFF000000));
    expect(typo.amountDisplay.fontWeight, FontWeight.w800);
    expect(typo.amountDisplay.fontFamily, 'Pretendard');
  });

  test('design styles: pageTitle 800·21, sectionTitle 700·13.5, amountHero 800·42', () {
    final typo = AppTypo(typo: const Pretendard(), fontColor: const Color(0xFF000000));
    expect(typo.pageTitle.fontSize, 21);
    expect(typo.pageTitle.fontWeight, FontWeight.w800);
    expect(typo.pageTitle.letterSpacing, -0.5);
    expect(typo.sectionTitle.fontSize, 13.5);
    expect(typo.sectionTitle.fontWeight, FontWeight.w700);
    expect(typo.amountHero.fontSize, 42);
    expect(typo.amountHero.fontWeight, FontWeight.w800);
  });

  test('accent styles use bundled Pretendard, not IBMPlexSans', () {
    final typo = AppTypo(typo: const Pretendard(), fontColor: const Color(0xFF000000));
    expect(typo.titleReadingW600.fontFamily, 'Pretendard');
    expect(typo.heroW700.fontFamily, 'Pretendard');
  });
}
