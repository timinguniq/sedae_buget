import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/compare/compare.view_model.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';
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
    final overview = ref.watch(monthOverviewProvider);
    final asyncProfile = ref.watch(userProfileProvider);
    final selfTrend = ref.watch(selfTrendProvider);
    final generationAvg = ref.watch(generationAvgProvider);
    final month = ref.watch(selectedMonthProvider);

    final ageGroup = asyncProfile.value?.ageGroup ?? AgeGroup.thirties;

    return DefaultLayout(
      child: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => LoadErrorView(error: e, onRetry: ref.read(monthlyTransactionsProvider.notifier).reload),
        data: (o) {
          // 리포트는 또래 비교가 중심이라, 또래 통계를 못 읽으면 화면 전체를 안내로 바꾼다.
          if (!o.hasPeer) return const Center(child: Text(peerUnavailableText));
          final won = NumberFormat.decimalPattern('ko');
          final peerTop = o.rank?.topPercent; // 또래 상위 N%. 빈 달이거나 표본이 없으면 null
          // 소득이 없으면 저축률·소득 대비 지출 모두 '—'.
          final savingsRate = o.month.savingsRate;
          final incomeRatio = o.month.expenseRatio;
          final insight = o.largestGap;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // ── 헤더 ─────────────────────────────────────────────
              Text('월간 리포트',
                  style: context.typo.caption1W600.copyWith(color: context.color.label.assistive)),
              Text(month.fullName,
                  style: context.typo.pageTitle.copyWith(color: context.color.label.normal)),
              const SizedBox(height: 14),

              // ── 이달의 발견 ──────────────────────────────────────
              MonthlyInsightCard(
                body: _insightBody(context, insight),
                sub: insight == null
                    ? null
                    : '한 달 ₩${won.format(insight.comparison.mine)} · 또래는 ₩${won.format(insight.comparison.peer)}',
              ),

              const SizedBox(height: 13),

              // ── 3 stat tiles ─────────────────────────────────────
              Row(children: [
                Expanded(child: _StatTile(
                    label: '또래 상위', value: peerTop == null ? '—' : '$peerTop%', accent: true)),
                const SizedBox(width: 9),
                Expanded(child: _StatTile(
                    label: '저축률', value: savingsRate == null ? '—' : '$savingsRate%')),
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
                    error: (e, _) => LoadErrorView(error: e, onRetry: ref.read(monthlyTransactionsProvider.notifier).reload),
                    data: (trend) => _SelfTrendBars(trend: trend),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  /// "또래보다 [카테고리]에 / 1.5배 더 썼어요". 크게 넘으면(50%↑) 배율, 그 밖은 %로 말하고
  /// 차이가 반올림해 0%면 "또래와 [카테고리]에 / 비슷하게 썼어요".
  InlineSpan _insightBody(
    BuildContext context,
    ({BudgetCategory category, PeerComparison comparison})? i,
  ) {
    if (i == null) return const TextSpan(text: '아직 분석할 지출이\n충분치 않아요');
    final c = i.comparison;
    final ratio = c.ratio;
    final ratioText = ratio == ratio.roundToDouble() ? '${ratio.round()}' : ratio.toStringAsFixed(1);
    final (lead, how) = switch (c.direction) {
      PeerDirection.more when c.strong => ('또래보다 ', '$ratioText배 더'),
      PeerDirection.more => ('또래보다 ', '${c.percent}% 더'),
      PeerDirection.less => ('또래보다 ', '${-c.percent}% 덜'),
      PeerDirection.similar => ('또래와 ', '비슷하게'),
    };
    return TextSpan(children: [
      TextSpan(text: lead),
      TextSpan(text: i.category.label, style: MonthlyInsightCard.highlightStyle(context)),
      TextSpan(text: '에\n$how 썼어요'),
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

  final List<({YearMonth month, int expense})> trend;

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
