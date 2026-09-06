import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/compare/peer_provider.dart';
import 'package:sedae_budget/presentation/page/onboarding/user_profile_provider.dart';
import 'package:sedae_budget/presentation/page/report/report_provider.dart';
import 'package:sedae_budget/presentation/page/report/widget/generation_avg_chart.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPeer = ref.watch(peerStatsProvider);
    final asyncTxs = ref.watch(monthlyTransactionsProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final asyncProfile = ref.watch(userProfileProvider);
    final selfTrend = ref.watch(selfTrendProvider);
    final generationAvg = ref.watch(generationAvgProvider);

    final ageGroup = asyncProfile.value?.ageGroup ?? AgeGroup.thirties;

    return DefaultLayout(
      child: asyncPeer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('또래 통계 실패: $e')),
        data: (peer) => asyncTxs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (txs) {
          final s = summary.requireValue;
          final won = NumberFormat.decimalPattern('ko');
          final totalExpense = s.expense;
          final income = (asyncProfile.value?.monthlyIncome ?? 0) > 0
              ? asyncProfile.value!.monthlyIncome
              : s.income;
          final savingsRate =
              income > 0 ? ((income - totalExpense) * 100 / income).round() : 0;
          final peerDiff = peer.diffPercent(totalExpense);

          final mySummary = s.byCategory;
          final insightLine = _buildInsightLine(mySummary, peer, ageGroup);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // ── 이달의 발견 ──────────────────────────────────────
              Text('이달의 발견',
                  style: context.typo.heading2W700
                      .copyWith(color: context.color.label.normal)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.color.background.surface,
                  borderRadius: BorderRadius.circular(CSize.card.radius),
                ),
                child: Text(
                  insightLine,
                  style: context.typo.body2W500
                      .copyWith(color: context.color.label.normal),
                ),
              ),

              const SizedBox(height: 20),

              // ── 3 stat tiles ─────────────────────────────────────
              Row(children: [
                Expanded(
                  child: _StatTile(
                    label: '총지출',
                    value: '₩${won.format(totalExpense)}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: '저축률',
                    value: '$savingsRate%',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: '또래 대비',
                    value: '${peerDiff >= 0 ? '+' : ''}$peerDiff%',
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // ── 세대별 월평균 ──────────────────────────────────────
              Text('세대별 월평균',
                  style: context.typo.body1W600
                      .copyWith(color: context.color.label.normal)),
              const SizedBox(height: 10),
              generationAvg.when(
                loading: () => const SizedBox(height: 96),
                error: (e, _) => const SizedBox(height: 96),
                data: (avgs) =>
                    GenerationAvgChart(myGroup: ageGroup, avgByGroup: avgs),
              ),

              const SizedBox(height: 24),

              // ── 자기 추이 ─────────────────────────────────────────
              Text('최근 6개월 내 지출',
                  style: context.typo.body1W600
                      .copyWith(color: context.color.label.normal)),
              const SizedBox(height: 10),
              selfTrend.when(
                loading: () =>
                    const SizedBox(height: 96, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('$e'),
                data: (trend) => _SelfTrendBars(trend: trend),
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  String _buildInsightLine(
    Map<BudgetCategory, int> mySummary,
    PeerStats peer,
    AgeGroup ageGroup,
  ) {
    BudgetCategory? best;
    double bestPct = 0;

    for (final c in BudgetCategory.values) {
      final mine = mySummary[c] ?? 0;
      final peerAvg = peer.avgByCategory[c] ?? 0;
      if (mine <= 0 || peerAvg <= 0) continue;
      final pct = (mine - peerAvg) * 100 / peerAvg;
      if (pct.abs() > bestPct.abs()) {
        bestPct = pct;
        best = c;
      }
    }

    if (best == null) return '아직 분석할 지출이 충분치 않아요';
    final pctRounded = bestPct.round();
    final direction = pctRounded > 0 ? '더' : '덜';
    return '${ageGroup.label} 또래보다 ${best.label} ${pctRounded.abs()}% $direction 썼어요';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: context.color.background.surface,
        borderRadius: BorderRadius.circular(CSize.sm.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: context.typo.caption1W500
                  .copyWith(color: context.color.label.assistive)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: context.typo.label2W600
                    .copyWith(color: context.color.label.normal)),
          ),
        ],
      ),
    );
  }
}

class _SelfTrendBars extends StatelessWidget {
  const _SelfTrendBars({required this.trend});

  final List<({DateTime month, int expense})> trend;

  @override
  Widget build(BuildContext context) {
    final maxExpense = trend.fold<int>(1, (m, e) => e.expense > m ? e.expense : m);

    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trend.map((e) {
          final h = 4.0 + 74.0 * e.expense / maxExpense;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: h,
                    decoration: BoxDecoration(
                      color: context.color.line.normal,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${e.month.month}월',
                    style: context.typo.caption2W500
                        .copyWith(color: context.color.label.assistive),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
