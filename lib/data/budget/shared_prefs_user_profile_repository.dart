import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// SharedPreferences 로컬 저장. 키·JSON 모양은 기존 사용자 데이터와 호환된다.
class SharedPrefsUserProfileRepository implements UserProfileRepository {
  static const _key = 'user_profile';

  @override
  Future<UserProfile?> current() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
