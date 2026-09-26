import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/widget/top_category_card.dart';
import 'package:sedae_budget/theme/theme.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child), theme: materialTheme(LightTheme()));

void main() {
  // 어떤 분류를 몇 개 고를지는 MonthOverview.topCategories가 정한다. 카드는 받은 순서대로 그린다.
  testWidgets('draws the given categories with peer badges and fires onTap', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);

    var taps = 0;
    await t.pumpWidget(_wrap(TopCategoryCard(
      top: [
        (category: BudgetCategory.fromId(1), amount: 540000, peer: PeerComparison.of(mine: 540000, peer: 470000)),
        (category: BudgetCategory.fromId(11), amount: 320000, peer: null),
        (category: BudgetCategory.fromId(3), amount: 180000, peer: PeerComparison.of(mine: 180000, peer: 120000)),
      ],
      onTap: () => taps++,
    )));
    await t.pump();

    expect(find.text('많이 쓴 카테고리'), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(1).label), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(11).label), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(3).label), findsOneWidget);
    expect(find.text('또래▲15%'), findsOneWidget);
    expect(find.text('또래▲50%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));

    await t.tap(find.text('많이 쓴 카테고리'));
    expect(taps, 1);
  });

  testWidgets('empty summary shows placeholder', (t) async {
    await t.pumpWidget(_wrap(const TopCategoryCard(top: [])));
    await t.pump();
    expect(find.text('아직 지출이 없어요'), findsOneWidget);
  });
}
