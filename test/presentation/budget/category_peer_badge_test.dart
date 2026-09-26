import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/widget/category_row.dart';
import 'package:sedae_budget/theme/theme.dart';

Widget _wrap(Widget child) => MaterialApp(
          home: Scaffold(body: child), theme: materialTheme(LightTheme()));

void main() {
  testWidgets('CategoryRow with a peer comparison shows ▲ badge when over peer', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(CategoryRow(
      label: '식비',
      amount: 400000,
      color: Colors.red,
      percent: 0.5,
      peer: PeerComparison.of(mine: 400000, peer: 300000),
    )));
    await tester.pump();

    // 400000 > 300000 → over → ▲, pct = (100000 * 100 / 300000).round() = 33
    expect(find.textContaining('▲'), findsOneWidget);
    expect(find.textContaining('33%'), findsOneWidget);
  });

  testWidgets('CategoryRow without a peer comparison shows no peer badge', (tester) async {
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

  // 이전에는 같은 금액이 '또래▼0%'로 보였다.
  testWidgets('또래와 같으면 비슷하다고 보인다', (tester) async {
    await tester.pumpWidget(_wrap(CategoryRow(
      label: '식비',
      amount: 300000,
      color: Colors.red,
      percent: 0.5,
      peer: PeerComparison.of(mine: 300000, peer: 300000),
    )));
    await tester.pump();

    expect(find.text('또래와 비슷'), findsOneWidget);
    expect(find.textContaining('또래▼'), findsNothing);
    expect(find.textContaining('또래▲'), findsNothing);
  });
}
