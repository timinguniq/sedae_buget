import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/widget/top_category_card.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

Widget _wrap(Widget child) => provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: MaterialApp(home: Scaffold(body: child), theme: ThemeService().lightThemeData()));

void main() {
  testWidgets('shows top 3 categories by amount with peer badges and fires onTap', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);

    var taps = 0;
    await t.pumpWidget(_wrap(TopCategoryCard(
      summary: {
        BudgetCategory.fromId(1): 540000,
        BudgetCategory.fromId(7): 90000,
        BudgetCategory.fromId(11): 320000,
        BudgetCategory.fromId(3): 180000,
      },
      peerByCategory: {BudgetCategory.fromId(1): 470000, BudgetCategory.fromId(3): 120000},
      onTap: () => taps++,
    )));
    await t.pump();

    expect(find.text('많이 쓴 카테고리'), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(1).label), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(11).label), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(3).label), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(7).label), findsNothing); // 4위는 생략
    expect(find.text('또래▲15%'), findsOneWidget);
    expect(find.text('또래▲50%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));

    await t.tap(find.text('많이 쓴 카테고리'));
    expect(taps, 1);
  });

  testWidgets('empty summary shows placeholder', (t) async {
    await t.pumpWidget(_wrap(const TopCategoryCard(summary: {})));
    await t.pump();
    expect(find.text('아직 지출이 없어요'), findsOneWidget);
  });
}
