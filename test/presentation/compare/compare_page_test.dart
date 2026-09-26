import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/repository/transaction_repository.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/compare/compare.page.dart';

import '../../helper/fakes.dart';

class _FakeRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<Transaction>> delete(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async => Result.success([
        Transaction.create(amount: 500000, categoryId: 1, date: DateTime(y, m, 5),
            type: TransactionType.expense, memo: '식료품'),
        Transaction.create(amount: 200000, categoryId: 7, date: DateTime(y, m, 10),
            type: TransactionType.expense, memo: '교통'),
        Transaction.create(amount: 100000, categoryId: 11, date: DateTime(y, m, 15),
            type: TransactionType.expense, memo: '외식'),
      ]);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}

/// 이달 지출(식료품 50만·교통 20만·외식 10만, 합계 80만)과 견줄 또래 통계.
PeerStats _peer({int avg = 1000000, List<int> samples = const [700000, 900000, 1200000]}) =>
    PeerStats(
      ageGroup: AgeGroup.thirties,
      avgMonthlyExpense: avg,
      avgSavingsRate: 0.2,
      // 외식(11)은 또래 평균이 없다.
      avgByCategory: {BudgetCategory.fromId(1): 400000, BudgetCategory.fromId(7): 250000},
      samples: samples,
    );

Future<void> _pumpCompare(WidgetTester tester, PeerStats peer) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = fakeContainer(user: testUser, transactions: _FakeRepo(), peerStats: peer);
  await tester.pumpWidget(provider.ChangeNotifierProvider(
    create: (_) => ThemeService(),
    child: fakeScope(container, const MaterialApp(home: ComparePage())),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  // 이전에는 같은 금액이 '또래보다 약 0원 더 ▲'로 보였다.
  testWidgets('이달 지출이 또래 평균과 같으면 비슷하다고 보인다', (tester) async {
    await _pumpCompare(tester, _peer(avg: 800000));
    expect(find.text('또래와 비슷해요'), findsOneWidget);
    expect(find.textContaining('0원 더'), findsNothing);
  });

  testWidgets('또래 평균이 없는 항목은 항목별 차이에서 뺀다', (tester) async {
    await _pumpCompare(tester, _peer());
    expect(find.text(BudgetCategory.fromId(1).label), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(7).label), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(11).label), findsNothing);
  });

  // 이전에는 표본이 없어도 '또래 1명 중 내 지출은 1등 · 상위 100%'로 보였다.
  testWidgets('또래 표본이 없으면 순위를 보이지 않는다', (tester) async {
    await _pumpCompare(tester, _peer(samples: const []));
    expect(find.textContaining('명 중'), findsNothing);
    expect(find.textContaining('상위'), findsNothing);
    expect(find.text('항목별 차이'), findsOneWidget);
  });

  testWidgets('compare page renders rank headline, versus cards and battle rows', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 저축률 카드가 프로필 소득을 읽으므로 사용자 fake도 함께 끼운다.
    final container = fakeContainer(
      user: testUser,
      transactions: _FakeRepo(),
      peerStats: StubPeerData.forGroup(AgeGroup.thirties),
    );
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(container, const MaterialApp(home: ComparePage())),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('또래 비교'), findsOneWidget);
    expect(find.text(AgeGroup.thirties.label), findsOneWidget); // 나이대 칩
    expect(find.text('또래'), findsWidgets); // versus bar labels
    expect(find.text('나'), findsWidgets);   // versus bar labels + histogram marker
    expect(find.textContaining('등'), findsWidgets); // rank headline
    expect(find.text('이번 달 지출 비교'), findsOneWidget);
    expect(find.text('소득 대비 저축률'), findsOneWidget);
    expect(find.text('항목별 차이'), findsOneWidget);
    expect(find.textContaining('끌어올려요'), findsOneWidget); // 인사이트 배너
    expect(find.text('또래 통계는 예시 데이터예요'), findsNothing);
  });

  // 프로필 월소득도 이달 수입도 없으면 저축률을 계산할 수 없다(0%가 아니다).
  testWidgets('소득이 없으면 내 저축률은 — 로 보인다', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = fakeContainer(
      user: testUser,
      transactions: _FakeRepo(),
      peerStats: StubPeerData.forGroup(AgeGroup.thirties),
    );
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(container, const MaterialApp(home: ComparePage())),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('소득 대비 저축률'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  // 비교 화면은 또래 통계가 본질이라 실패하면 화면 전체가 안내로 바뀐다.
  testWidgets('또래 통계를 못 읽으면 안내 문구를 보여준다', (tester) async {
    final container = fakeContainer(
      user: testUser,
      transactions: _FakeRepo(),
      peerRepository: FailingPeerStatsRepository(),
    );
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(container, const MaterialApp(home: ComparePage())),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('또래 통계를 불러오지 못했어요'), findsOneWidget);
    expect(find.text('항목별 차이'), findsNothing);
  });

  // 또래 비교는 기본 분류(통계청 12분류)로만 이뤄진다. 커스텀 카테고리는 상위 분류에
  // 합산될 뿐 별도 항목으로 나오지 않는다.
  testWidgets('항목별 비교는 기본 카테고리 이름만 쓴다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = fakeContainer(
      user: testUser,
      transactions: _CustomRepo(),
      peerStats: StubPeerData.forGroup(AgeGroup.thirties),
    );

    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(container, const MaterialApp(home: ComparePage())),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('반려동물'), findsNothing);
    expect(find.text(BudgetCategory.etc.label), findsOneWidget);
  });
}

/// 지출 전액이 커스텀 카테고리('반려동물' → 기타)로 잡힌 달.
class _CustomRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<Transaction>> delete(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async => Result.success([
        Transaction.create(amount: 300000, categoryId: 12, date: DateTime(y, m, 5),
            type: TransactionType.expense, customCategoryId: 'c1'),
      ]);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}
