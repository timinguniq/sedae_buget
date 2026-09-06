import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/budget/transaction_repository.dart';
import 'package:sedae_budget/domain/budget/transaction_usecase.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/category_manage.page.dart';
import 'package:sedae_budget/presentation/page/budget/widget/category_edit_sheet.dart';

import '../../helper/fakes.dart';

class _Repo implements TransactionRepository {
  @override
  Future<Result<Transaction>> upsert(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<Transaction>> delete(Transaction tx) async => Result.success(tx);
  @override
  Future<Result<List<Transaction>>> getMonth(int y, int m) async => const Result.success([]);
  @override
  Future<Result<List<Transaction>>> getRange(DateTime s, DateTime e) async =>
      const Result.success([]);
}

const _pet = CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12);

Future<InMemoryCategoryRepository> pumpPage(
  WidgetTester tester, {
  bool editing = false,
  List<CustomCategory> customs = const [_pet],
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  locator.registerSingleton<TransactionUsecase>(TransactionUsecase(_Repo()));
  final repo = registerFakeCategoryDependencies(customs);
  // 페이지의 닫기 버튼과 CDialog가 go_router의 context.pop을 쓰므로 실제 라우터 위에 띄운다.
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: SizedBox.shrink())),
      GoRoute(path: '/manage', builder: (_, _) => CategoryManagePage(initialEditing: editing)),
    ],
  );
  await tester.pumpWidget(provider.ChangeNotifierProvider(
    create: (_) => ThemeService(),
    child: ProviderScope(child: MaterialApp.router(routerConfig: router)),
  ));
  await tester.pump();
  router.push('/manage');
  // DefaultLayout이 계속 도는 Lottie를 띄워 pumpAndSettle은 끝나지 않는다.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return repo;
}

void main() {
  tearDown(() => locator.reset());

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
    final repo = await pumpPage(tester, editing: true);

    await tester.tap(find.byKey(const Key('category-delete-c1')));
    await tester.pump();
    expect(find.text('카테고리를 지울까요?'), findsOneWidget);
    await tester.tap(find.text('삭제'));
    await tester.pump();
    await tester.pump();

    expect(repo.items, isEmpty);
    expect(find.text('반려동물'), findsNothing);
  });

  testWidgets('추가 버튼 → 시트에서 이름 입력 후 저장하면 서버에 올라간다', (tester) async {
    final repo = await pumpPage(tester, customs: const []);

    expect(find.text('내 카테고리 0'), findsOneWidget);
    await tester.tap(find.byKey(const Key('category-add-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CategoryEditSheet), findsOneWidget);
    await tester.enterText(find.byKey(const Key('category-name-field')), '반려동물');
    await tester.pump();
    // 상위 카테고리 기본값은 '기타'
    await tester.tap(find.byKey(const Key('category-submit-button')));
    await tester.pump();
    await tester.pump();

    expect(repo.items.values.single.name, '반려동물');
    expect(repo.items.values.single.base, BudgetCategory.etc);
  });
}
