import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';

/// 또래 월지출 분포 막대 + 내 위치 강조. 통계는 목업(MockPeerStatsSource) — 추후 서버 교체.
class DistributionHistogram extends StatelessWidget {
  const DistributionHistogram({super.key, required this.stats, required this.myExpense});
  final PeerStats stats;
  final int myExpense;

  @override
  Widget build(BuildContext context) {
    const buckets = 12;
    final hist = stats.histogram(buckets);
    final maxH = hist.fold<int>(1, (m, v) => v > m ? v : m);
    final samples = stats.samples;
    if (samples.isEmpty) return const SizedBox(height: 96);
    final lo = samples.fold<int>(samples.first, (m, v) => v < m ? v : m);
    final hi = samples.fold<int>(samples.first, (m, v) => v > m ? v : m);
    final span = (hi - lo) == 0 ? 1 : (hi - lo);
    var myIdx = ((myExpense - lo) * buckets / span).floor();
    if (myIdx < 0) myIdx = 0;
    if (myIdx >= buckets) myIdx = buckets - 1;

    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(buckets, (i) {
          // 막대 최대 78px — '나' 라벨(~16px)과 합쳐도 96px 안에 들어와 클리핑/오버플로 없음.
          final h = 4.0 + 74.0 * hist[i] / maxH;
          final isMe = i == myIdx;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('나', style: context.typo.caption2W500.copyWith(color: context.color.primary.strong)),
                    ),
                  Container(
                    height: h,
                    decoration: BoxDecoration(
                      color: isMe ? context.color.primary.normal : context.color.line.normal,
                      borderRadius: BorderRadius.circular(3)),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
