import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedae_budget/entity/entity.dart';

class UserProfileStorage {
  static const _key = 'user_profile';

  Future<UserProfile?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> write(UserProfile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(p.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final userProfileStorageProvider =
    Provider<UserProfileStorage>((_) => UserProfileStorage());

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() => ref.read(userProfileStorageProvider).read();

  Future<void> save(UserProfile profile) async {
    await ref.read(userProfileStorageProvider).write(profile);
    state = AsyncData(profile);
  }

  Future<void> clear() async {
    await ref.read(userProfileStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
        UserProfileNotifier.new);
