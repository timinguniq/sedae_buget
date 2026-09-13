import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/transaction_edit.page.dart';

import '../../helper/fakes.dart';

class _CapturingRepo implements TransactionRepository {
  Transaction? saved;
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async { saved = tx; return Result.success(tx); }
  @override
  Future<Result<Transaction>> delete(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async => const Result.success([]);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime start, DateTime end) async =>
      const Result.success([]);
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));
  tearDown(() => locator.reset());

  // Pushes TransactionEditPage onto a real GoRouter stack so the page's
  // context.pop() (go_router) has somewhere to pop back to. Phone-sized
  // viewport keeps the keypad + save button on-screen. DefaultLayout mounts a
  // perpetual Lottie, so we pump fixed durations instead of pumpAndSettle.
  Future<_CapturingRepo> pumpEditPage(
    WidgetTester tester, {
    List<CustomCategory> customs = const [],
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _CapturingRepo();
    locator.registerSingleton<TransactionUsecase>(TransactionUsecase(repo));
    registerFakeCategoryDependencies(customs);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: SizedBox.shrink())),
        GoRoute(path: '/edit', builder: (_, _) => const TransactionEditPage()),
      ],
    );
    await tester.pumpWidget(
      provider.ChangeNotifierProvider(
        create: (_) => ThemeService(),
        child: ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pump();
    router.push('/edit');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return repo;
  }

  testWidgets('keypad entry saves amount', (tester) async {
    final repo = await pumpEditPage(tester);
    expect(find.text('저장하기'), findsOneWidget);
    expect(find.text('₩0'), findsOneWidget);
    for (final k in ['1', '2', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pump();
    await tester.pump();
    expect(repo.saved?.amount, 12000);
  });

  testWidgets('zero amount is blocked', (tester) async {
    final repo = await pumpEditPage(tester);
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pump();
    await tester.pump();
    expect(repo.saved, isNull);
  });

  // 커스텀 카테고리를 고르면 상위 기본 분류가 함께 저장돼 또래 비교 집계가 유지된다.
  testWidgets('custom category chip stores base id + customCategoryId', (tester) async {
    final repo = await pumpEditPage(tester,
        customs: const [CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12)]);

    await tester.ensureVisible(find.text('반려동물')); // 가로 스크롤 칩 행 끝
    await tester.tap(find.text('반려동물'));
    await tester.pump();
    for (final k in ['1', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pump();
    await tester.pump();

    expect(repo.saved?.customCategoryId, 'c1');
    expect(repo.saved?.categoryId, BudgetCategory.etc.id);
  });

  // 추가 칩 → 시트에서 만든 카테고리가 곧바로 이 거래에 선택돼야 한다.
  testWidgets('추가 칩으로 만든 카테고리가 바로 선택된다', (tester) async {
    final repo = await pumpEditPage(tester);

    await tester.ensureVisible(find.byKey(const Key('category-add-chip'))); // 가로 스크롤 칩 행 끝
    await tester.tap(find.byKey(const Key('category-add-chip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('카테고리 추가'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('category-name-field')), '반려동물');
    await tester.pump();
    await tester.tap(find.byKey(const Key('category-submit-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    for (final k in ['1', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pump();
    await tester.pump();

    expect(repo.saved?.customCategoryId, isNotNull);
    expect(repo.saved?.categoryId, BudgetCategory.etc.id); // 시트 기본 상위 분류
  });

  testWidgets('메모 필드는 전역 inputDecorationTheme의 outline 테두리를 받지 않는다', (tester) async {
    await pumpEditPage(tester);
    final memo = tester.widget<TextField>(
        find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == '메모 (선택)'));
    expect(memo.decoration?.enabledBorder, InputBorder.none);
    expect(memo.decoration?.focusedBorder, InputBorder.none);
  });
}
