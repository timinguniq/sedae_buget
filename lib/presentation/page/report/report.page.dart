import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/compare/peer_provider.dart';
import 'package:sedae_budget/presentation/page/onboarding/user_profile_provider.dart';
import 'package:sedae_budget/presentation/page/report/report_provider.dart';
import 'package:sedae_budget/presentation/page/report/widget/generation_avg_chart.dart';
import 'package:sedae_budget/presentation/page/report/widget/monthly_insight_card.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 세대별 대표 소비 칩 카피(디자인). 또래 통계에 대표 항목이 없어 고정 문구.
const _signatureSpend = <AgeGroup, String>{
  AgeGroup.teens: '간식',
  AgeGroup.twenties: '카페·모임',
  AgeGroup.thirties: '육아·주거',
  AgeGroup.forties: '자녀교육',
  AgeGroup.fiftiesPlus: '건강',
};

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
    final savingsRate = ref.watch(savingsRateProvider);
    final month = ref.watch(selectedMonthProvider);

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
          final peerTop = 100 - peer.percentBelow(totalExpense); // 또래 상위 N%
          // 소득 대비 지출(%) = 100 − 저축률. 소득(프로필 월소득 또는 이달 수입)이 없으면 표시 안 함.
          final hasIncome = (asyncProfile.value?.monthlyIncome ?? 0) > 0 || s.income > 0;
          final incomeRatio = (hasIncome && savingsRate != null) ? 100 - savingsRate : null;
          final insight = _findInsight(s.byCategory, peer);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // ── 헤더 ─────────────────────────────────────────────
              Text('월간 리포트',
                  style: context.typo.caption1W600.copyWith(color: context.color.label.assistive)),
              Text('${month.year}년 ${month.month}월',
                  style: context.typo.pageTitle.copyWith(color: context.color.label.normal)),
              const SizedBox(height: 14),

              // ── 이달의 발견 ──────────────────────────────────────
              MonthlyInsightCard(
                body: _insightBody(context, insight),
                sub: insight == null
                    ? null
                    : '한 달 ₩${won.format(insight.mine)} · 또래는 ₩${won.format(insight.peer)}',
              ),

              const SizedBox(height: 13),

              // ── 3 stat tiles ─────────────────────────────────────
              Row(children: [
                Expanded(child: _StatTile(label: '또래 상위', value: '$peerTop%', accent: true)),
                const SizedBox(width: 9),
                Expanded(child: _StatTile(label: '저축률', value: '${savingsRate ?? 0}%')),
                const SizedBox(width: 9),
                Expanded(child: _StatTile(
                    label: '소득 대비', value: incomeRatio == null ? '—' : '$incomeRatio%')),
              ]),

              const SizedBox(height: 14),

              // ── 세대별 월평균 ──────────────────────────────────────
              SurfaceCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('세대별 월평균 지출',
                      style: context.typo.sectionTitle.copyWith(
                          fontSize: 13, color: context.color.label.normal)),
                  const SizedBox(height: 14),
                  generationAvg.when(
                    loading: () => const SizedBox(height: 84),
                    error: (e, _) => const SizedBox(height: 84),
                    data: (avgs) => GenerationAvgChart(myGroup: ageGroup, avgByGroup: avgs),
                  ),
                ]),
              ),

              const SizedBox(height: 14),

              // ── 세대별 대표 소비 ───────────────────────────────────
              Text('세대별 대표 소비',
                  style: context.typo.caption1W600.copyWith(
                      fontWeight: context.typo.bold, color: context.color.label.normal)),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7, runSpacing: 7,
                children: [
                  for (final g in AgeGroup.values)
                    DesignChip(
                      label: '${g.label} · ${_signatureSpend[g]}',
                      style: g == ageGroup ? DesignChipStyle.coral : DesignChipStyle.outline,
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // ── 자기 추이 ─────────────────────────────────────────
              SurfaceCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('최근 6개월 내 지출',
                      style: context.typo.sectionTitle.copyWith(
                          fontSize: 13, color: context.color.label.normal)),
                  const SizedBox(height: 14),
                  selfTrend.when(
                    loading: () =>
                        const SizedBox(height: 96, child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => Text('$e'),
                    data: (trend) => _SelfTrendBars(trend: trend),
                  ),
                ]),
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  /// 또래 평균과 차이가 가장 큰 카테고리(둘 다 지출이 있는 항목만).
  ({BudgetCategory category, int pct, int mine, int peer})? _findInsight(
    Map<BudgetCategory, int> mySummary,
    PeerStats peer,
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

    if (best == null) return null;
    return (category: best, pct: bestPct.round(), mine: mySummary[best]!, peer: peer.avgByCategory[best]!);
  }

  /// "또래보다 [카테고리]에 / 1.5배 더 썼어요" (덜 쓴 경우 "N% 덜 썼어요").
  InlineSpan _insightBody(BuildContext context, ({BudgetCategory category, int pct, int mine, int peer})? i) {
    if (i == null) return const TextSpan(text: '아직 분석할 지출이\n충분치 않아요');
    final more = i.pct > 0;
    final ratio = i.mine / i.peer;
    final ratioText = ratio == ratio.roundToDouble() ? '${ratio.round()}' : ratio.toStringAsFixed(1);
    return TextSpan(children: [
      const TextSpan(text: '또래보다 '),
      TextSpan(text: i.category.label, style: MonthlyInsightCard.highlightStyle(context)),
      TextSpan(text: '에\n${more ? '$ratioText배 더' : '${i.pct.abs()}% 덜'} 썼어요'),
    ]);
  }
}

/// 디자인 stat 타일: 값 800·19(첫 타일 코랄) + 라벨 500·10, r16 + border.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.accent = false});

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: context.typo.amountDisplaySmall.copyWith(
                    fontSize: 19, letterSpacing: -0.3,
                    color: accent ? context.color.primary.normal : context.color.label.normal)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: context.typo.caption2W500
                  .copyWith(color: context.color.label.assistive)),
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
                      color: context.color.line.neutral,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${e.month.month}월',
                    style: context.typo.caption2W600
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
