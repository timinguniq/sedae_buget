import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/category_manage.page.dart';
import 'package:sedae_budget/presentation/page/budget/widget/category_edit_sheet.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

const _pet = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12);

/// 이번 달 5일.
DateTime _day() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 5);
}

/// [customs]·[month]를 심은 서버로 카테고리 관리 화면을 띄우고 그 서버를 돌려준다.
Future<StubServer> pumpPage(
  WidgetTester tester, {
  bool editing = false,
  List<CustomCategory> customs = const [_pet],
  List<Transaction> month = const [],
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final server = await tester.seedServer(categories: customs, transactions: month);
  final container = fakeContainer(server: server);
  // 페이지의 닫기 버튼과 CDialog가 go_router의 context.pop을 쓰므로 실제 라우터 위에 띄운다.
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: SizedBox.shrink())),
      GoRoute(path: '/manage', builder: (_, _) => CategoryManagePage(initialEditing: editing)),
    ],
  );
  await tester.pumpWidget(fakeScope(container, MaterialApp.router(theme: theme, routerConfig: router)));
  await tester.pump();
  router.push('/manage');
  await tester.settle();
  return server;
}

/// 서버에 있는 사용자 카테고리.
Future<List<CustomCategory>> _onServer(WidgetTester tester, StubServer server) async =>
    (await tester.untilDone(server.categories.getAll())).unwrap();

void main() {

  testWidgets('view mode: 안내 카드 + 기본 12개 + 내 카테고리, 편집 링크로 편집 모드 전환', (tester) async {
    await pumpPage(tester);

    expect(find.text('카테고리 관리'), findsOneWidget);
    expect(find.textContaining('또래 비교 통계의 기준'), findsOneWidget);
    expect(find.text('기본 카테고리 ${BudgetCategory.values.length}'), findsOneWidget);
    expect(find.text('내 카테고리 1'), findsOneWidget);
    expect(find.text('반려동물'), findsOneWidget);
    // 기본 카테고리에는 삭제 버튼이 없다.
    expect(find.byKey(const Key('category-delete-c1')), findsNothing);

    await tester.tap(find.byKey(const Key('category-edit-toggle')));
    await tester.pump();
    expect(find.text('카테고리 편집'), findsOneWidget);
    expect(find.text('수정 · 삭제 불가'), findsOneWidget);
  });

  // 분석 화면과 같은 기준: 사용자 카테고리로 분리된 거래는 기본 분류 건수에서 뺀다.
  // (지워진 카테고리를 가리키는 거래를 기본 분류로 세는 규칙은 ViewedMonth 테스트가 본다.)
  testWidgets('기본 카테고리 건수는 사용자 카테고리 거래를 빼고 센다', (tester) async {
    Transaction tx({String? customCategoryId}) => Transaction.create(
          amount: 1000, categoryId: BudgetCategory.etc.id, date: _day(),
          type: TransactionType.expense, customCategoryId: customCategoryId);
    await pumpPage(tester, month: [
      tx(),
      tx(),
      tx(customCategoryId: 'c1'), // 반려동물 → 따로 센다
    ]);

    expect(find.text('2건'), findsOneWidget);
  });

  // 이전에는 수입(기본값 식료품)이 식료품 건수에 섞였다.
  testWidgets('기본 카테고리 건수에 수입은 세지 않는다', (tester) async {
    Transaction tx(TransactionType type) => Transaction.create(
          amount: 1000, categoryId: BudgetCategory.food.id, date: _day(), type: type);
    await pumpPage(tester, month: [tx(TransactionType.expense), tx(TransactionType.income)]);

    expect(find.text('1건'), findsOneWidget);
    expect(find.text('2건'), findsNothing);
  });

  testWidgets('편집 모드: 내 카테고리만 삭제 버튼을 갖는다', (tester) async {
    await pumpPage(tester, editing: true);

    expect(find.text('카테고리 편집'), findsOneWidget);
    expect(find.byKey(const Key('category-delete-c1')), findsOneWidget);
    // 기본 분류 12개 중 어느 것에도 삭제 버튼이 붙지 않는다(총 1개뿐).
    expect(find.byIcon(Icons.remove), findsOneWidget);

    await tester.tap(find.byKey(const Key('category-edit-done')));
    await tester.pump();
    expect(find.text('카테고리 관리'), findsOneWidget);
  });

  testWidgets('삭제 확인 후 서버에서 지워진다', (tester) async {
    final server = await pumpPage(tester, editing: true);

    await tester.tap(find.byKey(const Key('category-delete-c1')));
    await tester.pump();
    expect(find.text('카테고리를 지울까요?'), findsOneWidget);
    await tester.tap(find.text('삭제'));
    await tester.settle();

    expect(await _onServer(tester, server), isEmpty);
    expect(find.text('반려동물'), findsNothing);
  });

  testWidgets('추가 버튼 → 시트에서 이름 입력 후 저장하면 서버에 올라간다', (tester) async {
    final server = await pumpPage(tester, customs: const []);

    expect(find.text('내 카테고리 0'), findsOneWidget);
    await tester.tap(find.byKey(const Key('category-add-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CategoryEditSheet), findsOneWidget);
    await tester.enterText(find.byKey(const Key('category-name-field')), '반려동물');
    await tester.pump();
    // 상위 카테고리 기본값은 '기타'
    await tester.tap(find.byKey(const Key('category-submit-button')));
    await tester.settle();

    final saved = (await _onServer(tester, server)).single;
    expect(saved.name, '반려동물');
    expect(saved.base, BudgetCategory.etc);
  });

  // 사용자가 고칠 수 있는 실패라 서버 문구를 이유로 보여준다.
  testWidgets('이름이 겹치면 시트에 이유를 보여주고 닫지 않는다', (tester) async {
    await pumpPage(tester); // 서버에 이미 '반려동물'이 있다

    await tester.tap(find.byKey(const Key('category-add-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const Key('category-name-field')), '반려동물');
    await tester.pump();
    await tester.tap(find.byKey(const Key('category-submit-button')));
    await tester.settle();

    expect(find.text('저장하지 못했어요. 이미 있는 이름입니다: 반려동물'), findsOneWidget);
    expect(find.byType(CategoryEditSheet), findsOneWidget);
  });

  testWidgets('다크 모드에서 안내 카드 배경은 라이트용 잉크색이 아니라 sunken surface다', (tester) async {
    await pumpPage(tester, theme: ThemeData(brightness: Brightness.dark));
    final card = tester.widget<Container>(find
        .ancestor(of: find.textContaining('또래 비교 통계의 기준'), matching: find.byType(Container))
        .first);
    expect((card.decoration as BoxDecoration).color, Palette.darkSurfaceSunken);
  });
}
