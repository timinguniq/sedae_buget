import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';

class CategoryBattleRow extends StatelessWidget {
  const CategoryBattleRow({super.key, required this.category, required this.mine, required this.peer});
  final BudgetCategory category;
  final int mine;
  final int peer;

  @override
  Widget build(BuildContext context) {
    final maxv = (mine > peer ? mine : peer).clamp(1, 1 << 31).toDouble();
    final diff = peer == 0 ? 0 : ((mine - peer) * 100 / peer).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(category.label, style: context.typo.label2W600.copyWith(color: context.color.label.normal)),
          Text(diff == 0 ? '또래와 비슷' : (diff < 0 ? '${-diff}% 적음' : '$diff% 많음'),
            style: context.typo.caption1W600.copyWith(
              color: diff <= 0 ? context.color.primary.strong : context.color.label.alternative)),
        ]),
        const SizedBox(height: 6),
        _bar(context, '나', mine / maxv, context.color.primary.normal),
        const SizedBox(height: 4),
        _bar(context, '또래', peer / maxv, context.color.line.strong),
      ]),
    );
  }

  Widget _bar(BuildContext context, String label, double f, Color c) => Row(children: [
    SizedBox(width: 28, child: Text(label, style: context.typo.caption2W500.copyWith(color: context.color.label.alternative))),
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(value: f.clamp(0.0, 1.0), minHeight: 8,
        backgroundColor: context.color.line.normal, color: c))),
  ]);
}
