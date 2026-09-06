import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/theme/theme.dart';

class TypeSegmented extends StatelessWidget {
  const TypeSegmented({super.key, required this.value, required this.onChanged});
  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(TransactionType t, String label) {
      final sel = t == value;
      return Expanded(child: GestureDetector(
        onTap: () => onChanged(t),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? context.color.primary.normal : context.color.background.alternative,
            borderRadius: BorderRadius.circular(CSize.sm.radius),
          ),
          alignment: Alignment.center,
          child: Text(label, style: context.typo.label1W600.copyWith(
            color: sel ? context.color.label.white : context.color.label.neutral)),
        ),
      ));
    }
    return Row(children: [
      seg(TransactionType.expense, '지출'), const SizedBox(width: 8), seg(TransactionType.income, '수입'),
    ]);
  }
}
