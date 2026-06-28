import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/budget/age_group.dart';

void main() {
  test('AgeGroup has 5 buckets with labels', () {
    expect(AgeGroup.values.length, 5);
    expect(AgeGroup.teens.label, '10대');
    expect(AgeGroup.twenties.label, '20대');
    expect(AgeGroup.thirties.label, '30대');
    expect(AgeGroup.forties.label, '40대');
    expect(AgeGroup.fiftiesPlus.label, '50대+');
  });
}
