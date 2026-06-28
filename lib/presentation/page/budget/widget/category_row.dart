import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/presentation/presentation.dart';

class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key, required this.label, required this.amount, required this.color, required this.percent});
  final String label; final int amount; final Color color; final double percent;
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
        Text('₩${won.format(amount)}', style: context.typo.body2W600.copyWith(color: context.color.label.normal)),
      ]),
    );
  }
}
