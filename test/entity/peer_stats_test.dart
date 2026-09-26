import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/budget/age_group.dart';
import 'package:sedae_budget/entity/budget/budget_category.dart';
import 'package:sedae_budget/entity/peer/peer_comparison.dart';
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

  group('compareTotal · compareCategory', () {
    test('월 합계와 분류별 지출을 또래 평균과 비교한다', () {
      expect(stats.compareTotal(2200000)?.percent, 10);
      expect(stats.compareCategory(BudgetCategory.food, 270000)?.percent, -10);
    });

    // 또래 평균이 0이거나 빠진 분류를 '넘었다'고 읽으면 그 분류의 모든 지출에 배지가 붙었다.
    test('또래 평균이 0이거나 빠진 분류는 비교하지 않는다', () {
      expect(stats.compareCategory(BudgetCategory.education, 500000), isNull);
      expect(stats.compareCategory(BudgetCategory.health, 500000), isNull);
    });
  });

  group('rankOf', () {
    test('많이 쓸수록 등수·상위 %가 작아진다', () {
      final low = stats.rankOf(1200000)!;
      final high = stats.rankOf(2800000)!;
      expect(high.rank, lessThan(low.rank));
      expect(high.topPercent, lessThan(low.topPercent));
    });

    test('전체 인원은 표본에 나를 더한 수, 상위 %는 나보다 적게 쓴 비율의 보수', () {
      final r = stats.rankOf(1500000)!;
      expect(r.total, 100);
      expect(r.topPercent, 100 - r.percentBelow);
    });

    // 이전에는 표본이 없어도 '또래 1명 중 1등 · 상위 100%'로 보였다.
    test('표본이 없으면 순위를 매기지 않는다', () {
      final empty = PeerStats(
        ageGroup: AgeGroup.twenties, avgMonthlyExpense: 0, avgSavingsRate: 0,
        avgByCategory: const {}, samples: const []);
      expect(empty.rankOf(1000000), isNull);
    });
  });

  test('histogram sums to sample count', () {
    expect(stats.histogram(10).reduce((a, b) => a + b), 99);
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
      expect(gap?.comparison.percent, 100);
      expect(gap?.comparison.mine, 600000);
      expect(gap?.comparison.peer, 300000);
    });
    test('덜 쓴 쪽이 더 크면 그쪽을 고른다', () {
      final gap = stats.largestCategoryGap(const {
        BudgetCategory.food: 310000, // +3%
        BudgetCategory.transport: 20000, // -80%
      });
      expect(gap?.category, BudgetCategory.transport);
      expect(gap?.comparison.percent, -80);
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
    // 차이가 없는 것도 발견이다('비슷하게 썼어요'). 비교할 항목이 없는 것과 다르다.
    test('모든 항목이 또래와 같으면 그중 첫 항목을 비슷하다고 고른다', () {
      final gap = stats.largestCategoryGap(const {BudgetCategory.food: 300000});
      expect(gap?.category, BudgetCategory.food);
      expect(gap?.comparison.direction, PeerDirection.similar);
    });
    test('비교할 항목이 없으면 null', () {
      expect(stats.largestCategoryGap(const {}), isNull);
    });
  });
}
