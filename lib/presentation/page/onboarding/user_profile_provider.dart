import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  UserProfileRepository get _repo => locator<UserProfileRepository>();

  @override
  Future<UserProfile?> build() => _repo.current();

  Future<void> save(UserProfile profile) async {
    await _repo.save(profile);
    state = AsyncData(profile);
  }

  Future<void> clear() async {
    await _repo.clear();
    state = const AsyncData(null);
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
        UserProfileNotifier.new);
