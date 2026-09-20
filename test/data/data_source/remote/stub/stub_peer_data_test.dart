import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  test('forGroup is deterministic and category sums ≈ mean', () {
    final a = StubPeerData.forGroup(AgeGroup.thirties);
    final b = StubPeerData.forGroup(AgeGroup.thirties);
    expect(a.avgMonthlyExpense, b.avgMonthlyExpense);
    expect(a.samples, b.samples);
    final catSum = a.avgByCategory.values.fold(0, (s, v) => s + v);
    expect((catSum - a.avgMonthlyExpense).abs() < a.avgMonthlyExpense * 0.02, isTrue);
    expect(a.samples.length, 99);
  });

  test('samples ascend and every group has all 12 categories', () {
    for (final g in AgeGroup.values) {
      final s = StubPeerData.forGroup(g);
      expect(s.ageGroup, g);
      expect(s.avgByCategory.length, BudgetCategory.values.length);
      for (var i = 1; i < s.samples.length; i++) {
        expect(s.samples[i] >= s.samples[i - 1], isTrue);
      }
    }
  });
}
