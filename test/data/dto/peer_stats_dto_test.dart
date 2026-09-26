import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  test('toJson uses categoryId string keys and enum names', () {
    final json = PeerStatsDto.fromEntity(StubPeerData.forGroup(AgeGroup.twenties)).toJson();
    expect(json['ageGroup'], 'twenties');
    final byCat = json['avgByCategory'] as Map<String, dynamic>;
    expect(byCat.keys, containsAll(['1', '12']));
    expect(byCat.keys.every((k) => int.tryParse(k) != null), isTrue);
  });

  test('fromJson(toJson(x)) round-trips every field', () {
    final original = StubPeerData.forGroup(AgeGroup.fiftiesPlus);
    final back =
        PeerStatsDto.fromJson(PeerStatsDto.fromEntity(original).toJson()).toEntity();
    expect(back.ageGroup, original.ageGroup);
    expect(back.avgMonthlyExpense, original.avgMonthlyExpense);
    expect(back.avgSavingsRate, original.avgSavingsRate);
    expect(back.avgByCategory, original.avgByCategory);
    expect(back.samples, original.samples);
  });

  // 서버가 분류를 늘려도 또래 부분 전체가 실패하지 않는다. 모르는 키만 버린다.
  test('모르는 분류 키는 버리고 아는 키는 남긴다', () {
    final stats = PeerStatsDto.fromJson({
      'ageGroup': 'thirties', 'avgMonthlyExpense': 1000000, 'avgSavingsRate': 0.2,
      'avgByCategory': {'1': 300000, '13': 5000, 'x': 1, '0': 2},
      'samples': [1, 2, 3],
    }).toEntity();
    expect(stats.avgByCategory, {BudgetCategory.food: 300000});
  });
}
