import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/theme/theme.dart';
import 'package:sedae_budget/presentation/page/budget/category_analysis.page.dart';
import 'package:sedae_budget/presentation/page/budget/widget/category_row.dart';

import '../../helper/fakes.dart';

const _pet = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12);

/// 이번 달 [day]일.
DateTime _d(int day) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, day);
}

Transaction _expense(int amount, int categoryId, int day, {String? customCategoryId}) => Transaction.create(
    amount: amount, categoryId: categoryId, date: _d(day), type: TransactionType.expense,
    customCategoryId: customCategoryId);

/// [transactions]·[customs]를 심은 서버로 분석 화면을 띄운다. [faults]로 서버 장애를 건다.
Future<void> _pump(
  WidgetTester t,
  List<Transaction> transactions, {
  List<CustomCategory> customs = const [],
  void Function(ServerFaults faults)? faults,
}) async {
  final server = await t.seedServer(categories: customs, transactions: transactions);
  faults?.call(server.faults);
  await t.pumpWidget(fakeScope(fakeContainer(server: server), const MaterialApp(home: CategoryAnalysisPage())));
  await t.settle();
}

void main() {

  testWidgets('shows donut + rows when data', (tester) async {
    await _pump(tester, [_expense(10000, 7, 5), _expense(4000, 11, 6)]);
    expect(find.byType(CategoryDonut), findsOneWidget);
    expect(find.byType(CategoryRow), findsWidgets);
  });

  testWidgets('custom header shows title, month total and month navigator', (tester) async {
    await _pump(tester, [_expense(1920000, 7, 5)]);
    expect(find.text('카테고리 분석'), findsOneWidget);
    expect(find.byType(RoundIconButton), findsOneWidget);
    // 도넛 가운데는 보고 있는 달의 이름으로 부른다(이전에는 이번 달도 '9월 총지출'이었다).
    expect(find.text('이번 달 총지출'), findsOneWidget);
    expect(find.text('192만'), findsOneWidget);

    final now = DateTime.now();
    String label(DateTime m) => '${m.year}.${m.month.toString().padLeft(2, '0')}';
    expect(find.text(label(DateTime(now.year, now.month))), findsOneWidget);
    // 이전에는 다음 달로 끝없이 넘어가 아직 오지 않은 달을 볼 수 있었다.
    await tester.tap(find.byKey(const Key('month-next')));
    await tester.settle();
    expect(find.text(label(DateTime(now.year, now.month))), findsOneWidget);
    await tester.tap(find.byKey(const Key('month-prev')));
    await tester.settle();
    expect(find.text(label(DateTime(now.year, now.month - 1))), findsOneWidget);
    expect(find.text('지출이 없어요'), findsOneWidget);
  });

  // 또래 통계가 실패해도 내 분석은 보인다. 또래 비교 토글만 빠진다.
  testWidgets('또래 통계를 못 읽어도 분석이 보이고 또래 토글은 없다', (tester) async {
    await _pump(tester, [_expense(10000, 7, 5)],
        faults: (f) => f.fail('GET', '/v1/peer', reason: FailureReason.server));

    expect(find.byType(CategoryDonut), findsOneWidget);
    expect(find.byType(CategoryRow), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('shows empty state when no expenses', (tester) async {
    await _pump(tester, const []);
    expect(find.text('지출이 없어요'), findsOneWidget);
  });

  // 카테고리 목록을 못 읽으면 커스텀 분리 없이 기본 분류로만 묶인다(합계는 그대로).
  testWidgets('카테고리 조회 실패해도 기본 분류로 분석 화면이 그려진다', (tester) async {
    await _pump(tester, [_expense(10000, 12, 5), _expense(20000, 12, 6, customCategoryId: 'c1')],
        customs: const [_pet], faults: (f) => f.fail('GET', '/v1/categories'));

    expect(find.byType(CategoryDonut), findsOneWidget);
    // 둘 다 기타(12)로 합쳐진 한 줄.
    expect(find.byType(CategoryRow), findsOneWidget);
    expect(find.text(BudgetCategory.etc.label), findsOneWidget);
    expect(find.text('카테고리 1개'), findsOneWidget);
  });

  testWidgets('커스텀 카테고리는 별도 행으로 나오고 또래 배지는 기본 분류에만 붙는다', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(tester, [_expense(10000, 12, 5), _expense(20000, 12, 6, customCategoryId: 'c1')],
        customs: const [_pet]);

    expect(find.byType(CategoryRow), findsNWidgets(2));
    expect(find.text('반려동물'), findsOneWidget);
    expect(find.text('카테고리 2개'), findsOneWidget);
    expect(find.byKey(const Key('category-manage-link')), findsOneWidget);

    // 또래 비교를 켜면 기본 분류 행 하나에만 ▲/▼ 배지가 붙는다.
    await tester.tap(find.byType(Switch));
    await tester.settle();
    final badges = tester.widgetList(find.textContaining('▲')).length +
        tester.widgetList(find.textContaining('▼')).length;
    expect(badges, 1);
  });
}
