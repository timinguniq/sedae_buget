import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/compare/widget/category_battle_row.dart';
import 'package:sedae_budget/presentation/page/compare/widget/compare_format.dart';
import 'package:sedae_budget/presentation/page/compare/widget/distribution_histogram.dart';
import 'package:sedae_budget/presentation/page/compare/widget/insight_banner.dart';
import 'package:sedae_budget/presentation/page/compare/widget/rank_headline.dart';
import 'package:sedae_budget/presentation/page/compare/widget/versus_bar_card.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 세대 비교 화면. 상단 시안 A(등수·분포·나 vs 또래·저축률) + 하단 시안 B(항목별 차이·인사이트).
/// 또래 통계는 서버(PeerStatsRepository).
class ComparePage extends ConsumerWidget {
  const ComparePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(monthOverviewProvider);
    final name = ref.watch(viewedMonthNameProvider);

    return DefaultLayout(
      child: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => LoadErrorView(error: e, onRetry: ref.read(monthlyTransactionsProvider.notifier).reload),
        data: (o) {
          // 또래 통계가 이 화면의 본질이라, 못 읽으면 화면 전체를 안내로 바꾼다.
          final peer = o.peer;
          if (peer == null) return const Center(child: Text(MonthOverview.peerUnavailable));
          final myExpense = o.month.expense;
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
          final top6 = o.month.topCategories(6);
          final peerAvg = peer.avgMonthlyExpense;
          final expenseMax = (myExpense > peerAvg ? myExpense : peerAvg).clamp(1, 1 << 62);
          final total = peer.compareTotal(myExpense);
          final rank = peer.rankOf(myExpense);
          // 소득이 없으면 내 저축률은 계산할 수 없다: 막대는 0, 값은 '—'.
          final savingsRate = o.month.savingsRate;
          final peerSavings = peer.avgSavingsRatePercent;
          final savingsMax = [savingsRate ?? 0, peerSavings, 1].reduce((a, b) => a > b ? a : b);
          // 또래 평균을 가장 끌어올리는 항목(또래 평균 지출 최대 카테고리).
          MapEntry<BudgetCategory, int>? peerTop;
          for (final e in peer.avgByCategory.entries) {
            if (peerTop == null || e.value > peerTop.value) peerTop = e;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('또래 비교',
                  style: context.typo.pageTitle.copyWith(fontSize: 20, color: context.color.label.normal)),
                _AgeChip(label: peer.ageGroup.label),
              ]),
              const SizedBox(height: 18),
              if (rank != null) ...[
                RankHeadline(rank: rank),
                const SizedBox(height: 22),
              ],
              DistributionHistogram(stats: peer, myExpense: myExpense),
              const SizedBox(height: 18),
              VersusBarCard(
                title: '$name 지출 비교',
                mineFraction: myExpense / expenseMax,
                peerFraction: peerAvg / expenseMax,
                mineText: manWon(myExpense),
                peerText: manWon(peerAvg),
                footer: total == null
                    ? null
                    : Text(
                        switch (total.direction) {
                          PeerDirection.more => '또래보다 약 ${manWon(total.mine - total.peer)}원 더 ▲',
                          PeerDirection.less => '또래보다 약 ${manWon(total.peer - total.mine)}원 덜 ▼',
                          PeerDirection.similar => '또래와 비슷해요',
                        },
                        style: context.typo.caption2W600.copyWith(
                          fontSize: 11,
                          color: total.direction == PeerDirection.more
                              ? context.color.primary.normal
                              : context.color.label.alternative),
                      ),
              ),
              const SizedBox(height: 13),
              VersusBarCard(
                title: '소득 대비 저축률',
                barHeight: 16,
                // 큰 쪽이 폭의 70%가 되도록 스케일(디자인 비율).
                mineFraction: (savingsRate ?? 0) / (savingsMax / 0.7),
                peerFraction: peerSavings / (savingsMax / 0.7),
                mineText: savingsRate == null ? '—' : '$savingsRate%',
                peerText: '$peerSavings%',
              ),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('항목별 차이', style: context.typo.sectionTitle.copyWith(color: context.color.label.normal)),
                Text('← 덜 씀 · 더 씀 →',
                  style: context.typo.caption2W500.copyWith(color: context.color.label.assistive)),
              ]),
              const SizedBox(height: 13),
              for (final e in top6)
                if (peer.compareCategory(e.key, e.value) case final comparison?)
                  CategoryBattleRow(category: e.key, comparison: comparison),
              if (peerTop != null) ...[
                const SizedBox(height: 2),
                InsightBanner(
                  prefix: '${peer.ageGroup.label}는 보통 ',
                  highlight: peerTop.key.label,
                  suffix: ' 지출이 또래 평균을 끌어올려요.',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 헤더 우측 나이대 칩 (흰 배경 + 테두리 + 700·11 잉크).
class _AgeChip extends StatelessWidget {
  const _AgeChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: context.color.background.surface,
        border: Border.all(color: context.color.line.normal),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: context.typo.caption2W600.copyWith(
        fontSize: 11, fontWeight: context.typo.bold, color: context.color.label.normal)),
    );
  }
}
