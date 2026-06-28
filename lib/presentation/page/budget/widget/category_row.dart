import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key, required this.label, required this.amount, required this.color, required this.percent, this.peerAmount});
  final String label; final int amount; final Color color; final double percent;
  /// 또래 평균 카테고리 지출(목업). null이면 배지 미표시.
  final int? peerAmount;
  @override
  Widget build(BuildContext context) {
    final won = NumberFormat.decimalPattern('ko');
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: context.typo.body2W500.copyWith(color: context.color.label.normal))),
        Text('${(percent * 100).round()}%', style: context.typo.caption1W500.copyWith(color: context.color.label.assistive)),
        const SizedBox(width: 10),
        if (peerAmount != null) ...[_PeerBadge(mine: amount, peer: peerAmount!), const SizedBox(width: 6)],
        Text('₩${won.format(amount)}', style: context.typo.body2W600.copyWith(color: context.color.label.normal)),
      ]),
    );
  }
}

/// 또래 평균 대비 배지(▲ 많이 씀 / ▼ 적게 씀). 또래 값은 목업.
class _PeerBadge extends StatelessWidget {
  const _PeerBadge({required this.mine, required this.peer});
  final int mine;
  final int peer;
  @override
  Widget build(BuildContext context) {
    final over = mine > peer;
    final pct = peer == 0 ? 0 : ((mine - peer).abs() * 100 / peer).round();
    final color = over ? context.color.label.alternative : context.color.primary.strong;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(CSize.sm.radius)),
      child: Text('${over ? '▲' : '▼'} $pct%',
        style: context.typo.caption2W500.copyWith(color: color)),
    );
  }
}
