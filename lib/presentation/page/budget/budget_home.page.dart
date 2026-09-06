import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/widget/peer_rank_card.dart';
import 'package:sedae_budget/presentation/page/budget/widget/savings_rate_card.dart';
import 'package:sedae_budget/presentation/page/budget/widget/summary_hero_card.dart';
import 'package:sedae_budget/presentation/page/budget/widget/top_category_card.dart';
import 'package:sedae_budget/presentation/page/budget/widget/transaction_tile.dart';
import 'package:sedae_budget/presentation/page/compare/peer_provider.dart';
import 'package:sedae_budget/presentation/page/report/report_provider.dart';
import 'package:sedae_budget/theme/theme.dart';

class BudgetHomePage extends ConsumerWidget {
  const BudgetHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final asyncTxs = ref.watch(monthlyTransactionsProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final asyncPeer = ref.watch(peerStatsProvider);
    final savingsRate = ref.watch(savingsRateProvider);

    return DefaultLayout(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateFormat('yyyy년 M월', 'ko').format(month),
                  style: context.typo.caption1W600.copyWith(color: context.color.label.assistive)),
              Text('이번 달 요약', style: context.typo.pageTitle.copyWith(color: context.color.label.normal)),
            ]),
            GestureDetector(
              onTap: () => context.push(RoutePath.setting.path),
              child: const MascotDongle(size: 40, ring: false)),
          ]),
          const SizedBox(height: 16),
          Expanded(child: asyncPeer.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('또래 통계 실패: $e')),
            data: (peer) => asyncTxs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('불러오기 실패: $e', style: context.typo.body2W400)),
            data: (txs) {
              final s = summary.requireValue;
              return ListView(children: [
                SummaryHeroCard(expense: s.expense, income: s.income, peerAvgExpense: peer.avgMonthlyExpense),
                const SizedBox(height: 13),
                PeerRankCard(stats: peer, myExpense: s.expense,
                  onDetail: () => context.go(RoutePath.compare.path)),
                const SizedBox(height: 13),
                TopCategoryCard(summary: s.byCategory, peerByCategory: peer.avgByCategory,
                  onTap: () => context.push(RoutePath.categoryAnalysis.path)),
                if (savingsRate != null) ...[
                  const SizedBox(height: 13),
                  SavingsRateCard(rate: savingsRate, peerRate: (peer.avgSavingsRate * 100).round()),
                ],
                const SizedBox(height: 13),
                Text('최근 내역', style: context.typo.sectionTitle.copyWith(color: context.color.label.normal)),
                if (txs.isEmpty)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('내역이 없어요. + 로 추가하세요',
                      style: context.typo.body2W400.copyWith(color: context.color.label.alternative))))
                else
                  ...txs.take(5).map((t) => TransactionTile(tx: t,
                    onTap: () => context.push(RoutePath.transactionEdit.path, extra: t))),
              ]);
            },
            ),
          )),
        ]),
      ),
    );
  }
}
