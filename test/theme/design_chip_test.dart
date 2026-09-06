import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/theme/theme.dart';

void main() {
  testWidgets('DesignChip renders label for every style and fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Row(children: [
      const DesignChip(label: '전체', style: DesignChipStyle.ink),
      DesignChip(label: '식비', onTap: () => taps++),
      const DesignChip(label: '20대', style: DesignChipStyle.coral),
    ]))));
    expect(find.text('전체'), findsOneWidget);
    expect(find.text('식비'), findsOneWidget);
    expect(find.text('20대'), findsOneWidget);
    await tester.tap(find.text('식비'));
    expect(taps, 1);
  });
}
