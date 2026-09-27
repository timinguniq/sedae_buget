import 'package:sedae_budget/entity/entity.dart';

/// Stub 서버가 응답하는 결정적(랜덤 아님) 또래 통계. 테스트 기대값도 여기서 만든다.
abstract class StubPeerData {
  StubPeerData._();

  // 나이대별 또래 평균 월지출(원).
  static const _means = <AgeGroup, int>{
    AgeGroup.teens: 800000,
    AgeGroup.twenties: 1900000,
    AgeGroup.thirties: 2600000,
    AgeGroup.forties: 3200000,
    AgeGroup.fiftiesPlus: 2800000,
  };
  static const _savings = <AgeGroup, double>{
    AgeGroup.teens: 0.10,
    AgeGroup.twenties: 0.18,
    AgeGroup.thirties: 0.22,
    AgeGroup.forties: 0.20,
    AgeGroup.fiftiesPlus: 0.25,
  };
  // 기본 분류별 평균 소비 비중(합=1.0).
  static const _share = <BudgetCategory, double>{
    BudgetCategory.groceries: 0.10,
    BudgetCategory.diningOut: 0.12,
    BudgetCategory.cafe: 0.04,
    BudgetCategory.drinks: 0.03,
    BudgetCategory.shopping: 0.06,
    BudgetCategory.beauty: 0.03,
    BudgetCategory.household: 0.04,
    BudgetCategory.housing: 0.16,
    BudgetCategory.communication: 0.05,
    BudgetCategory.transport: 0.05,
    BudgetCategory.car: 0.06,
    BudgetCategory.health: 0.05,
    BudgetCategory.education: 0.04,
    BudgetCategory.recreation: 0.05,
    BudgetCategory.travel: 0.04,
    BudgetCategory.pet: 0.01,
    BudgetCategory.gifts: 0.03,
    BudgetCategory.finance: 0.03,
    BudgetCategory.etc: 0.01,
  };

  static PeerStats forGroup(AgeGroup group) {
    final mean = _means[group]!;
    return PeerStats(
      ageGroup: group,
      avgMonthlyExpense: mean,
      avgSavingsRate: _savings[group]!,
      avgByCategory: {
        for (final c in BudgetCategory.values) c: (mean * _share[c]!).round(),
      },
      samples: _spread(mean, 99),
    );
  }

  // 0.45*mean ~ 1.75*mean 선형 분포(결정적, 오름차순).
  static List<int> _spread(int mean, int count) {
    final lo = (mean * 0.45).round(), hi = (mean * 1.75).round();
    return List.generate(count, (i) => lo + ((hi - lo) * i / (count - 1)).round());
  }
}
