import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/repository/transaction_repository.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/report/report.page.dart';
import 'package:sedae_budget/presentation/presentation.dart';

import '../../helper/fakes.dart';

class _FakeRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);

  @override
  Future<Result<Transaction>> delete(Transaction tx) async => Result.success(tx);

  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async =>
      Result.success([
        Transaction.create(
          amount: 600000,
          categoryId: 1,
          date: DateTime(2026, 6, 10),
          type: TransactionType.expense,
          memo: '식료품',
        ),
        Transaction.create(
          amount: 3000000,
          categoryId: 1,
          date: DateTime(2026, 6, 5),
          type: TransactionType.income,
        ),
      ]);

  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      Result.success([
        Transaction.create(
          amount: 500000,
          categoryId: 1,
          date: DateTime(2026, 6, 10),
          type: TransactionType.expense,
        ),
        Transaction.create(
          amount: 450000,
          categoryId: 7,
          date: DateTime(2026, 5, 15),
          type: TransactionType.expense,
        ),
        Transaction.create(
          amount: 300000,
          categoryId: 11,
          date: DateTime(2026, 4, 20),
          type: TransactionType.expense,
        ),
      ]);
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  testWidgets('report page renders insight, stats, and section headers',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = fakeContainer(
      user: testUser,
      transactions: _FakeRepo(),
      peerRepository: FakePeerStatsRepository(),
      peerStats: StubPeerData.forGroup(AgeGroup.thirties),
    );
    await tester.pumpWidget(
      provider.ChangeNotifierProvider(
        create: (_) => ThemeService(),
        child: fakeScope(
          container,
          MaterialApp(
            theme: ThemeService().lightThemeData(),
            home: const ReportPage(),
          ),
        ),
      ),
    );

    // Pump several frames to allow FutureProviders to resolve.
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('이달의 발견'), findsOneWidget);
    expect(find.text('월간 리포트'), findsOneWidget);
    expect(find.text('또래 상위'), findsOneWidget);
    expect(find.textContaining('저축률'), findsWidgets);
    expect(find.text('소득 대비'), findsOneWidget);
    expect(find.text('세대별 월평균 지출'), findsOneWidget);
    expect(find.text('세대별 대표 소비'), findsOneWidget);
    expect(find.text('최근 6개월 내 지출'), findsOneWidget);
    expect(find.textContaining('또래보다'), findsWidgets);
  });

  // 소득이 없으면 저축률도 소득 대비 지출도 계산할 수 없다. 두 칸이 같은 규칙을 따른다.
  // 식료품 지출 60만 원을 또래 식료품 평균 [food]와 견준다.
  group('이달의 발견', () {
    Future<void> pumpWithPeerFood(WidgetTester tester, int food) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final stub = StubPeerData.forGroup(AgeGroup.thirties);
      final container = fakeContainer(
        user: testUser,
        transactions: _FakeRepo(),
        peerRepository: FakePeerStatsRepository(),
        peerStats: PeerStats(
          ageGroup: stub.ageGroup,
          avgMonthlyExpense: stub.avgMonthlyExpense,
          avgSavingsRate: stub.avgSavingsRate,
          avgByCategory: {BudgetCategory.food: food},
          samples: stub.samples,
        ),
      );
      await tester.pumpWidget(provider.ChangeNotifierProvider(
        create: (_) => ThemeService(),
        child: fakeScope(container,
            MaterialApp(theme: ThemeService().lightThemeData(), home: const ReportPage())),
      ));
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
    }

    testWidgets('50% 이상 더 쓰면 배율로 말한다', (tester) async {
      await pumpWithPeerFood(tester, 400000); // +50%
      expect(find.textContaining('1.5배 더 썼어요'), findsOneWidget);
    });

    // 이전에는 +4%가 '1.0배 더 썼어요'로 보였다.
    testWidgets('50% 미만으로 더 쓰면 %로 말한다', (tester) async {
      await pumpWithPeerFood(tester, 577000); // +4%
      expect(find.textContaining('4% 더 썼어요'), findsOneWidget);
    });

    // 이전에는 +0.3%가 '0% 덜 썼어요'로, 방향이 반대로 보였다.
    testWidgets('차이가 반올림해 0%면 비슷하다고 말한다', (tester) async {
      await pumpWithPeerFood(tester, 598200); // +0.3%
      expect(find.textContaining('비슷하게 썼어요'), findsOneWidget);
      expect(find.textContaining('덜 썼어요'), findsNothing);
    });

    testWidgets('덜 쓰면 %로 말한다', (tester) async {
      await pumpWithPeerFood(tester, 800000); // -25%
      expect(find.textContaining('25% 덜 썼어요'), findsOneWidget);
    });
  });

  testWidgets('소득이 없으면 저축률과 소득 대비가 모두 — 다', (tester) async {
    final now = DateTime.now();
    await _pumpReport(tester, fakeContainer(
      user: testUser,
      transactions: InMemoryTransactionRepository([
        Transaction.create(amount: 600000, categoryId: 1, date: DateTime(now.year, now.month, 1),
            type: TransactionType.expense),
      ]),
      peerRepository: FakePeerStatsRepository(),
      peerStats: StubPeerData.forGroup(AgeGroup.thirties),
    ));

    expect(find.text('저축률'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('또래 통계를 못 읽으면 안내 문구를 보여준다', (tester) async {
    await _pumpReport(tester, fakeContainer(
      user: testUser,
      transactions: _FakeRepo(),
      peerRepository: FailingPeerStatsRepository(),
    ));

    expect(find.text('또래 통계를 불러오지 못했어요'), findsOneWidget);
  });
}

Future<void> _pumpReport(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(provider.ChangeNotifierProvider(
    create: (_) => ThemeService(),
    child: fakeScope(container,
        MaterialApp(theme: ThemeService().lightThemeData(), home: const ReportPage())),
  ));
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await tester.pump();
}
