import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/compare/widget/category_battle_row.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SizedBox(width: 350, child: child)));

Widget _row(int mine, int peer) => _wrap(CategoryBattleRow(
    category: BudgetCategory.food, comparison: PeerComparison.of(mine: mine, peer: peer)!));

void main() {
  testWidgets('more than peer → +N% (coral side)', (tester) async {
    await tester.pumpWidget(_row(150, 100));
    expect(find.text('+50%'), findsOneWidget);
    expect(find.text(BudgetCategory.food.label), findsOneWidget);
  });

  testWidgets('less than peer → −N%', (tester) async {
    await tester.pumpWidget(_row(90, 100));
    expect(find.text('−10%'), findsOneWidget);
  });

  testWidgets('반올림해 0%면 비슷', (tester) async {
    await tester.pumpWidget(_row(1004, 1000));
    expect(find.text('비슷'), findsOneWidget);
  });
}
