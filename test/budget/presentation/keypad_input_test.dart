import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/presentation/page/budget/widget/amount_keypad.dart';
import 'package:sedae_budget/theme/theme.dart';

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

  // 디자인: 숫자 키는 흰 바탕·테두리, 아래 줄 양 끝의 `00`·`⌫`는 바탕 없이 흐린 색이다.
  testWidgets('00 키는 바탕 없이 흐린 19px 글씨다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: materialTheme(LightTheme()),
      home: Scaffold(body: AmountKeypad(value: const KeypadInput(0), onChanged: (_) {})),
    ));

    Container keyOf(String label) =>
        tester.widget<Container>(find.ancestor(of: find.text(label), matching: find.byType(Container)).first);

    expect(keyOf('00').decoration, isNull);
    final style = tester.widget<Text>(find.text('00')).style!;
    expect(style.fontSize, 19);
    expect(style.color, LightTheme().color.label.alternative);

    expect(keyOf('0').decoration, isNotNull);
    expect(tester.widget<Text>(find.text('0')).style!.fontSize, 22);
  });
}
