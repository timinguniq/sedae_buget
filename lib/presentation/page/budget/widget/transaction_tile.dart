import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.tx,
    this.onTap,
    this.overPeer = false,
    this.label,
  });
  final Transaction tx;
  final VoidCallback? onTap;
  // 또래 평균 초과 배지(빈도 데이터 부재 → 카테고리 지출 초과로 근사).
  final bool overPeer;

  /// 표시할 카테고리 이름. null이면 기본 분류 이름(사용자 카테고리 이름을 넘길 때 쓴다).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final won = NumberFormat.decimalPattern('ko');
    final cat = BudgetCategory.fromId(tx.categoryId);
    final isExpense = tx.type == TransactionType.expense;
    final dateText = '${DateFormat('M.d').format(tx.date)}${(tx.memo?.isEmpty ?? true) ? '' : ' · ${tx.memo}'}';
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: context.color.background.alternative,
        child: Icon(cat.style.icon, size: 18, color: context.color.label.neutral)),
      title: Text(label ?? cat.label,
          style: context.typo.body2W600.copyWith(color: context.color.label.normal)),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(dateText,
                overflow: TextOverflow.ellipsis,
                style: context.typo.caption1W400.copyWith(color: context.color.label.alternative)),
          ),
          if (overPeer) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.color.primary.strong.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(CSize.sm.radius)),
              child: Text('또래보다 많이',
                style: context.typo.caption2W500.copyWith(color: context.color.primary.strong)),
            ),
          ],
        ],
      ),
      trailing: Text('${isExpense ? '-' : '+'}₩${won.format(tx.amount)}',
          style: context.typo.body2W600.copyWith(
              color: isExpense ? context.color.label.normal : context.color.primary.normal)),
    );
  }
}
