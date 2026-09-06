import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 또래 평균 대비 배지 `또래▲15%` / `또래▼10%`.
/// 초과=코랄, 미만=alternative. 초과 50%↑는 코랄 배경 + 흰 글씨.
/// [tinted]면 코랄 틴트 배경의 pill(홈 "많이 쓴 카테고리" 카드용).
class PeerDeltaBadge extends StatelessWidget {
  const PeerDeltaBadge({super.key, required this.mine, required this.peer, this.tinted = false});

  final int mine;
  final int peer;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final over = mine > peer;
    final pct = peer == 0 ? 0 : ((mine - peer).abs() * 100 / peer).round();
    final strong = over && pct >= 50;
    final accent = over ? context.color.primary.normal : context.color.label.alternative;
    final fg = strong ? context.color.static.white : accent;
    final Color? bg = strong
        ? context.color.primary.normal
        : (tinted ? (over ? context.color.primary.tint : context.color.background.alternative) : null);
    final pill = strong || tinted;
    return Container(
      padding: pill ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) : EdgeInsets.zero,
      decoration: bg == null ? null : BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
      child: Text(
        '또래${over ? '▲' : '▼'}$pct%',
        style: context.typo.caption2W600.copyWith(
          fontSize: tinted ? 9.5 : 9, height: 1.2, fontWeight: context.typo.bold, color: fg,
        ),
      ),
    );
  }
}
