import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  test('toJson uses categoryId string keys and enum names', () {
    final json = peerStatsToJson(StubPeerData.forGroup(AgeGroup.twenties));
    expect(json['ageGroup'], 'twenties');
    final byCat = json['avgByCategory'] as Map<String, dynamic>;
    expect(byCat.keys, containsAll(['1', '12']));
    expect(byCat.keys.every((k) => int.tryParse(k) != null), isTrue);
  });

  test('fromJson(toJson(x)) round-trips every field', () {
    final original = StubPeerData.forGroup(AgeGroup.fiftiesPlus);
    final back = peerStatsFromJson(peerStatsToJson(original));
    expect(back.ageGroup, original.ageGroup);
    expect(back.avgMonthlyExpense, original.avgMonthlyExpense);
    expect(back.avgSavingsRate, original.avgSavingsRate);
    expect(back.avgByCategory, original.avgByCategory);
    expect(back.samples, original.samples);
  });
}
