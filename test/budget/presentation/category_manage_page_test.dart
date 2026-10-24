import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/category_manage.page.dart';
import 'package:sedae_budget/presentation/page/budget/widget/category_edit_sheet.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

const _pet = CustomCategory(id: 'c1', name: '반려식물', baseCategoryId: 19);

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

final _nameField = find.byKey(const Key('category-name-field'));

/// 카테고리 관리 화면에서 추가 시트를 연다.
Future<void> _openAddSheet(WidgetTester tester) async {
  await pumpPage(tester, customs: const []);
  await tester.tap(find.byKey(const Key('category-add-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

TextEditingController _nameController(WidgetTester tester) =>
    tester.widget<TextField>(_nameField).controller!;

/// 키보드(IME)가 이름 칸에 [text]를 보낸다. [composing]은 조합 중(한글 등)인 범위.
Future<void> _imeSends(WidgetTester tester, String text, {TextRange composing = TextRange.empty}) async {
  tester.testTextInput.updateEditingValue(TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
    composing: composing,
  ));
  await tester.pump();
}

void main() {

  testWidgets('view mode: 안내 카드 + 기본 19개 + 내 카테고리, 편집 링크로 편집 모드 전환', (tester) async {
    await pumpPage(tester);

    expect(find.text('카테고리 관리'), findsOneWidget);
    expect(find.textContaining('또래 비교 통계의 기준'), findsOneWidget);
    expect(find.text('기본 카테고리 ${BudgetCategory.values.length}'), findsOneWidget);
    expect(find.text('내 카테고리 1'), findsOneWidget);
    expect(find.text('반려식물'), findsOneWidget);
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
      tx(customCategoryId: 'c1'), // 반려식물 → 따로 센다
    ]);

    expect(find.text('2건'), findsOneWidget);
  });

  // 이전에는 수입(기본값 식료품)이 식료품 건수에 섞였다.
  testWidgets('기본 카테고리 건수에 수입은 세지 않는다', (tester) async {
    Transaction tx(TransactionType type) => Transaction.create(
          amount: 1000, categoryId: BudgetCategory.groceries.id, date: _day(), type: type);
    await pumpPage(tester, month: [tx(TransactionType.expense), tx(TransactionType.income)]);

    expect(find.text('1건'), findsOneWidget);
    expect(find.text('2건'), findsNothing);
  });

  testWidgets('편집 모드: 내 카테고리만 삭제 버튼을 갖는다', (tester) async {
    await pumpPage(tester, editing: true);

    expect(find.text('카테고리 편집'), findsOneWidget);
    expect(find.byKey(const Key('category-delete-c1')), findsOneWidget);
    // 기본 분류 19개 중 어느 것에도 삭제 버튼이 붙지 않는다(총 1개뿐).
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
    expect(find.text('반려식물'), findsNothing);
  });

  testWidgets('추가 버튼 → 시트에서 이름 입력 후 저장하면 서버에 올라간다', (tester) async {
    final server = await pumpPage(tester, customs: const []);

    expect(find.text('내 카테고리 0'), findsOneWidget);
    await tester.tap(find.byKey(const Key('category-add-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CategoryEditSheet), findsOneWidget);
    await tester.enterText(find.byKey(const Key('category-name-field')), '반려식물');
    await tester.pump();
    // 상위 카테고리 기본값은 '기타'
    await tester.tap(find.byKey(const Key('category-submit-button')));
    await tester.settle();

    final saved = (await _onServer(tester, server)).single;
    expect(saved.name, '반려식물');
    expect(saved.base, BudgetCategory.etc);
  });

  // 입력 칸은 보이는 글자로 10자까지 받는다. 이전에는 글자 수를 UTF-16으로 세어 이모지 6개가 '12 / 10'이었고
  // 추가하기가 이유 없이 꺼졌다.
  testWidgets('이모지 이름도 보이는 글자로 세고 저장한다', (tester) async {
    final server = await pumpPage(tester, customs: const []);

    await tester.tap(find.byKey(const Key('category-add-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const Key('category-name-field')), '🐶' * 6);
    await tester.pump();
    expect(find.text('6 / 10'), findsOneWidget);

    await tester.tap(find.byKey(const Key('category-submit-button')));
    await tester.settle();

    expect((await _onServer(tester, server)).single.name, '🐶' * 6);
  });

  // 글자 수 표시와 입력 제한은 저장할 이름(앞뒤 공백을 뗀 것)으로 센다. 이전에는 공백까지 세어
  // 10자 이름 앞뒤에 공백이 있으면 입력이 잘렸고, ' 반려식물 '이 '6 / 10'이었다.
  testWidgets('앞뒤 공백은 글자 수에 넣지 않고, 10자 이름은 공백이 있어도 들어간다', (tester) async {
    final server = await pumpPage(tester, customs: const []);
    final field = find.byKey(const Key('category-name-field'));

    await tester.tap(find.byKey(const Key('category-add-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(field, ' 반려식물 ');
    await tester.pump();
    expect(find.text('4 / 10'), findsOneWidget);

    final spaced = '  ${'가' * 10}  ';
    await tester.enterText(field, spaced);
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, spaced);
    expect(find.text('10 / 10'), findsOneWidget);

    // 11자째는 받지 않는다.
    await tester.enterText(field, '$spaced가');
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, spaced);

    await tester.tap(find.byKey(const Key('category-submit-button')));
    await tester.settle();
    expect((await _onServer(tester, server)).single.name, '가' * 10);
  });

  // 입력 제한은 LengthLimitingTextInputFormatter와 같게 막고, 글자 수만 CategoryName으로 센다.
  // 이전에는 넘치는 입력을 통째로 거절해 붙여넣기가 아무것도 넣지 않았다.
  testWidgets('10자가 넘는 이름을 붙여 넣으면 앞 10자만 들어간다', (tester) async {
    await _openAddSheet(tester);
    await tester.enterText(_nameField, '가나다라마바사아자차카타');
    await tester.pump();
    expect(_nameController(tester).text, '가나다라마바사아자차');
    expect(find.text('10 / 10'), findsOneWidget);

    // 앞 공백은 글자 수에 넣지 않으므로 공백 뒤로 10자가 들어간다.
    await tester.enterText(_nameField, '');
    await tester.enterText(_nameField, '  가나다라마바사아자차카타');
    await tester.pump();
    expect(_nameController(tester).text, '  가나다라마바사아자차');
  }, variant: TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));

  // 고른 글자를 바꾸는 입력은 꽉 찬 칸에서도 받고 10자로 자른다(LengthLimitingTextInputFormatter와 같다).
  testWidgets('꽉 찬 이름에서 고른 글자 위에 더 긴 글을 붙여 넣으면 앞 10자만 남는다', (tester) async {
    await _openAddSheet(tester);
    await tester.enterText(_nameField, '가나다라마바사아자차');
    await tester.pump();
    _nameController(tester).selection = const TextSelection(baseOffset: 0, extentOffset: 1); // '가'를 고른다
    await tester.pump();

    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: 'XY나다라마바사아자차', selection: TextSelection.collapsed(offset: 2)));
    await tester.pump();
    expect(_nameController(tester).text, 'XY나다라마바사아자');
  });

  // 이전에는 넘친 값에서 지우는 입력도 그 전 값으로 되돌려 지울 수 없었다.
  testWidgets('이미 넘친 이름에서도 지울 수 있다', (tester) async {
    await _openAddSheet(tester);
    _nameController(tester).value = TextEditingValue(
      text: '가' * 12, selection: const TextSelection.collapsed(offset: 12)); // 입력 제한을 거치지 않은 값
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(_nameController(tester).text, '가' * 10); // 11자로 지운 뒤 10자로 자른다

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace); // 꽉 찬 이름에서도 지운다
    await tester.pump();
    expect(_nameController(tester).text, '가' * 9);
  });

  // 꽉 찬 칸에 끼워 넣은 글자가 끝 글자를 밀어내지 않는다(LengthLimitingTextInputFormatter와 같다).
  testWidgets('꽉 찬 이름 가운데에 글자를 넣으면 받지 않는다', (tester) async {
    await _openAddSheet(tester);
    await tester.enterText(_nameField, '가나다라마바사아자차');
    await tester.pump();

    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: '가나다라마X바사아자차', selection: TextSelection.collapsed(offset: 6)));
    await tester.pump();
    expect(_nameController(tester).text, '가나다라마바사아자차');
  });

  // iOS·macOS·웹은 조합(한글 등)이 끝난 뒤에 자른다(Flutter 기본). 이전에는 10자째를 조합하는 중에 친 다음 글자를
  // 거절해, 그 자음이 10자째의 받침으로 붙었다.
  testWidgets('iOS: 조합 중에는 넘쳐도 받고, 조합이 끝나면 10자로 자른다', (tester) async {
    await _openAddSheet(tester);
    final nine = '가' * 9;
    await _imeSends(tester, '$nine간', composing: const TextRange(start: 9, end: 10)); // 10자째 조합 중
    await _imeSends(tester, '$nine가나', composing: const TextRange(start: 10, end: 11)); // 'ㅏ' → '가나'
    expect(_nameController(tester).text, '$nine가나');

    await _imeSends(tester, '$nine가나'); // 조합이 끝났다
    expect(_nameController(tester).text, '$nine가');

    // 꽉 찬 칸에서는 새 조합을 시작하지 않는다.
    await _imeSends(tester, '$nine가ㄴ', composing: const TextRange(start: 10, end: 11));
    expect(_nameController(tester).text, '$nine가');
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  // Android는 조합을 IME가 맡으므로 조합 중이어도 바로 자른다(Flutter 기본, 이전 동작).
  testWidgets('Android: 조합 중이어도 넘치면 바로 자른다', (tester) async {
    await _openAddSheet(tester);
    final nine = '가' * 9;
    await _imeSends(tester, nine);
    await _imeSends(tester, '$nineにほ', composing: const TextRange(start: 9, end: 11));
    expect(_nameController(tester).value.text, '$nineに');
    expect(_nameController(tester).value.composing, const TextRange(start: 9, end: 10));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  // 서버는 저장했는데 응답을 잃었다. 다시 누르면 같은 카테고리로 저장돼 이름이 겹친다고 막히지 않는다.
  testWidgets('응답을 잃은 뒤 다시 누르면 카테고리 하나로 저장하고 닫힌다', (tester) async {
    final server = await pumpPage(tester, customs: const []);
    server.faults.loseResponse('PUT', '/v1/categories');

    await tester.tap(find.byKey(const Key('category-add-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const Key('category-name-field')), '반려식물');
    await tester.pump();
    await tester.tap(find.byKey(const Key('category-submit-button')));
    await tester.settle();
    expect(find.byType(CategoryEditSheet), findsOneWidget);

    await tester.tap(find.byKey(const Key('category-submit-button')));
    await tester.settle();

    expect(find.byType(CategoryEditSheet), findsNothing);
    expect((await _onServer(tester, server)).map((c) => c.name), ['반려식물']);
  });

  // 사용자가 고칠 수 있는 실패라 서버 문구를 이유로 보여준다.
  testWidgets('이름이 겹치면 시트에 이유를 보여주고 닫지 않는다', (tester) async {
    await pumpPage(tester); // 서버에 이미 '반려식물'이 있다

    await tester.tap(find.byKey(const Key('category-add-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const Key('category-name-field')), '반려식물');
    await tester.pump();
    await tester.tap(find.byKey(const Key('category-submit-button')));
    await tester.settle();

    expect(find.text('저장하지 못했어요. 이미 있는 이름입니다: 반려식물'), findsOneWidget);
    expect(find.byType(CategoryEditSheet), findsOneWidget);
  });

  testWidgets('다크 모드에서 안내 카드 배경은 라이트용 잉크색이 아니라 sunken surface다', (tester) async {
    await pumpPage(tester, theme: ThemeData(brightness: Brightness.dark));
    final card = tester.widget<Container>(find
        .ancestor(of: find.textContaining('또래 비교 통계의 기준'), matching: find.byType(Container))
        .first);
    expect((card.decoration as BoxDecoration).color, Palette.darkSurfaceSunken);
  });

  // 이전에는 설명이 검정 80% 고정이라 다크 대화상자 배경 위에서 읽히지 않았다.
  testWidgets('다크 모드에서 삭제 확인창의 설명·버튼은 다크 토큰 색이다', (tester) async {
    await pumpPage(tester, editing: true, theme: ThemeData(brightness: Brightness.dark));
    await tester.tap(find.byKey(const Key('category-delete-c1')));
    await tester.settle();

    Color? fillOf(String label) => tester
        .widget<ElevatedButton>(find.ancestor(of: find.text(label), matching: find.byType(ElevatedButton)))
        .style!
        .backgroundColor!
        .resolve({});
    expect(tester.widget<Text>(find.textContaining('(으)로 돌아가요')).style!.color, Palette.darkText);
    expect(tester.widget<Text>(find.text('취소')).style!.color, Palette.darkTextSecondary);
    expect(fillOf('취소'), Palette.darkSurfaceSunken);
    expect(fillOf('삭제'), Palette.primaryHeavy);
    expect(tester.widget<Text>(find.text('삭제')).style!.color, Palette.staticWhite);
  });
}
