import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/presentation/page/budget/widget/amount_keypad.dart';

void main() {
  test('append builds amount, backspace removes, no leading zero', () {
    var v = const KeypadInput(0);
    v = v.press('1'); v = v.press('2'); v = v.press('00');
    expect(v.amount, 1200);
    v = v.backspace();
    expect(v.amount, 120);
  });
  test('caps at 999,999,999', () {
    var v = const KeypadInput(123456789);
    v = v.press('9');
    expect(v.amount, 123456789); // unchanged (overflow blocked)
  });
}
