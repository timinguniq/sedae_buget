import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/presentation/page/budget/widget/peer_delta_badge.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 카테고리 분석 행. 디자인: 상단 구분선 / 라운드 사각 마커 10px·r3 /
/// 이름 600·13 + 비율 500·10.5 / 우측 금액 800·13 + 또래 배지.
class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key, required this.label, required this.amount, required this.color, required this.percent, this.peerAmount});
  final String label; final int amount; final Color color; final double percent;
  /// 또래 평균 카테고리 지출. null이면 배지 미표시.
  final int? peerAmount;
  @override
  Widget build(BuildContext context) {
    final won = NumberFormat.decimalPattern('ko');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: context.color.line.alternative))),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: context.typo.label2W600.copyWith(fontSize: 13, color: context.color.label.normal)),
          const SizedBox(height: 2),
          Text('${(percent * 100).round()}%',
            style: context.typo.caption2W500.copyWith(fontSize: 10.5, color: context.color.label.assistive)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(won.format(amount),
            style: context.typo.label2W600.copyWith(fontSize: 13, fontWeight: context.typo.extraBold, color: context.color.label.normal)),
          if (peerAmount != null) ...[
            const SizedBox(height: 2),
            PeerDeltaBadge(mine: amount, peer: peerAmount!),
          ],
        ]),
      ]),
    );
  }
}
