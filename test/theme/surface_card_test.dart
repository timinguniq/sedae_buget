import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/theme/theme.dart';

void main() {
  testWidgets('SurfaceCard and InkCard render children', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Column(children: [
      SurfaceCard(child: Text('surface')),
      InkCard(child: Text('ink')),
    ]))));
    expect(find.text('surface'), findsOneWidget);
    expect(find.text('ink'), findsOneWidget);
  });

  testWidgets('SurfaceCard onTap fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SurfaceCard(onTap: () => taps++, child: const Text('tap')))));
    await tester.tap(find.text('tap'));
    expect(taps, 1);
  });
}
