import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/peer/mock_peer_stats_source.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  final src = MockPeerStatsSource();
  test('forGroup is deterministic and category sums ≈ mean', () {
    final a = src.forGroup(AgeGroup.thirties);
    final b = src.forGroup(AgeGroup.thirties);
    expect(a.avgMonthlyExpense, b.avgMonthlyExpense);
    expect(a.samples, b.samples); // 결정적 _spread: 동일 입력 → 동일 표본
    final catSum = a.avgByCategory.values.fold(0, (s, v) => s + v);
    expect((catSum - a.avgMonthlyExpense).abs() < a.avgMonthlyExpense * 0.02, isTrue);
    expect(a.samples.length, 99);
  });
}
