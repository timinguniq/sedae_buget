import 'package:sedae_budget/entity/budget/age_group.dart';
import 'package:sedae_budget/entity/budget/budget_category.dart';

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

/// 또래 평균([peer]) 대비 내 지출([mine])의 증감률(%). 음수면 또래보다 덜 씀.
/// 또래 평균이 0이면(집계 없음) 0. 또래 비교 화면의 모든 `▲N%`·`+N%` 표기가 이 규칙을 쓴다.
int peerDeltaPercent({required int mine, required int peer}) =>
    peer == 0 ? 0 : ((mine - peer) * 100 / peer).round();

extension PeerStatsX on PeerStats {
  /// 또래 중 [userExpense]보다 적게 쓴 비율(%). 클수록 사용자가 많이 쓴 편.
  int percentBelow(int userExpense) {
    if (samples.isEmpty) return 0;
    final below = samples.where((s) => s < userExpense).length;
    return (below * 100 / samples.length).round();
  }

  /// 지출 상위 N%(많이 쓰는 순). [percentBelow]의 보수.
  int topPercent(int userExpense) => 100 - percentBelow(userExpense);

  /// 많이 쓰는 순 등수(1 = 가장 많이 씀)와 전체 인원(사용자 포함).
  ({int rank, int total}) rankOf(int userExpense) {
    final higher = samples.where((s) => s > userExpense).length;
    return (rank: higher + 1, total: samples.length + 1);
  }

  /// 또래 평균 저축률(%, 반올림). 화면의 저축률 비교는 모두 이 값을 쓴다.
  int get avgSavingsRatePercent => (avgSavingsRate * 100).round();

  /// 또래 평균 대비 증감률(%). 음수면 또래보다 덜 씀.
  int diffPercent(int userExpense) =>
      peerDeltaPercent(mine: userExpense, peer: avgMonthlyExpense);

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

  /// 또래 평균과 차이(%)가 가장 큰 기본 분류. 둘 다 지출이 있는 항목만 본다.
  /// 비교할 항목이 없으면 null.
  ({BudgetCategory category, int deltaPercent, int mine, int peer})?
      largestCategoryGap(Map<BudgetCategory, int> mySummary) {
    BudgetCategory? best;
    double bestPercent = 0;

    for (final c in BudgetCategory.values) {
      final mine = mySummary[c] ?? 0;
      final peer = avgByCategory[c] ?? 0;
      if (mine <= 0 || peer <= 0) continue;
      final percent = (mine - peer) * 100 / peer;
      if (percent.abs() > bestPercent.abs()) {
        bestPercent = percent;
        best = c;
      }
    }

    if (best == null) return null;
    return (
      category: best,
      deltaPercent: bestPercent.round(),
      mine: mySummary[best]!,
      peer: avgByCategory[best]!,
    );
  }
}
