import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 지출/수입 세그먼트. 디자인: `background.alternative` 트랙 r12 padding 3, 선택 코랄 r9 700·12 흰색.
class TypeSegmented extends StatelessWidget {
  const TypeSegmented({super.key, required this.value, required this.onChanged});
  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(TransactionType t, String label) {
      final sel = t == value;
      return GestureDetector(
        onTap: () => onChanged(t),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          decoration: sel
              ? BoxDecoration(color: context.color.primary.normal, borderRadius: BorderRadius.circular(9))
              : null,
          child: Text(label, style: context.typo.caption1W600.copyWith(
            fontWeight: sel ? context.typo.bold : context.typo.semiBold,
            color: sel ? context.color.static.white : context.color.label.alternative)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.color.background.alternative,
        borderRadius: BorderRadius.circular(CSize.sm.radius),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg(TransactionType.expense, '지출'), seg(TransactionType.income, '수입'),
      ]),
    );
  }
}
