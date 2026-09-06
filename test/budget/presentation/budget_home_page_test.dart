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
import 'package:sedae_budget/presentation/page/budget/budget_home.page.dart';
import 'package:sedae_budget/presentation/page/compare/peer_provider.dart';

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
  setUp(() {
    locator.registerSingleton<TransactionUsecase>(TransactionUsecase(_FakeRepo()));
    registerFakeUserDependencies(
      profile: const UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000),
    );
  });
  tearDown(() => locator.reset());

  testWidgets('shows total expense and a transaction', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stats = StubPeerData.forGroup(AgeGroup.thirties);
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: ProviderScope(
        overrides: [
          // 홈 테스트를 또래/프로필 의존에서 격리(고정 30대 Stub 수치).
          peerStatsProvider.overrideWith((_) => stats),
        ],
        child: MaterialApp(home: const BudgetHomePage()),
      ),
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
}
