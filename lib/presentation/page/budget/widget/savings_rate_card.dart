import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 홈 저축률 카드: 44px 도넛 + "이번 달 저축률 N% / 또래 평균 M% · …".
class SavingsRateCard extends StatelessWidget {
  const SavingsRateCard({super.key, required this.rate, required this.peerRate});

  /// 이달 저축률 % (0..100)
  final int rate;
  /// 또래 평균 저축률 %
  final int peerRate;

  @override
  Widget build(BuildContext context) {
    final r = rate.clamp(0, 100);
    final hint = r >= peerRate ? '잘 모으고 있어요' : '조금 더 모아볼까요?';
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
      child: Row(children: [
        SizedBox(
          width: 44, height: 44,
          child: Stack(alignment: Alignment.center, children: [
            CategoryDonut(
              values: [r, 100 - r],
              colors: [context.color.primary.normal, context.color.line.normal],
              size: 44, stroke: 6),
            Text('$r%', style: context.typo.caption2W600.copyWith(
                fontSize: 11, fontWeight: context.typo.extraBold, color: context.color.label.normal)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('이번 달 저축률 $r%', style: context.typo.sectionTitle.copyWith(color: context.color.label.normal)),
          const SizedBox(height: 2),
          Text('또래 평균 $peerRate% · $hint',
              style: context.typo.caption1W500.copyWith(fontSize: 11.5, color: context.color.label.assistive)),
        ])),
      ]),
    );
  }
}
