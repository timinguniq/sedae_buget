import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 코랄 히어로 카드: 이번 달 총지출(+수입/잔액 보조).
/// [peerAvgExpense] 지정 시 또래 비교 pill 표시(null이면 생략).
class SummaryHeroCard extends StatelessWidget {
  const SummaryHeroCard({super.key, required this.expense, required this.income, this.peerAvgExpense});
  final int expense;
  final int income;
  final int? peerAvgExpense;

  @override
  Widget build(BuildContext context) {
    final won = NumberFormat.decimalPattern('ko');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.color.primary.normal,
        borderRadius: BorderRadius.circular(CSize.lg.radius),
        boxShadow: context.deco.coralShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('이번 달 총지출', style: context.typo.label2W600.copyWith(color: context.color.label.white)),
        const SizedBox(height: 3),
        Text('₩${won.format(expense)}', style: context.typo.amountDisplay.copyWith(color: context.color.label.white)),
        const SizedBox(height: 11),
        Text('수입 ₩${won.format(income)} · 잔액 ₩${won.format(income - expense)}',
            style: context.typo.caption1W500.copyWith(color: context.color.label.white)),
        if (peerAvgExpense != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.color.label.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(CSize.pill.radius)),
            child: Text(_peerLabel(expense, peerAvgExpense!),
              style: context.typo.caption1W600.copyWith(color: context.color.label.white)),
          ),
        ],
      ]),
    );
  }
}

// 또래 값은 목업(MockPeerStatsSource) 기반 — 추후 서버 데이터로 교체.
String _peerLabel(int me, int peer) {
  if (peer == 0) return '또래 평균 집계 중';
  final d = ((me - peer) * 100 / peer).round();
  if (d == 0) return '또래 평균과 비슷해요';
  return d < 0 ? '또래보다 ${-d}% 덜 써요' : '또래보다 $d% 더 써요';
}
