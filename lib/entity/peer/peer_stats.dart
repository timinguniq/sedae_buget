import 'package:sedae_budget/entity/budget/age_group.dart';
import 'package:sedae_budget/entity/budget/budget_category.dart';
import 'package:sedae_budget/entity/peer/peer_comparison.dart';

/// 또래(같은 나이대) 집계 통계. 현재는 목업 — 추후 서버 응답으로 교체.
class PeerStats {
  const PeerStats({
    required this.ageGroup,
    required this.avgMonthlyExpense,
    required this.avgSavingsRate,
    required this.avgByCategory,
    required this.samples,
  });

  final AgeGroup ageGroup;
  final int avgMonthlyExpense;
  final double avgSavingsRate;
  final Map<BudgetCategory, int> avgByCategory;
  final List<int> samples; // 또래 월지출 표본(분포/순위 계산용)
}

/// 또래 중 내 지출 순위.
///
/// [rank]는 많이 쓰는 순 등수(1 = 가장 많이 씀), [total]은 나를 포함한 인원,
/// [percentBelow]는 또래 중 나보다 적게 쓴 비율(%), [topPercent]는 지출 상위 N%(그 보수).
typedef PeerRank = ({int rank, int total, int percentBelow, int topPercent});

extension PeerStatsX on PeerStats {
  /// 이달 내 지출 합계를 또래 월평균과 비교한다. 또래 값이 없으면 null.
  PeerComparison? compareTotal(int myExpense) =>
      PeerComparison.of(mine: myExpense, peer: avgMonthlyExpense);

  /// [category]의 내 지출을 또래 평균과 비교한다. 또래 평균이 0이거나 빠졌으면 null.
  PeerComparison? compareCategory(BudgetCategory category, int mine) =>
      PeerComparison.of(mine: mine, peer: avgByCategory[category]);

  /// 또래 중 내 지출([myExpense]) 순위. 표본이 없으면 순위를 매기지 않는다(null).
  PeerRank? rankOf(int myExpense) {
    if (samples.isEmpty) return null;
    final higher = samples.where((s) => s > myExpense).length;
    final below = samples.where((s) => s < myExpense).length;
    final percentBelow = (below * 100 / samples.length).round();
    return (
      rank: higher + 1,
      total: samples.length + 1,
      percentBelow: percentBelow,
      topPercent: 100 - percentBelow,
    );
  }

  /// 또래 평균 저축률(%, 반올림). 화면의 저축률 비교는 모두 이 값을 쓴다.
  int get avgSavingsRatePercent => (avgSavingsRate * 100).round();

  /// 분포를 [bucketCount]개 구간 막대 높이(인원수)로.
  List<int> histogram(int bucketCount) {
    final buckets = List.filled(bucketCount, 0);
    final spread = _spread();
    if (spread == null) return buckets;
    for (final s in samples) {
      buckets[_indexIn(spread, s, bucketCount)]++;
    }
    return buckets;
  }

  /// [value]가 [histogram]의 몇 번째 구간에 놓이는지. 범위 밖이면 양 끝으로 clamp.
  /// 표본이 없으면 0.
  int bucketIndexOf(int value, int bucketCount) {
    final spread = _spread();
    if (spread == null) return 0;
    return _indexIn(spread, value, bucketCount);
  }

  /// 표본이 덮는 구간. 표본이 없으면 null, 표본이 모두 같으면 폭 1.
  /// min/max는 정렬을 가정하지 않는다 — 표본 순서에 무관하게 동작한다.
  ({int lo, int span})? _spread() {
    if (samples.isEmpty) return null;
    final lo = samples.reduce((a, b) => a < b ? a : b);
    final hi = samples.reduce((a, b) => a > b ? a : b);
    return (lo: lo, span: (hi - lo) == 0 ? 1 : hi - lo);
  }

  int _indexIn(({int lo, int span}) spread, int value, int bucketCount) {
    var idx = ((value - spread.lo) * bucketCount / spread.span).floor();
    if (idx >= bucketCount) idx = bucketCount - 1;
    if (idx < 0) idx = 0;
    return idx;
  }

  /// 또래 평균과 차이(%)가 가장 큰 기본 분류와 그 비교. 내 지출과 또래 평균이 모두 있는 항목만 본다.
  /// 비교할 항목이 없으면 null.
  ({BudgetCategory category, PeerComparison comparison})? largestCategoryGap(
      Map<BudgetCategory, int> mySummary) {
    ({BudgetCategory category, PeerComparison comparison})? best;
    var bestGap = -1.0;
    for (final c in BudgetCategory.values) {
      final mine = mySummary[c] ?? 0;
      final comparison = compareCategory(c, mine);
      if (mine <= 0 || comparison == null) continue;
      final gap = (comparison.ratio - 1).abs();
      if (gap > bestGap) {
        bestGap = gap;
        best = (category: c, comparison: comparison);
      }
    }
    return best;
  }
}
