import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/transaction_list.page.dart';
import 'package:sedae_budget/presentation/page/budget/widget/day_ad_banner.dart';
import 'package:sedae_budget/presentation/page/budget/widget/transaction_tile.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

class _FakeRepo implements TransactionRepository {
  List<Transaction> txs = [
    Transaction.create(
        amount: 5000, categoryId: 7, date: DateTime(2026, 6, 5),
        type: TransactionType.expense),
  ];

  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<Transaction>> delete(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async => Result.success(txs);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}

void main() {
  late _FakeRepo repo;

  setUpAll(() => initializeDateFormatting('ko'));
  setUp(() => repo = _FakeRepo());

  /// 내역 화면의 공통 의존성: 거래·카테고리·또래·광고 fake.
  Future<ProviderContainer> container({
    PeerStatsRepository? peer,
    List<CustomCategory> customs = const [],
  }) async {
    final ads = FakeAdService();
    return fakeContainer(
      user: testUser,
      transactions: repo,
      categories: InMemoryCategoryRepository(customs),
      peerRepository: peer ?? FakePeerStatsRepository(),
      adService: ads,
      launchInterstitial: await fakeLaunchInterstitial(ads),
    );
  }

  testWidgets('renders a TransactionTile for each transaction', (tester) async {
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(await container(), const MaterialApp(home: TransactionListPage())),
    ));
    // DefaultLayout mounts a perpetual Lottie, so pumpAndSettle never settles.
    await tester.pump();
    await tester.pump();
    expect(find.byType(TransactionTile), findsOneWidget);
  });

  // 수입은 카테고리가 없다. 이전에는 월급이 '식료품' 이름·식료품 필터로 보이고 머리글 건수에도 섞였다.
  testWidgets('수입은 이름이 수입이고 분류 필터·건수에 들지 않는다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    repo.txs = [
      Transaction.create(amount: 5000, categoryId: BudgetCategory.food.id, date: DateTime(2026, 6, 5),
          type: TransactionType.expense, memo: '장보기'),
      Transaction.create(amount: 3000000, categoryId: BudgetCategory.food.id, date: DateTime(2026, 6, 1),
          type: TransactionType.income),
    ];
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(await container(), const MaterialApp(home: TransactionListPage())),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('이번 달 5,000원 · 1건'), findsOneWidget);
    expect(find.text('수입'), findsWidgets);

    await tester.tap(find.widgetWithText(DesignChip, BudgetCategory.food.label));
    await tester.pump();
    expect(find.byType(TransactionTile), findsOneWidget);
    expect(find.text('장보기'), findsOneWidget);
  });

  // 또래 통계가 실패해도 내 내역은 보인다. 또래 초과 배지만 빠진다.
  testWidgets('또래 통계를 못 읽어도 내역이 보인다', (tester) async {
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(await container(peer: FailingPeerStatsRepository()),
          const MaterialApp(home: TransactionListPage())),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.byType(TransactionTile), findsOneWidget);
    expect(find.text('또래보다 많이'), findsNothing);
  });

  testWidgets('이달 지출이 또래 평균을 넘는 분류의 거래에는 배지가 붙는다', (tester) async {
    repo.txs = [
      Transaction.create(amount: 50000000, categoryId: 1, date: DateTime(2026, 6, 5), type: TransactionType.expense),
    ];
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(await container(), const MaterialApp(home: TransactionListPage())),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('또래보다 많이'), findsOneWidget);
  });

  // 자기계발(현재 오락·문화)로 기록했지만 거래에는 옛 분류(기타)가 적혀 있는 경우.
  testWidgets('카테고리 칩은 사용자 카테고리의 현재 상위 분류로 거른다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    repo.txs = [
      Transaction.create(amount: 5000, categoryId: BudgetCategory.etc.id, date: DateTime(2026, 6, 5),
          type: TransactionType.expense, customCategoryId: 'c2'),
    ];
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(
          await container(customs: const [CustomCategory(id: 'c2', name: '자기계발', baseCategoryId: 9)]),
          const MaterialApp(home: TransactionListPage())),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.widgetWithText(DesignChip, BudgetCategory.recreation.label));
    await tester.pump();
    expect(find.byType(TransactionTile), findsOneWidget);
  });

  testWidgets('shows month header, summary line, date group header and filter chips', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(await container(), const MaterialApp(home: TransactionListPage())),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('내역'), findsOneWidget);
    expect(find.byKey(const Key('month-chip')), findsOneWidget);
    expect(find.text('이번 달 5,000원 · 1건'), findsOneWidget);
    expect(find.text('6월 5일'), findsOneWidget); // 날짜 그룹 헤더(오늘/어제 아님)
    expect(find.text('전체'), findsOneWidget);

    // 카테고리 필터 칩(이달 지출 상위 카테고리)을 누르면 그 카테고리만 남는다.
    final label = BudgetCategory.fromId(7).label;
    expect(find.byType(DesignChip), findsNWidgets(2));
    await tester.tap(find.widgetWithText(DesignChip, label));
    await tester.pump();
    expect(find.byType(TransactionTile), findsOneWidget);
  });

  testWidgets('하루 그룹마다 끝에 배너 광고 자리(DayAdBanner)가 붙는다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    repo.txs = [
      Transaction.create(amount: 5000, categoryId: 7, date: DateTime(2026, 6, 5), type: TransactionType.expense),
      Transaction.create(amount: 3000, categoryId: 7, date: DateTime(2026, 6, 3), type: TransactionType.expense),
      Transaction.create(amount: 2000, categoryId: 7, date: DateTime(2026, 6, 3), type: TransactionType.expense),
    ];

    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(await container(), const MaterialApp(home: TransactionListPage())),
    ));
    await tester.pump();
    await tester.pump();

    final banners = find.byType(DayAdBanner);
    expect(banners, findsNWidgets(2)); // 6/5, 6/3 두 그룹
    // 첫 배너는 6/5 타일 뒤, 6/3 헤더 앞에 놓인다.
    final firstBannerY = tester.getTopLeft(banners.first).dy;
    expect(firstBannerY, greaterThanOrEqualTo(tester.getBottomLeft(find.byType(TransactionTile).first).dy));
    expect(firstBannerY, lessThanOrEqualTo(tester.getTopLeft(find.text('6월 3일')).dy));
    // 광고가 로드되지 않으면(fake) 빈 프레임을 남기지 않는다.
    expect(find.text('광고'), findsNothing);
  });

  testWidgets('배너 광고는 위에서부터 최대 3개만 붙는다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    repo.txs = [
      for (final d in [5, 4, 3, 2, 1])
        Transaction.create(amount: 1000, categoryId: 7, date: DateTime(2026, 6, d), type: TransactionType.expense),
    ];

    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(await container(), const MaterialApp(home: TransactionListPage())),
    ));
    await tester.pump();
    await tester.pump();

    final banners = find.byType(DayAdBanner);
    expect(banners, findsNWidgets(3)); // 6/5, 6/4, 6/3 그룹 끝에만
    // 마지막 배너는 네 번째 그룹(6/2) 헤더보다 위에 있다.
    expect(tester.getTopLeft(banners.last).dy, lessThanOrEqualTo(tester.getTopLeft(find.text('6월 2일')).dy));
    expect(find.text('6월 1일'), findsOneWidget); // 다섯 그룹 모두 그려진 상태에서 센 것
  });
}
