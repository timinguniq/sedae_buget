import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/budget/age_group.dart';
import 'package:sedae_budget/entity/budget/budget_category.dart';
import 'package:sedae_budget/entity/peer/peer_stats.dart';

void main() {
  final stats = PeerStats(
    ageGroup: AgeGroup.thirties,
    avgMonthlyExpense: 2000000,
    avgSavingsRate: 0.2,
    avgByCategory: const {BudgetCategory.food: 300000},
    samples: List.generate(99, (i) => 1000000 + i * 20000), // 1.0M ~ ~2.96M
  );

  test('diffPercent sign', () {
    expect(stats.diffPercent(1800000), lessThan(0));
    expect(stats.diffPercent(2200000), greaterThan(0));
  });
  test('percentBelow monotonic', () {
    expect(stats.percentBelow(1000000), lessThan(stats.percentBelow(2500000)));
  });
  test('rankOf: more spend => smaller rank', () {
    final low = stats.rankOf(1200000).rank;
    final high = stats.rankOf(2800000).rank;
    expect(high, lessThan(low));
  });
  test('histogram sums to sample count', () {
    expect(stats.histogram(10).reduce((a, b) => a + b), 99);
  });
}
