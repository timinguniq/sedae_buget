import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 내역 타일. 디자인: 38px 라운드 사각 아바타(카테고리 첫 글자) / 제목 = memo 우선(없으면 카테고리) 600·13.5 /
/// 부제 `카테고리 · HH:mm` 500·11 / 금액 `−6,800` 700·14.
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
    final catLabel = label ?? BudgetCategory.fromId(tx.categoryId).label;
    final isExpense = tx.type == TransactionType.expense;
    final memo = tx.memo?.trim() ?? '';
    final title = memo.isEmpty ? catLabel : memo;
    final hasTime = tx.date.hour != 0 || tx.date.minute != 0;
    final subtitle = hasTime ? '$catLabel · ${DateFormat('HH:mm').format(tx.date)}' : catLabel;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.color.background.alternative,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(catLabel.isEmpty ? '' : catLabel.substring(0, 1),
                style: context.typo.label2W600.copyWith(
                    fontWeight: context.typo.bold, color: context.color.label.alternative)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(title,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: context.typo.label2W600.copyWith(fontSize: 13.5, color: context.color.label.normal)),
                ),
                if (overPeer) ...[const SizedBox(width: 6), const _PeerBadge()],
              ]),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: context.typo.caption2W500.copyWith(fontSize: 11, color: context.color.label.assistive)),
            ]),
          ),
          const SizedBox(width: 10),
          Text('${isExpense ? '−' : '+'}${won.format(tx.amount)}',
              style: context.typo.label2W600.copyWith(
                  fontWeight: context.typo.bold,
                  color: isExpense ? context.color.label.normal : context.color.primary.normal)),
        ]),
      ),
    );
  }
}

/// `또래보다 잦음` 배지(700·8.5 코랄 / 코랄 tint 배경).
class _PeerBadge extends StatelessWidget {
  const _PeerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: context.color.primary.tint,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text('또래보다 잦음',
          style: context.typo.caption2W600.copyWith(
              fontSize: 8.5, height: 1.3, fontWeight: context.typo.bold, color: context.color.primary.normal)),
    );
  }
}
