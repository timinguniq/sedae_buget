import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/budget/age_group.dart';
import 'package:sedae_budget/entity/budget/budget_category.dart';
import 'package:sedae_budget/entity/peer/peer_stats.dart';

void main() {
  final stats = PeerStats(
    ageGroup: AgeGroup.thirties,
    avgMonthlyExpense: 2000000,
    avgSavingsRate: 0.2,
    avgByCategory: const {
      BudgetCategory.food: 300000,
      BudgetCategory.transport: 100000,
      BudgetCategory.education: 0, // 또래 평균이 없는 항목
    },
    samples: List.generate(99, (i) => 1000000 + i * 20000), // 1.0M ~ 2.96M
  );

  // 홈 저축률 카드와 비교 화면 막대가 같은 반올림 규칙을 쓴다.
  test('avgSavingsRatePercent는 비율을 반올림한 %', () {
    expect(stats.avgSavingsRatePercent, 20);
    PeerStats withRate(double r) => PeerStats(
        ageGroup: AgeGroup.thirties, avgMonthlyExpense: 0, avgSavingsRate: r,
        avgByCategory: const {}, samples: const []);
    expect(withRate(0.235).avgSavingsRatePercent, 24);
    expect(withRate(0.234).avgSavingsRatePercent, 23);
  });

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

  group('peerDeltaPercent', () {
    test('또래 평균이 0이면 0', () {
      expect(peerDeltaPercent(mine: 50000, peer: 0), 0);
    });
    test('더 쓰면 양수, 덜 쓰면 음수', () {
      expect(peerDeltaPercent(mine: 600000, peer: 300000), 100);
      expect(peerDeltaPercent(mine: 270000, peer: 300000), -10);
    });
    test('반올림은 0에서 먼 쪽으로 — 부호를 붙이기 전과 뒤가 같다', () {
      expect(peerDeltaPercent(mine: 205, peer: 200), 3);
      expect(peerDeltaPercent(mine: 195, peer: 200), -3);
    });
    test('diffPercent는 같은 규칙을 쓴다', () {
      expect(
        stats.diffPercent(2200000),
        peerDeltaPercent(mine: 2200000, peer: stats.avgMonthlyExpense),
      );
    });
  });

  group('topPercent', () {
    test('percentBelow의 보수', () {
      expect(stats.topPercent(1500000), 100 - stats.percentBelow(1500000));
    });
    test('많이 쓸수록 상위 %가 작아진다', () {
      expect(stats.topPercent(2800000), lessThan(stats.topPercent(1200000)));
    });
  });

  group('bucketIndexOf', () {
    test('표본이 없으면 0', () {
      final empty = PeerStats(
        ageGroup: AgeGroup.twenties,
        avgMonthlyExpense: 0,
        avgSavingsRate: 0,
        avgByCategory: const {},
        samples: const [],
      );
      expect(empty.bucketIndexOf(123456, 15), 0);
    });
    test('최소 표본은 첫 버킷, 최대 표본은 마지막 버킷', () {
      expect(stats.bucketIndexOf(1000000, 15), 0);
      expect(stats.bucketIndexOf(2960000, 15), 14);
    });
    test('범위 밖 값은 양 끝으로 clamp', () {
      expect(stats.bucketIndexOf(-1, 15), 0);
      expect(stats.bucketIndexOf(999999999, 15), 14);
    });
    test('histogram과 같은 구간을 쓴다', () {
      final counted = List.filled(10, 0);
      for (final s in stats.samples) {
        counted[stats.bucketIndexOf(s, 10)]++;
      }
      expect(counted, stats.histogram(10));
    });
  });

  group('largestCategoryGap', () {
    test('또래와 차이(%)가 가장 큰 항목을 고른다', () {
      final gap = stats.largestCategoryGap(const {
        BudgetCategory.food: 600000, // +100%
        BudgetCategory.transport: 90000, // -10%
      });
      expect(gap?.category, BudgetCategory.food);
      expect(gap?.deltaPercent, 100);
      expect(gap?.mine, 600000);
      expect(gap?.peer, 300000);
    });
    test('덜 쓴 쪽이 더 크면 그쪽을 고른다', () {
      final gap = stats.largestCategoryGap(const {
        BudgetCategory.food: 310000, // +3%
        BudgetCategory.transport: 20000, // -80%
      });
      expect(gap?.category, BudgetCategory.transport);
      expect(gap?.deltaPercent, -80);
    });
    test('내 지출이나 또래 평균이 0인 항목은 후보에서 뺀다', () {
      expect(
        stats.largestCategoryGap(const {
          BudgetCategory.education: 500000, // 또래 평균 0
          BudgetCategory.food: 0, // 내 지출 0
        }),
        isNull,
      );
    });
    test('비교할 항목이 없으면 null', () {
      expect(stats.largestCategoryGap(const {}), isNull);
    });
  });
}
