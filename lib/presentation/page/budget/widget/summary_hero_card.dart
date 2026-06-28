import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 코랄 히어로 카드: 이번 달 총지출(+수입/잔액 보조). 또래 비교 pill은 제외(P2).
class SummaryHeroCard extends StatelessWidget {
  const SummaryHeroCard({super.key, required this.expense, required this.income});
  final int expense;
  final int income;

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
      ]),
    );
  }
}
