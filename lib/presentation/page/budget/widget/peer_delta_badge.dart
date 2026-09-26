import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/widget/common/peer_text.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 또래 평균 대비 배지 `또래▲15%` / `또래▼10%` / `또래와 비슷`.
/// 더 씀=코랄, 덜 씀·비슷=alternative. 크게 넘으면([PeerComparison.strong]) 코랄 배경 + 흰 글씨.
/// [tinted]면 코랄 틴트 배경의 pill(홈 "많이 쓴 카테고리" 카드용).
class PeerDeltaBadge extends StatelessWidget {
  const PeerDeltaBadge({super.key, required this.comparison, this.tinted = false});

  final PeerComparison comparison;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final over = comparison.direction == PeerDirection.more;
    final strong = comparison.strong;
    final accent = comparison.tone(context);
    final fg = strong ? context.color.static.white : accent;
    final Color? bg = strong
        ? context.color.primary.normal
        : (tinted ? (over ? context.color.primary.tint : context.color.background.alternative) : null);
    final pill = strong || tinted;
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
