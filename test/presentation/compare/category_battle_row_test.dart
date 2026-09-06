import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/compare/widget/category_battle_row.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SizedBox(width: 350, child: child)));

void main() {
  testWidgets('more than peer → +N% (coral side)', (tester) async {
    await tester.pumpWidget(_wrap(const CategoryBattleRow(category: BudgetCategory.food, mine: 150, peer: 100)));
    expect(find.text('+50%'), findsOneWidget);
    expect(find.text(BudgetCategory.food.label), findsOneWidget);
  });

  testWidgets('less than peer → −N%', (tester) async {
    await tester.pumpWidget(_wrap(const CategoryBattleRow(category: BudgetCategory.food, mine: 90, peer: 100)));
    expect(find.text('−10%'), findsOneWidget);
  });

  testWidgets('no peer data → 0%', (tester) async {
    await tester.pumpWidget(_wrap(const CategoryBattleRow(category: BudgetCategory.food, mine: 90, peer: 0)));
    expect(find.text('0%'), findsOneWidget);
  });
}
