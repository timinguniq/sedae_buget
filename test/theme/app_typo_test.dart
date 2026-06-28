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
}
