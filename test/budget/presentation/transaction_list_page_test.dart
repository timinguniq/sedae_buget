import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/transaction_list.page.dart';
import 'package:sedae_budget/presentation/page/budget/widget/transaction_tile.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

class _FakeRepo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<Transaction>> delete(Transaction tx) async => Result.success(tx);
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
  setUp(() {
    locator.registerSingleton<TransactionUsecase>(TransactionUsecase(_FakeRepo()));
    registerFakePeerDependencies();
    registerFakeCategoryDependencies();
  });
  tearDown(() => locator.reset());

  testWidgets('renders a TransactionTile for each transaction', (tester) async {
    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: ProviderScope(
        child: MaterialApp(home: const TransactionListPage()),
      ),
    ));
    // DefaultLayout mounts a perpetual Lottie, so pumpAndSettle never settles.
    await tester.pump();
    await tester.pump();
    expect(find.byType(TransactionTile), findsOneWidget);
  });

  testWidgets('shows month header, summary line, date group header and filter chips', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: ProviderScope(
        child: MaterialApp(home: const TransactionListPage()),
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('내역'), findsOneWidget);
    expect(find.byKey(const Key('month-chip')), findsOneWidget);
    expect(find.text('이번 달 5,000원 · 1건'), findsOneWidget);
    expect(find.text('6월 5일'), findsOneWidget); // 날짜 그룹 헤더(오늘/어제 아님)
    expect(find.text('전체'), findsOneWidget);

    // 카테고리 필터 칩(이달 지출 상위 카테고리)을 누르면 그 카테고리만 남는다.
    final label = BudgetCategory.fromId(7).label;
    expect(find.byType(DesignChip), findsNWidgets(2));
    await tester.tap(find.widgetWithText(DesignChip, label));
    await tester.pump();
    expect(find.byType(TransactionTile), findsOneWidget);
  });

  test('dateGroupLabel: 오늘 / 어제 / M월 D일', () {
    final now = DateTime(2026, 6, 27, 15);
    expect(dateGroupLabel(DateTime(2026, 6, 27), now: now), '오늘 · 6월 27일');
    expect(dateGroupLabel(DateTime(2026, 6, 26), now: now), '어제 · 6월 26일');
    expect(dateGroupLabel(DateTime(2026, 6, 25), now: now), '6월 25일');
  });
}
