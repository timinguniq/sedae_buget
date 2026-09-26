import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/budget_home.page.dart';

import '../../helper/fakes.dart';

const _profile = UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000);

/// 이번 달 10일 택시비 한 건.
List<Transaction> _taxi() {
  final now = DateTime.now();
  return [
    Transaction.create(amount: 12000, categoryId: 7, date: DateTime(now.year, now.month, 10),
        type: TransactionType.expense, memo: '택시'),
  ];
}

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  testWidgets('shows total expense and a transaction', (tester) async {
    final server = await tester.seedServer(profile: _profile, transactions: _taxi());
    await _pumpHome(tester, fakeContainer(server: server));

    expect(find.textContaining('12,000'), findsWidgets);
    expect(find.text('택시'), findsOneWidget); // memo is the tile title (design)

    // 디자인 카드 4종 + 최근 내역
    expect(find.text('이번 달 요약'), findsOneWidget);
    expect(find.text('또래 중 내 지출 순위'), findsOneWidget);
    expect(find.text('많이 쓴 카테고리'), findsOneWidget);
    expect(find.text(BudgetCategory.fromId(7).label), findsWidgets);
    expect(find.text('최근 내역'), findsOneWidget);
  });

  // 내역 화면과 같은 거래가 홈에서만 기본 분류 이름으로 보이던 문제.
  testWidgets('최근 내역은 사용자 카테고리 이름으로 보인다', (tester) async {
    final now = DateTime.now();
    final server = await tester.seedServer(
      profile: _profile,
      categories: const [CustomCategory(id: 'c1', name: '반려동물', baseCategoryId: 12)],
      transactions: [
        Transaction.create(amount: 30000, categoryId: 12, date: DateTime(now.year, now.month, 3),
            type: TransactionType.expense, customCategoryId: 'c1'),
      ],
    );
    await _pumpHome(tester, fakeContainer(server: server));

    expect(find.text('반려동물'), findsWidgets);
  });

  // 또래 통계 서버가 내려가도 내 장부는 보여야 한다(또래 부분만 빠진다).
  testWidgets('또래 통계를 못 읽어도 내 지출과 최근 내역은 보인다', (tester) async {
    final server = await tester.seedServer(profile: _profile, transactions: _taxi());
    server.faults.fail('GET', '/v1/peer', reason: FailureReason.server);
    await _pumpHome(tester, fakeContainer(server: server));

    expect(find.text('택시'), findsOneWidget);
    expect(find.textContaining('12,000'), findsWidgets);
    expect(find.text('많이 쓴 카테고리'), findsOneWidget);
    expect(find.text('또래 통계를 불러오지 못했어요'), findsOneWidget);
    expect(find.text('또래 중 내 지출 순위'), findsNothing);
    // 저축률은 내 값이라 남고, 또래 평균 문구만 빠진다.
    expect(find.textContaining('이번 달 저축률'), findsOneWidget);
    expect(find.textContaining('또래 평균'), findsNothing);
  });

  // 이전에는 지난 달을 봐도 '이번 달 요약·이번 달 총지출·이번 달 저축률'로 보였다.
  testWidgets('지난 달을 보면 그 달 이름으로 보인다', (tester) async {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month - 1);
    final server = await tester.seedServer(profile: _profile, transactions: [
      Transaction.create(amount: 12000, categoryId: 7, date: DateTime(last.year, last.month, 10),
          type: TransactionType.expense, memo: '택시'),
    ]);
    final container = fakeContainer(server: server);
    container.read(selectedMonthProvider.notifier).prev();
    await _pumpHome(tester, container);

    expect(find.text('${last.month}월 요약'), findsOneWidget);
    expect(find.text('${last.month}월 총지출'), findsOneWidget);
    expect(find.textContaining('${last.month}월 저축률'), findsOneWidget);
    expect(find.textContaining('이번 달'), findsNothing);
  });

  // 이전에는 히어로가 거래 수입(₩0)을, 같은 화면의 저축률은 프로필 소득을 기준으로 했다.
  testWidgets('히어로의 소득·잔액은 저축률과 같은 소득을 쓴다', (tester) async {
    final server = await tester.seedServer(profile: _profile, transactions: _taxi());
    await _pumpHome(tester, fakeContainer(server: server));

    expect(find.text('소득 ₩3,000,000 · 잔액 ₩2,988,000'), findsOneWidget);
  });

  // 이전에는 표본이 없어도 '1명 중 1등 · 상위 100%'로 보였다.
  testWidgets('또래 표본이 없으면 순위 카드를 보이지 않는다', (tester) async {
    final server = await tester.seedServer(
      profile: _profile,
      transactions: _taxi(),
      peerStats: (g) {
        final stub = StubPeerData.forGroup(g);
        return PeerStats(
          ageGroup: stub.ageGroup,
          avgMonthlyExpense: stub.avgMonthlyExpense,
          avgSavingsRate: stub.avgSavingsRate,
          avgByCategory: stub.avgByCategory,
          samples: const [],
        );
      },
    );
    await _pumpHome(tester, fakeContainer(server: server));

    expect(find.text('또래 중 내 지출 순위'), findsNothing);
    expect(find.text('또래 통계를 불러오지 못했어요'), findsNothing);
    expect(find.text('많이 쓴 카테고리'), findsOneWidget);
  });

  // 이전에는 '불러오기 실패: <예외 문자열>'만 보이고 다시 읽을 방법이 없었다.
  testWidgets('이달 거래를 못 읽으면 이유와 다시 시도를 보여주고, 다시 시도하면 읽는다', (tester) async {
    final server = await tester.seedServer(profile: _profile, transactions: _taxi());
    server.faults.fail('GET', '/v1/transactions', times: 1);
    await _pumpHome(tester, fakeContainer(server: server));

    expect(find.text('불러오지 못했어요. 인터넷에 연결되어 있지 않아요'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.settle();

    expect(find.text('택시'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
  });

  // 소득(프로필 월소득·이달 수입)이 없으면 저축률을 계산할 수 없다.
  testWidgets('소득이 없으면 저축률 카드를 보이지 않는다', (tester) async {
    final server = await tester.seedServer(
      profile: const UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 0),
      transactions: _taxi(),
    );
    await _pumpHome(tester, fakeContainer(server: server));

    expect(find.text('택시'), findsOneWidget);
    expect(find.textContaining('이번 달 저축률'), findsNothing);
  });
}

Future<void> _pumpHome(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(fakeScope(container, MaterialApp(home: const BudgetHomePage())));
  await tester.settle();
}
