import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 또래 월지출 분포 15버킷 막대 + 내 위치 마스코트 마커 + 축선·3분할 라벨. 통계는 서버(PeerStatsRepository).
class DistributionHistogram extends StatelessWidget {
  const DistributionHistogram({super.key, required this.stats, required this.myExpense});
  final PeerStats stats;
  final int myExpense;

  static const int buckets = 15;
  static const double _plotHeight = 106;
  static const double _barsHeight = 78;
  static const double _markerWidth = 40;

  @override
  Widget build(BuildContext context) {
    final samples = stats.samples;
    if (samples.isEmpty) return const SizedBox(height: _plotHeight);
    final hist = stats.histogram(buckets);
    final maxH = hist.fold<int>(1, (m, v) => v > m ? v : m);
    final lo = samples.fold<int>(samples.first, (m, v) => v < m ? v : m);
    final hi = samples.fold<int>(samples.first, (m, v) => v > m ? v : m);
    final span = (hi - lo) == 0 ? 1 : (hi - lo);
    var myIdx = ((myExpense - lo) * buckets / span).floor();
    if (myIdx < 0) myIdx = 0;
    if (myIdx >= buckets) myIdx = buckets - 1;

    final axisLabel = context.typo.caption2W500.copyWith(color: context.color.label.assistive);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: _plotHeight,
        child: LayoutBuilder(builder: (context, c) {
          final slot = c.maxWidth / buckets;
          return Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: 0, right: 0, bottom: 0, height: _barsHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(buckets, (i) {
                  // 막대 최대 72px — 마커(≈39px)와 합쳐도 106px 안.
                  final h = 4.0 + 68.0 * hist[i] / maxH;
                  final isMe = i == myIdx;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.5),
                      child: Container(
                        height: h,
                        decoration: BoxDecoration(
                          color: isMe ? context.color.primary.normal : context.color.line.neutral,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              left: slot * (myIdx + 0.5) - _markerWidth / 2,
              top: 0,
              width: _markerWidth,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _MeMarker(),
                const SizedBox(height: 2),
                Text('나', style: context.typo.caption2W600.copyWith(
                  fontSize: 9, fontWeight: context.typo.bold, color: context.color.primary.normal)),
              ]),
            ),
          ]);
        }),
      ),
      const SizedBox(height: 8),
      Container(height: 2, decoration: BoxDecoration(
        color: context.color.line.normal, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 7),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('적게 씀', style: axisLabel), Text('평균', style: axisLabel), Text('많이 씀', style: axisLabel),
      ]),
    ]);
  }
}

/// 26px 코랄 마스코트 마커(배경색 2.5px 테두리 + 코랄 그림자).
class _MeMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.color.background.normal,
        boxShadow: [BoxShadow(
          color: context.color.primary.normal.withValues(alpha: 0.45), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: const MascotDongle(size: 21, ring: false),
    );
  }
}
