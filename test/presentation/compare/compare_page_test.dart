import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/data/peer/mock_peer_stats_source.dart';
import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/compare/compare.page.dart';
import 'package:sedae_budget/presentation/page/compare/peer_provider.dart';

class _FakeRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async => Result.success([
        Transaction.create(amount: 500000, categoryId: 1, date: DateTime(y, m, 5),
            type: TransactionType.expense, memo: '식료품'),
        Transaction.create(amount: 200000, categoryId: 7, date: DateTime(y, m, 10),
            type: TransactionType.expense, memo: '교통'),
        Transaction.create(amount: 100000, categoryId: 11, date: DateTime(y, m, 15),
            type: TransactionType.expense, memo: '외식'),
      ]);
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  testWidgets('compare page renders battle rows and rank card', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: ProviderScope(
        overrides: [
          transactionUsecaseProvider.overrideWithValue(TransactionUsecase(_FakeRepo())),
          peerStatsProvider.overrideWithValue(MockPeerStatsSource().forGroup(AgeGroup.thirties)),
        ],
        child: const MaterialApp(home: ComparePage()),
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('또래와 비교'), findsOneWidget);
    expect(find.text('또래'), findsWidgets); // battle bar labels
    expect(find.text('나'), findsWidgets);   // battle bar labels + histogram
    expect(find.textContaining('등'), findsWidgets); // rank card
  });
}
