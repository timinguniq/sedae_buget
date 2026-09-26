import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/budget/widget/peer_rank_card.dart';
import 'package:sedae_budget/presentation/page/budget/widget/savings_rate_card.dart';
import 'package:sedae_budget/presentation/page/budget/widget/summary_hero_card.dart';
import 'package:sedae_budget/presentation/page/budget/widget/top_category_card.dart';
import 'package:sedae_budget/presentation/page/budget/widget/transaction_tile.dart';
import 'package:sedae_budget/theme/theme.dart';

class BudgetHomePage extends ConsumerWidget {
  const BudgetHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final overview = ref.watch(monthOverviewProvider);

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
          Expanded(child: overview.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => LoadErrorView(error: e, onRetry: ref.read(monthlyTransactionsProvider.notifier).reload),
            data: (o) {
              final peer = o.peer;
              final savingsRate = o.savingsRate;
              final txs = o.transactions;
              return ListView(children: [
                SummaryHeroCard(expense: o.expense, income: o.income, peerAvgExpense: peer?.avgMonthlyExpense),
                const SizedBox(height: 13),
                if (peer != null)
                  PeerRankCard(stats: peer, myExpense: o.expense,
                    onDetail: () => context.go(RoutePath.compare.path))
                else
                  SurfaceCard(child: Text(MonthOverview.peerUnavailable,
                    style: context.typo.caption1W500.copyWith(color: context.color.label.assistive))),
                const SizedBox(height: 13),
                TopCategoryCard(top: o.topCategories(3), peerByCategory: peer?.avgByCategory ?? const {},
                  onTap: () => context.push(RoutePath.categoryAnalysis.path)),
                if (savingsRate != null) ...[
                  const SizedBox(height: 13),
                  SavingsRateCard(rate: savingsRate, peerRate: peer?.avgSavingsRatePercent),
                ],
                const SizedBox(height: 13),
                Text('최근 내역', style: context.typo.sectionTitle.copyWith(color: context.color.label.normal)),
                if (txs.isEmpty)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('내역이 없어요. + 로 추가하세요',
                      style: context.typo.body2W400.copyWith(color: context.color.label.alternative))))
                else
                  ...txs.take(5).map((t) => TransactionTile(tx: t, label: o.catalog.of(t).label,
                    onTap: () => context.push(RoutePath.transactionEdit.path, extra: t))),
              ]);
            },
          )),
        ]),
      ),
    );
  }
}
