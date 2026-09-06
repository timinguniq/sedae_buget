import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 리포트 "이달의 발견" 잉크 카드: 라벨(코랄 소프트) + 본문(흰색, 강조어 코랄 소프트) + 서브 + 우하단 코랄 마스코트 워터마크 74px.
class MonthlyInsightCard extends StatelessWidget {
  const MonthlyInsightCard({super.key, required this.body, this.sub});

  /// 본문. 강조어는 [highlightStyle]로 감싼 [TextSpan]으로 넘긴다.
  final InlineSpan body;
  final String? sub;

  static TextStyle bodyStyle(BuildContext context) => context.typo.body1W600.copyWith(
        fontWeight: context.typo.bold, height: 1.5, letterSpacing: 0, color: context.color.static.white);

  static TextStyle highlightStyle(BuildContext context) => bodyStyle(context).copyWith(color: Palette.coralSoft);

  @override
  Widget build(BuildContext context) {
    return InkCard(
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          right: -24, bottom: -29,
          child: Transform.rotate(
            angle: -8 * math.pi / 180,
            child: const MascotDongle(size: 74, featureColor: Palette.staticWhite),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 64),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('이달의 발견', style: context.typo.caption2W600.copyWith(
              fontSize: 11, fontWeight: context.typo.bold, letterSpacing: 0.3, color: Palette.coralSoft)),
            const SizedBox(height: 7),
            Text.rich(body, style: bodyStyle(context)),
            if (sub != null) ...[
              const SizedBox(height: 8),
              Text(sub!, style: context.typo.caption2W500.copyWith(
                fontSize: 11.5, color: context.color.static.white.withValues(alpha: 0.6))),
            ],
          ]),
        ),
      ]),
    );
  }
}
