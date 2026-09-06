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
  Future<_CapturingRepo> pumpEditPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = _CapturingRepo();
    locator.registerSingleton<TransactionUsecase>(TransactionUsecase(repo));
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
}
