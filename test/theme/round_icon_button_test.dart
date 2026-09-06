import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/theme/theme.dart';

void main() {
  testWidgets('RoundIconButton is 30px and fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: RoundIconButton(icon: Icons.chevron_left, onTap: () => taps++),
    )));
    expect(tester.getSize(find.byType(RoundIconButton)), const Size(30, 30));
    await tester.tap(find.byType(RoundIconButton));
    expect(taps, 1);
  });
}
