import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/budget/age_group.dart';
import 'package:sedae_budget/entity/budget/user_profile.dart';

void main() {
  test('UserProfile JSON round-trips', () {
    const p = UserProfile(ageGroup: AgeGroup.thirties, monthlyIncome: 3000000);
    final back = UserProfile.fromJson(p.toJson());
    expect(back, p);
    expect(p.toJson()['ageGroup'], 'thirties');
  });
}
