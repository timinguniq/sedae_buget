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
import 'package:sedae_budget/presentation/page/compare/peer_provider.dart';
import 'package:sedae_budget/presentation/page/report/report.page.dart';
import 'package:sedae_budget/presentation/presentation.dart';

import '../../helper/fakes.dart';

class _FakeRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);

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
  setUp(() {
    locator.registerSingleton<TransactionUsecase>(TransactionUsecase(_FakeRepo()));
    registerFakePeerDependencies();
    registerFakeUserDependencies();
  });
  tearDown(() => locator.reset());

  testWidgets('report page renders insight, stats, and section headers',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stats = StubPeerData.forGroup(AgeGroup.thirties);
    await tester.pumpWidget(
      provider.ChangeNotifierProvider(
        create: (_) => ThemeService(),
        child: ProviderScope(
          overrides: [
            peerStatsProvider.overrideWith((_) => stats),
          ],
          child: MaterialApp(
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
    expect(find.textContaining('저축률'), findsWidgets);
    expect(find.textContaining('세대별'), findsOneWidget);
    expect(find.textContaining('또래보다'), findsWidgets);
  });
}
