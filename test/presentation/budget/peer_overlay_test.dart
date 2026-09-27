import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/presentation/page/budget/widget/summary_hero_card.dart';
import 'package:sedae_budget/presentation/page/budget/widget/peer_rank_card.dart';
import 'package:sedae_budget/presentation/widget/common/peer_text.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 또래 월평균 [avg]와 견준 히어로 pill.
PeerPill? _peer(int expense, {int avg = 2000000}) {
  final total = PeerComparison.of(mine: expense, peer: avg);
  return PeerCompared(
    total: total,
    rank: null,
    savings: const SavingsComparison(mine: null, peer: 20),
    totalBars: null,
    savingsBars: (mine: 0, peer: 1),
  ).heroPill;
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child), theme: materialTheme(LightTheme()));

void main() {
  testWidgets('hero pill shows peer comparison', (t) async {
    await t.pumpWidget(_wrap(SummaryHeroCard(label: '이번 달', expense: 1800000, peer: _peer(1800000))));
    await t.pump();
    expect(find.text('또래 평균보다 10% 덜 썼어요'), findsOneWidget);
    expect(find.text('▼'), findsOneWidget);
  });

  testWidgets('hero pill shows ▲ when over peer', (t) async {
    await t.pumpWidget(_wrap(SummaryHeroCard(label: '이번 달', expense: 2220000, peer: _peer(2220000))));
    await t.pump();
    expect(find.text('또래 평균보다 11% 더 썼어요'), findsOneWidget);
    expect(find.text('▲'), findsOneWidget);
  });

  testWidgets('또래 평균이 없으면 집계 중이라고 보인다', (t) async {
    await t.pumpWidget(_wrap(SummaryHeroCard(label: '이번 달', expense: 1800000, peer: _peer(1800000, avg: 0))));
    await t.pump();
    expect(find.text('또래 평균 집계 중'), findsOneWidget);
    expect(find.text('▲'), findsNothing);
  });

  testWidgets('빈 달이면 비교 대신 내역을 추가하라고 보인다', (t) async {
    await t.pumpWidget(_wrap(SummaryHeroCard(
        label: '이번 달', expense: 0, peer: const PeerEmptyMonth().heroPill)));
    await t.pump();
    expect(find.text('내역을 추가하면 비교가 시작돼요'), findsOneWidget);
    expect(find.text('▼'), findsNothing);
  });

  // 디자인: '상위 N%'는 좋은 뜻으로 읽혀 '많이 쓰는 쪽 N%'로 바뀌었다.
  testWidgets('rank card shows 등 and 많이 쓰는 쪽 with axis labels and 자세히', (t) async {
    final stats = StubPeerData.forGroup(AgeGroup.thirties);
    final rank = stats.rankOf(2600000)!;
    await t.pumpWidget(_wrap(PeerRankCard(rank: rank)));
    await t.pump();
    expect(find.textContaining('등'), findsOneWidget);
    expect(find.text('많이 쓰는 쪽 ${rank.topPercent}%'), findsOneWidget);
    expect(find.text('${rank.total}명 중 ${rank.rank}등'), findsOneWidget);
    expect(find.textContaining('상위'), findsNothing);
    expect(find.text('적게 씀'), findsOneWidget);
    expect(find.text('많이 씀'), findsOneWidget);
    expect(find.text('자세히 ›'), findsOneWidget);
  });

  // '많이 쓰는 쪽 N%'가 '상위 N%'보다 길어 좁은 화면에서 순위 줄이 넘쳤다(넘침은 테스트 실패로 잡힌다).
  testWidgets('rank card fits a narrow phone', (t) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final stats = StubPeerData.forGroup(AgeGroup.thirties);
    await t.pumpWidget(_wrap(Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: PeerRankCard(rank: stats.rankOf(2600000)!),
    )));
    await t.pump();
    expect(find.textContaining('많이 쓰는 쪽'), findsOneWidget);
  });
}
