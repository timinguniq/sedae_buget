import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/ledger.view_model.dart';
import 'package:sedae_budget/presentation/page/budget/transaction_list.page.dart';
import 'package:sedae_budget/presentation/page/budget/widget/day_ad_banner.dart';
import 'package:sedae_budget/presentation/page/budget/widget/transaction_tile.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

/// 지난 달. 날짜 머리글이 '오늘·어제'가 되지 않도록 지난 달 거래로 본다.
final _last = () {
  final now = DateTime.now();
  return DateTime(now.year, now.month - 1);
}();

DateTime _d(int day) => DateTime(_last.year, _last.month, day);

/// 날짜 그룹 머리글('M월 D일').
String _header(int day) => '${_last.month}월 $day일';

Transaction _expense(int amount, int day, {int categoryId = 7, String? memo, String? customCategoryId}) =>
    Transaction.create(
        amount: amount, categoryId: categoryId, date: _d(day), type: TransactionType.expense,
        memo: memo, customCategoryId: customCategoryId);

/// [transactions]·[customs]를 심은 서버로 지난 달 내역 화면을 띄운다. [faults]로 서버 장애를 건다.
Future<void> _pump(
  WidgetTester tester, {
  List<Transaction>? transactions,
  List<CustomCategory> customs = const [],
  void Function(ServerFaults faults)? faults,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final server = await tester.seedServer(categories: customs, transactions: transactions ?? [_expense(5000, 5)]);
  faults?.call(server.faults);
  final ads = FakeAdService();
  final container = fakeContainer(
    server: server,
    adService: ads,
    launchInterstitial: await fakeLaunchInterstitial(ads),
  );
  container.read(selectedMonthProvider.notifier).prev();
  await tester.pumpWidget(fakeScope(container, const MaterialApp(home: TransactionListPage())));
  await tester.settle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  testWidgets('renders a TransactionTile for each transaction', (tester) async {
    await _pump(tester);
    expect(find.byType(TransactionTile), findsOneWidget);
  });

  // 수입은 카테고리가 없다. 이전에는 월급이 '식료품' 이름·식료품 필터로 보이고 머리글 건수에도 섞였다.
  testWidgets('수입은 이름이 수입이고 분류 필터·건수에 들지 않는다', (tester) async {
    await _pump(tester, transactions: [
      _expense(5000, 5, categoryId: BudgetCategory.food.id, memo: '장보기'),
      Transaction.create(amount: 3000000, categoryId: BudgetCategory.food.id, date: _d(1),
          type: TransactionType.income),
    ]);

    expect(find.text('${_last.month}월 5,000원 · 1건'), findsOneWidget);
    expect(find.text('수입'), findsWidgets);

    await tester.tap(find.widgetWithText(DesignChip, BudgetCategory.food.label));
    await tester.settle();
    expect(find.byType(TransactionTile), findsOneWidget);
    expect(find.text('장보기'), findsOneWidget);
  });

  // 또래 통계가 실패해도 내 내역은 보인다. 또래 초과 배지만 빠진다.
  testWidgets('또래 통계를 못 읽어도 내역이 보인다', (tester) async {
    await _pump(tester, faults: (f) => f.fail('GET', '/v1/peer', reason: FailureReason.server));

    expect(find.byType(TransactionTile), findsOneWidget);
    expect(find.text('또래보다 많이'), findsNothing);
  });

  testWidgets('이달 지출이 또래 평균을 넘는 분류의 거래에는 배지가 붙는다', (tester) async {
    await _pump(tester, transactions: [_expense(50000000, 5, categoryId: 1)]);

    expect(find.text('또래보다 많이'), findsOneWidget);
  });

  // 상위 분류가 낡은 거래를 현재 상위 분류로 거르는 규칙은 ViewedMonth 테스트가 본다.
  testWidgets('카테고리 칩은 사용자 카테고리 거래를 그 상위 분류로 거른다', (tester) async {
    await _pump(
      tester,
      customs: const [CustomCategory(id: 'c2', name: '자기계발', baseCategoryId: 9)],
      transactions: [_expense(5000, 5, categoryId: BudgetCategory.recreation.id, customCategoryId: 'c2')],
    );

    await tester.tap(find.widgetWithText(DesignChip, BudgetCategory.recreation.label));
    await tester.settle();
    expect(find.byType(TransactionTile), findsOneWidget);
  });

  testWidgets('shows month header, summary line, date group header and filter chips', (tester) async {
    await _pump(tester);

    expect(find.text('내역'), findsOneWidget);
    expect(find.byKey(const Key('month-chip')), findsOneWidget);
    expect(find.text('${_last.month}월 5,000원 · 1건'), findsOneWidget);
    expect(find.text(_header(5)), findsOneWidget); // 날짜 그룹 헤더(오늘/어제 아님)
    expect(find.text('전체'), findsOneWidget);

    // 카테고리 필터 칩(이달 지출 상위 카테고리)을 누르면 그 카테고리만 남는다.
    final label = BudgetCategory.fromId(7).label;
    expect(find.byType(DesignChip), findsNWidgets(2));
    await tester.tap(find.widgetWithText(DesignChip, label));
    await tester.settle();
    expect(find.byType(TransactionTile), findsOneWidget);
  });

  testWidgets('하루 그룹마다 끝에 배너 광고 자리(DayAdBanner)가 붙는다', (tester) async {
    await _pump(tester, transactions: [_expense(5000, 5), _expense(3000, 3), _expense(2000, 3)]);

    final banners = find.byType(DayAdBanner);
    expect(banners, findsNWidgets(2)); // 5일, 3일 두 그룹
    // 첫 배너는 5일 타일 뒤, 3일 헤더 앞에 놓인다.
    final firstBannerY = tester.getTopLeft(banners.first).dy;
    expect(firstBannerY, greaterThanOrEqualTo(tester.getBottomLeft(find.byType(TransactionTile).first).dy));
    expect(firstBannerY, lessThanOrEqualTo(tester.getTopLeft(find.text(_header(3))).dy));
    // 광고가 로드되지 않으면(fake) 빈 프레임을 남기지 않는다.
    expect(find.text('광고'), findsNothing);
  });

  testWidgets('배너 광고는 위에서부터 최대 3개만 붙는다', (tester) async {
    await _pump(tester, transactions: [for (final d in [5, 4, 3, 2, 1]) _expense(1000, d)]);

    final banners = find.byType(DayAdBanner);
    expect(banners, findsNWidgets(3)); // 5·4·3일 그룹 끝에만
    // 마지막 배너는 네 번째 그룹(2일) 헤더보다 위에 있다.
    expect(tester.getTopLeft(banners.last).dy, lessThanOrEqualTo(tester.getTopLeft(find.text(_header(2))).dy));
    expect(find.text(_header(1)), findsOneWidget); // 다섯 그룹 모두 그려진 상태에서 센 것
  });
}
