import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/data/peer/mock_peer_stats_source.dart';
import 'package:sedae_budget/presentation/page/budget/widget/summary_hero_card.dart';
import 'package:sedae_budget/presentation/page/budget/widget/peer_rank_card.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';

Widget _wrap(Widget child) => provider.ChangeNotifierProvider(
  create: (_) => ThemeService(),
  child: MaterialApp(home: Scaffold(body: child), theme: ThemeService().lightThemeData()));

void main() {
  testWidgets('hero pill shows peer comparison', (t) async {
    await t.pumpWidget(_wrap(const SummaryHeroCard(expense: 1800000, income: 0, peerAvgExpense: 2000000)));
    await t.pump();
    expect(find.text('또래보다 10% 덜 써요'), findsOneWidget);
  });

  testWidgets('rank card shows 등 and 상위', (t) async {
    final stats = MockPeerStatsSource().forGroup(AgeGroup.thirties);
    await t.pumpWidget(_wrap(PeerRankCard(stats: stats, myExpense: 2600000)));
    await t.pump();
    expect(find.textContaining('등'), findsOneWidget);
    expect(find.textContaining('상위'), findsOneWidget);
  });
}
