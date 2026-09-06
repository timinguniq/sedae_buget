import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 시안 A 대형 등수 블록: "또래 N명 중 내 지출은" / `N등`(800·46 코랄) / 잉크 배지 `상위 N% · 많이 쓰는 편`.
class RankHeadline extends StatelessWidget {
  const RankHeadline({super.key, required this.stats, required this.myExpense});
  final PeerStats stats;
  final int myExpense;

  @override
  Widget build(BuildContext context) {
    final r = stats.rankOf(myExpense);
    final below = stats.percentBelow(myExpense); // 또래 중 나보다 적게 쓴 %
    final top = 100 - below;                      // 상위 N% (많이 쓰는 순)
    final heavy = below >= 50;
    final coral = context.color.primary.normal;
    return Column(children: [
      Text('또래 ${r.total}명 중 내 지출은',
        style: context.typo.caption1W600.copyWith(fontSize: 12.5, color: context.color.label.alternative)),
      const SizedBox(height: 1),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('${r.rank}', style: context.typo.amountDisplay.copyWith(fontSize: 46, height: 1.1, letterSpacing: -2, color: coral)),
          const SizedBox(width: 5),
          Text('등', style: context.typo.heading2W700.copyWith(fontWeight: context.typo.extraBold, color: coral)),
        ],
      ),
      const SizedBox(height: 3),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(color: InkCard.colorOf(context), borderRadius: BorderRadius.circular(20)),
        child: Text('상위 $top% · ${heavy ? '많이' : '적게'} 쓰는 편',
          style: context.typo.caption1W600.copyWith(fontSize: 11.5, fontWeight: context.typo.bold, color: context.color.static.white)),
      ),
    ]);
  }
}
