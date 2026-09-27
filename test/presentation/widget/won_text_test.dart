import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/presentation/widget/common/won_text.dart';

void main() {
  test('전체·쉼표만·부호: 음수는 맨 앞에 −를 쓴다', () {
    expect(WonText.full.of(1920000), '₩1,920,000');
    expect(WonText.full.of(0), '₩0');
    expect(WonText.full.of(-500000), '−₩500,000');
    expect(WonText.plain.of(540000), '540,000');
    expect(WonText.plain.of(-540000), '−540,000');
    expect(WonText.signed.of(6800), '+6,800');
    expect(WonText.signed.of(-6800), '−6,800');
    expect(WonText.signed.of(0), '0');
  });

  test('짧게: 1만 미만은 쉼표, 100만 미만은 소수 한 자리, 그 이상은 만 반올림, 1억 이상은 억', () {
    const cases = {
      0: '0',
      9300: '9,300',
      9999: '9,999',
      10000: '1만',
      14000: '1.4만',
      14999: '1.5만',
      15000: '1.5만',
      190000: '19만',
      995000: '99.5만',
      999960: '100만',
      1000000: '100만',
      1920000: '192만',
      1925000: '193만',
      99994999: '9999만',
      99995000: '1억',
      100000000: '1억',
      250000000: '2.5억',
    };
    for (final e in cases.entries) {
      expect(WonText.short.of(e.key), e.value, reason: '${e.key}');
    }
    expect(WonText.short.of(-15000), '−1.5만');
  });

  test('짧게+원은 짧게 쓴 뒤 원을 붙인다', () {
    expect(WonText.shortWithUnit.of(1920000), '192만원');
    expect(WonText.shortWithUnit.of(15000), '1.5만원');
    expect(WonText.shortWithUnit.of(9300), '9,300원');
    expect(WonText.shortWithUnit.of(-190000), '−19만원');
  });
}
