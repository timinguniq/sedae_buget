import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/widget/peer_delta_badge.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 홈 "많이 쓴 카테고리" 카드: 상위 [count]개 진행바(7px, 코랄) + 또래 배지. 탭 시 [onTap].
class TopCategoryCard extends StatelessWidget {
  const TopCategoryCard({
    super.key,
    required this.summary,
    this.peerByCategory = const {},
    this.onTap,
    this.count = 3,
  });

  final Map<BudgetCategory, int> summary;
  /// 또래 평균 카테고리 지출. 값이 없거나 0이면 배지 생략.
  final Map<BudgetCategory, int> peerByCategory;
  final VoidCallback? onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    final top = (summary.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(count)
        .toList();
    final maxAmount = top.isEmpty ? 1 : top.first.value;
    return SurfaceCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('많이 쓴 카테고리', style: context.typo.sectionTitle.copyWith(color: context.color.label.normal)),
        const SizedBox(height: 14),
        if (top.isEmpty)
          Text('아직 지출이 없어요', style: context.typo.caption1W500.copyWith(color: context.color.label.assistive))
        else
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: 13),
            _row(context, top[i].key, top[i].value, top[i].value / maxAmount),
          ],
      ]),
    );
  }

  Widget _row(BuildContext context, BudgetCategory cat, int amount, double fraction) {
    final won = NumberFormat.decimalPattern('ko');
    final peer = peerByCategory[cat] ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(cat.label, style: context.typo.caption1W600.copyWith(fontSize: 12.5, color: context.color.label.normal)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('₩${won.format(amount)}',
              style: context.typo.caption1W600.copyWith(fontSize: 12.5, fontWeight: context.typo.bold, color: context.color.label.normal)),
          if (peer > 0) ...[const SizedBox(width: 7), PeerDeltaBadge(mine: amount, peer: peer, tinted: true)],
        ]),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: fraction.clamp(0.0, 1.0), minHeight: 7,
          backgroundColor: context.color.background.alternative,
          color: context.color.primary.normal),
      ),
    ]);
  }
}
