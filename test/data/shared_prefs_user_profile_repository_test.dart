import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('save → current → clear round-trip', () async {
    final UserProfileRepository repo = SharedPrefsUserProfileRepository();
    expect(await repo.current(), isNull);
    await repo.save(
        const UserProfile(ageGroup: AgeGroup.twenties, monthlyIncome: 2500000));
    expect((await repo.current())?.monthlyIncome, 2500000);
    await repo.clear();
    expect(await repo.current(), isNull);
  });

  test('reads legacy key user_profile written before refactor', () async {
    SharedPreferences.setMockInitialValues(
        {'user_profile': '{"ageGroup":"twenties","monthlyIncome":2500000}'});
    expect((await SharedPrefsUserProfileRepository().current())?.ageGroup,
        AgeGroup.twenties);
  });
}
