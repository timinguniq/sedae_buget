import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/widget/peer_rank_card.dart';
import 'package:sedae_budget/presentation/page/compare/peer_provider.dart';
import 'package:sedae_budget/presentation/page/compare/widget/distribution_histogram.dart';
import 'package:sedae_budget/presentation/page/compare/widget/category_battle_row.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 세대 비교 화면. 또래 통계는 목업(MockPeerStatsSource) — 추후 서버 교체.
class ComparePage extends ConsumerWidget {
  const ComparePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peer = ref.watch(peerStatsProvider);
    final asyncTxs = ref.watch(monthlyTransactionsProvider);
    final usecase = ref.read(transactionUsecaseProvider);

    return DefaultLayout(
      child: asyncTxs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (txs) {
          final myExpense = usecase.totalExpense(txs);
          if (myExpense == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const MascotDongle(size: 64),
                  const SizedBox(height: 16),
                  Text('내역을 추가하면 비교가 시작돼요',
                    textAlign: TextAlign.center,
                    style: context.typo.body1W500.copyWith(color: context.color.label.alternative)),
                ]),
              ),
            );
          }
          final mySummary = usecase.categorySummary(txs);
          final top6 = (mySummary.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(6)
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text('${peer.ageGroup.label} 또래와 비교',
                style: context.typo.heading2W700.copyWith(color: context.color.label.normal)),
              const SizedBox(height: 4),
              Text('또래 통계는 예시 데이터예요',
                style: context.typo.caption1W400.copyWith(color: context.color.label.assistive)),
              const SizedBox(height: 16),
              PeerRankCard(stats: peer, myExpense: myExpense),
              const SizedBox(height: 20),
              Text('또래 지출 분포', style: context.typo.body1W600.copyWith(color: context.color.label.normal)),
              const SizedBox(height: 10),
              DistributionHistogram(stats: peer, myExpense: myExpense),
              const SizedBox(height: 24),
              Text('항목별 나 vs 또래', style: context.typo.body1W600.copyWith(color: context.color.label.normal)),
              const SizedBox(height: 4),
              for (final e in top6)
                CategoryBattleRow(category: e.key, mine: e.value, peer: peer.avgByCategory[e.key] ?? 0),
            ],
          );
        },
      ),
    );
  }
}
