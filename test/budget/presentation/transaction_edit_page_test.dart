import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/ledger.view_model.dart';
import 'package:sedae_budget/presentation/page/budget/transaction_edit.page.dart';

import '../../helper/fakes.dart';

const _pet = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12);

/// 서버에 저장된 이번 달 거래(새 초안의 날짜는 오늘이다).
Future<List<Transaction>> _onServer(WidgetTester tester, StubServer server) async {
  final now = DateTime.now();
  return (await tester.untilDone(server.transactions.getRange(YearMonth.of(now).start, YearMonth.of(now).end))).unwrap();
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  // Pushes TransactionEditPage onto a real GoRouter stack so the page's
  // context.pop() (go_router) has somewhere to pop back to. Phone-sized
  // viewport keeps the keypad + save button on-screen.
  Future<StubServer> pumpEditPage(
    WidgetTester tester, {
    List<CustomCategory> customs = const [],
    void Function(ServerFaults faults)? faults,
    Transaction? existing,
    bool lastMonth = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final server = await tester.seedServer(categories: customs);
    faults?.call(server.faults);
    final container = fakeContainer(server: server);
    if (lastMonth) container.read(selectedMonthProvider.notifier).prev();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: SizedBox.shrink())),
        GoRoute(path: '/edit', builder: (_, _) => TransactionEditPage(existing: existing)),
      ],
    );
    await tester.pumpWidget(
      fakeScope(container, MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();
    router.push('/edit');
    await tester.settle();
    return server;
  }

  testWidgets('keypad entry saves amount', (tester) async {
    final server = await pumpEditPage(tester);
    expect(find.text('저장하기'), findsOneWidget);
    expect(find.text('₩0'), findsOneWidget);
    for (final k in ['1', '2', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.settle();
    expect((await _onServer(tester, server)).single.amount, 12000);
  });

  // 이전에는 저장 실패를 삼키고 화면을 닫아, 사용자가 저장된 줄 알았다.
  testWidgets('저장이 실패하면 화면을 닫지 않고 이유를 보여준다', (tester) async {
    await pumpEditPage(tester, faults: (f) => f.fail('PUT', '/v1/transactions'));
    for (final k in ['1', '2', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.settle(); // SnackBar 등장

    expect(find.byType(TransactionEditPage), findsOneWidget);
    expect(find.text('저장하지 못했어요. 인터넷에 연결되어 있지 않아요'), findsOneWidget);
  });

  // 첫 저장이 끝나기 전에 다시 누르면 거래가 두 번 저장됐다.
  testWidgets('저장 중에 다시 눌러도 한 번만 저장한다', (tester) async {
    final server = await pumpEditPage(tester);
    final reply = server.faults.hold('PUT', '/v1/transactions');
    for (final k in ['1', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pump();

    reply.complete();
    await tester.settle();
    expect(server.faults.count('PUT', '/v1/transactions'), 1);
    expect(find.byType(TransactionEditPage), findsNothing);
  });

  // 디자인: 입력 화면은 지출만 적는다(소득은 프로필 월소득). 지출/수입 토글 대신 제목이 있다.
  group('제목', () {
    testWidgets('새 거래는 지출 입력이고 지출/수입을 고르지 않는다', (tester) async {
      await pumpEditPage(tester);
      expect(find.text('지출 입력'), findsOneWidget);
      expect(find.text('수입'), findsNothing);
      expect(find.byKey(const Key('category-add-chip')), findsOneWidget);
      expect(find.byKey(const Key('delete-button')), findsNothing);
    });

    testWidgets('지출을 고치면 지출 수정이고 지울 수 있다', (tester) async {
      await pumpEditPage(tester, existing: Transaction.create(
          amount: 1000, categoryId: 1, date: DateTime.now(), type: TransactionType.expense));
      expect(find.text('지출 수정'), findsOneWidget);
      expect(find.byKey(const Key('delete-button')), findsOneWidget);
    });

    // 전에 적은 수입은 남아 있으니 고칠 수 있어야 한다. 수입은 카테고리가 없다
    // (이전에는 수입에도 지출 카테고리 칩을 보여 월급이 '식료품'으로 저장됐다).
    testWidgets('수입을 고치면 수입 수정이고 카테고리를 고르지 않는다', (tester) async {
      await pumpEditPage(tester, customs: const [_pet], existing: Transaction.create(
          amount: 3000000, categoryId: 1, date: DateTime.now(), type: TransactionType.income));
      expect(find.text('수입 수정'), findsOneWidget);
      expect(find.byKey(const Key('category-add-chip')), findsNothing);
      expect(find.text('반려동물'), findsNothing);
      expect(find.text(BudgetCategory.transport.label), findsNothing);
    });
  });

  testWidgets('zero amount is blocked', (tester) async {
    final server = await pumpEditPage(tester);
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.settle();
    expect(server.faults.count('PUT', '/v1/transactions'), 0);
  });

  // 커스텀 카테고리를 고르면 상위 기본 분류가 함께 저장돼 또래 비교 집계가 유지된다.
  testWidgets('custom category chip stores base id + customCategoryId', (tester) async {
    final server = await pumpEditPage(tester, customs: const [_pet]);

    await tester.ensureVisible(find.text('반려동물')); // 가로 스크롤 칩 행 끝
    await tester.tap(find.text('반려동물'));
    await tester.pump();
    for (final k in ['1', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.settle();

    final saved = (await _onServer(tester, server)).single;
    expect(saved.customCategoryId, 'c1');
    expect(saved.categoryId, BudgetCategory.etc.id);
  });

  // 추가 칩 → 시트에서 만든 카테고리가 곧바로 이 거래에 선택돼야 한다.
  testWidgets('추가 칩으로 만든 카테고리가 바로 선택된다', (tester) async {
    final server = await pumpEditPage(tester);

    await tester.ensureVisible(find.byKey(const Key('category-add-chip'))); // 가로 스크롤 칩 행 끝
    await tester.tap(find.byKey(const Key('category-add-chip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('카테고리 추가'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('category-name-field')), '반려동물');
    await tester.pump();
    await tester.tap(find.byKey(const Key('category-submit-button')));
    await tester.settle();

    for (final k in ['1', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.settle();

    final saved = (await _onServer(tester, server)).single;
    expect(saved.customCategoryId, isNotNull);
    expect(saved.categoryId, BudgetCategory.etc.id); // 시트 기본 상위 분류
  });

  // 이전에는 지난 달을 보며 추가해도 오늘 날짜로 저장돼, 보고 있는 목록에 나타나지 않았다.
  testWidgets('지난 달을 보며 추가하면 그 달의 거래로 저장한다', (tester) async {
    final server = await pumpEditPage(tester, lastMonth: true);
    for (final k in ['1', '0', '0', '0']) {
      await tester.tap(find.text(k));
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.settle();

    final now = DateTime.now();
    final last = DateTime(now.year, now.month - 1);
    final saved = (await tester.untilDone(server.transactions.getRange(YearMonth.of(last).start, YearMonth.of(last).end))).unwrap();
    expect(saved.single.amount, 1000);
  });

  // 이전에는 2100년까지 고를 수 있었는데, 보고 있는 달은 이번 달보다 뒤로 가지 않아
  // 미래로 적은 거래는 어느 화면에서도 다시 볼 수 없었다.
  testWidgets('날짜는 오늘까지만 고를 수 있다', (tester) async {
    await pumpEditPage(tester);
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();

    final picker = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(DateUtils.isSameDay(picker.lastDate, DateTime.now()), isTrue);
  });

  // 이전에는 첫 날짜가 2020년으로 박혀 있어 그보다 이른 거래의 날짜를 누르면 assert로 멈췄다.
  testWidgets('2020년보다 이른 거래도 날짜를 고를 수 있다', (tester) async {
    final old = Transaction.create(
        amount: 1000, categoryId: 1, date: DateTime(2019, 12, 27), type: TransactionType.expense);
    await pumpEditPage(tester, existing: old);
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();

    final picker = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(picker.firstDate, DateTime(2019, 12, 27));
  });

  testWidgets('메모 필드는 전역 inputDecorationTheme의 outline 테두리를 받지 않는다', (tester) async {
    await pumpEditPage(tester);
    final memo = tester.widget<TextField>(
        find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == '메모 (선택)'));
    expect(memo.decoration?.enabledBorder, InputBorder.none);
    expect(memo.decoration?.focusedBorder, InputBorder.none);
  });
}
