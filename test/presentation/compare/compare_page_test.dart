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

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

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
