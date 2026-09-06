import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/budget/category_repository.dart';
import 'package:sedae_budget/domain/budget/category_usecase.dart';
import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';
import 'package:sedae_budget/presentation/page/budget/category_analysis.page.dart';
import 'package:sedae_budget/presentation/page/budget/widget/category_row.dart';

import '../../helper/fakes.dart';

class _Repo implements TransactionRepository {
  _Repo(this._list);
  final List<Transaction> _list;
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<Transaction>> delete(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async => Result.success(_list);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}

/// 카테고리 목록 조회가 실패하는 저장소(네트워크 오류 시나리오).
class _FailingCategoryRepo implements CategoryRepository {
  @override
  Future<Result<List<CustomCategory>>> getAll() async =>
      Result.failure(ErrorResult(resultCode: 'NETWORK_ERROR', message: '네트워크에 연결할 수 없습니다.'));
  @override
  Future<Result<CustomCategory>> upsert(CustomCategory c) async => Result.success(c);
  @override
  Future<Result<CustomCategory>> delete(CustomCategory c) async => Result.success(c);
}

Widget _app(
  List<Transaction> list, [
  List<CustomCategory> customs = const [],
  CategoryRepository? categoryRepository,
]) {
  locator.registerSingleton<TransactionUsecase>(TransactionUsecase(_Repo(list)));
  registerFakePeerDependencies();
  if (categoryRepository == null) {
    registerFakeCategoryDependencies(customs);
  } else {
    locator
      ..registerSingleton<CategoryRepository>(categoryRepository)
      ..registerSingleton<CategoryUsecase>(CategoryUsecase(categoryRepository));
  }
  return provider.ChangeNotifierProvider(
    create: (_) => ThemeService(),
    child: const ProviderScope(
      child: MaterialApp(home: CategoryAnalysisPage()),
    ),
  );
}

void main() {
  tearDown(() => locator.reset());

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

  testWidgets('custom header shows title, month total and month navigator', (tester) async {
    await tester.pumpWidget(_app([
      Transaction.create(amount: 1920000, categoryId: 7, date: DateTime(2026, 6, 5), type: TransactionType.expense),
    ]));
    await tester.pump();
    await tester.pump();
    expect(find.text('카테고리 분석'), findsOneWidget);
    expect(find.byType(RoundIconButton), findsOneWidget);
    expect(find.textContaining('총지출'), findsOneWidget);
    expect(find.text('192만'), findsOneWidget);

    final now = DateTime.now();
    String label(DateTime m) => '${m.year}.${m.month.toString().padLeft(2, '0')}';
    expect(find.text(label(DateTime(now.year, now.month))), findsOneWidget);
    await tester.tap(find.byKey(const Key('month-next')));
    await tester.pump();
    await tester.pump();
    expect(find.text(label(DateTime(now.year, now.month + 1))), findsOneWidget);
  });

  testWidgets('shows empty state when no expenses', (tester) async {
    await tester.pumpWidget(_app(const []));
    await tester.pump();
    await tester.pump();
    expect(find.text('지출이 없어요'), findsOneWidget);
  });

  // 카테고리 목록을 못 읽으면 커스텀 분리 없이 기본 분류로만 묶인다(합계는 그대로).
  testWidgets('카테고리 조회 실패해도 기본 분류로 분석 화면이 그려진다', (tester) async {
    await tester.pumpWidget(_app([
      Transaction.create(amount: 10000, categoryId: 12, date: DateTime(2026, 6, 5), type: TransactionType.expense),
      Transaction.create(amount: 20000, categoryId: 12, date: DateTime(2026, 6, 6),
          type: TransactionType.expense, customCategoryId: 'c1'),
    ], const [], _FailingCategoryRepo()));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CategoryDonut), findsOneWidget);
    // 둘 다 기타(12)로 합쳐진 한 줄.
    expect(find.byType(CategoryRow), findsOneWidget);
    expect(find.text(BudgetCategory.etc.label), findsOneWidget);
    expect(find.text('카테고리 1개'), findsOneWidget);
  });

  testWidgets('커스텀 카테고리는 별도 행으로 나오고 또래 배지는 기본 분류에만 붙는다', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app([
      Transaction.create(amount: 10000, categoryId: 12, date: DateTime(2026, 6, 5), type: TransactionType.expense),
      Transaction.create(amount: 20000, categoryId: 12, date: DateTime(2026, 6, 6),
          type: TransactionType.expense, customCategoryId: 'c1'),
    ], const [CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12)]));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CategoryRow), findsNWidgets(2));
    expect(find.text('반려동물'), findsOneWidget);
    expect(find.text('카테고리 2개'), findsOneWidget);
    expect(find.byKey(const Key('category-manage-link')), findsOneWidget);

    // 또래 비교를 켜면 기본 분류 행 하나에만 ▲/▼ 배지가 붙는다.
    await tester.tap(find.byType(Switch));
    await tester.pump();
    final badges = tester.widgetList(find.textContaining('▲')).length +
        tester.widgetList(find.textContaining('▼')).length;
    expect(badges, 1);
  });
}
