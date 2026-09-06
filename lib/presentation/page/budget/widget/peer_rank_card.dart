import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 또래 순위 카드. 통계 값은 서버(PeerStatsRepository).
/// 디자인: `상위 N%`(800·25 코랄) + `100명 중 N등` / 트랙 6px + 코랄 원형 마커 17px / "적게 씀"·"많이 씀" / `자세히 ›`.
class PeerRankCard extends StatelessWidget {
  const PeerRankCard({super.key, required this.stats, required this.myExpense, this.onDetail});
  final PeerStats stats;
  final int myExpense;
  final VoidCallback? onDetail;

  static const double _marker = 17;

  @override
  Widget build(BuildContext context) {
    final r = stats.rankOf(myExpense);
    final below = stats.percentBelow(myExpense); // 또래 중 나보다 적게 쓴 %
    final topPercent = 100 - below;              // 지출 상위 % (나보다 많이·같게 쓴 또래 비율)
    return SurfaceCard(
      onTap: onDetail,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('또래 중 내 지출 순위', style: context.typo.sectionTitle.copyWith(color: context.color.label.normal)),
          Text('자세히 ›', style: context.typo.caption2W600.copyWith(fontSize: 11, color: context.color.label.assistive)),
        ]),
        const SizedBox(height: 7),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text('상위 $topPercent%', style: context.typo.amountDisplaySmall.copyWith(color: context.color.primary.normal)),
          const SizedBox(width: 8),
          Text('${r.total}명 중 ${r.rank}등',
              style: context.typo.caption1W600.copyWith(color: context.color.label.alternative)),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: LayoutBuilder(builder: (context, c) {
            final left = (c.maxWidth - _marker) * below / 100;
            return Stack(children: [
              Positioned(
                top: 11, left: 0, right: 0,
                child: Container(height: 6,
                  decoration: BoxDecoration(color: context.color.line.normal, borderRadius: BorderRadius.circular(3))),
              ),
              Positioned(
                top: 14 - _marker / 2, left: left,
                child: Container(
                  width: _marker, height: _marker,
                  decoration: BoxDecoration(
                    color: context.color.primary.normal,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.color.static.white, width: 2.5),
                    boxShadow: [BoxShadow(
                      color: context.color.primary.normal.withValues(alpha: 0.5),
                      blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                ),
              ),
              Positioned(left: 0, top: 24, child: _axisLabel(context, '적게 씀')),
              Positioned(right: 0, top: 24, child: _axisLabel(context, '많이 씀')),
            ]);
          }),
        ),
      ]),
    );
  }

  Widget _axisLabel(BuildContext context, String text) =>
      Text(text, style: context.typo.caption2W500.copyWith(fontSize: 9, color: context.color.label.disable));
}
