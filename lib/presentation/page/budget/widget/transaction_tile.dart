import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx, this.onTap});
  final Transaction tx;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final won = NumberFormat.decimalPattern('ko');
    final cat = BudgetCategory.fromId(tx.categoryId);
    final isExpense = tx.type == TransactionType.expense;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: context.color.background.alternative,
        child: Icon(cat.style.icon, size: 18, color: context.color.label.neutral)),
      title: Text(cat.label, style: context.typo.body2W600.copyWith(color: context.color.label.normal)),
      subtitle: Text('${DateFormat('M.d').format(tx.date)}${(tx.memo?.isEmpty ?? true) ? '' : ' · ${tx.memo}'}',
          style: context.typo.caption1W400.copyWith(color: context.color.label.alternative)),
      trailing: Text('${isExpense ? '-' : '+'}₩${won.format(tx.amount)}',
          style: context.typo.body2W600.copyWith(
              color: isExpense ? context.color.label.normal : context.color.primary.normal)),
    );
  }
}
