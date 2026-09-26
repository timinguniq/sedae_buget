import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/presentation/page/budget/widget/summary_hero_card.dart';
import 'package:sedae_budget/presentation/page/budget/widget/peer_rank_card.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 또래 월평균 [avg]와 견준 히어로 pill.
HeroPeer _peer(int expense, {int avg = 2000000}) =>
    (emptyMonth: false, total: PeerComparison.of(mine: expense, peer: avg));

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
    await t.pumpWidget(_wrap(const SummaryHeroCard(
        label: '이번 달', expense: 0, peer: (emptyMonth: true, total: null))));
    await t.pump();
    expect(find.text('내역을 추가하면 비교가 시작돼요'), findsOneWidget);
    expect(find.text('▼'), findsNothing);
  });

  testWidgets('rank card shows 등 and 상위 with axis labels and 자세히', (t) async {
    final stats = StubPeerData.forGroup(AgeGroup.thirties);
    await t.pumpWidget(_wrap(PeerRankCard(rank: stats.rankOf(2600000)!)));
    await t.pump();
    expect(find.textContaining('등'), findsOneWidget);
    expect(find.textContaining('상위'), findsOneWidget);
    expect(find.text('적게 씀'), findsOneWidget);
    expect(find.text('많이 씀'), findsOneWidget);
    expect(find.text('자세히 ›'), findsOneWidget);
  });
}
