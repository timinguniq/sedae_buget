import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/compare/compare.page.dart';
import 'package:sedae_budget/presentation/page/compare/peer_provider.dart';

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
  setUp(() {
    locator.registerSingleton<TransactionUsecase>(TransactionUsecase(_FakeRepo()));
    registerFakeUserDependencies(); // 저축률 카드가 프로필 소득을 읽는다
  });
  tearDown(() => locator.reset());

  testWidgets('compare page renders rank headline, versus cards and battle rows', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stats = StubPeerData.forGroup(AgeGroup.thirties);
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: ProviderScope(
        overrides: [
          peerStatsProvider.overrideWith((_) => stats),
        ],
        child: const MaterialApp(home: ComparePage()),
      ),
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

  // 또래 비교는 기본 분류(통계청 12분류)로만 이뤄진다. 커스텀 카테고리는 상위 분류에
  // 합산될 뿐 별도 항목으로 나오지 않는다.
  testWidgets('항목별 비교는 기본 카테고리 이름만 쓴다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    locator.unregister<TransactionUsecase>();
    locator.registerSingleton<TransactionUsecase>(TransactionUsecase(_CustomRepo()));

    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: ProviderScope(
        overrides: [
          peerStatsProvider.overrideWith((_) => StubPeerData.forGroup(AgeGroup.thirties)),
        ],
        child: const MaterialApp(home: ComparePage()),
      ),
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
