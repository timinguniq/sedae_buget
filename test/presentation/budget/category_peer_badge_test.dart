import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/presentation/page/budget/widget/category_row.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

Widget _wrap(Widget child) => provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: MaterialApp(
          home: Scaffold(body: child), theme: ThemeService().lightThemeData()));

void main() {
  testWidgets('CategoryRow with peerAmount shows ▲ badge when over peer', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(CategoryRow(
      label: '식비',
      amount: 400000,
      color: Colors.red,
      percent: 0.5,
      peerAmount: 300000,
    )));
    await tester.pump();

    // 400000 > 300000 → over → ▲, pct = (100000 * 100 / 300000).round() = 33
    expect(find.textContaining('▲'), findsOneWidget);
    expect(find.textContaining('33%'), findsOneWidget);
  });

  testWidgets('CategoryRow without peerAmount shows no peer badge', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(const CategoryRow(
      label: '식비',
      amount: 400000,
      color: Colors.red,
      percent: 0.5,
    )));
    await tester.pump();

    expect(find.textContaining('▲'), findsNothing);
    expect(find.textContaining('▼'), findsNothing);
  });
}
