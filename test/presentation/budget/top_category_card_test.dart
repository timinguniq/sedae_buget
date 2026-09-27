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
        (category: BudgetCategory.fromId(2), amount: 320000, peer: null),
        (category: BudgetCategory.fromId(5), amount: 180000, peer: PeerComparison.of(mine: 180000, peer: 120000)),
      ],
      onTap: () => taps++,
    )));
    await t.pump();

    expect(find.text('많이 쓴 카테고리'), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(1).label), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(2).label), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(5).label), findsOneWidget);
    expect(find.text('또래▲15%'), findsOneWidget);
    expect(find.text('또래▲50%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));

    await t.tap(find.text('많이 쓴 카테고리'));
    expect(taps, 1);
  });

  // 디자인: 또래보다 더 쓴 분류만 코랄 막대, 덜 쓰거나 비슷하면 회색 막대. 또래 비교가 없으면 코랄 그대로.
  group('막대 색', () {
    final top = [
      (category: BudgetCategory.fromId(1), amount: 540000, peer: PeerComparison.of(mine: 540000, peer: 470000)),
      (category: BudgetCategory.fromId(8), amount: 380000, peer: PeerComparison.of(mine: 380000, peer: 420000)),
      (category: BudgetCategory.fromId(10), amount: 200000, peer: PeerComparison.of(mine: 200000, peer: 200000)),
      (category: BudgetCategory.fromId(2), amount: 100000, peer: null),
    ];

    List<Color?> barColors(WidgetTester t) =>
        t.widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).map((w) => w.color).toList();

    testWidgets('라이트: 더 씀·비교 없음은 코랄, 덜 씀·비슷은 회색', (t) async {
      await t.pumpWidget(_wrap(TopCategoryCard(top: top)));
      expect(barColors(t),
          [Palette.primaryNormal, Palette.neutral400, Palette.neutral400, Palette.primaryNormal]);
    });

    testWidgets('다크: 회색 막대는 다크 톤이다', (t) async {
      await t.pumpWidget(MaterialApp(
          home: Scaffold(body: TopCategoryCard(top: top)), theme: materialTheme(DarkTheme())));
      expect(barColors(t),
          [Palette.primaryNormal, Palette.darkTextDisabled, Palette.darkTextDisabled, Palette.primaryNormal]);
    });
  });

  testWidgets('empty summary shows placeholder', (t) async {
    await t.pumpWidget(_wrap(const TopCategoryCard(top: [])));
    await t.pump();
    expect(find.text('아직 지출이 없어요'), findsOneWidget);
  });
}
