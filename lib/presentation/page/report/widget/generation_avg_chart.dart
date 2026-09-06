import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/compare/widget/compare_format.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 세대별 월평균 지출 막대 차트: 막대 위 금액 라벨 + 하단 구분선 + 세대 라벨. 내 나이대(myGroup)는 코랄 800.
class GenerationAvgChart extends StatelessWidget {
  const GenerationAvgChart({super.key, required this.myGroup, required this.avgByGroup});

  final AgeGroup myGroup;
  final Map<AgeGroup, int> avgByGroup;

  @override
  Widget build(BuildContext context) {
    final groups = AgeGroup.values;
    final maxAvg = avgByGroup.values.fold<int>(1, (m, v) => v > m ? v : m);
    final coral = context.color.primary.normal;
    final faint = context.color.label.assistive;

    return Column(children: [
      SizedBox(
        height: 84,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: groups.map((g) {
            final v = avgByGroup[g] ?? 0;
            final isMe = g == myGroup;
            // 라벨(≈11px) + 4 + 막대 최대 68px = 83px ≤ 84.
            final h = 4.0 + 64.0 * v / maxAvg;
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(manWon(v), style: context.typo.caption2W600.copyWith(
                    fontSize: isMe ? 10 : 9, height: 1.2,
                    fontWeight: isMe ? context.typo.extraBold : context.typo.bold,
                    color: isMe ? coral : faint)),
                  const SizedBox(height: 4),
                  Container(
                    width: 26, height: h,
                    decoration: BoxDecoration(
                      color: isMe ? coral : context.color.line.neutral,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 7),
      Container(height: 1, color: context.color.line.alternative),
      const SizedBox(height: 7),
      Row(
        children: groups.map((g) {
          final isMe = g == myGroup;
          return Expanded(
            child: Text(g.label, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
              style: context.typo.caption2W600.copyWith(
                fontWeight: isMe ? context.typo.extraBold : context.typo.semiBold,
                color: isMe ? coral : faint)),
          );
        }).toList(),
      ),
    ]);
  }
}
