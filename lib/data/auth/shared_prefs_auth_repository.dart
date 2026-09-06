import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';

/// SharedPreferences 로컬 저장. 키·JSON 모양은 기존 사용자 데이터와 호환된다.
class SharedPrefsAuthRepository implements AuthRepository {
  static const _key = 'auth_user';

  @override
  Future<AuthUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }

  @override
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
