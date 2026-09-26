import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final name = ref.watch(viewedMonthNameProvider);
    final overview = ref.watch(monthOverviewProvider);

    return DefaultLayout(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(month.fullName,
                  style: context.typo.caption1W600.copyWith(color: context.color.label.assistive)),
              Text('$name 요약', style: context.typo.pageTitle.copyWith(color: context.color.label.normal)),
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
              final m = o.month;
              final savingsRate = m.savingsRate;
              final txs = m.transactions;
              return ListView(children: [
                SummaryHeroCard(
                    label: name, expense: m.expense, income: m.income, balance: m.balance,
                    peer: o.hasPeer ? (emptyMonth: o.isEmpty, total: o.total) : null),
                if (!o.hasPeer) ...[
                  const SizedBox(height: 13),
                  SurfaceCard(child: Text(peerUnavailableText,
                    style: context.typo.caption1W500.copyWith(color: context.color.label.assistive))),
                ] else if (o.rank case final rank?) ...[
                  const SizedBox(height: 13),
                  PeerRankCard(rank: rank, onDetail: () => context.go(RoutePath.compare.path)),
                ],
                const SizedBox(height: 13),
                TopCategoryCard(top: o.topCategories(3),
                  onTap: () => context.push(RoutePath.categoryAnalysis.path)),
                if (savingsRate != null) ...[
                  const SizedBox(height: 13),
                  SavingsRateCard(label: name, rate: savingsRate, peer: o.savings),
                ],
                const SizedBox(height: 13),
                Text('최근 내역', style: context.typo.sectionTitle.copyWith(color: context.color.label.normal)),
                if (txs.isEmpty)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('내역이 없어요. + 로 추가하세요',
                      style: context.typo.body2W400.copyWith(color: context.color.label.alternative))))
                else
                  ...txs.take(5).map((t) => TransactionTile(tx: t, label: m.labelOf(t),
                    onTap: () => context.push(RoutePath.transactionEdit.path, extra: t))),
              ]);
            },
          )),
        ]),
      ),
    );
  }
}
