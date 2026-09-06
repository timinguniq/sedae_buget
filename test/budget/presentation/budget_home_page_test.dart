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

class _FakeRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
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
  setUp(() =>
      locator.registerSingleton<TransactionUsecase>(TransactionUsecase(_FakeRepo())));
  tearDown(() => locator.reset());

  testWidgets('shows total expense and a transaction', (tester) async {
    final stats = await MockPeerStatsRepository().forGroup(AgeGroup.thirties);
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: ProviderScope(
        overrides: [
          // 홈 테스트를 또래/프로필/SharedPreferences 의존에서 격리(고정 30대 목업).
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
    expect(find.text('택시'), findsNothing); // memo shown in subtitle via textContaining
    expect(find.textContaining('택시'), findsOneWidget);
  });
}
