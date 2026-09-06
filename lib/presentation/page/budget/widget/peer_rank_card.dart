import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 또래 순위 카드. 통계 값은 목업(MockPeerStatsRepository) — 추후 서버 교체.
class PeerRankCard extends StatelessWidget {
  const PeerRankCard({super.key, required this.stats, required this.myExpense});
  final PeerStats stats;
  final int myExpense;

  @override
  Widget build(BuildContext context) {
    final r = stats.rankOf(myExpense);
    final below = stats.percentBelow(myExpense); // 또래 중 나보다 적게 쓴 %
    final spentMoreThan = 100 - below;           // 내가 적게 쓴 또래 비율(절약 지표)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.background.surface,
        borderRadius: BorderRadius.circular(CSize.card.radius),
        border: Border.all(color: context.color.line.normal)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${stats.ageGroup.label} 또래 중', style: context.typo.caption1W500.copyWith(color: context.color.label.alternative)),
        const SizedBox(height: 4),
        Text('${r.rank}등 · 상위 $spentMoreThan%',
          style: context.typo.title3W600.copyWith(color: context.color.label.normal)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: below / 100, minHeight: 8,
            backgroundColor: context.color.line.normal,
            color: context.color.primary.normal)),
      ]),
    );
  }
}
