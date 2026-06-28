import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';
import 'package:sedae_budget/presentation/page/budget/category_analysis.page.dart';
import 'package:sedae_budget/presentation/page/budget/widget/category_row.dart';

class _Repo implements TransactionRepository {
  _Repo(this._list);
  final List<Transaction> _list;
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async => Result.success(_list);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}

Widget _app(List<Transaction> list) => provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: ProviderScope(
        overrides: [transactionUsecaseProvider.overrideWithValue(TransactionUsecase(_Repo(list)))],
        child: const MaterialApp(home: CategoryAnalysisPage()),
      ),
    );

void main() {
  testWidgets('shows donut + rows when data', (tester) async {
    await tester.pumpWidget(_app([
      Transaction.create(amount: 10000, categoryId: 7, date: DateTime(2026, 6, 5), type: TransactionType.expense),
      Transaction.create(amount: 4000, categoryId: 11, date: DateTime(2026, 6, 6), type: TransactionType.expense),
    ]));
    await tester.pump();
    await tester.pump();
    expect(find.byType(CategoryDonut), findsOneWidget);
    expect(find.byType(CategoryRow), findsWidgets);
  });

  testWidgets('shows empty state when no expenses', (tester) async {
    await tester.pumpWidget(_app(const []));
    await tester.pump();
    await tester.pump();
    expect(find.text('지출이 없어요'), findsOneWidget);
  });
}
