import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';

/// 세대별 월평균 지출 막대 차트. 내 나이대(myGroup) 강조.
class GenerationAvgChart extends StatelessWidget {
  const GenerationAvgChart({super.key, required this.myGroup, required this.avgByGroup});

  final AgeGroup myGroup;
  final Map<AgeGroup, int> avgByGroup;

  @override
  Widget build(BuildContext context) {
    final groups = AgeGroup.values;
    final maxAvg = avgByGroup.values.fold<int>(1, (m, v) => v > m ? v : m);

    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: groups.map((g) {
          final h = 4.0 + 74.0 * avgByGroup[g]! / maxAvg;
          final isMe = g == myGroup;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: h,
                    decoration: BoxDecoration(
                      color: isMe
                          ? context.color.primary.normal
                          : context.color.line.normal,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    g.label,
                    style: context.typo.caption2W500.copyWith(
                      color: isMe
                          ? context.color.primary.normal
                          : context.color.label.assistive,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
