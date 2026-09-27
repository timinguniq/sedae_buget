import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sedae_budget/presentation/widget/common/peer_text.dart';
import 'package:sedae_budget/presentation/widget/common/won_text.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 코랄 히어로 카드: 달 총지출 + 또래 비교 pill + 소득/잔액 보조 + 우하단 마스코트 워터마크.
/// [peer]가 있으면 또래 비교 pill을 그린다(또래 통계를 못 읽었으면 null — pill 생략). 문구는 `PeerStanding.heroPill`.
class SummaryHeroCard extends StatelessWidget {
  const SummaryHeroCard({
    super.key,
    required this.label,
    required this.expense,
    this.income,
    this.balance,
    this.peer,
  });

  /// 보고 있는 달의 이름('이번 달', '8월').
  final String label;
  final int expense;

  /// 소득과 잔액(저축률과 같은 기준). 소득이 없으면 둘 다 null이고 그 줄을 그리지 않는다.
  final int? income;
  final int? balance;
  final PeerPill? peer;

  @override
  Widget build(BuildContext context) {
    final white = context.color.static.white;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.color.primary.normal,
        borderRadius: BorderRadius.circular(CSize.lg.radius),
        boxShadow: context.deco.coralShadow,
      ),
      child: Stack(children: [
        // 워터마크: 크림색 얼굴 + 코랄 이목구비, 8° 회전
        Positioned(
          right: -12, bottom: -18,
          child: Transform.rotate(
            angle: 8 * math.pi / 180,
            child: const MascotDongle(size: 80, faceColor: Palette.cream, featureColor: Palette.primaryNormal, ring: false),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 19, 20, 19),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$label 총지출',
                style: context.typo.caption1W600.copyWith(fontSize: 12.5, color: white.withValues(alpha: 0.92))),
            const SizedBox(height: 3),
            Text(WonText.full.of(expense), style: context.typo.amountDisplay.copyWith(color: white)),
            if (peer case final peer?) ...[
              const SizedBox(height: 11),
              _PeerPill(peer: peer),
            ],
            if ((income, balance) case (final income?, final balance?)) ...[
              const SizedBox(height: 10),
              Text('소득 ${WonText.full.of(income)} · 잔액 ${WonText.full.of(balance)}',
                  style: context.typo.caption1W500.copyWith(color: white.withValues(alpha: 0.85))),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// `▲ 또래 평균보다 N% 더 썼어요` pill (흰색 22% 배경). 또래 값은 서버(PeerStatsRepository) 기반.
class _PeerPill extends StatelessWidget {
  const _PeerPill({required this.peer});

  final PeerPill peer;

  @override
  Widget build(BuildContext context) {
    final white = context.color.static.white;
    final (:arrow, text: label) = peer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(CSize.pill.radius)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (arrow != null) ...[
          Text(arrow, style: context.typo.caption2W600.copyWith(fontSize: 9, fontWeight: context.typo.extraBold, color: white)),
          const SizedBox(width: 4),
        ],
        Text(label, style: context.typo.caption1W600.copyWith(fontSize: 11.5, fontWeight: context.typo.bold, color: white)),
      ]),
    );
  }
}
