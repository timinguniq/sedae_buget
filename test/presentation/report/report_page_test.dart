import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/report/report.page.dart';
import 'package:sedae_budget/theme/theme.dart';

import '../../helper/fakes.dart';

final _now = DateTime.now();

DateTime _monthsAgo(int months, int day) => DateTime(_now.year, _now.month - months, day);

/// 이달 식료품 지출 60만·수입 300만과, 지난 두 달의 지출(최근 6개월 추이용).
List<Transaction> _ledger() => [
      Transaction.create(amount: 600000, categoryId: 1, date: _monthsAgo(0, 1),
          type: TransactionType.expense, memo: '식료품'),
      Transaction.create(amount: 3000000, categoryId: 1, date: _monthsAgo(0, 1), type: TransactionType.income),
      Transaction.create(amount: 450000, categoryId: 7, date: _monthsAgo(1, 15), type: TransactionType.expense),
      Transaction.create(amount: 300000, categoryId: 11, date: _monthsAgo(2, 20), type: TransactionType.expense),
    ];

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  testWidgets('report page renders insight, stats, and section headers',
      (tester) async {
    await _pumpReport(tester);

    expect(find.text('이달의 발견'), findsOneWidget);
    expect(find.text('월간 리포트'), findsOneWidget);
    expect(find.text('또래 상위'), findsOneWidget);
    expect(find.textContaining('저축률'), findsWidgets);
    expect(find.text('소득 대비'), findsOneWidget);
    expect(find.text('세대별 월평균 지출'), findsOneWidget);
    expect(find.text('세대별 대표 소비'), findsOneWidget);
    expect(find.text('최근 6개월 내 지출'), findsOneWidget);
    expect(find.textContaining('또래보다'), findsWidgets);
  });

  // 소득이 없으면 저축률도 소득 대비 지출도 계산할 수 없다. 두 칸이 같은 규칙을 따른다.
  // 식료품 지출 60만 원을 또래 식료품 평균 [food]와 견준다.
  group('이달의 발견', () {
    Future<void> pumpWithPeerFood(WidgetTester tester, int food) async {
      final stub = StubPeerData.forGroup(AgeGroup.thirties);
      await _pumpReport(
        tester,
        peer: PeerStats(
          ageGroup: stub.ageGroup,
          avgMonthlyExpense: stub.avgMonthlyExpense,
          avgSavingsRate: stub.avgSavingsRate,
          avgByCategory: {BudgetCategory.food: food},
          samples: stub.samples,
        ),
      );
    }

    testWidgets('50% 이상 더 쓰면 배율로 말한다', (tester) async {
      await pumpWithPeerFood(tester, 400000); // +50%
      expect(find.textContaining('1.5배 더 썼어요'), findsOneWidget);
    });

    // 이전에는 1.96배가 '2.0배 더 썼어요'로 보였다(반올림 전에 정수인지 봤다).
    testWidgets('배율은 반올림한 뒤 정수면 정수로 말한다', (tester) async {
      await pumpWithPeerFood(tester, 306122); // 60만 / 30.6만 ≈ 1.96배
      expect(find.textContaining('2배 더 썼어요'), findsOneWidget);
      expect(find.textContaining('2.0배'), findsNothing);
    });

    // 이전에는 +4%가 '1.0배 더 썼어요'로 보였다.
    testWidgets('50% 미만으로 더 쓰면 %로 말한다', (tester) async {
      await pumpWithPeerFood(tester, 577000); // +4%
      expect(find.textContaining('4% 더 썼어요'), findsOneWidget);
    });

    // 이전에는 +0.3%가 '0% 덜 썼어요'로, 방향이 반대로 보였다.
    testWidgets('차이가 반올림해 0%면 비슷하다고 말한다', (tester) async {
      await pumpWithPeerFood(tester, 598200); // +0.3%
      expect(find.textContaining('비슷하게 썼어요'), findsOneWidget);
      expect(find.textContaining('덜 썼어요'), findsNothing);
    });

    testWidgets('덜 쓰면 %로 말한다', (tester) async {
      await pumpWithPeerFood(tester, 800000); // -25%
      expect(find.textContaining('25% 덜 썼어요'), findsOneWidget);
    });
  });

  testWidgets('소득이 없으면 저축률과 소득 대비가 모두 — 다', (tester) async {
    await _pumpReport(tester, transactions: [
      Transaction.create(amount: 600000, categoryId: 1, date: _monthsAgo(0, 1), type: TransactionType.expense),
    ]);

    expect(find.text('저축률'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
  });

  // 이전에는 지출 0원인 달을 '또래 상위 100%'로 보였다.
  testWidgets('빈 달(지출 0원)은 또래 순위를 매기지 않는다', (tester) async {
    await _pumpReport(tester, transactions: [
      Transaction.create(amount: 3000000, categoryId: 1, date: _monthsAgo(0, 1), type: TransactionType.income),
    ]);

    // 또래 상위 칸만 '—'다(저축률 100%·소득 대비 0%는 내 값이라 남는다).
    expect(find.text('—'), findsOneWidget);
    expect(find.textContaining('아직 분석할 지출이'), findsOneWidget);
  });

  testWidgets('또래 통계를 못 읽으면 안내 문구를 보여준다', (tester) async {
    await _pumpReport(tester, faults: (f) => f.fail('GET', '/v1/peer', reason: FailureReason.server));

    expect(find.text('또래 통계를 불러오지 못했어요'), findsOneWidget);
  });
}

/// 리포트 화면을 띄운다. 서버는 [transactions](기본은 [_ledger])를 심고 또래 통계는 [peer]로 답한다.
Future<void> _pumpReport(
  WidgetTester tester, {
  PeerStats? peer,
  List<Transaction>? transactions,
  void Function(ServerFaults faults)? faults,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final server = await tester.seedServer(
    transactions: transactions ?? _ledger(),
    peerStats: peer == null ? null : (_) => peer,
  );
  faults?.call(server.faults);
  await tester.pumpWidget(fakeScope(fakeContainer(server: server),
        MaterialApp(theme: materialTheme(LightTheme()), home: const ReportPage())));
  await tester.settle();
}
