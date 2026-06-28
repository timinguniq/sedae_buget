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
  final double avgSavingsRate; // 0..1
  final Map<BudgetCategory, int> avgByCategory;
  final List<int> samples; // 또래 월지출 표본(분포/순위 계산용)
}

extension PeerStatsX on PeerStats {
  /// 또래 중 [userExpense]보다 적게 쓴 비율(%). 클수록 사용자가 많이 쓴 편.
  int percentBelow(int userExpense) {
    if (samples.isEmpty) return 0;
    final below = samples.where((s) => s < userExpense).length;
    return (below * 100 / samples.length).round();
  }

  /// 많이 쓰는 순 등수(1 = 가장 많이 씀)와 전체 인원(사용자 포함).
  ({int rank, int total}) rankOf(int userExpense) {
    final higher = samples.where((s) => s > userExpense).length;
    return (rank: higher + 1, total: samples.length + 1);
  }

  /// 또래 평균 대비 증감률(%). 음수면 또래보다 덜 씀.
  int diffPercent(int userExpense) {
    if (avgMonthlyExpense == 0) return 0;
    return ((userExpense - avgMonthlyExpense) * 100 / avgMonthlyExpense).round();
  }

  /// 분포를 [bucketCount]개 구간 막대 높이(인원수)로.
  List<int> histogram(int bucketCount) {
    if (samples.isEmpty) return List.filled(bucketCount, 0);
    // min/max(정렬 가정 없이) — 표본 순서에 무관하게 동작.
    final lo = samples.reduce((a, b) => a < b ? a : b);
    final hi = samples.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo) == 0 ? 1 : (hi - lo);
    final buckets = List.filled(bucketCount, 0);
    for (final s in samples) {
      var idx = ((s - lo) * bucketCount / span).floor();
      if (idx >= bucketCount) idx = bucketCount - 1;
      if (idx < 0) idx = 0;
      buckets[idx]++;
    }
    return buckets;
  }
}
