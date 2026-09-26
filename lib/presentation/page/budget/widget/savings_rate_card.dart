import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/widget/common/peer_text.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 홈 저축률 카드: 44px 도넛 + "{달} 저축률 N% / 또래 평균 M% · …".
class SavingsRateCard extends StatelessWidget {
  const SavingsRateCard({super.key, required this.label, required this.rate, this.peer});

  /// 보고 있는 달의 이름('이번 달', '8월').
  final String label;

  /// 저축률 %. 지출이 소득보다 많으면 음수이고 그대로 보여준다(도넛만 0..100에서 멈춘다).
  final int rate;
  /// 또래 평균 저축률과의 비교. 또래 통계를 못 읽었거나 빈 달이면 null이고 비교 문구를 빼고 보여준다.
  final SavingsComparison? peer;

  @override
  Widget build(BuildContext context) {
    final arc = rate.clamp(0, 100);
    final peer = this.peer;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
      child: Row(children: [
        SizedBox(
          width: 44, height: 44,
          child: Stack(alignment: Alignment.center, children: [
            CategoryDonut(
              values: [arc, 100 - arc],
              colors: [context.color.primary.normal, context.color.line.normal],
              size: 44, stroke: 6),
            Text('$rate%', style: context.typo.caption2W600.copyWith(
                fontSize: 11, fontWeight: context.typo.extraBold, color: context.color.label.normal)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label 저축률 $rate%', style: context.typo.sectionTitle.copyWith(color: context.color.label.normal)),
          if (peer != null) ...[
            const SizedBox(height: 2),
            Text('또래 평균 ${peer.peer}% · ${peer.verdict}',
                style: context.typo.caption1W500.copyWith(fontSize: 11.5, color: context.color.label.assistive)),
          ],
        ])),
      ]),
    );
  }
}
