import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/widget/common/peer_text.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 또래 평균 대비 배지 `또래▲15%` / `또래▼10%` / `또래와 비슷`. 글자색·바탕색은 `peer_text.dart`의 [PeerText.badgeTone]이 정한다.
/// [tinted]면 바탕이 있는 pill(홈 "많이 쓴 카테고리" 카드용).
class PeerDeltaBadge extends StatelessWidget {
  const PeerDeltaBadge({super.key, required this.comparison, this.tinted = false});

  final PeerComparison comparison;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final (:fg, :bg) = comparison.badgeTone(context, tinted: tinted);
    final pill = bg != null;
    return Container(
      padding: pill ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) : EdgeInsets.zero,
      decoration: bg == null ? null : BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
      child: Text(
        comparison.badge,
        style: context.typo.caption2W600.copyWith(
          fontSize: tinted ? 9.5 : 9, height: 1.2, fontWeight: context.typo.bold, color: fg,
        ),
      ),
    );
  }
}
