import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/onboarding/user_profile_provider.dart';

import '../../helper/fakes.dart';

void main() {
  setUp(() => registerFakeUserDependencies());
  tearDown(() => locator.reset());

  test('build() returns null when nothing saved', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(userProfileProvider.future), isNull);
  });

  test('save() persists and updates state', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(userProfileProvider.future);
    await c.read(userProfileProvider.notifier).save(
        const UserProfile(ageGroup: AgeGroup.twenties, monthlyIncome: 2500000));
    expect(c.read(userProfileProvider).value?.ageGroup, AgeGroup.twenties);
    // 새 컨테이너에서 다시 읽어도 유지(저장소는 get_it 싱글턴)
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    expect((await c2.read(userProfileProvider.future))?.monthlyIncome, 2500000);
  });
}
