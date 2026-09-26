import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/widget/common/peer_text.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 시안 B "항목별 차이" 다이버징 바: 라벨(우측 정렬 58px) · 중앙 기준선 · 좌(덜 씀, 회색)/우(더 씀, 코랄) 막대 · `+50%`/`−10%`.
class CategoryBattleRow extends StatelessWidget {
  const CategoryBattleRow({super.key, required this.category, required this.comparison});
  final BudgetCategory category;

  /// 이 분류의 또래 비교. 또래 값이 없는 분류는 행을 만들지 않는다(부르는 쪽이 판단).
  final PeerComparison comparison;

  @override
  Widget build(BuildContext context) {
    final diff = comparison.percent;
    final more = comparison.direction == PeerDirection.more;
    // 디자인 스케일: +50% ≈ 한쪽 폭의 90%.
    final f = (diff.abs() / 55).clamp(0.0, 1.0);
    final barColor = more ? context.color.primary.normal : context.color.label.disable;
    final textColor = comparison.tone(context);
    final label = comparison.rowLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        SizedBox(
          width: 58,
          child: Text(category.label,
            textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: context.typo.caption2W600.copyWith(fontSize: 11, color: context.color.label.normal)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: SizedBox(
            height: 18,
            child: LayoutBuilder(builder: (context, c) {
              final half = c.maxWidth / 2;
              return Stack(children: [
                Positioned(
                  left: half - 0.75, top: 0, bottom: 0, width: 1.5,
                  child: ColoredBox(color: context.color.line.neutral)),
                if (diff != 0)
                  Positioned(
                    top: 2, height: 14,
                    left: more ? half : half - half * f,
                    width: half * f,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: more
                            ? const BorderRadius.horizontal(right: Radius.circular(5))
                            : const BorderRadius.horizontal(left: Radius.circular(5)),
                      ),
                    ),
                  ),
              ]);
            }),
          ),
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 38,
          child: Text(label, style: context.typo.caption2W600.copyWith(
            fontSize: 11, fontWeight: context.typo.bold, color: textColor)),
        ),
      ]),
    );
  }
}
