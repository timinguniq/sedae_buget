import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 코랄 히어로 카드: 이번 달 총지출 + 또래 비교 pill + 수입/잔액 보조 + 우하단 마스코트 워터마크.
/// [peerAvgExpense] 지정 시 또래 비교 pill 표시(null이면 생략).
class SummaryHeroCard extends StatelessWidget {
  const SummaryHeroCard({super.key, required this.expense, required this.income, this.peerAvgExpense});
  final int expense;
  final int income;
  final int? peerAvgExpense;

  @override
  Widget build(BuildContext context) {
    final won = NumberFormat.decimalPattern('ko');
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
            Text('이번 달 총지출',
                style: context.typo.caption1W600.copyWith(fontSize: 12.5, color: white.withValues(alpha: 0.92))),
            const SizedBox(height: 3),
            Text('₩${won.format(expense)}', style: context.typo.amountDisplay.copyWith(color: white)),
            if (peerAvgExpense != null) ...[
              const SizedBox(height: 11),
              _PeerPill(expense: expense, peer: peerAvgExpense!),
            ],
            const SizedBox(height: 10),
            Text('수입 ₩${won.format(income)} · 잔액 ₩${won.format(income - expense)}',
                style: context.typo.caption1W500.copyWith(color: white.withValues(alpha: 0.85))),
          ]),
        ),
      ]),
    );
  }
}

/// `▲ 또래 평균보다 N% 더 썼어요` pill (흰색 22% 배경). 또래 값은 서버(PeerStatsRepository) 기반.
class _PeerPill extends StatelessWidget {
  const _PeerPill({required this.expense, required this.peer});
  final int expense;
  final int peer;

  @override
  Widget build(BuildContext context) {
    final white = context.color.static.white;
    final (arrow, label) = _peerLabel(expense, peer);
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

(String?, String) _peerLabel(int me, int peer) {
  if (peer == 0) return (null, '또래 평균 집계 중');
  final d = ((me - peer) * 100 / peer).round();
  if (d == 0) return (null, '또래 평균과 비슷해요');
  return d < 0 ? ('▼', '또래 평균보다 ${-d}% 덜 썼어요') : ('▲', '또래 평균보다 $d% 더 썼어요');
}
