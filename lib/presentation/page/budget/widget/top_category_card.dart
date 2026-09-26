import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/widget/peer_delta_badge.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 홈 "많이 쓴 카테고리" 카드: [top] 진행바(7px, 코랄) + 또래 배지. 탭 시 [onTap].
class TopCategoryCard extends StatelessWidget {
  const TopCategoryCard({
    super.key,
    required this.top,
    this.onTap,
  });

  /// 많이 쓴 기본 분류(금액 내림차순)와 그 또래 비교. 고르는 규칙은 `MonthOverview.topCategories`에 있다.
  /// 또래 비교가 없으면(또래 통계·그 분류의 또래 값 없음) 배지를 그리지 않는다.
  final List<({BudgetCategory category, int amount, PeerComparison? peer})> top;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final maxAmount = top.isEmpty ? 1 : top.first.amount;
    return SurfaceCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('많이 쓴 카테고리', style: context.typo.sectionTitle.copyWith(color: context.color.label.normal)),
        const SizedBox(height: 14),
        if (top.isEmpty)
          Text('아직 지출이 없어요', style: context.typo.caption1W500.copyWith(color: context.color.label.assistive))
        else
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: 13),
            _row(context, top[i].category, top[i].amount, top[i].amount / maxAmount, top[i].peer),
          ],
      ]),
    );
  }

  Widget _row(BuildContext context, BudgetCategory cat, int amount, double fraction, PeerComparison? comparison) {
    final won = NumberFormat.decimalPattern('ko');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(cat.label, style: context.typo.caption1W600.copyWith(fontSize: 12.5, color: context.color.label.normal)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('₩${won.format(amount)}',
              style: context.typo.caption1W600.copyWith(fontSize: 12.5, fontWeight: context.typo.bold, color: context.color.label.normal)),
          if (comparison != null) ...[
            const SizedBox(width: 7),
            PeerDeltaBadge(comparison: comparison, tinted: true),
          ],
        ]),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: fraction.clamp(0.0, 1.0), minHeight: 7,
          backgroundColor: context.color.background.alternative,
          color: context.color.primary.normal),
      ),
    ]);
  }
}
