import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/repository/transaction_repository.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/budget_home.page.dart';

import '../../helper/fakes.dart';

class _FakeRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<Transaction>> delete(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async => Result.success([
        Transaction.create(amount: 12000, categoryId: 7, date: DateTime(y, m, 10),
            type: TransactionType.expense, memo: '택시'),
      ]);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  testWidgets('shows total expense and a transaction', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 홈 테스트를 또래/프로필 의존에서 격리(고정 30대 Stub 수치).
    final container = fakeContainer(
      user: testUser,
      profile: const UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000),
      transactions: _FakeRepo(),
      peerStats: StubPeerData.forGroup(AgeGroup.thirties),
    );
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(container, MaterialApp(home: const BudgetHomePage())),
    ));
    // DefaultLayout always renders a perpetually-animating loading Lottie
    // (opacity 0 when not loading), so pumpAndSettle never settles. Pump a
    // couple of frames to let the async provider resolve to data instead.
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('12,000'), findsWidgets);
    expect(find.text('택시'), findsOneWidget); // memo is the tile title (design)

    // 디자인 카드 4종 + 최근 내역
    expect(find.text('이번 달 요약'), findsOneWidget);
    expect(find.text('또래 중 내 지출 순위'), findsOneWidget);
    expect(find.text('많이 쓴 카테고리'), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(7).label), findsWidgets);
    expect(find.text('최근 내역'), findsOneWidget);
  });

  // 내역 화면과 같은 거래가 홈에서만 기본 분류 이름으로 보이던 문제.
  testWidgets('최근 내역은 사용자 카테고리 이름으로 보인다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = fakeContainer(
      user: testUser,
      profile: const UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000),
      transactions: _PetRepo(),
      categories: InMemoryCategoryRepository(
          const [CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12)]),
      peerStats: StubPeerData.forGroup(AgeGroup.thirties),
    );
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: fakeScope(container, MaterialApp(home: const BudgetHomePage())),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('반려동물'), findsWidgets);
  });

  // 또래 통계 서버가 내려가도 내 장부는 보여야 한다(또래 부분만 빠진다).
  testWidgets('또래 통계를 못 읽어도 내 지출과 최근 내역은 보인다', (tester) async {
    await _pumpHome(tester, fakeContainer(
      user: testUser,
      profile: const UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000),
      transactions: _FakeRepo(),
      peerRepository: FailingPeerStatsRepository(),
    ));

    expect(find.text('택시'), findsOneWidget);
    expect(find.textContaining('12,000'), findsWidgets);
    expect(find.text('많이 쓴 카테고리'), findsOneWidget);
    expect(find.text('또래 통계를 불러오지 못했어요'), findsOneWidget);
    expect(find.text('또래 중 내 지출 순위'), findsNothing);
    // 저축률은 내 값이라 남고, 또래 평균 문구만 빠진다.
    expect(find.textContaining('이번 달 저축률'), findsOneWidget);
    expect(find.textContaining('또래 평균'), findsNothing);
  });

  // 소득(프로필 월소득·이달 수입)이 없으면 저축률을 계산할 수 없다.
  testWidgets('소득이 없으면 저축률 카드를 보이지 않는다', (tester) async {
    await _pumpHome(tester, fakeContainer(
      user: testUser,
      profile: const UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 0),
      transactions: _FakeRepo(),
      peerStats: StubPeerData.forGroup(AgeGroup.thirties),
    ));

    expect(find.text('택시'), findsOneWidget);
    expect(find.textContaining('이번 달 저축률'), findsNothing);
  });
}

Future<void> _pumpHome(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(provider.ChangeNotifierProvider(
    create: (_) => ThemeService(),
    child: fakeScope(container, MaterialApp(home: const BudgetHomePage())),
  ));
  await tester.pump();
  await tester.pump();
}

/// 이달 지출 한 건이 사용자 카테고리('반려동물' → 기타)로 잡힌 달.
class _PetRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<Transaction>> delete(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async => Result.success([
        Transaction.create(amount: 30000, categoryId: 12, date: DateTime(y, m, 3),
            type: TransactionType.expense, customCategoryId: 'c1'),
      ]);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}
