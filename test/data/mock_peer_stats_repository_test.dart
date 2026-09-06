import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  final PeerStatsRepository repo = MockPeerStatsRepository();

  test('forGroup is deterministic and category sums ≈ mean', () async {
    final a = await repo.forGroup(AgeGroup.thirties);
    final b = await repo.forGroup(AgeGroup.thirties);
    expect(a.avgMonthlyExpense, b.avgMonthlyExpense);
    expect(a.samples, b.samples); // 결정적 _spread: 동일 입력 → 동일 표본
    final catSum = a.avgByCategory.values.fold(0, (s, v) => s + v);
    expect((catSum - a.avgMonthlyExpense).abs() < a.avgMonthlyExpense * 0.02, isTrue);
    expect(a.samples.length, 99);
  });
}
