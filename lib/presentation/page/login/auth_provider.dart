import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedae_budget/entity/entity.dart';

class AuthStorage {
  static const _key = 'auth_user';

  Future<AuthUser?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> write(AuthUser u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(u.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final authStorageProvider = Provider<AuthStorage>((_) => AuthStorage());

class AuthNotifier extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() => ref.read(authStorageProvider).read();

  /// 백엔드 없음 → 목업 로그인: 제공자별 가짜 닉네임으로 로컬 저장.
  Future<void> signInMock(AuthProvider provider) async {
    final user = AuthUser(provider: provider, nickname: '${provider.label} 사용자');
    await ref.read(authStorageProvider).write(user);
    state = AsyncData(user);
  }

  Future<void> signOut() async {
    await ref.read(authStorageProvider).clear();
    state = const AsyncData(null);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthUser?>(AuthNotifier.new);
