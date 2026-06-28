import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/transaction_list.page.dart';
import 'package:sedae_budget/presentation/page/budget/widget/transaction_tile.dart';

class _FakeRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async => Result.success([
        Transaction.create(
            amount: 5000, categoryId: 7, date: DateTime(2026, 6, 5),
            type: TransactionType.expense),
      ]);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));
  testWidgets('renders a TransactionTile for each transaction', (tester) async {
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: ProviderScope(
        overrides: [transactionUsecaseProvider.overrideWithValue(TransactionUsecase(_FakeRepo()))],
        child: MaterialApp(home: const TransactionListPage()),
      ),
    ));
    // DefaultLayout mounts a perpetual Lottie, so pumpAndSettle never settles.
    await tester.pump();
    await tester.pump();
    expect(find.byType(TransactionTile), findsOneWidget);
  });
}
